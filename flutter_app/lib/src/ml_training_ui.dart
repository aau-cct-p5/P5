
import 'package:flutter/material.dart';

class MLTrainingWidget extends StatefulWidget {
  final Function(String) onSurfaceTypeChanged;

  const MLTrainingWidget({Key? key, required this.onSurfaceTypeChanged})
      : super(key: key);

  @override
  _MLTrainingWidgetState createState() => _MLTrainingWidgetState();
}

class _MLTrainingWidgetState extends State<MLTrainingWidget> {
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
            widget.onSurfaceTypeChanged(_selectedSurfaceType);
            if (_selectedSurfaceType != 'none') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please only cycle on $_selectedSurfaceType surfaces.'),
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
                    : value[0].toUpperCase() + value.substring(1),
              ),
            );
          }).toList(),
        ),
        // ...collect data buttons...
      ],
    );
  }
}