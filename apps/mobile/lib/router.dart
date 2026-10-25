import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/catalog_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/chat_screen.dart';

GoRouter mobileRouter(VoidCallback failNext) => GoRouter(initialLocation: '/cars',
  errorBuilder: (context, state) => Scaffold(body: Center(child: TextButton(
    onPressed: () => context.go('/cars'), child: const Text('Stranica ne postoji. Katalog')))),
  routes: [
    ShellRoute(builder: (context, state, child) {
      final path = state.uri.path;
      return Scaffold(body: child, bottomNavigationBar: NavigationBar(
        selectedIndex: path == '/favorites' ? 1 : path == '/reservations' ? 2 : 0,
        onDestinationSelected: (index) => context.go(['/cars', '/favorites', '/reservations'][index]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.directions_car), label: 'Katalog'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Favoriti'),
          NavigationDestination(icon: Icon(Icons.bookmark), label: 'Moje rezervacije'),
        ]));
    }, routes: [
      GoRoute(path: '/cars', builder: (_, _) => CatalogScreen(failNext: failNext)),
      GoRoute(path: '/favorites', builder: (_, _) => CatalogScreen(mode: 'favorites', failNext: failNext)),
      GoRoute(path: '/reservations', builder: (_, _) => CatalogScreen(mode: 'reservations', failNext: failNext)),
    ]),
    GoRoute(path: '/cars/:id', builder: (_, state) => DetailScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/cars/:id/chat', builder: (_, state) => ChatScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/filters', builder: (_, _) => const FiltersScreen()),
  ]);
