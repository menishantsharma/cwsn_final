from urllib.parse import urlencode

from allauth.account.adapter import DefaultAccountAdapter
from rest_framework.authtoken.models import Token


class MobileAwareAccountAdapter(DefaultAccountAdapter):
    """
    Custom allauth adapter that detects mobile OAuth requests (flagged via
    session) and redirects back to the app via deep link after a successful
    social login, carrying a DRF auth token in the query parameters.

    All other logins (web admin, browser) fall through to the default
    behaviour unchanged.
    """

    def get_login_redirect_url(self, request):
        # Check for the mobile flag set by MobileOAuthStartView.
        if request.session.pop('mobile_oauth', False):
            user = request.user
            if not user or not user.is_authenticated:
                return 'cwsn://auth/callback?error=unauthenticated'

            token, _ = Token.objects.get_or_create(user=user)

            params = urlencode({
                'token': token.key,
                'user_id': str(user.pk),
                'email': user.email or '',
                'first_name': user.first_name or '',
                'last_name': user.last_name or '',
            })
            return f'cwsn://auth/callback?{params}'

        # Non-mobile login – use default redirect (LOGIN_REDIRECT_URL or '/').
        return super().get_login_redirect_url(request)
