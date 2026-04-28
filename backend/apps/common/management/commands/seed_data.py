import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.db import transaction
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType
from django.utils import timezone

from faker import Faker

from apps.users.models import User, CWSNProfile, ChildProfile, CaregiverProfile, ModeratorProfile
from apps.common.models import (
    Region, ServiceCategory, ServiceSubCategory, Disability, Language,
    Ad, AdRegionWeight, AdDailyAnalytics
)
from apps.services.models import Service, AvailabilitySlot
from apps.interactions.models import Report, ServiceRequest, Upvote, Notification

TEST_PASSWORD = 'password123'

# 21 Disabilities under RPwD Act 2016
DISABILITIES = [
    'Blindness', 'Low Vision', 'Leprosy Cured Persons', 'Locomotor Disability',
    'Dwarfism', 'Intellectual Disability', 'Mental Illness', 'Autism Spectrum Disorder',
    'Cerebral Palsy', 'Muscular Dystrophy', 'Chronic Neurological Conditions',
    'Specific Learning Disabilities', 'Multiple Sclerosis', 'Speech and Language Disability',
    'Thalassemia', 'Hemophilia', 'Sickle Cell Disease',
    'Multiple Disabilities including Deaf-Blindness', 'Acid Attack Victim',
    'Hearing Impairment (Deaf and Hard of Hearing)', "Parkinson's Disease",
]

# Service Categories & Sub-categories
CATEGORIES = {
    'Educational Support': {
        'description': 'Academic and learning assistance for CWSN',
        'subcategories': [
            ('Shadow Teacher', 'One-on-one classroom support for children with special needs'),
            ('IEP Specialist', 'Individualized Education Programme planning and implementation'),
            ('Early Intervention', 'Developmental support for children aged 0-6 years'),
            ('Special Education Tutoring', 'Curriculum-adapted academic coaching'),
            ('Sign Language Instruction', 'Indian Sign Language (ISL) teaching'),
            ('Braille Instruction', 'Braille reading and writing training'),
            ('Remedial Teaching', 'Targeted instruction for learning gaps'),
        ],
    },
    'Therapy Services': {
        'description': 'Clinical and rehabilitative therapies',
        'subcategories': [
            ('Speech and Language Therapy', 'Communication and swallowing disorder therapy'),
            ('Occupational Therapy', 'Daily living skills and sensory integration'),
            ('Physiotherapy', 'Movement, strength, and motor skill rehabilitation'),
            ('Behavioral Therapy (ABA)', 'Applied Behavior Analysis for autism and related conditions'),
            ('Cognitive Behavioral Therapy', 'Psychological therapy for mental health challenges'),
            ('Sensory Integration Therapy', 'Sensory processing and regulation support'),
        ],
    },
    'Recreational & Sports': {
        'description': 'Inclusive recreation, sports, and creative activities',
        'subcategories': [
            ('Adaptive Swimming', 'Modified swimming instruction for physical disabilities'),
            ('Wheelchair Sports', 'Basketball, racing, and other wheelchair-based sports'),
            ('Art Therapy', 'Creative expression for emotional and cognitive development'),
            ('Music Therapy', 'Rhythm and melody-based therapeutic interventions'),
            ('Yoga & Mindfulness', 'Adaptive yoga and relaxation techniques'),
            ('Dance Movement Therapy', 'Therapeutic dance and movement sessions'),
        ],
    },
    'Medical & Health': {
        'description': 'Medical consultations and health services for CWSN',
        'subcategories': [
            ('Pediatric Neurology', 'Specialist consultation for neurological conditions'),
            ('Child Psychology', 'Behavioral and emotional assessment and counseling'),
            ('Nutrition & Dietetics', 'Special dietary planning for medical conditions'),
            ('Dental Care (Special Needs)', 'Adapted dental services for CWSN'),
            ('Audiometry & Hearing Aid Fitting', 'Hearing assessment and device support'),
            ('Orthotic & Prosthetic Services', 'Assistive devices for locomotor disabilities'),
        ],
    },
    'Assistive Technology': {
        'description': 'Technology-based aids and training',
        'subcategories': [
            ('AAC Device Training', 'Augmentative and Alternative Communication setup'),
            ('Screen Reader & Accessibility Setup', 'Digital accessibility for visually impaired'),
            ('Assistive Device Assessment', 'Evaluation and recommendation of assistive aids'),
            ('Computer Literacy (Adapted)', 'IT training with accessibility tools'),
        ],
    },
    'Legal & Financial Aid': {
        'description': 'Rights, benefits, and financial guidance for families',
        'subcategories': [
            ('Disability Certificate Assistance', 'Help obtaining UDID / disability certificate'),
            ('Government Scheme Guidance', 'Navigation of state and central welfare schemes'),
            ('Disability Trust & Estate Planning', 'Financial planning for long-term care'),
            ('Legal Rights Counseling', 'Awareness of RPwD Act rights and entitlements'),
        ],
    },
    'Home & Daily Living Support': {
        'description': 'In-home assistance and daily care services',
        'subcategories': [
            ('Personal Care Attendant', 'Assistance with daily living activities'),
            ('Respite Care', 'Temporary caregiver relief for families'),
            ('Home Modification Consultation', 'Accessibility assessment of living spaces'),
        ],
    },
    'Transport & Mobility': {
        'description': 'Accessible transport and mobility solutions',
        'subcategories': [
            ('Wheelchair Accessible Cabs', 'Accessible transport booking assistance'),
            ('Mobility Training', 'Orientation and mobility instruction for visually impaired'),
            ('Travel Escort Services', 'Accompanied travel support'),
        ],
    },
}

