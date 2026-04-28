# apps/users/views.py
import hashlib
from django.core.cache import cache
import requests
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, permission_classes as perm
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.conf import settings
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
from .models import User, CWSNProfile, ChildProfile, CaregiverProfile
from .serializers import CWSNProfileSerializer, ChildProfileSerializer, CaregiverProfileSerializer
from apps.common.utils import assign_region_from_coordinates

class SendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        phone_number = request.data.get('phone_number')
        if not phone_number:
            return Response({'error': 'Phone number is required'}, status=status.HTTP_400_BAD_REQUEST)

        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        client.http_client.timeout = 5.0  # Timeout applied here

        try:
            verification = client.verify \
                .v2 \
                .services(settings.TWILIO_VERIFY_SERVICE_SID) \
                .verifications \
                .create(to=phone_number, channel='whatsapp')
            
            return Response({'status': 'OTP sent successfully via WhatsApp', 'sid': verification.sid}, status=status.HTTP_200_OK)
            
        except TwilioRestException as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except requests.exceptions.Timeout:
            # Catching the timeout gracefully
            return Response({'error': 'Twilio service timed out. Please try again.'}, status=status.HTTP_504_GATEWAY_TIMEOUT)


class VerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        phone_number = request.data.get('phone_number')
        code = request.data.get('code')

        if not phone_number or not code:
            return Response({'error': 'Phone number and code are required'}, status=status.HTTP_400_BAD_REQUEST)

        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        client.http_client.timeout = 5.0  # ADDED TIMEOUT HERE

        try:
            verification_check = client.verify \
                .v2 \
                .services(settings.TWILIO_VERIFY_SERVICE_SID) \
                .verification_checks \
                .create(to=phone_number, code=code)

            if verification_check.status == 'approved':
                user, created = User.objects.get_or_create(phone_number=phone_number)
                token, _ = Token.objects.get_or_create(user=user)
                return Response({
                    'status': 'OTP verified successfully',
                    'token': token.key,
                    'is_new_user': created,
                    'user_id': user.id,
                    'is_cwsn_user': user.is_cwsn_user,
                    'is_caregiver': user.is_caregiver,
                }, status=status.HTTP_200_OK)
            else:
                return Response({'error': 'Invalid OTP'}, status=status.HTTP_400_BAD_REQUEST)
                
        except TwilioRestException as e:
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except requests.exceptions.Timeout:
            # Catching the timeout gracefully
            return Response({'error': 'Twilio service timed out. Please try again.'}, status=status.HTTP_504_GATEWAY_TIMEOUT)

@api_view(['POST'])
@perm([permissions.IsAuthenticated])
def switch_role(request):
    role = request.data.get('role', '').lower()
    user = request.user

    if role == 'caregiver':
        if not user.is_caregiver:
            user.is_caregiver = True
            user.save(update_fields=['is_caregiver'])
            
        CaregiverProfile.objects.get_or_create(
            user=user,
            defaults={
                'name': user.phone_number,
                'age': 0,
                'gender': 'Other',
            },
        )
        return Response({'status': 'ok', 'role': 'caregiver'})

    if role == 'parent':
        if not user.is_cwsn_user:
            user.is_cwsn_user = True
            user.save(update_fields=['is_cwsn_user'])
            
        CWSNProfile.objects.get_or_create(
            user=user,
            defaults={
                'name': user.phone_number,
                'age': 0,
                'gender': 'Other',
            },
        )
        return Response({'status': 'ok', 'role': 'parent'})

    return Response(
        {'detail': 'Invalid role. Use "caregiver" or "parent".'},
        status=status.HTTP_400_BAD_REQUEST,
    )

@api_view(['DELETE'])
@perm([permissions.IsAuthenticated])
def delete_account(request):
    user = request.user
    user.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)

class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.user == request.user

class CWSNProfileViewSet(viewsets.ModelViewSet):
    serializer_class = CWSNProfileSerializer
    permission_classes = [permissions.IsAuthenticated, IsOwnerOrReadOnly]

    def get_queryset(self):
        return CWSNProfile.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        lat = self.request.data.get('latitude')
        lon = self.request.data.get('longitude')
        region = assign_region_from_coordinates(lat, lon) if lat and lon else None
        serializer.save(user=self.request.user, region=region)

    def perform_update(self, serializer):
        lat = self.request.data.get('latitude')
        lon = self.request.data.get('longitude')
        if lat and lon:
            region = assign_region_from_coordinates(lat, lon)
            serializer.save(region=region)
        else:
            serializer.save()

class ChildProfileViewSet(viewsets.ModelViewSet):
    serializer_class = ChildProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ChildProfile.objects.filter(parent=self.request.user)

    def perform_create(self, serializer):
        serializer.save(parent=self.request.user)

class CaregiverProfileViewSet(viewsets.ModelViewSet):
    serializer_class = CaregiverProfileSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsOwnerOrReadOnly]

    def get_queryset(self):
        if (self.action == 'list' and self.request.query_params.get('mine') and self.request.user.is_authenticated):
            return CaregiverProfile.objects.filter(user=self.request.user).prefetch_related('languages')

        if self.action == 'list':
            return CaregiverProfile.active.all().prefetch_related('languages')
            
        return CaregiverProfile.objects.all().prefetch_related('languages')

    def list(self, request, *args, **kwargs):
        is_mine = request.query_params.get('mine') == 'true'
        
        # Never cache the user's own profile â€” it must reflect updates immediately.
        if is_mine:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)
            
        query_string = request.META.get('QUERY_STRING', '')
        cache_key = f"caregiver_profiles_list_public_{hashlib.md5(query_string.encode()).hexdigest()}"

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
            
        cache.set(cache_key, response_data, timeout=900)
        return Response(response_data)

    def retrieve(self, request, *args, **kwargs):
        profile_id = kwargs.get('pk')
        cache_key = f"caregiver_profile_detail_{profile_id}"
        
        cached_data = cache.get(cache_key)
        if cached_data:
            return Response(cached_data)

        instance = self.get_object()
        serializer = self.get_serializer(instance)
        cache.set(cache_key, serializer.data, timeout=900)
        return Response(serializer.data)

    def perform_create(self, serializer):
        lat = self.request.data.get('latitude')
        lon = self.request.data.get('longitude')
        region = assign_region_from_coordinates(lat, lon) if lat and lon else None
        instance = serializer.save(user=self.request.user, region=region)
        cache.delete(f"caregiver_profile_detail_{instance.pk}")

    def perform_update(self, serializer):
        lat = self.request.data.get('latitude')
        lon = self.request.data.get('longitude')
        if lat and lon:
            region = assign_region_from_coordinates(lat, lon)
            instance = serializer.save(region=region)
        else:
            instance = serializer.save()
            
        cache.delete(f"caregiver_profile_detail_{instance.pk}")