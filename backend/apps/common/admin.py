# apps/common/admin.py
from django.contrib import admin
from .models import (
    Region, ServiceCategory, Disability, Language,
    Ad, AdRegionWeight, AdDailyAnalytics, ServiceSubCategory
)

@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    # Added latitude and longitude to the display list
    list_display = ('name', 'parent', 'latitude', 'longitude')
    search_fields = ('name',)
    list_filter = ('parent',)

# --- NEW: Inline Editor for Subcategories ---
class ServiceSubCategoryInline(admin.TabularInline):
    model = ServiceSubCategory
    extra = 1 # Shows one blank row by default for easy adding

# --- MODIFIED: Upgraded ServiceCategory Admin ---
@admin.register(ServiceCategory)
class ServiceCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'short_description')
    search_fields = ('name',)
    inlines = [ServiceSubCategoryInline] # Embeds subcategories inside the category page

# --- NEW: Standalone SubCategory Admin ---
@admin.register(ServiceSubCategory)
class ServiceSubCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'short_description')
    list_filter = ('category',) # Allows filtering by parent category on the right sidebar
    search_fields = ('name', 'category__name')

admin.site.register(Disability)
admin.site.register(Language)

# 1. Inline Weight Editor
class AdRegionWeightInline(admin.TabularInline):
    model = AdRegionWeight
    extra = 1

# 2. Ad Management Panel
@admin.register(Ad)
class AdAdmin(admin.ModelAdmin):
    list_display = ('title', 'sponsor_name', 'is_active', 'start_date', 'end_date')
    list_filter = ('is_active', 'start_date')
    search_fields = ('title', 'sponsor_name')
    inlines = [AdRegionWeightInline]

# 3. Analytics Panel
@admin.register(AdDailyAnalytics)
class AdDailyAnalyticsAdmin(admin.ModelAdmin):
    list_display = ('ad', 'region', 'date', 'views', 'clicks', 'click_through_rate')
    list_filter = ('date', 'region', 'ad')
    date_hierarchy = 'date' 

    def click_through_rate(self, obj):
        if obj.views == 0:
            return "0.00%"
        ctr = (obj.clicks / obj.views) * 100
        return f"{ctr:.2f}%"
    
    click_through_rate.short_description = 'CTR'