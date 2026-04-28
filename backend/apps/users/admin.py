# apps/users/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, CWSNProfile, ChildProfile, CaregiverProfile, ModeratorProfile
from apps.services.models import Service
from django.urls import reverse
from django.utils.html import format_html
from django import forms
from django.contrib import messages

try:
    admin.site.unregister(User)
except admin.sites.NotRegistered:
    pass

class CaregiverProfileInline(admin.StackedInline):
    model = CaregiverProfile
    can_delete = False
    verbose_name_plural = 'Caregiver Profile'
    
    def get_fieldsets(self, request, obj=None):
        moderator_fields = ('Moderation (Editable)', {
            'fields': ('region', 'is_verified', 'verification_notes', 'availability_status')
        })
        if request.user.is_superuser:
            all_fields = (None, {'fields': ('name', 'age', 'gender', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude', 'qualifications', 'recommendations')})
            return (all_fields, moderator_fields)
        if hasattr(request.user, 'moderator_profile'):
            return (moderator_fields,)
        return ()

    def get_readonly_fields(self, request, obj=None):
        if not request.user.is_superuser:
            return ('name', 'age', 'gender', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude', 'qualifications', 'recommendations')
        return ()


class ServiceInline(admin.TabularInline):
    model = Service
    fk_name = 'caregiver'
    extra = 0
    can_delete = False
    fields = ('title', 'region', 'category', 'is_active', 'edit_link')
    readonly_fields = ('title', 'region', 'category', 'is_active', 'edit_link')

    def edit_link(self, obj):
        if obj.pk:
            url = reverse('admin:services_service_change', args=(obj.pk,))
            return format_html('<a href="{}">Edit Service</a>', url)
        return "N/A"
    edit_link.short_description = 'Link'

    def has_add_permission(self, request, obj=None):
        return False
        
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
            regions_pks = request.user.moderator_profile.get_accessible_region_pks()
            return qs.filter(region_id__in=regions_pks)
        return qs.none()


class CWSNProfileInline(admin.StackedInline):
    model = CWSNProfile
    can_delete = False
    verbose_name_plural = 'CWSN User Profile (Read-Only for Moderators)'

    fieldsets = (
        (None, {
            'fields': ('name', 'age', 'gender', 'region', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude')
        }),
    )

    def get_readonly_fields(self, request, obj=None):
        if request.user.is_superuser:
            return ()
        return ('name', 'age', 'gender', 'region', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude')
        
    def has_change_permission(self, request, obj=None):
        return request.user.is_superuser


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    base_fieldsets = UserAdmin.fieldsets
    role_fieldset = ('Role Management', {'fields': ('is_cwsn_user', 'is_caregiver', 'is_moderator')})
    suspension_fieldset = ('Suspension (Moderator)', {'fields': ('is_suspended', 'suspension_reason')})

    # --- CHANGED: Added get_display_name to the front of the list ---
    list_display = ['get_display_name', 'phone_number', 'is_cwsn_user', 'is_caregiver', 'is_moderator', 'is_suspended']
    list_filter = UserAdmin.list_filter + ('is_suspended', 'is_staff', 'is_cwsn_user', 'is_caregiver')
    search_fields = ['phone_number', 'email', 'username', 'first_name', 'last_name']
    
    inlines = [CaregiverProfileInline, ServiceInline]

    # --- ADDED: Method to hook the property into the admin list ---
    @admin.display(description='Name / Identity')
    def get_display_name(self, obj):
        return obj.display_name

    def has_module_permission(self, request):
        if request.user.is_superuser:
            return True
        return False

    def get_fieldsets(self, request, obj=None):
        if request.user.is_superuser:
            custom_fieldset = (
                (None, {'fields': ('phone_number', 'password')}),
                ('Personal info', {'fields': ('email', 'first_name', 'last_name')}),
            )
            return custom_fieldset + (self.role_fieldset, self.suspension_fieldset)
        if hasattr(request.user, 'moderator_profile') and obj and obj.is_caregiver:
            # Show display name and phone to moderators
            user_info = ('User Info (Read-Only)', {'fields': ('get_display_name', 'phone_number')})
            return (user_info, self.suspension_fieldset)
        return (self.suspension_fieldset,)
    
    def get_readonly_fields(self, request, obj=None):
        if not request.user.is_superuser:
            return ('get_display_name', 'phone_number', 'email', 'first_name', 'last_name', 'date_joined', 'last_login')
        return super().get_readonly_fields(request, obj)
        
    def get_inlines(self, request, obj):
        if obj and obj.is_caregiver:
            return [CaregiverProfileInline, ServiceInline]
        if obj and obj.is_cwsn_user and request.user.is_superuser:
             return [CWSNProfileInline]
        return []

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
            regions_pks = request.user.moderator_profile.get_accessible_region_pks()
            return qs.filter(is_superuser=False) & \
                   qs.filter(caregiver_profile__region_id__in=regions_pks)
        return qs.none()


class CWSNProfileAdminForm(forms.ModelForm):
    is_suspended = forms.BooleanField(required=False, label='Is Suspended')
    suspension_reason = forms.CharField(required=False, widget=forms.Textarea(attrs={'rows': 4}), label='Suspension Reason')

    class Meta:
        model = CWSNProfile
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance and self.instance.pk:
            user = self.instance.user
            self.fields['is_suspended'].initial = user.is_suspended
            self.fields['suspension_reason'].initial = user.suspension_reason


@admin.register(CWSNProfile)
class CWSNProfileAdmin(admin.ModelAdmin):
    form = CWSNProfileAdminForm
    list_display = ('name', 'user_phone', 'region', 'get_is_suspended')
    list_filter = ('region',)
    search_fields = ('name', 'user__phone_number')
    
    def user_phone(self, obj):
        return obj.user.phone_number
    
    @admin.display(description='Is Suspended', boolean=True)
    def get_is_suspended(self, obj):
        return obj.user.is_suspended

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
            regions_pks = request.user.moderator_profile.get_accessible_region_pks()
            return qs.filter(region_id__in=regions_pks)
        return qs.none()

    def get_fieldsets(self, request, obj=None):
        profile_fields = ('CWSN Profile (Read-Only)', {'fields': ('name', 'age', 'gender', 'region', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude')})
        user_fields = ('User Account Info', {'fields': ('user_phone_display',)})
        suspension_fields = ('Suspension', {'fields': ('is_suspended', 'suspension_reason')})
        children_fieldset = ('Children Profiles', {'fields': ('display_children',)})

        if request.user.is_superuser:
            superuser_profile_fields = ('CWSN Profile', {'fields': ('user', 'name', 'age', 'gender', 'region', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude')})
            return (superuser_profile_fields, suspension_fields, children_fieldset)
        
        return (user_fields, profile_fields, suspension_fields, children_fieldset)
    
    def get_readonly_fields(self, request, obj=None):
        base_readonly = ['user_phone_display', 'display_children']
        if request.user.is_superuser:
            return ['display_children']
        
        base_readonly.extend(['user', 'name', 'age', 'gender', 'region', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude'])
        return base_readonly
    
    @admin.display(description='User Phone')
    def user_phone_display(self, obj):
        if obj and obj.pk:
            return obj.user.phone_number
        return "-"
    
    @admin.display(description='Children')
    def display_children(self, obj):
        children = obj.user.children.all()
        if not children.exists():
            return "No children listed for this user."
        html = "<ul>"
        for child in children:
            url = reverse('admin:users_childprofile_change', args=(child.pk,))
            html += f"<li><a href='{url}'>{child.name}</a> (Age: {child.age})</li>"
        html += "</ul>"
        return format_html(html)
    
    def has_change_permission(self, request, obj=None):
        return request.user.is_superuser or hasattr(request.user, 'moderator_profile')

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        user = obj.user
        user.is_suspended = form.cleaned_data.get('is_suspended')
        user.suspension_reason = form.cleaned_data.get('suspension_reason')
        user.save(update_fields=['is_suspended', 'suspension_reason'])


class CaregiverProfileAdminForm(forms.ModelForm):
    is_suspended = forms.BooleanField(required=False, label='Is Suspended')
    suspension_reason = forms.CharField(required=False, widget=forms.Textarea(attrs={'rows': 4}), label='Suspension Reason')

    class Meta:
        model = CaregiverProfile
        fields = '__all__'

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance and self.instance.pk:
            user = self.instance.user
            self.fields['is_suspended'].initial = user.is_suspended
            self.fields['suspension_reason'].initial = user.suspension_reason


@admin.register(CaregiverProfile)
class CaregiverProfileAdmin(admin.ModelAdmin):
    form = CaregiverProfileAdminForm
    list_display = ('name', 'user_phone', 'region', 'is_verified', 'availability_status', 'get_is_suspended')
    list_filter = ('region', 'is_verified', 'availability_status')
    search_fields = ('name', 'user__phone_number')

    def user_phone(self, obj):
        return obj.user.phone_number

    @admin.display(description='Is Suspended', boolean=True)
    def get_is_suspended(self, obj):
        return obj.user.is_suspended

    def get_fieldsets(self, request, obj=None):
        moderator_fields = ('Moderation (Editable)', {'fields': ('region', 'is_verified', 'verification_notes', 'availability_status')})
        readonly_fields_set = ('Caregiver Info (Read-Only)', {'fields': ('name', 'user_phone_display', 'age', 'upvote_count', 'gender', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude', 'qualifications', 'recommendations')})
        service_list_fieldset = ('Caregiver\'s Services', {'fields': ('display_services',)})
        suspension_fieldset = ('Suspension', {'fields': ('is_suspended', 'suspension_reason')})

        if request.user.is_superuser:
            superuser_fields = (None, {'fields': ('user', 'name', 'age', 'gender', 'upvote_count', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude', 'qualifications', 'recommendations')})
            return (superuser_fields, moderator_fields, suspension_fieldset, service_list_fieldset)
        
        if hasattr(request.user, 'moderator_profile'):
            return (readonly_fields_set, moderator_fields, suspension_fieldset, service_list_fieldset)
        return ()
    
    def get_readonly_fields(self, request, obj=None):
        readonly = ['display_services', 'upvote_count'] 
        if request.user.is_superuser:
            return readonly
        if hasattr(request.user, 'moderator_profile'):
            readonly.extend(['name', 'user_phone_display', 'user', 'age', 'gender', 'street_address', 'landmark', 'postal_code', 'latitude', 'longitude', 'qualifications', 'recommendations'])
        return readonly

    @admin.display(description='User Phone')
    def user_phone_display(self, obj):
        if obj and obj.pk:
            return obj.user.phone_number
        return "-"

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
             regions_pks = request.user.moderator_profile.get_accessible_region_pks()
             return qs.filter(region_id__in=regions_pks)
        return qs.none()

    def display_services(self, obj):
        services = obj.user.services.all()
        if not services.exists():
            return "No services listed for this caregiver."
        html = "<ul>"
        for service in services:
            url = reverse('admin:services_service_change', args=(service.pk,))
            status = 'Active' if service.is_active else 'Inactive'
            html += f"<li><a href='{url}'>{service.title}</a> ({status} - {service.region.name})</li>"
        html += "</ul>"
        return format_html(html)
    
    display_services.short_description = 'Services'

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        user = obj.user
        user.is_suspended = form.cleaned_data.get('is_suspended')
        user.suspension_reason = form.cleaned_data.get('suspension_reason')
        user.save(update_fields=['is_suspended', 'suspension_reason'])


@admin.register(ChildProfile)
class ChildProfileAdmin(admin.ModelAdmin):
    list_display = ('name', 'parent_phone', 'age')
    search_fields = ('name', 'parent__phone_number')
    
    def parent_phone(self, obj):
        return obj.parent.phone_number
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
            regions_pks = request.user.moderator_profile.get_accessible_region_pks()
            return qs.filter(parent__cwsn_profile__region_id__in=regions_pks)
        return qs.none()


@admin.register(ModeratorProfile)
class ModeratorProfileAdmin(admin.ModelAdmin):
    list_display = ('user_phone',)
    search_fields = ('user__phone_number',)
    filter_horizontal = ('regions',) 

    def user_phone(self, obj):
        return obj.user.phone_number
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'moderator_profile'):
            return qs.filter(user=request.user)
        return qs.none()