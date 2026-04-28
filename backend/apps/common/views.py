# apps/common/views.py
from django.db import transaction, IntegrityError
from rest_framework import viewsets, views, status, response
from django.utils import timezone
from django.db.models import F
import random
from .models import (
    Region, ServiceCategory, Disability, Language, ServiceSubCategory,
    Ad, AdRegionWeight, AdDailyAnalytics
)
from .serializers import (
    RegionSerializer, ServiceCategorySerializer, DisabilitySerializer,
    LanguageSerializer, ServiceSubCategorySerializer
)

# These are simple read-only viewsets for the app to get filter options
class RegionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Region.objects.all()
    serializer_class = RegionSerializer

class ServiceCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ServiceCategory.objects.all()
    serializer_class = ServiceCategorySerializer

class ServiceSubCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = ServiceSubCategorySerializer

    def get_queryset(self):
        qs = ServiceSubCategory.objects.all()
        category_id = self.request.query_params.get('category')
        if category_id:
            qs = qs.filter(category_id=category_id)
        return qs

class DisabilityViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Disability.objects.all()
    serializer_class = DisabilitySerializer

class LanguageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Language.objects.all()
    serializer_class = LanguageSerializer

class FetchAdAPIView(views.APIView):
    permission_classes = [] 

    def get(self, request):
        region_id = request.query_params.get('region_id')
        
        if not region_id:
            return response.Response({"error": "region_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        # 1. Get all active weights for this region
        today = timezone.localdate()
        weights = AdRegionWeight.objects.filter(
            region_id=region_id,
            ad__is_active=True,
            ad__start_date__lte=today,
        ).exclude(ad__end_date__lt=today) # Exclude expired ads

        if not weights.exists():
            return response.Response({"message": "No ads available for this region"}, status=status.HTTP_404_NOT_FOUND)

        # 2. Extract ads and their corresponding weights
        ad_list = [w.ad for w in weights]
        weight_list = [w.weight for w in weights]

        # 3. Pick ONE ad based on the weights (e.g., 70% chance for Ad 1, 30% for Ad 2)
        selected_ad = random.choices(population=ad_list, weights=weight_list, k=1)[0]

        # 4. Return the ad data
        return response.Response({
            "id": selected_ad.id,
            "title": selected_ad.title,
            "image_url": selected_ad.image_url,
            "redirect_url": selected_ad.redirect_url
        })

class RecordAdInteractionAPIView(views.APIView):
    permission_classes = []

    def post(self, request, ad_id):
        action = request.data.get('action') # 'view' or 'click'
        region_id = request.data.get('region_id')
        
        if action not in ['view', 'click']:
            return response.Response({"error": "Invalid action"}, status=status.HTTP_400_BAD_REQUEST)

        date_today = timezone.localdate()

        # Determine what we are incrementing
        update_kwargs = (
            {'views': F('views') + 1}
            if action == 'view'
            else {'clicks': F('clicks') + 1}
        )

        # 1. OPTIMISTIC UPDATE
        rows_updated = AdDailyAnalytics.objects.filter(
            ad_id=ad_id,
            region_id=region_id,
            date=date_today
        ).update(**update_kwargs)

        # 2. CREATION FALLBACK
        if rows_updated == 0:
            try:
                with transaction.atomic():
                    AdDailyAnalytics.objects.create(
                        ad_id=ad_id,
                        region_id=region_id,
                        date=date_today,
                        views=1 if action == 'view' else 0,
                        clicks=1 if action == 'click' else 0
                    )
            except IntegrityError:
                # Row was created by another request → update instead
                AdDailyAnalytics.objects.filter(
                    ad_id=ad_id,
                    region_id=region_id,
                    date=date_today
                ).update(**update_kwargs)

        return response.Response({"status": "recorded"})
