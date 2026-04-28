import math
from apps.common.models import Region

def calculate_haversine(lat1, lon1, lat2, lon2):
    """
    Calculate the great circle distance in kilometers between two points 
    on the earth (specified in decimal degrees).
    """
    # Convert decimal degrees to radians 
    lat1, lon1, lat2, lon2 = map(math.radians, [float(lat1), float(lon1), float(lat2), float(lon2)])

    # Haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a)) 
    r = 6371 # Radius of earth in kilometers
    return c * r

def assign_region_from_coordinates(lat, lon):
    """
    Finds the nearest region centroid using Haversine distance.
    """
    regions = Region.objects.exclude(latitude__isnull=True, longitude__isnull=True)
    closest_region = None
    min_distance = float('inf')
    
    for region in regions:
        distance = calculate_haversine(lat, lon, region.latitude, region.longitude)
        if distance < min_distance:
            min_distance = distance
            closest_region = region
            
    return closest_region