# apps/services/admin.py
from django.contrib import admin
from .models import Service, AvailabilitySlot

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('title', 'caregiver', 'category', 'is_active', 'is_archived', 'upvote_count')
    list_filter = ('is_active', 'is_archived', 'service_type', 'payment_type')
    search_fields = ('title', 'description', 'caregiver__email')

    # --- ADDED THIS METHOD ---
    def get_queryset(self, request):
        """
        Filter Services by the moderator's region(s).
        """
        qs = super().get_queryset(request)
        # Admins see everything
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
            regions_pks = request.user.moderator_profile.get_accessible_region_pks()
            return qs.filter(region_id__in=regions_pks)

admin.site.register(AvailabilitySlot)