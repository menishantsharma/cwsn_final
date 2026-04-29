# Services Flow

## What it does
After selecting a subcategory, the user lands on the Services page. It fetches all services for that specific category + subcategory combination and shows them as a list of cards.

## API
Single call: `GET /api/services/services/?category=<id>&sub_category=<id>`
Response is paginated: `{ count, next, previous, results: [...] }`
`caregiver_profile` is nested inside each service — no second API call needed.

## Folder Structure
```
lib/features/services/
├── data/
│   ├── repositories/
│   │   └── service_repository_impl.dart
│   └── sources/
│       └── service_remote_source.dart
├── domain/
│   ├── models/
│   │   └── service_model.dart         (contains ServiceModel + CaregiverProfileModel)
│   └── repositories/
│       └── service_repository.dart
└── presentation/
    ├── pages/
    │   └── services_page.dart
    └── providers/
        └── service_provider.dart
```

Shared widget: `lib/core/widgets/empty_state.dart`

## How it works

1. `SubcategoriesPage` taps → `context.push(AppRoutes.services, extra: subcategory)`
2. `ServicesPage` receives `SubcategoryModel` via GoRouter `extra`
3. `serviceProvider((subcategory.categoryId, subcategory.id))` (FutureProvider.family) is watched
4. `ServiceRemoteSource` hits the API, parses `results[]` into `List<ServiceModel>`
5. `ServicesPage` renders:
   - Loading → spinner
   - Error → error text
   - Empty → EmptyState widget
   - Data → ListView of service cards
6. Each service card shows title, description, serviceType chip, paymentType chip
7. Tapping a card → TODO: navigate to service detail page

## Navigation (GoRouter)
- `/services` → ServicesPage, receives SubcategoryModel via `state.extra`
- Route registered in `lib/app/app_router.dart`

## Key Notes
- `SubcategoryModel` has a `categoryId` field (parsed from `json['category']`) — this is how ServicesPage knows the category without needing CategoryModel passed separately
- `SERVICE_TYPES`: `"Online"`, `"Offline"`, `"Hybrid"` (Title case from backend)
- `PAYMENT_TYPES`: `"Paid"`, `"Unpaid"` (Title case from backend)
- `description` on Service is always a non-null string

## What's next
- Build service detail page
- Wire service card tap → pass ServiceModel to detail page
