import '../entities/transaction.dart';

enum DeleteScope { onlyThis, thisAndFuture, all }
enum EditScope { onlyThis, thisAndFuture, all }

abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<void> saveTransactions(List<Transaction> transactions);
  Future<void> deleteTransaction(String id);
  Future<void> deleteTransactionWithScope(Transaction transaction, DeleteScope scope);
  Future<void> saveTransactionWithScope(Transaction transaction, EditScope scope);
  Future<void> updateTransactionPaidStatus(String id, bool isPaid);
  Future<void> markAllTransactionsAsPaidForMonth(int year, int month);
  Future<List<Transaction>> getTransactionsByMonth(int year, int month);
  Future<List<Transaction>> getPendingDebts();
  Future<String> exportData();
  Future<void> importData(String jsonString);
}
