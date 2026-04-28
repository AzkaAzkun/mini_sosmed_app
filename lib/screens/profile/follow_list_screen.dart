import 'package:flutter/material.dart';
import 'package:mini_sosmed_app/services/db_service.dart';
import 'package:mini_sosmed_app/services/follow_service.dart';
import 'package:mini_sosmed_app/screens/profile/profile_screen.dart';

class FollowListScreen extends StatelessWidget {
  final String userId;
  final String title;
  final bool isFollowers;

  FollowListScreen({
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  final FollowService _followService = FollowService();
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<List<String>>(
        stream: isFollowers
            ? _followService.getFollowers(userId)
            : _followService.getFollowing(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                isFollowers ? 'Belum ada pengikut.' : 'Belum mengikuti siapapun.',
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          final userIds = snapshot.data!;

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final targetId = userIds[index];
              
              return FutureBuilder<Map<String, dynamic>?>(
                future: _dbService.getUserData(targetId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();
                  
                  final userData = userSnapshot.data!;
                  
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: targetId),
                        ),
                      );
                    },
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(userData['username'] ?? 'Unknown'),
                    subtitle: Text(userData['email'] ?? ''),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
