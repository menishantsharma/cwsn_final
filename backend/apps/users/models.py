# apps/users/models.py
from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.conf import settings
from apps.common.models import Region
from django.db.models import Sum
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from apps.services.models import Service
from django.core.cache import cache

class CustomUserManager(BaseUserManager):
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError('The Phone Number must be set')
        # Extra formatting or validation for phone numbers could go here
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(phone_number, password, **extra_fields)


class User(AbstractUser):
    # Use phone_number as the primary identifier for WhatsApp OTP Auth
    phone_number = models.CharField(max_length=20, unique=True, help_text="Primary identifier for WhatsApp OTP.")
    email = models.EmailField(unique=True, blank=True, null=True)
    username = models.CharField(max_length=150, blank=True)

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = []

    # Use the custom manager
    objects = CustomUserManager()

    # Role booleans
    is_cwsn_user = models.BooleanField(default=False)
    is_caregiver = models.BooleanField(default=False)
    is_moderator = models.BooleanField(default=False)
    is_suspended = models.BooleanField(
        default=False,
        help_text="Hide user from listings and disable new requests."
    )
    has_completed_onboarding = models.BooleanField(
        default=False,
        help_text="Set to True once the user finishes the onboarding flow."
    )
    suspension_reason = models.TextField(
        blank=True, 
        null=True,
        help_text="Why the moderator suspended them (spam, fake info, etc.)"
    )

    @property
    def display_name(self):
        """Intelligently grabs the user's name based on their role/profile."""
        if self.is_caregiver and hasattr(self, 'caregiver_profile'):
            return self.caregiver_profile.name
        elif self.is_cwsn_user and hasattr(self, 'cwsn_profile'):
            return self.cwsn_profile.name
        elif self.first_name or self.last_name:
            return f"{self.first_name} {self.last_name}".strip()
        return "New User (No Profile)"

    def __str__(self):
        # This globally changes how the user is displayed in foreign keys, dropdowns, etc.
        return f"{self.display_name} ({self.phone_number})"

class ActiveCaregiverManager(models.Manager):
    """
    A custom manager that returns only active, non-suspended caregivers.
    """
    def get_queryset(self):
        return super().get_queryset().filter(
            user__is_suspended=False,
            is_verified=True
        )

class CWSNProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='cwsn_profile')
    name = models.CharField(max_length=255)
    age = models.PositiveIntegerField()
    gender = models.CharField(max_length=10, choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')])
    
    street_address = models.CharField(max_length=255, blank=True, default='')
    landmark = models.CharField(max_length=255, blank=True, default='')
    postal_code = models.CharField(max_length=20, blank=True, default='')
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    region = models.ForeignKey('common.Region', on_delete=models.SET_NULL, null=True, blank=True, related_name='cwsn_users')
    
    def __str__(self):
        return f"{self.name}'s CWSN Profile"

class ChildProfile(models.Model):
    parent = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='children')
    name = models.CharField(max_length=255)
    age = models.PositiveIntegerField()
    gender = models.CharField(max_length=10, choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')])
    disabilities = models.ManyToManyField('common.Disability', blank=True)

    def __str__(self):
        return f"{self.name} (Child of {self.parent.phone_number})"

class CaregiverProfile(models.Model):
    AVAILABILITY_CHOICES = [
        ('Available', 'Available'),
        ('Busy', 'Busy'),
    ]
    
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='caregiver_profile')
    name = models.CharField(max_length=255)
    age = models.PositiveIntegerField()
    gender = models.CharField(max_length=10, choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')])
    qualifications = models.TextField(blank=True)
    recommendations = models.TextField(blank=True)
    languages = models.ManyToManyField('common.Language', blank=True)
    about_me = models.TextField(blank=True)
    
    street_address = models.CharField(max_length=255, blank=True, default='')
    landmark = models.CharField(max_length=255, blank=True, default='')
    postal_code = models.CharField(max_length=20, blank=True, default='')
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    region = models.ForeignKey('common.Region', on_delete=models.SET_NULL, null=True, blank=True, related_name='caregivers')
    
    is_verified = models.BooleanField(
        default=False,
        help_text="Moderator has verified this caregiver's qualifications."
    )
    verification_notes = models.TextField(
        blank=True, 
        null=True,
        help_text="Comments about verification (optional)."
    )
    availability_status = models.CharField(
        max_length=20,
        choices=AVAILABILITY_CHOICES,
        default='Available',
        help_text="Caregiver's current availability status."
    )
    objects = models.Manager() 
    active = ActiveCaregiverManager()
    
    @property
    def upvote_count(self):
        """Calculates the sum of upvotes from all non-archived services."""
        result = self.user.services.filter(is_archived=False).aggregate(total=Sum('upvote_count'))
        return result['total'] or 0
    
    def __str__(self):
        return f"{self.name}'s Caregiver Profile"

class ModeratorProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='moderator_profile')
    regions = models.ManyToManyField('common.Region', related_name='moderators')

    def __str__(self):
        return f"{self.user.phone_number}'s Moderator Profile"

    def get_accessible_region_pks(self):
        """
        Returns a set of all Region PKs this moderator can access.
        """
        base_regions = self.regions.all()
        base_region_pks = set(base_regions.values_list('pk', flat=True))
        
        if not base_region_pks:
            return set()

        all_regions_data = Region.objects.values('pk', 'parent_id')
        
        parent_map = {} 
        for region_data in all_regions_data:
            parent_pk = region_data['parent_id']
            child_pk = region_data['pk']
            if parent_pk not in parent_map:
                parent_map[parent_pk] = []
            parent_map[parent_pk].append(child_pk)
        
        accessible_pks = set(base_region_pks)
        queue = list(base_region_pks)
        
        while queue:
            current_pk = queue.pop(0)
            children_pks = parent_map.get(current_pk, [])
            for child_pk in children_pks:
                if child_pk not in accessible_pks:
                    accessible_pks.add(child_pk)
                    queue.append(child_pk)
                    
        return accessible_pks

@receiver(post_save, sender=User)
def handle_caregiver_suspension(sender, instance, created, update_fields, **kwargs):
    """
    When a Caregiver's User account is suspended, deactivate all their services.
    """
    if not created and instance.is_caregiver:
        if update_fields and 'is_suspended' in update_fields:
            if instance.is_suspended:
                instance.services.all().update(is_active=False)

# --- REDIS CACHE INVALIDATION ---
@receiver([post_save, post_delete], sender=CaregiverProfile)
def invalidate_caregiver_profile_cache(sender, instance, **kwargs):
    cache.delete_pattern("caregiver_profiles_list_*")
    cache.delete(f"caregiver_profile_detail_{instance.id}")

    # Added by me
    cache.delete_pattern("services_list_user_*")
    cache.delete_pattern("services_list_public_*")