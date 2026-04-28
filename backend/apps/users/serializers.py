# apps/users/serializers.py
from rest_framework import serializers
from .models import User, CWSNProfile, ChildProfile, CaregiverProfile
from apps.common.models import Language
from apps.interactions.models import ServiceRequest

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'phone_number', 'email', 'is_cwsn_user', 'is_caregiver', 'is_moderator']

class ChildProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChildProfile
        fields = '__all__'
        read_only_fields = ['parent']

class CWSNProfileSerializer(serializers.ModelSerializer):
    children = ChildProfileSerializer(many=True, read_only=True)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)

    class Meta:
        model = CWSNProfile
        fields = [
            'id', 'user', 'name', 'age', 'gender', 'children',
            'street_address', 'landmark', 'postal_code',
            'latitude', 'longitude', 'phone_number'
        ]

class CaregiverProfileSerializer(serializers.ModelSerializer):
    contact_no = serializers.SerializerMethodField()
    region_name = serializers.CharField(source='region.name', read_only=True)
    languages = serializers.SerializerMethodField()
    language_ids = serializers.PrimaryKeyRelatedField(
        many=True, queryset=Language.objects.all(),
        write_only=True, source='languages', required=False,
    )
    upvote_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = CaregiverProfile
        fields = [
            'id', 'user', 'name', 'age', 'gender', 'region', 'region_name',
            'about_me', 'street_address', 'landmark', 'postal_code',
            'latitude', 'longitude', 'qualifications', 'recommendations',
            'upvote_count', 'languages', 'language_ids', 'contact_no'
        ]

    def get_languages(self, obj):
        return [lang.name for lang in obj.languages.all()]

    def get_contact_no(self, profile_obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        
        requesting_user = request.user
        if profile_obj.user == requesting_user:
            return profile_obj.user.phone_number
            
        user_requests = ServiceRequest.objects.filter(
            cwsn_user=requesting_user,
            caregiver=profile_obj.user
        )
        if user_requests.filter(status='Accepted').exists():
            return profile_obj.user.phone_number
            
        return None