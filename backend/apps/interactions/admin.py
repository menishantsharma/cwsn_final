# apps/interactions/admin.py
from django.contrib import admin
from .models import Notification, ServiceRequest, Report, Upvote
from apps.users.models import ChildProfile

@admin.register(ServiceRequest)
class ServiceRequestAdmin(admin.ModelAdmin):
    list_display = ('service', 'cwsn_user', 'caregiver', 'child', 'status')
    list_filter = ('status',)
    search_fields = ('cwsn_user__phone_number', 'caregiver__phone_number', 'service__title')    
    
    # ADDED: Make the note read-only for existing requests
    def get_readonly_fields(self, request, obj=None):
        if obj: # If obj exists, the request has already been sent
            return ['note']
        return []
    
    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        """
        Filters the dropdowns to only show the relevant user types.
        """
        if db_field.name == "cwsn_user":
            # Only show users flagged as CWSN users or caregivers
            kwargs["queryset"] = db_field.related_model.objects.filter(is_cwsn_user=True) | db_field.related_model.objects.filter(is_caregiver=True)
            
        elif db_field.name == "caregiver":
            # Only show users flagged as Caregivers
            kwargs["queryset"] = db_field.related_model.objects.filter(is_caregiver=True)
            
        return super().formfield_for_foreignkey(db_field, request, **kwargs)
    
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        # If we are editing an existing request, filter the child dropdown
        if obj and obj.cwsn_user:
            form.base_fields['child'].queryset = ChildProfile.objects.filter(parent=obj.cwsn_user)
        return form

@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    # --- MODIFIED/ADDED LINES ---
    list_display = ('reported_user', 'reporter', 'region_of_incident', 'status', 'created_at')
    list_filter = ('status', 'region_of_incident', 'created_at') # Added created_at
    search_fields = ('reported_user__phone_number', 'reporter__phone_number')       
    
    # Organize the admin view and show the new action field
    fieldsets = (
        ('Report Details (Read-Only)', {
            'fields': ('reporter', 'reported_user', 'region_of_incident', 'reason', 'created_at')
        }),
        ('Moderation', {
            'fields': ('status', 'moderator_action')
        }),
    )
    
    def get_readonly_fields(self, request, obj=None):
        """
        Makes key fields read-only after creation.
        """
        if obj: # obj is not None, so this is an existing report (change view)
            # --- MODIFIED/ADDED LINES ---
            return ['reporter', 'reported_user', 'region_of_incident', 'reason', 'created_at']
        return [] # On add view, all fields are editable
    # ---

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
            regions_pks = request.user.moderator_profile.get_accessible_region_pks()
            return qs.filter(region_of_incident_id__in=regions_pks)
        return qs.none()

admin.site.register(Upvote)

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('recipient', 'notification_type', 'title', 'is_read', 'created_at')
    list_filter = ('is_read', 'notification_type', 'created_at')
    search_fields = ('recipient__email', 'title', 'message')
    readonly_fields = ('created_at',)