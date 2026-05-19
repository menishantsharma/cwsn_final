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
    
    # Core Auth Routes (OTP sent by Firebase on device; backend only verifies the id_token)
    path('auth/verify-otp/', views.VerifyOTPView.as_view(), name='verify_otp'),
    path('auth/me/', views.MeView.as_view(), name='auth_me'),
    path('auth/onboarded/', views.MarkOnboardedView.as_view(), name='mark_onboarded'),

    # Change Phone (Flutter verifies new number via Firebase, sends id_token here)
    path('change-phone/confirm/', views.ChangePhoneConfirmView.as_view(), name='change_phone_confirm'),
]