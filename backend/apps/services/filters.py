# apps/services/filters.py
import math
import django_filters
from django.db.models import Q, F, FloatField, ExpressionWrapper
from django.db.models.functions import Cast, Power, Sqrt
from .models import Service

class NumberInFilter(django_filters.BaseInFilter, django_filters.NumberFilter):
    pass

class CharInFilter(django_filters.BaseInFilter, django_filters.CharFilter):
    pass

class ServiceFilter(django_filters.FilterSet):
    category = django_filters.NumberFilter(field_name='category__id')
    sub_category = django_filters.NumberFilter(field_name='sub_category__id')
    service_type = django_filters.ChoiceFilter(choices=Service.SERVICE_TYPES)
    payment_type = django_filters.ChoiceFilter(choices=Service.PAYMENT_TYPES)
    target_gender = django_filters.ChoiceFilter(choices=Service.GENDER_TARGETS)
    
    region = NumberInFilter(field_name='region__id', lookup_expr='in')
    target_disabilities = NumberInFilter(field_name='target_disabilities__id', lookup_expr='in')
    
    caregiver_gender = django_filters.CharFilter(field_name='caregiver__caregiver_profile__gender', lookup_expr='iexact')
    languages = CharInFilter(field_name='caregiver__caregiver_profile__languages__name', lookup_expr='in')

    search = django_filters.CharFilter(method='filter_search')
    child_age = django_filters.NumberFilter(method='filter_child_age')
    
    distance_km = django_filters.NumberFilter(method='filter_by_distance')
    user_lat = django_filters.NumberFilter(method='skip_filter')
    user_lon = django_filters.NumberFilter(method='skip_filter')

    class Meta:
        model = Service
        fields = [
            'category', 'sub_category', 'service_type', 'payment_type',
            'target_gender', 'region', 'target_disabilities', 'caregiver_gender', 'languages'
        ]

    def skip_filter(self, queryset, name, value):
        return queryset

    def filter_by_distance(self, queryset, name, value):
        lat_str = self.data.get('user_lat')
        lon_str = self.data.get('user_lon')
        
        lat, lon = None, None
        
        if lat_str and lon_str:
            lat = float(lat_str)
            lon = float(lon_str)
        else:
            request = getattr(self, 'request', None)
            if request and request.user.is_authenticated and hasattr(request.user, 'cwsn_profile'):
                profile = request.user.cwsn_profile
                if profile.latitude and profile.longitude:
                    lat = float(profile.latitude)
                    lon = float(profile.longitude)
                    
        if lat is None or lon is None:
            return queryset 

        # --- DISTANCE CALCULATION CHANGES START HERE ---
        
        # Apply the 10% Margin
        distance_limit = float(value)
        adjusted_limit = distance_limit * 1.10
        
        # Conversion factors (Degrees to KM)
        # 1 degree of latitude is approx 111 km. 
        # Longitude distance changes based on how close you are to the poles.
        lat_degree_km = 111.0
        lon_degree_km = 111.0 * math.cos(math.radians(lat))

        # Calculate Bounding Box boundaries in degrees
        lat_margin = adjusted_limit / lat_degree_km
        lon_margin = adjusted_limit / lon_degree_km

        # Bounding Box Pre-Filter (Fast indexed scan)
        queryset = queryset.filter(
            caregiver__caregiver_profile__latitude__isnull=False,
            caregiver__caregiver_profile__longitude__isnull=False,
            caregiver__caregiver_profile__latitude__range=(lat - lat_margin, lat + lat_margin),
            caregiver__caregiver_profile__longitude__range=(lon - lon_margin, lon + lon_margin)
        )

        # Fast 2D Euclidean Distance Calculation on the remaining rows
        cg_lat = Cast(F('caregiver__caregiver_profile__latitude'), FloatField())
        cg_lon = Cast(F('caregiver__caregiver_profile__longitude'), FloatField())

        queryset = queryset.annotate(
            distance_calc=ExpressionWrapper(
                Sqrt(
                    Power((cg_lat - lat) * lat_degree_km, 2) +
                    Power((cg_lon - lon) * lon_degree_km, 2)
                ),
                output_field=FloatField(),
            )
        ).filter(distance_calc__lte=adjusted_limit)
        
        # --- DISTANCE CALCULATION CHANGES END HERE ---
        
        return queryset

    def filter_search(self, queryset, name, value):
        return queryset.filter(
            Q(title__icontains=value) | Q(description__icontains=value)
        )

    def filter_child_age(self, queryset, name, value):
        return queryset.filter(
            (Q(target_age_min__lte=value) | Q(target_age_min__isnull=True)) &
            (Q(target_age_max__gte=value) | Q(target_age_max__isnull=True))
        )