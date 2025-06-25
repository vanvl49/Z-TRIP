import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionController extends GetxController {
  // Reactive state
  final RxList<Transaction> transactions = <Transaction>[].obs;
  final Rx<Transaction?> selectedTransaction = Rx<Transaction?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Get token from storage
  String? _getToken() {
    final box = GetStorage();
    return box.read('token');
  }

  // =============================================================
  // GET ALL TRANSACTIONS
  // =============================================================
  Future<void> fetchAllTransactions() async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final fetchedTransactions = await TransactionService.getTransactions(
        token,
      );
      transactions.value = fetchedTransactions;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat transaksi: $e';
      transactions.clear();
    }
  }

  // =============================================================
  // GET TRANSACTION BY ID
  // =============================================================
  Future<void> fetchTransactionById(int id) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final transaction = await TransactionService.getTransactionById(
        token,
        id,
      );
      selectedTransaction.value = transaction;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat detail transaksi: $e';
      selectedTransaction.value = null;
    }
  }

  // =============================================================
  // GET UNPAID TRANSACTIONS
  // =============================================================
  Future<List<Transaction>> fetchUnpaidTransactions() async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return [];
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final unpaidTransactions = await TransactionService.getUnpaidTransactions(
        token,
      );
      isLoading.value = false;
      return unpaidTransactions;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal memuat transaksi yang belum dibayar: $e';
      return [];
    }
  }

  // =============================================================
  // UPLOAD PAYMENT PROOF
  // =============================================================
  Future<bool> uploadPaymentProof(
    int transactionId,
    Uint8List imageBytes,
  ) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final success = await TransactionService.uploadPaymentProof(
        token,
        transactionId,
        imageBytes,
      );

      isLoading.value = false;

      if (success) {
        // Refresh transactions and selected transaction if it's the updated one
        fetchAllTransactions();
        if (selectedTransaction.value?.id == transactionId) {
          fetchTransactionById(transactionId);
        }
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal mengupload bukti pembayaran: $e';
      return false;
    }
  }

  // =============================================================
  // APPROVE PAYMENT (ADMIN)
  // =============================================================
  Future<bool> approvePayment(int transactionId) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final success = await TransactionService.approvePayment(
        token,
        transactionId,
      );

      isLoading.value = false;

      if (success) {
        // Refresh transactions and selected transaction if it's the approved one
        fetchAllTransactions();
        if (selectedTransaction.value?.id == transactionId) {
          fetchTransactionById(transactionId);
        }
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menyetujui pembayaran: $e';
      return false;
    }
  }

  // =============================================================
  // REJECT PAYMENT (ADMIN)
  // =============================================================
  Future<bool> rejectPayment(int transactionId, String reason) async {
    final token = _getToken();
    if (token == null) {
      hasError.value = true;
      errorMessage.value = 'Tidak ada token autentikasi';
      return false;
    }

    isLoading.value = true;
    hasError.value = false;

    try {
      final success = await TransactionService.rejectPayment(
        token,
        transactionId,
        reason,
      );

      isLoading.value = false;

      if (success) {
        // Refresh transactions and selected transaction if it's the rejected one
        fetchAllTransactions();
        if (selectedTransaction.value?.id == transactionId) {
          fetchTransactionById(transactionId);
        }
      }

      return success;
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Gagal menolak pembayaran: $e';
      return false;
    }
  }

  // Get payment image URL helper
  String getPaymentImageUrl(int transactionId) {
    return TransactionService.getPaymentImageUrl(transactionId);
  }

  // Clear selected transaction
  void clearSelectedTransaction() {
    selectedTransaction.value = null;
  }
}
