import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<void> saveTransactions(List<Transaction> transactions);
  Future<void> deleteTransaction(String id);
  Future<void> updateTransactionPaidStatus(String id, bool isPaid);
  Future<void> markAllTransactionsAsPaidForMonth(int year, int month);
  Future<List<Transaction>> getTransactionsByMonth(int year, int month);
  Future<List<Transaction>> getPendingDebts();
  Future<String> exportData();
  Future<void> importData(String jsonString);
}
