# apps/common/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'regions', views.RegionViewSet)
router.register(r'categories', views.ServiceCategoryViewSet)
router.register(r'disabilities', views.DisabilityViewSet)
router.register(r'languages', views.LanguageViewSet)
router.register(r'subcategories', views.ServiceSubCategoryViewSet, basename='servicesubcategory')
router.register(r'issues', views.AppIssueViewSet, basename='appissue')

urlpatterns = [
    path('', include(router.urls)),
]