LANGUAGES = [
    'English', 'Hindi', 'Marathi', 'Tamil', 'Telugu',
    'Kannada', 'Malayalam', 'Bengali', 'Gujarati', 'Punjabi',
    'Odia', 'Assamese', 'Urdu',
]

REGION_COORDS = {
    'India': (20.5937, 78.9629),
    'Maharashtra': (19.7515, 75.7139), 'Mumbai': (19.0760, 72.8777), 'Pune': (18.5204, 73.8567), 'Nagpur': (21.1458, 79.0882), 'Deglur': (18.5492, 77.5815),
    'Delhi NCR': (28.7041, 77.1025), 'Delhi': (28.7041, 77.1025), 'Gurgaon': (28.4595, 77.0266), 'Noida': (28.5355, 77.3910),
    'Karnataka': (15.3173, 75.7139), 'Bengaluru': (12.9716, 77.5946), 'Mysuru': (12.2958, 76.6394),
    'Gujarat': (22.2587, 71.1924), 'Ahmedabad': (23.0225, 72.5714), 'Surat': (21.1702, 72.8311),
    'Tamil Nadu': (11.1271, 78.6569), 'Chennai': (13.0827, 80.2707), 'Coimbatore': (11.0168, 76.9558),
    'West Bengal': (22.9868, 87.8550), 'Kolkata': (22.5726, 88.3639),
    'Telangana': (18.1124, 79.0193), 'Hyderabad': (17.3850, 78.4867),
    'Rajasthan': (27.0238, 74.2179), 'Jaipur': (26.9124, 75.7873),
}

