import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desp/main.dart';
import 'package:desp/features/dashboard/domain/entities/transaction.dart';
import 'package:desp/features/dashboard/domain/repositories/transaction_repository.dart';

class FakeTransactionRepository implements TransactionRepository {
  @override
  Future<void> saveTransaction(Transaction transaction) async {}
  
  @override
  Future<void> saveTransactions(List<Transaction> transactions) async {}
  
  @override
  Future<void> deleteTransaction(String id) async {}
  
  @override
  Future<void> deleteTransactionWithScope(Transaction transaction, DeleteScope scope) async {}
  
  @override
  Future<void> saveTransactionWithScope(Transaction transaction, EditScope scope) async {}
  
  @override
  Future<void> updateTransactionPaidStatus(String id, bool isPaid) async {}
  
  @override
  Future<void> markAllTransactionsAsPaidForMonth(int year, int month) async {}
  
  @override
  Future<List<Transaction>> getTransactionsByMonth(int year, int month) async => [];
  
  @override
  Future<List<Transaction>> getPendingDebts() async => [];

  @override
  Future<String> exportData() async => '[]';

  @override
  Future<void> importData(String jsonString) async {}
}

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    final repository = FakeTransactionRepository();
    await tester.pumpWidget(MyApp(repository: repository));
    
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
