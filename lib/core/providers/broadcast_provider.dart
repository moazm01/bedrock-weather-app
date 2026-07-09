import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  const BroadcastModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory BroadcastModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BroadcastModel(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class BroadcastProvider extends ChangeNotifier {
  BroadcastModel? _latestBroadcast;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isLoading = false;

  BroadcastProvider() {
    _startListening();
  }

  BroadcastModel? get latestBroadcast => _latestBroadcast;
  bool get isLoading => _isLoading;

  void _startListening() {
    _isLoading = true;
    notifyListeners();

    try {
      _subscription = FirebaseFirestore.instance
          .collection('system_broadcasts')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen(
            (snapshot) {
              _isLoading = false;
              if (snapshot.docs.isNotEmpty) {
                final doc = snapshot.docs.first;
                _latestBroadcast = BroadcastModel.fromFirestore(
                  doc.data(),
                  doc.id,
                );
              } else {
                _latestBroadcast = null;
              }
              notifyListeners();
            },
            onError: (_) {
              _isLoading = false;
              _latestBroadcast = null;
              notifyListeners();
            },
          );
    } catch (_) {
      _isLoading = false;
      _latestBroadcast = null;
      notifyListeners();
    }
  }

  void dismissBroadcast() {
    _latestBroadcast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
