import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/market_data_service.dart';
import 'data/repositories/auth_repository.dart';

import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/market/market_data_bloc.dart';
import 'presentation/blocs/market/market_data_event.dart';

import 'presentation/screens/auth/login_screen.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, AuthRepository? authRepository})
      : _authRepository = authRepository;

  final AuthRepository? _authRepository;

  @override
  Widget build(BuildContext context) {
    final authRepository = _authRepository ??
        AuthRepository(
          remoteDataSource: AuthRemoteDataSource(client: http.Client()),
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
          )..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<MarketDataBloc>(
          create: (context) => MarketDataBloc(
            marketDataService: MarketDataService(),
          )..add(const InitMarketDataEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'TradeVision',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}