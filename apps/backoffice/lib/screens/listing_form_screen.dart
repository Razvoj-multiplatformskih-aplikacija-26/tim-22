import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation.dart';

class ListingFormScreen extends StatelessWidget {
  const ListingFormScreen({super.key, this.id});
  final String? id;
  @override
  Widget build(BuildContext context) => BlocConsumer<ListingsBloc, ListingsState>(
    listener: (context, state) {
      showOperationError(context, state);
    }, builder: (context, state) {
      final listing = id == null ? null : findListing(state.listings, ListingId(id!));
      final editable = id == null || (listing != null && canEditListing(listing, context.read<ListingsBloc>().role));
      return Scaffold(appBar: AppBar(title: Text(id == null ? 'Novi oglas' : 'Izmeni oglas'),
        leading: IconButton(tooltip: 'Katalog', onPressed: state.saving ? null : () => context.go('/cars'),
          icon: const Icon(Icons.arrow_back))),
        body: LoadView(state: state, child: !editable ? const Center(child: Text('Oglas nije dostupan za izmenu.'))
          : _ListingForm(key: ValueKey(id), listing: listing)));
    });
}

class _ListingForm extends StatefulWidget {
  const _ListingForm({super.key, this.listing});
  final CarListing? listing;
  @override
  State<_ListingForm> createState() => _ListingFormState();
}
class _ListingFormState extends State<_ListingForm> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.listing?.title ?? '');
  late final price = TextEditingController(text: widget.listing?.priceEur.toString() ?? '');
  late final description = TextEditingController(text: widget.listing?.description ?? '');
  late final fields = <String, TextEditingController>{
    'Marka': TextEditingController(text: widget.listing?.specs.brand ?? ''),
    'Model': TextEditingController(text: widget.listing?.specs.model ?? ''),
    'Godište': TextEditingController(text: widget.listing?.specs.year == 0
      ? '' : widget.listing?.specs.year.toString()),
    'Kilometraža (km)': TextEditingController(text: widget.listing?.specs.mileageKm == 0
      ? '' : widget.listing?.specs.mileageKm.toString()),
    'Tip auta': TextEditingController(text: widget.listing?.specs.bodyType ?? ''),
    'Pogon': TextEditingController(text: widget.listing?.specs.drive ?? ''),
    'Broj vrata': TextEditingController(text: widget.listing?.specs.doors ?? ''),
    'Boja': TextEditingController(text: widget.listing?.specs.color ?? ''),
    'Menjač': TextEditingController(text: widget.listing?.specs.transmission ?? ''),
    'Broj brzina': TextEditingController(text: widget.listing?.specs.gears ?? ''),
    'Gorivo': TextEditingController(text: widget.listing?.specs.fuel ?? ''),
  };
  bool submitted = false;
  @override
  void dispose() {
    title.dispose(); price.dispose(); description.dispose();
    for (final controller in fields.values) { controller.dispose(); }
    super.dispose();
  }

  CarSpecs get specs => CarSpecs(
    brand: fields['Marka']!.text.trim(), model: fields['Model']!.text.trim(),
    year: int.tryParse(fields['Godište']!.text.trim()) ?? 0,
    mileageKm: int.tryParse(fields['Kilometraža (km)']!.text.trim()) ?? 0,
    bodyType: fields['Tip auta']!.text.trim(), drive: fields['Pogon']!.text.trim(),
    doors: fields['Broj vrata']!.text.trim(), color: fields['Boja']!.text.trim(),
    transmission: fields['Menjač']!.text.trim(), gears: fields['Broj brzina']!.text.trim(),
    fuel: fields['Gorivo']!.text.trim());

  Widget specField(String label) {
    final numeric = label == 'Godište' || label == 'Kilometraža (km)';
    return TextFormField(controller: fields[label],
      decoration: InputDecoration(labelText: label),
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      validator: numeric ? (text) => text == null || text.trim().isEmpty ? null
        : switch (validatePositiveNumber(int.tryParse(text.trim()))) {
            Failure<int>(:final error) => errorLabel(error), Success<int>() => null,
          } : null);
  }
  @override
  Widget build(BuildContext context) => BlocConsumer<ListingsBloc, ListingsState>(
    listenWhen: (previous, current) => submitted && previous.saveRevision != current.saveRevision,
    listener: (context, state) => context.go('/cars/${state.savedId!.value}'),
    builder: (context, state) => Form(key: form, child: ListView(padding: const EdgeInsets.all(24), children: [
      TextFormField(controller: title, enabled: !state.saving,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(labelText: 'Naziv vozila'), validator: (text) {
          final result = validateListingInput(title: text ?? '', priceEur: int.tryParse(price.text.trim()));
          return result is Failure<int> && result.error is EmptyTitle ? errorLabel(result.error) : null;
        }),
      TextFormField(controller: price, enabled: !state.saving, keyboardType: TextInputType.number,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(labelText: 'Cena (€)'), validator: priceError),
      TextFormField(controller: description, enabled: !state.saving, minLines: 2, maxLines: 5,
        decoration: const InputDecoration(labelText: 'Opis')),
      const SizedBox(height: 16),
      for (final label in fields.keys) Padding(padding: const EdgeInsets.only(bottom: 12),
        child: specField(label)),
      const SizedBox(height: 16),
      FilledButton(onPressed: state.saving ? null : () {
        if (!form.currentState!.validate()) return;
        submitted = true;
        context.read<ListingsBloc>().add(ListingSaved(id: widget.listing?.id,
          title: title.text, priceEur: int.tryParse(price.text.trim()),
          description: description.text, specs: specs));
      }, child: Text(state.saving ? 'Čuvanje…' : 'Sačuvaj')),
      TextButton(onPressed: state.saving ? null : () => context.go(widget.listing == null
        ? '/cars' : '/cars/${widget.listing!.id.value}'), child: const Text('Odustani')),
    ])));
}
