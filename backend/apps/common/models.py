# apps/common/models.py
from django.utils import timezone
from django.db import models

class Region(models.Model):
    name = models.CharField(max_length=255) 
    parent = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='children')
    
    # Add centroid coordinates for the region
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)

    class Meta:
        verbose_name_plural = 'Regions'
        # 2. Add this constraint block
        constraints = [
            models.UniqueConstraint(
                fields=['name', 'parent'], 
                name='unique_region_per_parent'
            )
        ]

    def __str__(self):
        if self.parent:
            return f"{self.name}, {self.parent.name}"
        return self.name

class ServiceCategory(models.Model):
    name = models.CharField(max_length=100, unique=True)
    short_description = models.TextField(blank=True, null=True)
    image_url = models.URLField(max_length=500, blank=True, null=True)

    class Meta:
        verbose_name_plural = 'Service Categories'

    def __str__(self):
        return self.name

class ServiceSubCategory(models.Model):
    category = models.ForeignKey(ServiceCategory, on_delete=models.CASCADE, related_name='subcategories')
    name = models.CharField(max_length=100)
    short_description = models.TextField(blank=True, null=True)
    image_url = models.URLField(max_length=500, blank=True, null=True)

    class Meta:
        verbose_name_plural = 'Service Sub-Categories'
        # Prevent duplicate sub-categories under the same category
        unique_together = ('category', 'name')

    def __str__(self):
        return f"{self.name} ({self.category.name})"

class Disability(models.Model):
    name = models.CharField(max_length=255, unique=True)

    class Meta:
        verbose_name_plural = 'Disabilities'

    def __str__(self):
        return self.name

class Language(models.Model):
    name = models.CharField(max_length=100, unique=True)

    def __str__(self):
        return self.name

class Ad(models.Model):
    title = models.CharField(max_length=255, help_text="Internal name for the ad campaign")
    sponsor_name = models.CharField(max_length=255, blank=True, null=True)
    image_url = models.URLField(max_length=500, help_text="Link to the ad banner image")
    redirect_url = models.URLField(max_length=500, help_text="Where the user goes when they click")
    
    # Active controls
    is_active = models.BooleanField(default=True)
    start_date = models.DateField(default=timezone.now, null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    
    # Many-to-Many relationship with regions, utilizing a custom "through" model for proportions
    regions = models.ManyToManyField('Region', through='AdRegionWeight', related_name='ads')

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

class AdRegionWeight(models.Model):
    """
    Defines the proportion/weight of an Ad in a specific Region.
    If Region A has Ad1 (weight 70) and Ad2 (weight 30), Ad1 shows 70% of the time.
    """
    ad = models.ForeignKey(Ad, on_delete=models.CASCADE)
    region = models.ForeignKey('Region', on_delete=models.CASCADE)
    weight = models.PositiveIntegerField(default=10, help_text="Relative weight/proportion for this region")

    class Meta:
        unique_together = ('ad', 'region') # An ad can only have one weight per region

    def __str__(self):
        return f"{self.ad.title} in {self.region.name} (Weight: {self.weight})"

class AdDailyAnalytics(models.Model):
    """
    Minimalistic data storage for graphs. 
    Groups views and clicks by Ad, Region, and Day.
    """
    ad = models.ForeignKey(Ad, on_delete=models.CASCADE, related_name='analytics')
    region = models.ForeignKey('Region', on_delete=models.SET_NULL, null=True, blank=True)
    date = models.DateField(default=timezone.localdate)
    
    views = models.PositiveIntegerField(default=0)
    clicks = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ('ad', 'region', 'date')
        verbose_name_plural = "Ad Daily Analytics"

    def __str__(self):
        return f"{self.ad.title} - {self.region.name if self.region else 'Global'} - {self.date}"