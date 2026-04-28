# apps/users/tests_performance.py
import time
from django.urls import reverse
from rest_framework.test import APITestCase
from rest_framework import status
from django.core.cache import cache

from .models import User, CaregiverProfile
from apps.common.models import Language, Region

class CachePerformanceTests(APITestCase):
    
    def setUp(self):
        """
        Set up a heavy database state to ensure the initial database query 
        and serialization take a measurable amount of time.
        """
        self.region = Region.objects.create(name="Performance Test Region")
        self.lang1 = Language.objects.create(name="English")
        self.lang2 = Language.objects.create(name="Hindi")

        # Use phone_number instead of username/email
        self.test_user = User.objects.create_user(phone_number="+1000000000")
        self.client.force_authenticate(user=self.test_user)

        # Bulk create 50 Caregiver Profiles
        for i in range(50):
            cg_user = User.objects.create_user(
                phone_number=f"+100000000{i + 1}", 
                is_caregiver=True
            )
            profile = CaregiverProfile.objects.create(
                user=cg_user,
                name=f"Caregiver {i}",
                age=30,
                gender="Any",
                region=self.region,
                is_verified=True 
            )
            profile.languages.add(self.lang1, self.lang2)

    def test_cache_speed_difference(self):
        """
        Measures the time difference between an uncached request and a cached request.
        """
        cache.clear()
        
        url = reverse('caregiverprofile-list')

        # --- REQUEST 1: THE CACHE MISS ---
        start_time_miss = time.time()
        response_miss = self.client.get(url, format='json')
        end_time_miss = time.time()
        time_taken_miss = end_time_miss - start_time_miss
        self.assertEqual(response_miss.status_code, status.HTTP_200_OK)

        # --- REQUEST 2: THE CACHE HIT ---
        start_time_hit = time.time()
        response_hit = self.client.get(url, format='json')
        end_time_hit = time.time()
        time_taken_hit = end_time_hit - start_time_hit
        self.assertEqual(response_hit.status_code, status.HTTP_200_OK)

        print(f"\n--- Performance Test Results ---")
        print(f"Uncached Request (DB + Serialization): {time_taken_miss:.5f} seconds")
        print(f"Cached Request (Redis):              {time_taken_hit:.5f} seconds")
        
        if time_taken_hit > 0:
            speedup = time_taken_miss / time_taken_hit
            print(f"Speedup Multiplier:                  {speedup:.2f}x faster")
        print(f"--------------------------------\n")

        self.assertLess(
            time_taken_hit, 
            time_taken_miss / 2, 
            "The cached request was not significantly faster than the uncached request. Is Redis working?"
        )