from django.core.management.base import BaseCommand
from django.db import transaction

from apps.users.models import User, CWSNProfile, ChildProfile, CaregiverProfile, ModeratorProfile
from apps.services.models import Service, AvailabilitySlot
from apps.interactions.models import Report, ServiceRequest, Upvote, Notification
from apps.common.models import Ad, AdRegionWeight, AdDailyAnalytics


class Command(BaseCommand):
    help = (
        'Removes all dummy / generated data (users, services, interactions, ads) '
        'while keeping reference data (categories, subcategories, disabilities, '
        'languages, regions).'
    )

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING('Clearing dummy data...'))

        # Order matters — delete dependents first.
        counts = {}
        counts['Notifications'] = Notification.objects.all().delete()[0]
        counts['Upvotes'] = Upvote.objects.all().delete()[0]
        counts['Reports'] = Report.objects.all().delete()[0]
        counts['ServiceRequests'] = ServiceRequest.objects.all().delete()[0]
        counts['AvailabilitySlots'] = AvailabilitySlot.objects.all().delete()[0]
        counts['Services'] = Service.objects.all().delete()[0]
        counts['Ads'] = Ad.objects.all().delete()[0]
        counts['Users'] = User.objects.all().delete()[0]

        for label, count in counts.items():
            self.stdout.write(f'  Deleted {count} {label}')

        self.stdout.write(self.style.SUCCESS(
            'Done. Reference data (categories, disabilities, languages, regions) preserved.'
        ))
