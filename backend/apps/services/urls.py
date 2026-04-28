# apps/services/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'services' # Useful for reverse lookup like 'services:service-list'

router = DefaultRouter()
router.register(r'services', views.ServiceViewSet, basename='service')
router.register(r'slots', views.AvailabilitySlotViewSet, basename='availabilityslot')

urlpatterns = [
    path('', include(router.urls)),
]