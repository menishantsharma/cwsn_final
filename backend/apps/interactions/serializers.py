# apps/interactions/serializers.py
from rest_framework import serializers
from .models import Notification, ServiceRequest, Report, Upvote

class ServiceRequestSerializer(serializers.ModelSerializer):
    service_title = serializers.CharField(source='service.title', read_only=True)
    child_name = serializers.CharField(source='child.name', read_only=True)
    child_age = serializers.IntegerField(source='child.age', read_only=True)
    child_gender = serializers.CharField(source='child.gender', read_only=True)
    cwsn_user_phone = serializers.CharField(source='cwsn_user.phone_number', read_only=True)
    cwsn_user_name = serializers.SerializerMethodField()
    caregiver_phone = serializers.CharField(source='caregiver.phone_number', read_only=True)
    caregiver_name = serializers.SerializerMethodField()

    class Meta:
        model = ServiceRequest
        fields = [
            'id', 'service', 'service_title', 'child', 'child_name',
            'child_age', 'child_gender',
            'cwsn_user', 'cwsn_user_phone', 'cwsn_user_name',
            'caregiver', 'caregiver_phone', 'caregiver_name',
            'status', 'note', 'created_at'
        ]
        read_only_fields = ('cwsn_user', 'caregiver', 'status')
    
    def update(self, instance, validated_data):
        validated_data.pop('note', None)
        return super().update(instance, validated_data)

    def get_cwsn_user_name(self, obj):
        profile = getattr(obj.cwsn_user, 'cwsn_profile', None)
        return profile.name if profile else obj.cwsn_user.phone_number

    def get_caregiver_name(self, obj):
        profile = getattr(obj.caregiver, 'caregiver_profile', None)
        return profile.name if profile else obj.caregiver.phone_number

class ReportSerializer(serializers.ModelSerializer):
    reporter_email = serializers.EmailField(source='reporter.email', read_only=True)
    reported_user_email = serializers.EmailField(source='reported_user.email', read_only=True)

    class Meta:
        model = Report
        fields = [
            'id', 'reporter', 'reporter_email', 'reported_user', 
            'reported_user_email', 'reason', 'region_of_incident', 
            'status', 'created_at'
        ]
        read_only_fields = ('reporter', 'region_of_incident', 'status')

class UpvoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Upvote
        fields = ['id', 'voter', 'service', 'created_at']
        read_only_fields = ('voter',)

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'id', 'notification_type', 'title', 'message', 
            'is_read', 'created_at', 'content_type', 'object_id'
        ]
        read_only_fields = ['notification_type', 'title', 'message', 'created_at', 'content_type', 'object_id']