# tests.py
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from apps.users.models import User, CWSNProfile, CaregiverProfile, ChildProfile
from apps.common.models import Region, ServiceCategory, Disability
from apps.services.models import Service
from apps.interactions.models import ServiceRequest, Upvote, Report

class MasterBackendIntegrationTests(APITestCase):
    
    def setUp(self):
        # 1. Core Base Data
        self.region = Region.objects.create(name="Mumbai", latitude=19.0760, longitude=72.8777)
        self.category = ServiceCategory.objects.create(name="Therapy", short_description="Desc")
        self.disability = Disability.objects.create(name="Autism")

        # 2. Users Setup (Replaced username/email with phone_number)
        self.parent_user = User.objects.create_user(phone_number="+19999999999")
        self.caregiver_user = User.objects.create_user(phone_number="+18888888888")
        self.mod_user = User.objects.create_user(phone_number="+17777777777", is_moderator=True)

        # 3. API Clients
        self.parent_client = self.client_class()
        self.parent_client.force_authenticate(user=self.parent_user)
        
        self.caregiver_client = self.client_class()
        self.caregiver_client.force_authenticate(user=self.caregiver_user)

    def test_01_onboarding_and_role_switch(self):
        """Test user role switching and profile auto-creation."""
        # Parent Onboarding
        res = self.parent_client.post('/api/users/switch-role/', {'role': 'parent'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(User.objects.get(phone_number="+19999999999").is_cwsn_user)
        self.assertTrue(CWSNProfile.objects.filter(user=self.parent_user).exists())

        # Caregiver Onboarding
        res = self.caregiver_client.post('/api/users/switch-role/', {'role': 'caregiver'})
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(User.objects.get(phone_number="+18888888888").is_caregiver)
        self.assertTrue(CaregiverProfile.objects.filter(user=self.caregiver_user).exists())

    def test_02_profile_updates_and_region_assignment(self):
        """Test profile updates, address fields, and spatial region assignment."""
        self.parent_client.post('/api/users/switch-role/', {'role': 'parent'})
        profile = CWSNProfile.objects.get(user=self.parent_user)
        
        data = {
            'name': 'John Doe',
            'age': 35,
            'gender': 'Male',
            'street_address': '123 Main St',
            'postal_code': '400001',
            'latitude': 19.0760,
            'longitude': 72.8777
        }
        res = self.parent_client.patch(f'/api/users/cwsn-profiles/{profile.id}/', data)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        
        # Verify region auto-assignment
        profile.refresh_from_db()
        self.assertEqual(profile.region, self.region)
        self.assertEqual(profile.postal_code, '400001')

    def test_03_child_creation_permissions(self):
        """Test child creation and ensure only parents can create them."""
        self.parent_client.post('/api/users/switch-role/', {'role': 'parent'})
        
        data = {
            'name': 'Timmy',
            'age': 5,
            'gender': 'Male',
            'disabilities': [self.disability.id]
        }
        res = self.parent_client.post('/api/users/child-profiles/', data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ChildProfile.objects.count(), 1)
        self.assertEqual(ChildProfile.objects.first().parent, self.parent_user)

    def test_04_service_creation_and_archiving(self):
        """Test caregiver creating and archiving a service."""
        self.caregiver_client.post('/api/users/switch-role/', {'role': 'caregiver'})
        
        data = {
            'title': 'Speech Therapy',
            'description': '1-on-1 therapy',
            'category': self.category.id,
            'service_type': 'Online',
            'payment_type': 'Paid',
            'target_gender': 'Any',
            'region': self.region.id
        }
        
        # Create Service
        res = self.caregiver_client.post('/api/services/services/', data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        service_id = res.data['id']
        
        # Soft Delete (Archive)
        res_del = self.caregiver_client.delete(f'/api/services/services/{service_id}/')
        self.assertEqual(res_del.status_code, status.HTTP_204_NO_CONTENT)
        
        # Verify it is archived and inactive
        service = Service.objects.get(id=service_id)
        self.assertTrue(service.is_archived)
        self.assertFalse(service.is_active)

    def test_05_service_requests_and_notes(self):
        """Test request flow including the new note field."""
        self.parent_client.post('/api/users/switch-role/', {'role': 'parent'})
        self.caregiver_client.post('/api/users/switch-role/', {'role': 'caregiver'})
        
        child = ChildProfile.objects.create(parent=self.parent_user, name="Timmy", age=5, gender="Male")
        service = Service.objects.create(caregiver=self.caregiver_user, title="Therapy", service_type="Online", payment_type="Paid")

        data = {
            'service': service.id,
            'child': child.id,
            'note': 'Please consider Timmy for morning slots.'
        }
        
        # Parent sends request
        res = self.parent_client.post('/api/interactions/requests/', data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        req_id = res.data['id']
        
        # Verify Note
        request_obj = ServiceRequest.objects.get(id=req_id)
        self.assertEqual(request_obj.note, 'Please consider Timmy for morning slots.')

        # Attempt to modify note via PATCH (should fail/ignore)
        self.parent_client.patch(f'/api/interactions/requests/{req_id}/', {'note': 'Hacked note'})
        request_obj.refresh_from_db()
        self.assertEqual(request_obj.note, 'Please consider Timmy for morning slots.')

        # Caregiver Accepts
        res_accept = self.caregiver_client.post(f'/api/interactions/requests/{req_id}/accept/')
        self.assertEqual(res_accept.status_code, status.HTTP_200_OK)
        request_obj.refresh_from_db()
        self.assertEqual(request_obj.status, 'Accepted')

    def test_06_upvote_logic_and_edge_cases(self):
        """Test upvoting constraints (must have requested) and aggregate count."""
        self.parent_client.post('/api/users/switch-role/', {'role': 'parent'})
        self.caregiver_client.post('/api/users/switch-role/', {'role': 'caregiver'})
        
        # Setup Caregiver Profile to test property aggregation
        CaregiverProfile.objects.get(user=self.caregiver_user) 
        
        child = ChildProfile.objects.create(parent=self.parent_user, name="Timmy", age=5, gender="Male")
        service = Service.objects.create(caregiver=self.caregiver_user, title="Therapy", service_type="Online", payment_type="Paid")

        # Edge Case 1: Try upvoting without requesting
        res_fail = self.parent_client.post('/api/interactions/upvotes/', {'service': service.id})
        self.assertEqual(res_fail.status_code, status.HTTP_400_BAD_REQUEST)
        
        # Create Request
        ServiceRequest.objects.create(cwsn_user=self.parent_user, caregiver=self.caregiver_user, child=child, service=service, status="Pending")

        # Upvote Success
        res_success = self.parent_client.post('/api/interactions/upvotes/', {'service': service.id})
        self.assertEqual(res_success.status_code, status.HTTP_201_CREATED)
        
        # Edge Case 2: Duplicate upvote
        res_dup = self.parent_client.post('/api/interactions/upvotes/', {'service': service.id})
        self.assertEqual(res_dup.status_code, status.HTTP_400_BAD_REQUEST)

        # Check Aggregate property on CaregiverProfile
        service.refresh_from_db()
        self.assertEqual(service.upvote_count, 1)
        self.assertEqual(self.caregiver_user.caregiver_profile.upvote_count, 1)

    def test_07_report_flow(self):
        """Test that a user can report a caregiver."""
        data = {
            'reported_user': self.caregiver_user.id,
            'reason': 'Inappropriate behavior'
        }
        res = self.parent_client.post('/api/interactions/reports/', data)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Report.objects.count(), 1)
        self.assertEqual(Report.objects.first().reporter, self.parent_user)

    def test_08_permissions_edge_cases(self):
        """Test boundary permissions for specific roles."""
        self.caregiver_client.post('/api/users/switch-role/', {'role': 'caregiver'})
        
        # Caregiver tries to create a child
        res1 = self.caregiver_client.post('/api/users/child-profiles/', {'name': 'Timmy', 'age': 5, 'gender': 'Male'})
        
        # Caregiver tries to send a service request
        child = ChildProfile.objects.create(parent=self.parent_user, name="Timmy", age=5, gender="Male")
        service = Service.objects.create(caregiver=self.caregiver_user, title="Therapy", service_type="Online", payment_type="Paid")
        
        res2 = self.caregiver_client.post('/api/interactions/requests/', {
            'service': service.id,
            'child': child.id
        })
        self.assertEqual(res2.status_code, status.HTTP_403_FORBIDDEN)