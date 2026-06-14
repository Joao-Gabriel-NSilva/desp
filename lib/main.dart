import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/data/repositories/transaction_repository_impl.dart';
import 'features/dashboard/data/services/auth_service.dart';
import 'features/dashboard/domain/entities/user_profile.dart';
import 'features/dashboard/domain/repositories/transaction_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';
import 'features/dashboard/presentation/pages/home_navigation_page.dart';
import 'features/dashboard/presentation/pages/login_page.dart';

import 'features/dashboard/data/services/firestore_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase not initialized: $e');
  }

  // Inicialização do repositório
  final TransactionRepository repository = TransactionRepositoryImpl();

  // Iniciar sincronização em segundo plano se houver usuário/família
  await FirestoreSyncService.instance.startSync();

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final TransactionRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(repository: repository)
        ..add(LoadDashboard(targetMonth: DateTime.now())),
      child: MaterialApp(
        title: 'Desp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: FutureBuilder<UserProfile?>(
          future: AuthService.instance.getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0F172A),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              );
            }
            final user = snapshot.data;
            if (user != null) {
              return const HomeNavigationPage();
            } else {
              return const LoginPage();
            }
          },
        ),
      ),
    );
  }
}
