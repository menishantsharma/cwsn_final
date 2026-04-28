# apps/users/tests_twilio.py
from unittest.mock import patch
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from .models import User

class TwilioPhoneAuthTests(APITestCase):
    
    # We no longer need setUp() to pre-authenticate users, 
    # because these endpoints are now public (AllowAny).

    # --- SEND OTP TESTS ---

    @patch('apps.users.views.Client')
    def test_send_otp_success(self, MockTwilioClient):
        """Test that sending an OTP returns a 200 OK via WhatsApp."""
        mock_instance = MockTwilioClient.return_value
        mock_instance.verify.v2.services().verifications.create.return_value.sid = 'VE1234567890'

        url = reverse('send_otp')
        response = self.client.post(url, {'phone_number': '+1234567890'}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['sid'], 'VE1234567890')
        self.assertEqual(response.data['status'], 'OTP sent successfully via WhatsApp')

    def test_send_otp_missing_number(self):
        """Test that omitting the phone number returns a 400 Bad Request."""
        url = reverse('send_otp')
        response = self.client.post(url, {}, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    # --- VERIFY OTP TESTS (LOGIN/SIGNUP) ---

    @patch('apps.users.views.Client')
    def test_verify_otp_new_user_signup(self, MockTwilioClient):
        """Test that an approved OTP for a new number creates a User and returns a token."""
        mock_instance = MockTwilioClient.return_value
        mock_instance.verify.v2.services().verification_checks.create.return_value.status = 'approved'

        test_phone = '+1987654321'
        url = reverse('verify_otp')
        response = self.client.post(url, {
            'phone_number': test_phone,
            'code': '123456'
        }, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_new_user'])
        self.assertIn('token', response.data)
        
        # Verify the user was actually created in the database
        self.assertTrue(User.objects.filter(phone_number=test_phone).exists())

    @patch('apps.users.views.Client')
    def test_verify_otp_existing_user_login(self, MockTwilioClient):
        """Test that an approved OTP for an existing number logs them in."""
        test_phone = '+1122334455'
        User.objects.create_user(phone_number=test_phone)

        mock_instance = MockTwilioClient.return_value
        mock_instance.verify.v2.services().verification_checks.create.return_value.status = 'approved'

        url = reverse('verify_otp')
        response = self.client.post(url, {
            'phone_number': test_phone,
            'code': '654321'
        }, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Should flag as NOT a new user, but still return a valid token
        self.assertFalse(response.data['is_new_user'])
        self.assertIn('token', response.data)

    @patch('apps.users.views.Client')
    def test_verify_otp_failure(self, MockTwilioClient):
        """Test that an incorrect OTP denies access and returns 400."""
        mock_instance = MockTwilioClient.return_value
        mock_instance.verify.v2.services().verification_checks.create.return_value.status = 'pending'

        url = reverse('verify_otp')
        response = self.client.post(url, {
            'phone_number': '+1122334455',
            'code': '000000' # Wrong code
        }, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(response.data['error'], 'Invalid OTP')

    def test_verify_otp_missing_params(self):
        """Test that omitting required parameters returns a 400 Bad Request."""
        url = reverse('verify_otp')
        response = self.client.post(url, {
            'phone_number': '+1234567890'
            # Missing 'code'
        }, format='json')
        
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)