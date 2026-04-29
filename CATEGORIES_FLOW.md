# Categories Flow

## What it does
After login, the user lands on the Categories page. They select a category → subcategories are shown → they select a subcategory → services are shown.

## API
Single call: `GET /api/common/categories/`
Subcategories come nested inside each category — no extra API call needed.

## Folder Structure
```
lib/features/categories/
├── data/
│   ├── repositories/
│   │   └── category_repository_impl.dart
│   └── sources/
│       └── category_remote_source.dart
├── domain/
│   ├── models/
│   │   ├── category_model.dart
│   │   └── subcategory_model.dart
│   └── repositories/
│       └── category_repository.dart
└── presentation/
    ├── pages/
    │   └── categories_page.dart
    └── providers/
        └── category_provider.dart
```

Shared widget: `lib/core/widgets/empty_state.dart`

## How it works

1. `categoryProvider` (AsyncNotifier) calls `getCategories()` on build
2. `CategoryRemoteSource` hits the API, parses `results[]` into `List<CategoryModel>`
3. Each `CategoryModel` includes its subcategories already parsed
4. `CategoriesPage` watches the provider:
   - Loading → spinner
   - Error → error text
   - Empty → EmptyState widget
   - Data → ListView of category cards
5. Tapping a card will navigate to subcategories (not yet built)

## What's next
- Build subcategories page
- Wire category card tap → pass selected CategoryModel to subcategories page
