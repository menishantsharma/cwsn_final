# apps/interactions/views.py
from django.forms import ValidationError
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import serializers
from .models import Notification, ServiceRequest, Report, Upvote
from .serializers import NotificationSerializer, ServiceRequestSerializer, ReportSerializer, UpvoteSerializer
from .permissions import IsModeratorInRegion
from rest_framework.exceptions import PermissionDenied
from apps.services.models import Service

class ServiceRequestViewSet(viewsets.ModelViewSet):
    serializer_class = ServiceRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        service_id = self.request.query_params.get('service')
        caregiver_id = self.request.query_params.get('caregiver')
        as_parent = self.request.query_params.get('as_parent')

        base = (
            ServiceRequest.objects
            .select_related(
                'service',
                'child',
                'cwsn_user__cwsn_profile',
                'caregiver__caregiver_profile',
            )
        )

        # forces the CWSN (sender) view even for dual-role users.
        force_parent_view = as_parent == 'true' or caregiver_id is not None

        if user.is_caregiver and not force_parent_view:
            qs = base.filter(caregiver=user)
            if service_id:
                qs = qs.filter(service_id=service_id)
            return qs
        if user.is_cwsn_user:
            qs = base.filter(cwsn_user=user)
            if service_id:
                qs = qs.filter(service_id=service_id)
            if caregiver_id:
                qs = qs.filter(caregiver_id=caregiver_id)
            return qs
        return ServiceRequest.objects.none()
    
    def perform_create(self, serializer):
        if not self.request.user.is_cwsn_user:
            raise PermissionDenied("Only CWSN users can send requests.")
        
        service = serializer.validated_data.get('service')
        child = serializer.validated_data.get('child')
        
        if service.caregiver.is_suspended:
            raise PermissionDenied("This caregiver is suspended and cannot receive new requests.")
            
        existing = ServiceRequest.objects.filter(
            cwsn_user=self.request.user, child=child, service=service,
        ).first()
        
        if existing:
            if existing.status == 'Rejected':
                existing.delete()
            else:
                raise serializers.ValidationError(
                    {"non_field_errors": ["A request for this child and service already exists."]}
                )

        serializer.save(cwsn_user=self.request.user, caregiver=service.caregiver)

    @action(detail=False, methods=['get'])
    def pending_count(self, request):
        count = self.get_queryset().filter(status='Pending').count()
        return Response({'count': count})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def accept(self, request, pk=None):
        service_request = self.get_object()
        if request.user != service_request.caregiver:
            return Response({'error': 'Not authorized'}, status=status.HTTP_403_FORBIDDEN)

        service_request.status = 'Accepted'
        service_request.save(update_fields=['status'])
        return Response(ServiceRequestSerializer(service_request).data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def reject(self, request, pk=None):
        service_request = self.get_object()
        if request.user not in [service_request.caregiver, service_request.cwsn_user]:
            return Response({'error': 'Not authorized'}, status=status.HTTP_403_FORBIDDEN)

        service_request.status = 'Rejected'
        service_request.save(update_fields=['status'])
        return Response(ServiceRequestSerializer(service_request).data)

class ReportViewSet(viewsets.ModelViewSet):
    serializer_class = ReportSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_permissions(self):
        if self.action in ['update', 'partial_update', 'destroy']:
            self.permission_classes = [permissions.IsAdminUser | IsModeratorInRegion]
        return super().get_permissions()

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Report.objects.all()
        if user.is_moderator:
            regions = user.moderator_profile.regions.all()
            return Report.objects.filter(region_of_incident__in=regions)
        if user.is_authenticated:
            return Report.objects.filter(reporter=user)
        return Report.objects.none()
    
    def perform_create(self, serializer):
        serializer.save(reporter=self.request.user)

class UpvoteViewSet(viewsets.ModelViewSet):
    serializer_class = UpvoteSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Upvote.objects.filter(voter=self.request.user)

    def perform_create(self, serializer):
        if not self.request.user.is_cwsn_user:
            raise permissions.PermissionDenied("Only CWSN users can upvote services.")
        
        service = serializer.validated_data.get('service')
        
        has_accepted = ServiceRequest.objects.filter(
            cwsn_user=self.request.user,
            caregiver=service.caregiver,
            status='Accepted',
        ).exists()

        if not has_accepted:
            raise serializers.ValidationError("You can only upvote a service once a request to that caregiver has been accepted.")

        if Upvote.objects.filter(voter=self.request.user, service=service).exists():
            raise serializers.ValidationError("You have already upvoted this service.")

        serializer.save(voter=self.request.user)

class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(
            recipient=self.request.user
        ).select_related('recipient')

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save(update_fields=['is_read'])
        return Response({'status': 'marked as read'})

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        updated_count = self.get_queryset().filter(is_read=False).update(is_read=True)
        return Response({'status': f'{updated_count} notifications marked as read'})

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        count = self.get_queryset().filter(is_read=False).count()
        return Response({'count': count})