# apps/users/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'cwsn-profiles', views.CWSNProfileViewSet, basename='cwsnprofile')
router.register(r'child-profiles', views.ChildProfileViewSet, basename='childprofile')
router.register(r'caregiver-profiles', views.CaregiverProfileViewSet, basename='caregiverprofile')

urlpatterns = [
    path('', include(router.urls)),
    path('switch-role/', views.switch_role, name='switch_role'),
    path('delete-account/', views.delete_account, name='delete_account'),
    
    # Core Auth Routes
    path('auth/send-otp/', views.SendOTPView.as_view(), name='send_otp'),
    path('auth/verify-otp/', views.VerifyOTPView.as_view(), name='verify_otp'),
]