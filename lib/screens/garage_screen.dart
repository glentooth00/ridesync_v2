import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';
import 'main_shell.dart';

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
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          const Text('MY GARAGE', style: TextStyle(color: AppTheme.orange, letterSpacing: 2.2, fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 8),
          Text('Your machines.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Keep your motorcycles and odometer details in one place.', style: TextStyle(color: AppTheme.muted)),
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
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
              child: const Column(children: [
                Icon(Icons.two_wheeler, size: 54, color: AppTheme.orange),
                SizedBox(height: 14),
                Text('Your garage is empty', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Add your first motorcycle to get started.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted)),
              ]),
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
                  border: Border.all(color: active ? AppTheme.orange.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(height: 54, width: 54, decoration: BoxDecoration(color: AppTheme.surfaceRaised, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.two_wheeler, color: AppTheme.orange, size: 30)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(motorcycle.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${motorcycle.year} • ${motorcycle.engineCc.isEmpty ? 'CC not set' : '${motorcycle.engineCc} cc'}', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                    ])),
                    IconButton(onPressed: () => _showMotorcycleForm(context, existing: motorcycle), icon: const Icon(Icons.edit_outlined), tooltip: 'Edit motorcycle'),
                  ]),
                  const Divider(height: 24),
                  Row(children: [
                    const Icon(Icons.speed, color: AppTheme.muted, size: 18),
                    const SizedBox(width: 8),
                    const Text('Odometer', style: TextStyle(color: AppTheme.muted)),
                    const Spacer(),
                    Text('${motorcycle.odometerKm.toStringAsFixed(0)} km', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 14),
                  if (active)
                    const Row(children: [Icon(Icons.check_circle, size: 16, color: AppTheme.orange), SizedBox(width: 6), Text('ACTIVE MOTORCYCLE', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))])
                  else
                    OutlinedButton(onPressed: () => onSelectMotorcycle(motorcycle.id), child: const Text('Set as active motorcycle')),
                ]),
              );
            }),
        ],
      );

  Future<void> _showMotorcycleForm(BuildContext context, {Motorcycle? existing}) async {
    final formKey = GlobalKey<FormState>();
    final make = TextEditingController(text: existing?.make ?? '');
    final model = TextEditingController(text: existing?.model ?? '');
    final year = TextEditingController(text: '${existing?.year ?? DateTime.now().year}');
    final cc = TextEditingController(text: existing?.engineCc ?? '');
    final odo = TextEditingController(text: '${existing?.odometerKm ?? 0}'.replaceAll(RegExp(r'\.0$'), ''));
    final plate = TextEditingController(text: existing?.plateNumber ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add motorcycle' : 'Edit motorcycle'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: make, decoration: const InputDecoration(labelText: 'Make (e.g. Keeway)'), validator: _required),
            const SizedBox(height: 10),
            TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Model (e.g. Cafe Racer 152)'), validator: _required),
            const SizedBox(height: 10),
            TextFormField(controller: year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year'), validator: (v) {
              final value = int.tryParse(v ?? '');
              return value == null || value < 1900 || value > DateTime.now().year + 1 ? 'Enter a valid year' : null;
            }),
            const SizedBox(height: 10),
            TextFormField(controller: cc, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Engine size in cc (optional)')),
            const SizedBox(height: 10),
            TextFormField(controller: odo, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Odometer in km'), validator: (v) {
              final value = double.tryParse(v ?? '');
              return value == null || value < 0 ? 'Enter a valid odometer' : null;
            }),
            const SizedBox(height: 10),
            TextFormField(controller: plate, decoration: const InputDecoration(labelText: 'Plate number (optional)')),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, {
                'make': make.text.trim(), 'model': model.text.trim(), 'year': year.text.trim(),
                'cc': cc.text.trim(), 'odo': odo.text.trim(), 'plate': plate.text.trim(),
              });
            }
          }, child: const Text('Save')),
        ],
      ),
    );

    make.dispose(); model.dispose(); year.dispose(); cc.dispose(); odo.dispose(); plate.dispose();
    if (result == null) return;
    final motorcycle = Motorcycle(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch,
      name: '${result['make']} ${result['model']}',
      make: result['make']!,
      model: result['model']!,
      year: int.parse(result['year']!),
      engineCc: result['cc']!,
      odometerKm: double.parse(result['odo']!),
      plateNumber: result['plate']!,
    );
    if (existing == null) {
      await onAddMotorcycle(motorcycle);
    } else {
      await onUpdateMotorcycle(motorcycle);
    }
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;
}
