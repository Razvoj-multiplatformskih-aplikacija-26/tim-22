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
  runApp(BackofficeApp(repository: repository, failNext: repository.failNextRequest));
}

class BackofficeApp extends StatefulWidget {
  const BackofficeApp({super.key, required this.repository, required this.failNext});
  final ListingsRepository repository;
  final VoidCallback failNext;
  @override
  State<BackofficeApp> createState() => _BackofficeAppState();
}
class _BackofficeAppState extends State<BackofficeApp> {
  late final ListingsBloc bloc = ListingsBloc(repository: widget.repository,
    role: UserRole.staff, userId: const UserId('staff-1'))..add(const LoadRequested());
  late final GoRouter router = backofficeRouter(widget.failNext);
  @override
  void dispose() { router.dispose(); bloc.close(); super.dispose(); }
  @override
  Widget build(BuildContext context) => BlocProvider.value(value: bloc,
    child: MaterialApp.router(title: 'AutoMatch · Osoblje', theme: appTheme(), routerConfig: router));
}
