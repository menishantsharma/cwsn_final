# apps/services/serializers.py
from rest_framework import serializers
from .models import Service, AvailabilitySlot
from apps.users.serializers import CaregiverProfileSerializer
from apps.common.models import Disability

class AvailabilitySlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = AvailabilitySlot
        fields = ['id', 'service', 'start_time', 'end_time', 'is_booked']
        read_only_fields = ['is_booked']

    def validate(self, data):
        if data['start_time'] >= data['end_time']:
            raise serializers.ValidationError("End time must be after start time.")
        return data

class ServiceSerializer(serializers.ModelSerializer):
    # Nested read-only data for display
    caregiver_profile = CaregiverProfileSerializer(source='caregiver.caregiver_profile', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    sub_category_name = serializers.CharField(source='sub_category.name', read_only=True, default='')
    slots = AvailabilitySlotSerializer(many=True, read_only=True)

    # For Writing: Accepting IDs
    target_disabilities = serializers.PrimaryKeyRelatedField(
        many=True, queryset=Disability.objects.all(), required=False
    )
    # For Reading: displaying names
    target_disabilities_names = serializers.StringRelatedField(
        many=True, read_only=True, source='target_disabilities'
    )

    class Meta:
        model = Service
        fields = [
            'id', 'title', 'description', 'image', 'is_active', 'is_archived', 'upvote_count',
            'service_type', 'payment_type', 'max_participants',
            'target_age_min', 'target_age_max', 'target_gender',
            'caregiver', 'caregiver_profile',
            'category', 'category_name',
            'sub_category', 'sub_category_name',
            'slots', 'target_disabilities', 'target_disabilities_names',
            'region',
        ]
        read_only_fields = ['caregiver', 'upvote_count', 'is_archived']