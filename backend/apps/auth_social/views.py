import requests as http_requests

from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token

from apps.users.models import User


# ---------------------------------------------------------------------------
# Provider token validators
# Each returns a dict {email, first_name, last_name, provider_uid} or None.
# ---------------------------------------------------------------------------

def _validate_google_token(id_token: str):
    """Validate a Google ID token via Google's tokeninfo endpoint."""
    resp = http_requests.get(
        'https://oauth2.googleapis.com/tokeninfo',
        params={'id_token': id_token},
        timeout=10,
    )
    if resp.status_code != 200:
        return None
    data = resp.json()
    return {
        'email': data.get('email'),
        'first_name': data.get('given_name', ''),
        'last_name': data.get('family_name', ''),
        'provider_uid': data.get('sub'),
    }


def _validate_apple_token(identity_token: str):
    """
    Decode an Apple identity token (JWT).
    In production you should verify the signature against Apple's public keys.
    """
    import jwt
    try:
        decoded = jwt.decode(
            identity_token,
            options={'verify_signature': False},
            algorithms=['RS256'],
        )
        return {
            'email': decoded.get('email', ''),
            'first_name': '',
            'last_name': '',
            'provider_uid': decoded.get('sub'),
        }
    except Exception:
        return None


def _validate_facebook_token(access_token: str):
    """Validate a Facebook access token via the Graph API."""
    resp = http_requests.get(
        'https://graph.facebook.com/me',
        params={
            'access_token': access_token,
            'fields': 'id,email,first_name,last_name',
        },
        timeout=10,
    )
    if resp.status_code != 200:
        return None
    data = resp.json()
    return {
        'email': data.get('email'),
        'first_name': data.get('first_name', ''),
        'last_name': data.get('last_name', ''),
        'provider_uid': data.get('id'),
    }


_VALIDATORS = {
    'google': _validate_google_token,
    'apple': _validate_apple_token,
    'facebook': _validate_facebook_token,
}


# ---------------------------------------------------------------------------
# API endpoint
# ---------------------------------------------------------------------------

@api_view(['POST'])
@permission_classes([AllowAny])
def social_token_login(request):
    """
    POST /api/auth/social/token/
    Body: {"provider": "google|apple|facebook", "token": "<id/access token>"}

    Validates the token with the provider, gets or creates a local user,
    and returns a DRF auth token the Flutter app uses for all future requests.

    Optionally accepts "first_name" and "last_name" in the body — Apple
    only sends the name on the very first sign-in, so the Flutter app
    forwards it here.
    """
    provider = request.data.get('provider', '').lower()
    token = request.data.get('token', '')

    if not token:
        return Response(
            {'error': 'Token is required.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    validator = _VALIDATORS.get(provider)
    if validator is None:
        return Response(
            {'error': f'Unknown provider: {provider}'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user_info = validator(token)
    if user_info is None:
        return Response(
            {'error': 'Invalid or expired token.'},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    email = user_info.get('email')
    if not email:
        return Response(
            {'error': 'Email not available from provider.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Apple only provides the name on the first sign-in; accept from body.
    first_name = (
        request.data.get('first_name')
        or user_info.get('first_name', '')
    )
    last_name = (
        request.data.get('last_name')
        or user_info.get('last_name', '')
    )

    user, created = User.objects.get_or_create(
        email=email,
        defaults={
            'first_name': first_name,
            'last_name': last_name,
            'username': email,
        },
    )

    # Update name if the user existed but had blank fields.
    if not created:
        changed = False
        if not user.first_name and first_name:
            user.first_name = first_name
            changed = True
        if not user.last_name and last_name:
            user.last_name = last_name
            changed = True
        if changed:
            user.save(update_fields=['first_name', 'last_name'])

    auth_token, _ = Token.objects.get_or_create(user=user)

    return Response({
        'token': auth_token.key,
        'user_id': str(user.pk),
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'is_new_user': created,
    })
