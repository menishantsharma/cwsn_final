# apps/common/serializers.py
from rest_framework import serializers
from .models import AppIssue, Region, ServiceCategory, Disability, Language, ServiceSubCategory

class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = ['id', 'name', 'parent']

class ServiceSubCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceSubCategory
        fields = ['id', 'category', 'name', 'short_description', 'image_url']

class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ['id', 'name', 'short_description', 'image_url']

class DisabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Disability
        fields = ['id', 'name']

class LanguageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Language
        fields = ['id', 'name']

class AppIssueSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppIssue
        fields = ['id', 'description', 'created_at']
        read_only_fields = ['created_at']