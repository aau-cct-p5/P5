import 'package:flutter/material.dart';

/// A widget that allows the user to select a surface type for training.
class MLTrainingWidget extends StatefulWidget {
  final Function(String) onSurfaceTypeChanged;

  const MLTrainingWidget({Key? key, required this.onSurfaceTypeChanged})
      : super(key: key);

  @override
  _MLTrainingWidgetState createState() => _MLTrainingWidgetState();
}

class _MLTrainingWidgetState extends State<MLTrainingWidget> {
  /// Currently selected surface type.
  String _selectedSurfaceType = 'none';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: _selectedSurfaceType,
          onChanged: (String? newValue) {
            setState(() {
              _selectedSurfaceType = newValue ?? 'none';
            });
            // Notify the parent widget about the surface type change.
            widget.onSurfaceTypeChanged(_selectedSurfaceType);
            if (_selectedSurfaceType != 'none') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  // Inform the user to cycle on the selected surface type.
                  content: Text(
                      'Please only cycle on $_selectedSurfaceType surfaces.'),
                ),
              );
            }
          },
          items: <String>['none', 'asphalt', 'gravel']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value == 'none'
                    ? 'No label'
                    // Capitalize the first letter of the surface type.
                    : value[0].toUpperCase() + value.substring(1),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
