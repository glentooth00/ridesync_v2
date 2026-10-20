
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';

class GarageScreen extends StatelessWidget {
  const GarageScreen({
    super.key,
    required this.motorcycles,
    required this.selectedMotorcycleId,
    required this.onAddMotorcycle,
    required this.onUpdateMotorcycle,
    required this.onSelectMotorcycle,
  });

  final List<Motorcycle> motorcycles;
  final int selectedMotorcycleId;
  final Future<void> Function(Motorcycle) onAddMotorcycle;
  final Future<void> Function(Motorcycle) onUpdateMotorcycle;
  final Future<void> Function(int) onSelectMotorcycle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text(
          'MY GARAGE',
          style: TextStyle(
            color: AppTheme.orange,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your machines.',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Keep your motorcycles and odometer details in one place.',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () => _showMotorcycleForm(context),
          icon: const Icon(Icons.add),
          label: const Text('ADD MOTORCYCLE'),
        ),
        const SizedBox(height: 18),
        if (motorcycles.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.two_wheeler,
                    size: 54, color: AppTheme.orange),
                SizedBox(height: 14),
                Text(
                  'Your garage is empty',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Add your first motorcycle to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
          )
        else
          ...motorcycles.map((motorcycle) {
            final active = motorcycle.id == selectedMotorcycleId;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? AppTheme.orange.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceRaised,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: AppTheme.orange,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              motorcycle.displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${motorcycle.id}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${motorcycle.year} • '
                              '${motorcycle.engineCc.isEmpty ? 'CC not set' : '${motorcycle.engineCc} cc'}',
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showMotorcycleForm(
                          context,
                          existing: motorcycle,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit motorcycle',
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.speed,
                          color: AppTheme.muted, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Odometer',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                      const Spacer(),
                      Text(
                        '${motorcycle.odometerKm.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (active)
                    const Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: AppTheme.orange),
                        SizedBox(width: 6),
                        Text(
                          'ACTIVE MOTORCYCLE',
                          style: TextStyle(
                            color: AppTheme.orange,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton(
                      onPressed: () =>
                          onSelectMotorcycle(motorcycle.id),
                      child: const Text('Set as active motorcycle'),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showMotorcycleForm(
    BuildContext context, {
    Motorcycle? existing,
  }) async {
    final result = await showDialog<Motorcycle>(
      context: context,
      builder: (_) => _MotorcycleFormDialog(existing: existing),
    );

    if (result == null || !context.mounted) return;

    try {
      if (existing == null) {
        await onAddMotorcycle(result);
      } else {
        await onUpdateMotorcycle(result);
      }
    } catch (error, stackTrace) {
      debugPrint('RideSync motorcycle save failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save motorcycle: $error'),
        ),
      );
    }
  }
}

class _MotorcycleFormDialog extends StatefulWidget {
  const _MotorcycleFormDialog({this.existing});

  final Motorcycle? existing;

  @override
  State<_MotorcycleFormDialog> createState() =>
      _MotorcycleFormDialogState();
}

class _MotorcycleFormDialogState
    extends State<_MotorcycleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _make;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _cc;
  late final TextEditingController _odo;
  late final TextEditingController _plate;

  @override
  void initState() {
    super.initState();

    final bike = widget.existing;

    _make = TextEditingController(text: bike?.make ?? '');
    _model = TextEditingController(text: bike?.model ?? '');
    _year = TextEditingController(
      text: '${bike?.year ?? DateTime.now().year}',
    );
    _cc = TextEditingController(text: bike?.engineCc ?? '');
    _odo = TextEditingController(
      text: '${bike?.odometerKm ?? 0}'.replaceAll(
        RegExp(r'\.0$'),
        '',
      ),
    );
    _plate = TextEditingController(text: bike?.plateNumber ?? '');
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _cc.dispose();
    _odo.dispose();
    _plate.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final year = int.tryParse(_year.text.trim());
    final odometer = double.tryParse(_odo.text.trim());

    if (year == null || odometer == null) return;

    final make = _make.text.trim();
    final model = _model.text.trim();

    final motorcycle = Motorcycle(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch,
      name: '$make $model',
      make: make,
      model: model,
      year: year,
      engineCc: _cc.text.trim(),
      odometerKm: odometer,
      plateNumber: _plate.text.trim(),
    );

    Navigator.of(context).pop(motorcycle);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Add motorcycle'
            : 'Edit motorcycle',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _make,
                decoration: const InputDecoration(
                  labelText: 'Make (e.g. Keeway)',
                ),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _model,
                decoration: const InputDecoration(
                  labelText: 'Model (e.g. Cafe Racer 152)',
                ),
                validator: _required,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
                validator: (value) {
                  final year = int.tryParse(value ?? '');

                  return year == null ||
                          year < 1900 ||
                          year > DateTime.now().year + 1
                      ? 'Enter a valid year'
                      : null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cc,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Engine size in cc (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _odo,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Odometer in km',
                ),
                validator: (value) {
                  final odometer = double.tryParse(value ?? '');

                  return odometer == null || odometer < 0
                      ? 'Enter a valid odometer'
                      : null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _plate,
                decoration: const InputDecoration(
                  labelText: 'Plate number (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
