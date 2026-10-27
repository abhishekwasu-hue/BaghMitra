import 'dart:async';

import 'package:bagmitra/admin/admin_app.dart';
import 'package:bagmitra/admin/admin_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'kb_admin_test.dart' show FakeKbAdmin;

class FakeAdminAuth implements AdminAuth {
  FakeAdminAuth({bool signedIn = false, this.roles = const {}})
    : _token = signedIn ? 'tok' : null;

  final _changes = StreamController<void>.broadcast();
  String? _token;

  @override
  final Set<String> roles;

  @override
  String? get accessToken => _token;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> signIn(String email, String password) async {
    if (password != 'right') throw const AdminSignInError();
    _token = 'tok';
    _changes.add(null);
  }

  @override
  Future<void> signOut() async {
    _token = null;
    _changes.add(null);
  }
}

void main() {
  testWidgets('admin signs in, sees the shell, signs out', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AdminApp(
        productName: 'BagMitra',
        auth: FakeAdminAuth(),
        kb: FakeKbAdmin(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Knowledge cards'), findsNothing);

    await tester.enterText(find.byKey(const Key('admin-email')), 'a@b.in');
    await tester.enterText(find.byKey(const Key('admin-password')), 'wrong');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is wrong.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('admin-password')), 'right');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Citrus psylla'), findsOneWidget);

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-email')), findsOneWidget);
  });
}
