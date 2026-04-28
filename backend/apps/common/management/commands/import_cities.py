import csv
from django.core.management.base import BaseCommand
from apps.common.models import Region  # Adjust if your model is elsewhere

class Command(BaseCommand):
    help = 'Bulletproof script to build Country -> State -> City hierarchy from a CSV'

    def add_arguments(self, parser):
        parser.add_argument('csv_filepath', type=str, help='Path to the CSV file')

    def handle(self, *args, **kwargs):
        filepath = kwargs['csv_filepath']
        
        # STEP 1: Create the Country (India)
        india, _ = Region.objects.get_or_create(name='India', parent=None)
        self.stdout.write(self.style.SUCCESS('Root node ensured: India'))

        # STEP 2: Ingest and sanitize the CSV data completely
        cleaned_data = []
        try:
            # utf-8-sig destroys invisible BOM characters from Windows/Excel
            with open(filepath, mode='r', encoding='utf-8-sig') as file:
                reader = csv.DictReader(file)
                for row in reader:
                    clean_row = {}
                    for k, v in row.items():
                        # Force keys to lowercase and strip all spaces
                        clean_key = str(k).strip().lower() if k else 'phantom_column'
                        clean_val = str(v).strip() if v else ''
                        clean_row[clean_key] = clean_val
                    cleaned_data.append(clean_row)
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Failed to read CSV: {str(e)}'))
            return

        if not cleaned_data:
            self.stdout.write(self.style.ERROR('CSV is completely empty or unreadable.'))
            return

        # STEP 3: Extract unique states and create them under India ONLY
        unique_state_codes = {row.get('state_code') for row in cleaned_data if row.get('state_code')}
        
        state_objects = {}
        for code in unique_state_codes:
            # parent=india ensures we don't crash if a city shares a name with a state code
            state, _ = Region.objects.get_or_create(name=code, parent=india)
            state_objects[code] = state
            
        self.stdout.write(self.style.SUCCESS(f'Verified/Created {len(unique_state_codes)} States.'))

        # STEP 4: Safely construct the Cities
        cities_to_create = []
        for row in cleaned_data:
            id_val = row.get('id')
            state_code = row.get('state_code')
            name_val = row.get('name', 'Unknown')
            
            # Skip blank lines or missing required relationships
            if not id_val or not state_code or not id_val.isdigit():
                continue
                
            parent_state = state_objects.get(state_code)
            if not parent_state:
                continue
                
            # Safely cast coordinates
            try:
                lat_val = float(row.get('latitude')) if row.get('latitude') else None
                long_val = float(row.get('longitude')) if row.get('longitude') else None
            except ValueError:
                lat_val = None
                long_val = None
                
            city = Region(
                id=int(id_val),
                name=name_val,
                parent=parent_state,
                latitude=lat_val,
                longitude=long_val,
            )
            cities_to_create.append(city)

        self.stdout.write(self.style.WARNING(f'Pushing {len(cities_to_create)} cities to database...'))
        
        # Bulk create will skip duplicates if you kept unique=True
        Region.objects.bulk_create(cities_to_create, ignore_conflicts=True)
        self.stdout.write(self.style.SUCCESS('Successfully completed database import!'))