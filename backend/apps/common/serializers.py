# apps/common/serializers.py
from rest_framework import serializers
from .models import Region, ServiceCategory, Disability, Language, ServiceSubCategory

class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = ['id', 'name', 'parent']

class ServiceSubCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceSubCategory
        fields = ['id', 'category', 'name', 'short_description', 'image_url']

class ServiceCategorySerializer(serializers.ModelSerializer):
    # Optionally nest sub-categories so the frontend gets everything in one call
    subcategories = ServiceSubCategorySerializer(many=True, read_only=True)

    class Meta:
        model = ServiceCategory
        fields = ['id', 'name', 'short_description', 'image_url', 'subcategories']

class DisabilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Disability
        fields = ['id', 'name']

class LanguageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Language
        fields = ['id', 'name']