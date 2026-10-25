import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.id});
  final String id;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final messages = <String>[];

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void send([String? suggestion]) {
    final text = (suggestion ?? input.text).trim();
    if (text.isEmpty) return;
    setState(() => messages.add(text));
    input.clear();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ListingsBloc, ListingsState>(
    builder: (context, state) {
      final listing = findListing(state.listings, ListingId(widget.id));
      if (listing == null || !isPublic(listing) || !state.favorites.contains(listing.id)) {
        return Scaffold(appBar: AppBar(title: const Text('Chat')),
          body: const Center(child: Text('Sačuvajte auto da biste otvorili chat.')));
      }
      final suggestions = [
        'Da li je ${listing.title} i dalje dostupan?',
        'Mogu li da zakažem razgledanje?',
        'Da li imate servisnu istoriju?',
      ];
      return Scaffold(
        appBar: AppBar(title: Text(listing.title)),
        body: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(
            'Demo razgovor · poruke se ne šalju vlasniku i nestaju kada napustite ekran.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final message in messages)
              Align(alignment: Alignment.centerRight, child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(padding: const EdgeInsets.all(12), child: Text(message))))),
          ])),
          SingleChildScrollView(scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [for (final text in suggestions)
              Padding(padding: const EdgeInsets.only(right: 8),
                child: ActionChip(label: Text(text), onPressed: () => send(text)))])),
          Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Expanded(child: TextField(controller: input,
              decoration: const InputDecoration(labelText: 'Poruka'),
              textInputAction: TextInputAction.send, onSubmitted: (_) => send())),
            IconButton(tooltip: 'Dodaj poruku u demo chat', icon: const Icon(Icons.send),
              onPressed: () => send()),
          ])),
        ])),
      );
    });
}
