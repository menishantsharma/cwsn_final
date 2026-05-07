# apps/services/views.py
from django.db.models import Q
from rest_framework import viewsets, permissions, status, decorators
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from apps.users.models import CaregiverProfile
from .models import Service, AvailabilitySlot
from .serializers import ServiceSerializer, AvailabilitySlotSerializer
from .filters import ServiceFilter
import hashlib
from django.core.cache import cache

class IsCaregiverOwnerOrReadOnly(permissions.BasePermission):
    """
    Custom permission:
    - Safe methods (GET, HEAD, OPTIONS) allowed for everyone.
    - Write permissions only for the caregiver who owns the object.
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        # Write permissions only for the caregiver who owns this service
        return obj.caregiver == request.user

class ServiceViewSet(viewsets.ModelViewSet):
    serializer_class = ServiceSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsCaregiverOwnerOrReadOnly]
    filterset_class = ServiceFilter
    parser_classes = (MultiPartParser, FormParser)

    def get_queryset(self):
        """
        Logic:
        1. ?mine=true → return only the authenticated caregiver's own services.
        2. Public/Clients see ONLY active services.
        3. Caregivers see active services AND their own inactive services.
        """
        user = self.request.user

        base = (
            Service.objects
            .select_related(
                'caregiver__caregiver_profile__region',
                'category',
                'sub_category',
            )
            .prefetch_related('slots', 'target_disabilities')
        )

        if self.request.query_params.get('mine') == 'true' and user.is_authenticated:
            return base.filter(caregiver=user, is_archived=False)

        return base.filter(caregiver__is_suspended=False, is_archived=False).distinct()
    
    # --- REDIS CACHING IMPLEMENTATION ---
    def list(self, request, *args, **kwargs):
        is_mine = request.query_params.get('mine') == 'true'
        
        # Hash the query string so different filters get different cache keys
        query_string = request.META.get('QUERY_STRING', '')
        query_hash = hashlib.md5(query_string.encode('utf-8')).hexdigest()

        if is_mine and request.user.is_authenticated:
            cache_key = f"services_list_user_{request.user.id}_{query_hash}"
        else:
            cache_key = f"services_list_public_{query_hash}"

        cached_data = cache.get(cache_key)
        if cached_data:
            return Response(cached_data)

        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response_data = self.get_paginated_response(serializer.data).data
        else:
            serializer = self.get_serializer(queryset, many=True)
            response_data = serializer.data
            
        cache.set(cache_key, response_data, timeout=900) # Cache for 15 minutes
        return Response(response_data)

    def retrieve(self, request, *args, **kwargs):
        service_id = kwargs.get('pk')
        cache_key = f"service_detail_{service_id}"
        
        cached_data = cache.get(cache_key)
        if cached_data:
            return Response(cached_data)

        instance = self.get_object()
        serializer = self.get_serializer(instance)
        cache.set(cache_key, serializer.data, timeout=900)
        return Response(serializer.data)
    # ------------------------------------

    # ADDED: Soft Delete (Archive) instead of hard delete
    def destroy(self, request, *args, **kwargs):
        service = self.get_object()
        service.is_archived = True
        service.is_active = False # Deactivate it so it stops showing in active lists
        service.save(update_fields=['is_archived', 'is_active'])
        return Response({'status': 'Service archived'}, status=status.HTTP_204_NO_CONTENT)

    def perform_create(self, serializer):
        user = self.request.user
        # Auto-promote to caregiver on first service creation
        if not getattr(user, 'is_caregiver', False):
            user.is_caregiver = True
            user.save(update_fields=['is_caregiver'])
        # Ensure a CaregiverProfile exists so search results include it
        CaregiverProfile.objects.get_or_create(
            user=user,
            defaults={
                'name': user.get_full_name() or user.email,
                'contact_no': '',
                'age': 0,
                'gender': 'Other',
            },
        )
        serializer.save(caregiver=user)

class AvailabilitySlotViewSet(viewsets.ModelViewSet):
    serializer_class = AvailabilitySlotSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsCaregiverOwnerOrReadOnly]

    def get_queryset(self):
        """
        Frontend usage: /api/slots/?service=1
        """
        queryset = AvailabilitySlot.objects.all()
        
        # Filter by service if provided in query params
        service_id = self.request.query_params.get('service')
        if service_id:
            queryset = queryset.filter(service_id=service_id)
            
        # Optional: Hide booked slots from public list?
        # if self.action == 'list':
        #     queryset = queryset.filter(is_booked=False)
            
        return queryset

    def perform_create(self, serializer):
        # Ensure the user creating the slot owns the service
        service = serializer.validated_data.get('service')
        if service and service.caregiver != self.request.user:
             raise PermissionDenied("You can only add slots to your own services.")
        serializer.save(caregiver=self.request.user)

    @decorators.action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def book(self, request, pk=None):
        """
        Custom endpoint to book a slot.
        URL: POST /api/slots/{id}/book/
        """
        slot = self.get_object()
        
        if slot.is_booked:
            return Response({'detail': 'This slot is already booked.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Authentication note: You might want to log who booked this.
        # Since the current model doesn't have a 'client' field, we just toggle the flag.
        slot.is_booked = True
        slot.save()
        
        return Response({'status': 'booked', 'slot_id': slot.id}, status=status.HTTP_200_OK)