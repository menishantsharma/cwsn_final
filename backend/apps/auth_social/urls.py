from django.urls import path

from .views import social_token_login

urlpatterns = [
    # POST /api/auth/social/token/
    # Body: {"provider": "google|apple|facebook", "token": "<token>"}
    path('token/', social_token_login, name='social_token_login'),
]
