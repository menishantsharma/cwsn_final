# apps/services/models.py
from django.db import models
from django.conf import settings
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.core.cache import cache

class ActiveServiceManager(models.Manager):
    """
    A custom manager that returns only active, non-archived services from
    non-suspended, verified caregivers.
    """
    def get_queryset(self):
        return super().get_queryset().filter(
            is_active=True,
            is_archived=False,
            caregiver__is_suspended=False,
            caregiver__caregiver_profile__is_verified=True
        )

class Service(models.Model):
    SERVICE_TYPES = [('Online', 'Online'), ('Offline', 'Offline'), ('Hybrid', 'Hybrid')]
    PAYMENT_TYPES = [('Paid', 'Paid'), ('Unpaid', 'Unpaid')]
    GENDER_TARGETS = [('Male', 'Male'), ('Female', 'Female'), ('Any', 'Any')]

    title = models.CharField(max_length=255)
    description = models.TextField()
    service_type = models.CharField(max_length=10, choices=SERVICE_TYPES)
    payment_type = models.CharField(max_length=10, choices=PAYMENT_TYPES)
    max_participants = models.PositiveIntegerField(null=True, blank=True)
    target_age_min = models.PositiveIntegerField(null=True, blank=True)
    target_age_max = models.PositiveIntegerField(null=True, blank=True)
    target_gender = models.CharField(max_length=10, choices=GENDER_TARGETS, default='Any')
    target_disabilities = models.ManyToManyField('common.Disability', blank=True)
    
    caregiver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='services')
    sub_category = models.ForeignKey('common.ServiceSubCategory', on_delete=models.SET_NULL, null=True, blank=True)
    category = models.ForeignKey('common.ServiceCategory', on_delete=models.SET_NULL, null=True)
    region = models.ForeignKey('common.Region', on_delete=models.SET_NULL, null=True, blank=True, related_name='services')
    image = models.ImageField(upload_to='service_images/', null=True, blank=True)
    upvote_count = models.PositiveIntegerField(default=0)
    
    is_active = models.BooleanField(default=True)
    is_archived = models.BooleanField(default=False, help_text="Soft-delete status. Archived services are hidden.")

    objects = models.Manager()
    active = ActiveServiceManager()

    class Meta:
        ordering = ['-id']
        indexes = [
            # Public listing: non-archived, non-suspended caregiver
            models.Index(fields=['caregiver', 'is_archived']),
            # Subcategory listing (most common query)
            models.Index(fields=['sub_category', 'is_archived']),
            # Category-level listing
            models.Index(fields=['category', 'is_archived']),
            # Region-scoped queries (Offline distance filter)
            models.Index(fields=['region', 'is_archived']),
        ]

    def __str__(self):
        return self.title

class AvailabilitySlot(models.Model):
    caregiver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='availability_slots')
    service = models.ForeignKey(Service, on_delete=models.CASCADE, related_name='slots', null=True, blank=True)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    is_booked = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.caregiver.email} slot for {self.service.title}"

# --- REDIS CACHE INVALIDATION ---
@receiver([post_save, post_delete], sender=Service)
def invalidate_service_cache(sender, instance, **kwargs):
    # Using delete_pattern from django-redis to wipe all paginated/filtered permutations
    cache.delete_pattern("services_list_*")
    cache.delete(f"service_detail_{instance.id}")