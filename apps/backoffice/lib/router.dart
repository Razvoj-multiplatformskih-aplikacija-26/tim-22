import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/catalog_screen.dart';
import 'screens/listing_form_screen.dart';

GoRouter backofficeRouter(VoidCallback failNext) => GoRouter(initialLocation: '/cars',
  errorBuilder: (context, state) => Scaffold(body: Center(child: TextButton(
    onPressed: () => context.go('/cars'), child: const Text('Stranica ne postoji. Katalog')))),
  routes: [
    GoRoute(path: '/cars/new', builder: (_, _) => const ListingFormScreen()),
    GoRoute(path: '/cars/:id/edit', builder: (_, state) => ListingFormScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/cars', pageBuilder: (_, _) => NoTransitionPage(
      key: const ValueKey('catalog'), child: CatalogScreen(failNext: failNext))),
    GoRoute(path: '/cars/:id', pageBuilder: (_, state) => NoTransitionPage(
      key: const ValueKey('catalog'), child: CatalogScreen(id: state.pathParameters['id'], failNext: failNext))),
  ]);
