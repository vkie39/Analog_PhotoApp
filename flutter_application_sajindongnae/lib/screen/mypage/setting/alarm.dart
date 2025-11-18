import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({super.key});

  @override
  State<AlarmSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<AlarmSettingsScreen> {
  bool _allNotifications = true;
  bool _communityNotifications = true;
  bool _likeNotifications = true;
  bool _requestNotifications = true;

  bool _isLoading = true;

  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    final data = doc.data();
    setState(() {
      _allNotifications = data?['notifications_all'] ?? true;
      _communityNotifications = data?['notifications_community'] ?? true;
      _likeNotifications = data?['notifications_like'] ?? true;
      _requestNotifications = data?['notifications_request'] ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
      'notifications_all': _allNotifications,
      'notifications_community': _communityNotifications,
      'notifications_like': _likeNotifications,
      'notifications_request': _requestNotifications,
    }, SetOptions(merge: true));
  }

  void _onAllNotificationsChanged(bool value) {
    setState(() {
      _allNotifications = value;
      if (value) {
        // 전체 알림 ON → 하위 알림도 모두 ON
        _communityNotifications = true;
        _likeNotifications = true;
        _requestNotifications = true;
      } else {
        // 전체 알림 OFF → 하위 알림 OFF
        _communityNotifications = false;
        _likeNotifications = false;
        _requestNotifications = false;
      }
    });
    _saveSettings();
  }


  void _onSubNotificationChanged(String type, bool value) {
    setState(() {
      switch (type) {
        case 'community':
          _communityNotifications = value;
          break;
        case 'like':
          _likeNotifications = value;
          break;
        case 'request':
          _requestNotifications = value;
          break;
      }
      // 하위 알림 중 하나라도 ON이면 전체 알림은 ON
      _allNotifications =
          _communityNotifications || _likeNotifications || _requestNotifications;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('알림 설정'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '알림 설정',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          SwitchListTile(
            title: const Text('알림 허용'),
            value: _allNotifications,
            onChanged: _onAllNotificationsChanged,
            activeTrackColor: const Color(0xFFDBEFC4), 
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('커뮤니티 알림 허용'),
            value: _communityNotifications,
            onChanged: _allNotifications
                ? (v) => _onSubNotificationChanged('community', v)
                : null, // 전체 OFF면 하위 토글 비활성
            activeTrackColor: const Color(0xFFDBEFC4), 
          ),
          SwitchListTile(
            title: const Text('좋아요 알림 허용'),
            value: _likeNotifications,
            onChanged: _allNotifications
                ? (v) => _onSubNotificationChanged('like', v)
                : null,
            activeTrackColor: const Color(0xFFDBEFC4), 
          ),
          SwitchListTile(
            title: const Text('의뢰글 알림 허용'),
            value: _requestNotifications,
            onChanged: _allNotifications
                ? (v) => _onSubNotificationChanged('request', v)
                : null,
            activeTrackColor: const Color(0xFFDBEFC4), 
          ),
        ],
      ),
    );
  }
}
