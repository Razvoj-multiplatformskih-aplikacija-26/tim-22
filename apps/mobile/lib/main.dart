import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'data/memory_listings_repository.dart';
import 'presentation.dart';
import 'router.dart';

void main() {
  final repository = MemoryListingsRepository();
  runApp(MobileApp(repository: repository, failNext: repository.failNextRequest));
}

class MobileApp extends StatefulWidget {
  const MobileApp({super.key, required this.repository, required this.failNext});
  final ListingsRepository repository;
  final VoidCallback failNext;
  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  late final ListingsBloc bloc = ListingsBloc(repository: widget.repository,
    role: UserRole.customer, userId: const UserId('user-1'))..add(const LoadRequested());
  late final GoRouter router = mobileRouter(widget.failNext);
  @override
  void dispose() { router.dispose(); bloc.close(); super.dispose(); }
  @override
  Widget build(BuildContext context) => BlocProvider.value(value: bloc,
    child: MaterialApp.router(title: 'AutoMatch', theme: appTheme(), routerConfig: router));
}
