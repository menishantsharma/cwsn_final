import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/pages/map_picker_page.dart';

class LocationPickerField extends StatelessWidget {
  final LocationPickerResult? location;
  final VoidCallback onTap;

  const LocationPickerField({
    super.key,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: location == null
                ? Colors.grey.shade400
                : Theme.of(context).colorScheme.primary,
            width: location == null ? 1 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              location == null ? Icons.map_outlined : Icons.location_on,
              color: location == null
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                location?.displayLocation ?? 'Tap to pick your area on map',
                style: TextStyle(
                  color: location == null ? Colors.grey[600] : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
