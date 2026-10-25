import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});
  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final form = GlobalKey<FormState>();
  final priceFocus = FocusNode();
  late final current = context.read<ListingsBloc>().state.filters;
  late final price = TextEditingController(text: current.maxPrice?.toString() ?? '');
  late final mileage = TextEditingController(text: current.maxMileageKm?.toString() ?? '');
  late final year = TextEditingController(text: current.minYear?.toString() ?? '');
  late String brand = current.specs.brand, model = current.specs.model,
    bodyType = current.specs.bodyType,
    drive = current.specs.drive, doors = current.specs.doors,
    color = current.specs.color, transmission = current.specs.transmission,
    gears = current.specs.gears, fuel = current.specs.fuel;

  @override
  void dispose() {
    price.dispose(); mileage.dispose(); year.dispose(); priceFocus.dispose();
    super.dispose();
  }

  Widget select(String label, String value, Iterable<String> options,
      ValueChanged<String> change) {
    final choices = {...options, value}..remove('');
    final sorted = choices.toList()..sort();
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey(label == 'Model' ? '$label:$brand' : label),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [const DropdownMenuItem(value: '', child: Text('Sve')),
          for (final choice in sorted) DropdownMenuItem(value: choice, child: Text(choice))],
        onChanged: (value) => setState(() => change(value ?? ''))));
  }

  void apply() {
    if (!form.currentState!.validate()) {
      priceFocus.requestFocus();
      return;
    }
    context.read<ListingsBloc>().add(FiltersChanged(ListingFilters(
      maxPrice: int.tryParse(price.text.trim()),
      maxMileageKm: int.tryParse(mileage.text.trim()),
      minYear: int.tryParse(year.text.trim()),
      specs: CarSpecs(brand: brand, model: model,
        bodyType: bodyType, drive: drive, doors: doors, color: color,
        transmission: transmission, gears: gears, fuel: fuel))));
    context.go('/cars');
  }

  @override
  Widget build(BuildContext context) {
    final specs = publicListings(context.read<ListingsBloc>().state.listings)
        .map((listing) => listing.specs).toList();
    return Scaffold(appBar: AppBar(title: const Text('Filteri')),
      body: Form(key: form, child: SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Kombinuj kriterijume. Prazna cena i „Sve“ ne ograničavaju izbor.'),
        const SizedBox(height: 16),
        TextFormField(controller: price, focusNode: priceFocus, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Maksimalna cena (€)'),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (text) => text == null || text.trim().isEmpty ? null : priceError(text)),
        const SizedBox(height: 12),
        TextFormField(controller: mileage, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Maksimalna kilometraža (km)'),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: numberError),
        const SizedBox(height: 12),
        TextFormField(controller: year, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Godište od'),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: numberError),
        const SizedBox(height: 12),
        select('Marka', brand, specs.map((s) => s.brand), (v) {
          brand = v;
          model = '';
        }),
        select('Model', model, specs.where((s) => brand.isEmpty || s.brand == brand)
          .map((s) => s.model), (v) => model = v),
        select('Tip auta', bodyType, specs.map((s) => s.bodyType), (v) => bodyType = v),
        select('Pogon', drive, specs.map((s) => s.drive), (v) => drive = v),
        select('Broj vrata', doors, specs.map((s) => s.doors), (v) => doors = v),
        select('Boja', color, specs.map((s) => s.color), (v) => color = v),
        select('Menjač', transmission, specs.map((s) => s.transmission), (v) => transmission = v),
        select('Broj brzina', gears, specs.map((s) => s.gears), (v) => gears = v),
        select('Gorivo', fuel, specs.map((s) => s.fuel), (v) => fuel = v),
        FilledButton(onPressed: apply, child: const Text('Primeni')),
        TextButton(onPressed: () {
          context.read<ListingsBloc>().add(const FiltersChanged(ListingFilters()));
          context.go('/cars');
        }, child: const Text('Ukloni filtere')),
      ]))));
  }
}
