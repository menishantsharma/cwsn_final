# apps/interactions/permissions.py
from rest_framework import permissions

class IsModeratorInRegion(permissions.BasePermission):
    """
    Allows access only to moderators for the region of the object.
    """
    def has_object_permission(self, request, view, obj):
        # Admins can do anything
        if request.user.is_superuser:
            return True
        
        # Check if user is a moderator and has a profile
        if not (request.user.is_moderator and hasattr(request.user, 'moderator_profile')):
            return False
        
        accessible_region_pks = request.user.moderator_profile.get_accessible_region_pks()
        
        # Logic for Report objects
        if hasattr(obj, 'region_of_incident'):
            return obj.region_of_incident in accessible_region_pks

        # Logic for Caregiver/CWSN profiles (obj would be the profile)
        if hasattr(obj, 'region'):
            return obj.region in accessible_region_pks

        return False