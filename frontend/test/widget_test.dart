import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/main.dart';
import 'package:frontend/data/datasources/auth_remote_datasource.dart';
import 'package:frontend/data/repositories/auth_repository.dart';

void main() {
  testWidgets('App smoke test – renders without crashing', (WidgetTester tester) async {
    final authRepository = AuthRepository(
      remoteDataSource: AuthRemoteDataSource(client: http.Client()),
    );

    await tester.pumpWidget(MyApp(authRepository: authRepository));
    await tester.pump();

    // L'app démarre sur la LoginScreen – vérifie qu'elle se charge
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