class Command(BaseCommand):
    help = 'Seeds the database with realistic categories, 21 RPwD disabilities, and sample data using phone_number auth.'

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING('Deleting old data...'))
        User.objects.all().delete()
        Region.objects.all().delete()
        ServiceCategory.objects.all().delete()
        ServiceSubCategory.objects.all().delete()
        Disability.objects.all().delete()
        Language.objects.all().delete()
        Group.objects.all().delete()
        Ad.objects.all().delete()
        Notification.objects.all().delete()
        self.stdout.write(self.style.SUCCESS('Old data deleted.'))

        fake = Faker('en_IN')

        # 1. Admin
        self.stdout.write('Creating Admin user...')
        User.objects.create_superuser(
            phone_number='+919999999999', 
            email='admin@app.com', 
            first_name='System', 
            last_name='Admin', 
            password=TEST_PASSWORD
        )

        # 2. Regions
        self.stdout.write('Creating regions...')
        i_lat, i_lon = REGION_COORDS.get('India')
        r_india = Region.objects.create(name='India', latitude=i_lat, longitude=i_lon)
        
        states = {
            'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Deglur'],
            'Delhi NCR': ['Delhi', 'Gurgaon', 'Noida'],
            'Karnataka': ['Bengaluru', 'Mysuru'],
            'Gujarat': ['Ahmedabad', 'Surat'],
            'Tamil Nadu': ['Chennai', 'Coimbatore'],
            'West Bengal': ['Kolkata'],
            'Telangana': ['Hyderabad'],
            'Rajasthan': ['Jaipur'],
        }
        
        city_regions = []
        for state_name, cities in states.items():
            s_lat, s_lon = REGION_COORDS.get(state_name, (None, None))
            state = Region.objects.create(name=state_name, parent=r_india, latitude=s_lat, longitude=s_lon)
            for city in cities:
                c_lat, c_lon = REGION_COORDS.get(city, (None, None))
                city_regions.append(Region.objects.create(name=city, parent=state, latitude=c_lat, longitude=c_lon))

        # 3. Disabilities
        self.stdout.write('Creating 21 disabilities...')
        disability_objs = []
        for name in DISABILITIES:
            disability_objs.append(Disability.objects.create(name=name))

        # 4. Languages
        self.stdout.write('Creating languages...')
        lang_objs = []
        for name in LANGUAGES:
            lang_objs.append(Language.objects.create(name=name))
        lang_en = lang_objs[0]

        # 5. Categories & Sub-categories
        self.stdout.write('Creating service categories and subcategories...')
        cat_objs = {}
        for cat_name, cat_info in CATEGORIES.items():
            cat = ServiceCategory.objects.create(
                name=cat_name, short_description=cat_info['description']
            )
            cat_objs[cat_name] = cat
            for sub_name, sub_desc in cat_info['subcategories']:
                ServiceSubCategory.objects.create(
                    category=cat, name=sub_name, short_description=sub_desc
                )

        all_categories = list(ServiceCategory.objects.all())

        # 6. Moderator Group
        self.stdout.write('Creating Moderator group...')
        moderator_group, _ = Group.objects.get_or_create(name='Moderators')
        models_to_manage = [CWSNProfile, CaregiverProfile, Report, Service, User]
        perms = []
        for model in models_to_manage:
            ct = ContentType.objects.get_for_model(model)
            perms.extend(Permission.objects.filter(content_type=ct))
        moderator_group.permissions.set(perms)

        # 7. Moderators
        self.stdout.write('Creating moderators...')
        mod_cities = city_regions[:8]
        for i, region in enumerate(mod_cities):
            mod_user = User.objects.create_user(
                phone_number=f'+9188888{str(i).zfill(5)}',
                email=f'mod_{region.name.lower().replace(" ", "")}@app.com',
                password=TEST_PASSWORD, 
                is_moderator=True, 
                is_staff=True
            )
            mod_user.groups.add(moderator_group)
            mod_profile = ModeratorProfile.objects.create(user=mod_user)
            mod_profile.regions.add(region)

        # 8. Caregivers
        self.stdout.write('Creating 20 caregivers...')
        caregiver_users = []
        qualifications_list = [
            'B.Ed (Special Education)', 'M.Ed (Special Education)',
            'Certified ABA Therapist (BCBA)', 'Diploma in Occupational Therapy',
            'B.P.Th (Physiotherapy)', 'M.Sc Speech-Language Pathology',
            'RCI Registered Clinical Psychologist', 'Diploma in Sign Language Interpretation',
            'Certificate in Assistive Technology', 'M.A. Rehabilitation Psychology',
        ]

        for i in range(20):
            profile = fake.profile()
            name = profile['name']
            
            user = User.objects.create_user(
                phone_number=f'+9177777{str(i).zfill(5)}',
                email=f'caregiver.{name.split()[0].lower()}{i}@app.com',
                password=TEST_PASSWORD, 
                is_caregiver=True
            )
            
            assigned_region = random.choice(city_regions)
            lat_offset = random.uniform(-0.02, 0.02)
            lon_offset = random.uniform(-0.02, 0.02)
            
            cg_profile = CaregiverProfile.objects.create(
                user=user, 
                name=name, 
                age=random.randint(25, 55),
                gender=random.choice(['Male', 'Female']),
                region=assigned_region,
                street_address=fake.street_address(),
                landmark=fake.street_name(),
                postal_code=fake.postcode(),
                latitude=assigned_region.latitude + lat_offset if assigned_region.latitude else None,
                longitude=assigned_region.longitude + lon_offset if assigned_region.longitude else None,
                qualifications=random.choice(qualifications_list),
                about_me=fake.text(max_nb_chars=150),
                is_verified=random.choices([True, False], weights=[0.8, 0.2])[0],
                availability_status=random.choice(['Available', 'Busy']),
            )
            cg_profile.languages.add(lang_en, *random.sample(lang_objs[1:], 2))
            caregiver_users.append(user)

        # 9. CWSN Users & Children
        self.stdout.write('Creating 40 CWSN users with children...')
        cwsn_users = []
        for i in range(40):
            profile = fake.profile()
            name = profile['name']
            
            user = User.objects.create_user(
                phone_number=f'+9166666{str(i).zfill(5)}',
                email=f'parent.{name.split()[0].lower()}{i}@app.com',
                password=TEST_PASSWORD, 
                is_cwsn_user=True
            )
            
            assigned_region = random.choice(city_regions)
            lat_offset = random.uniform(-0.02, 0.02)
            lon_offset = random.uniform(-0.02, 0.02)
            
            CWSNProfile.objects.create(
                user=user, 
                name=name, 
                age=random.randint(28, 50),
                gender=random.choice(['Male', 'Female']),
                region=assigned_region,
                street_address=fake.street_address(),
                landmark=fake.street_name(),
                postal_code=fake.postcode(),
                latitude=assigned_region.latitude + lat_offset if assigned_region.latitude else None,
                longitude=assigned_region.longitude + lon_offset if assigned_region.longitude else None,
            )
            cwsn_users.append(user)

            for _ in range(random.randint(1, 3)):
                child = ChildProfile.objects.create(
                    parent=user, 
                    name=fake.first_name(),
                    age=random.randint(3, 18),
                    gender=random.choice(['Male', 'Female'])
                )
                child.disabilities.add(*random.sample(disability_objs, random.randint(1, 3)))

        # 10. Services & Availability Slots
        self.stdout.write('Creating services and slots for each caregiver...')
        all_services = []
        for caregiver in caregiver_users:
            for _ in range(random.randint(2, 4)):
                cat = random.choice(all_categories)
                subcats = list(cat.subcategories.all())
                sub_cat = random.choice(subcats) if subcats else None

                title = sub_cat.name if sub_cat else cat.name
                service = Service.objects.create(
                    caregiver=caregiver, 
                    category=cat, 
                    sub_category=sub_cat,
                    region=caregiver.caregiver_profile.region,
                    title=title,
                    description=sub_cat.short_description if sub_cat else cat.short_description or '',
                    service_type=random.choice(['Online', 'Offline', 'Hybrid']),
                    payment_type=random.choice(['Paid', 'Unpaid']),
                    target_age_min=random.randint(3, 8),
                    target_age_max=random.randint(12, 18),
                    target_gender=random.choice(['Male', 'Female', 'Any']),
                    is_active=random.choices([True, False], weights=[0.9, 0.1])[0],
                )
                service.target_disabilities.add(*random.sample(disability_objs, random.randint(1, 4)))
                all_services.append(service)
                
                # Create Availability Slots for this service
                for _ in range(random.randint(2, 6)):
                    # Random day in the next 14 days
                    future_days = random.randint(1, 14)
                    # Random hour between 9 AM and 6 PM
                    hour = random.randint(9, 17) 
                    start_time = timezone.now() + timedelta(days=future_days)
                    start_time = start_time.replace(hour=hour, minute=0, second=0, microsecond=0)
                    end_time = start_time + timedelta(hours=1)
                    
                    AvailabilitySlot.objects.create(
                        caregiver=caregiver,
                        service=service,
                        start_time=start_time,
                        end_time=end_time,
                        is_booked=random.choices([True, False], weights=[0.3, 0.7])[0]
                    )

        # 11. Ads
        self.stdout.write('Creating ads...')
        today = timezone.localdate()
        ad_data = [
            {'title': 'UDID Registration Drive', 'sponsor': 'Dept of Empowerment of PwD'},
            {'title': 'Inclusive Education Workshop', 'sponsor': 'NCERT'},
            {'title': 'Assistive Devices Expo 2026', 'sponsor': 'ALIMCO'},
            {'title': 'RPwD Act Awareness Campaign', 'sponsor': 'National Trust'},
            {'title': 'Skill Development for PwD', 'sponsor': 'NHFDC'},
        ]
        for ad_info in ad_data:
            ad = Ad.objects.create(
                title=ad_info['title'], sponsor_name=ad_info['sponsor'],
                image_url=f"https://via.placeholder.com/600x200?text={ad_info['title'].replace(' ', '+')}",
                redirect_url='https://example.com', is_active=True,
                start_date=today - timedelta(days=30),
                end_date=today + timedelta(days=60),
            )
            for r in random.sample(city_regions, min(4, len(city_regions))):
                AdRegionWeight.objects.create(ad=ad, region=r, weight=random.randint(20, 80))
                for day_offset in range(7):
                    views = random.randint(50, 400)
                    AdDailyAnalytics.objects.create(
                        ad=ad, region=r, date=today - timedelta(days=day_offset),
                        views=views, clicks=random.randint(1, max(1, int(views * 0.12)))
                    )

        # 12. Interactions
        self.stdout.write('Creating interactions (requests, reports, upvotes)...')

        for _ in range(50):
            parent = random.choice(cwsn_users)
            region_services = [s for s in all_services if s.region == parent.cwsn_profile.region]
            if not region_services:
                continue
            service = random.choice(region_services)
            children = list(parent.children.all())
            if not children:
                continue
            child = random.choice(children)
            if not ServiceRequest.objects.filter(cwsn_user=parent, child=child, service=service).exists():
                note_text = fake.sentence(nb_words=12) if random.random() > 0.5 else ""
                ServiceRequest.objects.create(
                    cwsn_user=parent, caregiver=service.caregiver,
                    child=child, service=service, status='Pending',
                    note=note_text
                )

        for _ in range(10):
            Report.objects.create(
                reporter=random.choice(cwsn_users),
                reported_user=random.choice(caregiver_users),
                reason=fake.sentence(nb_words=10), status='Open'
            )

        for _ in range(75):
            voter = random.choice(cwsn_users)
            service = random.choice(all_services)
            if not Upvote.objects.filter(voter=voter, service=service).exists():
                # Fulfill upvote constraint: voter must have requested the service
                if not ServiceRequest.objects.filter(cwsn_user=voter, service=service).exists():
                    child = random.choice(list(voter.children.all())) if voter.children.exists() else None
                    if child:
                         ServiceRequest.objects.create(
                             cwsn_user=voter, caregiver=service.caregiver,
                             child=child, service=service, status='Accepted'
                         )
                         Upvote.objects.create(voter=voter, service=service)

        # 13. Trigger status changes -> notifications
        self.stdout.write('Triggering status updates for notifications...')
        pending = ServiceRequest.objects.filter(status='Pending')
        for req in pending[:25]:
            req.status = random.choice(['Accepted', 'Rejected'])
            req.save()

        open_reports = Report.objects.filter(status='Open')
        for rep in open_reports[:5]:
            rep.status = random.choice(['Resolved', 'Dismissed'])
            rep.moderator_action = 'Reviewed and action taken.'
            rep.save()

        for user in User.objects.all()[:30]:
            Notification.objects.create(
                recipient=user, notification_type='SYSTEM',
                title='Welcome to CWSN Connect!',
                message='We are glad to have you. Complete your profile to get started.',
            )

        all_notifs = Notification.objects.all()
        for notif in all_notifs:
            if random.random() > 0.5:
                notif.is_read = True
                notif.save(update_fields=['is_read'])

        self.stdout.write(f'  -> {Disability.objects.count()} disabilities')
        self.stdout.write(f'  -> {ServiceCategory.objects.count()} categories, {ServiceSubCategory.objects.count()} subcategories')
        self.stdout.write(f'  -> {Service.objects.count()} services')
        self.stdout.write(f'  -> {AvailabilitySlot.objects.count()} availability slots')
        self.stdout.write(f'  -> {all_notifs.count()} notifications')
        self.stdout.write(self.style.SUCCESS('Database seeded successfully!'))