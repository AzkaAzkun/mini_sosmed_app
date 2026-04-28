import 'package:flutter/material.dart';
import 'package:mini_sosmed_app/models/post_model.dart';
import 'package:mini_sosmed_app/services/auth_service.dart';
import 'package:mini_sosmed_app/services/db_service.dart';
import 'package:mini_sosmed_app/services/follow_service.dart';
import 'package:mini_sosmed_app/screens/profile/post_detail_screen.dart';
import 'package:mini_sosmed_app/screens/profile/follow_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final FollowService _followService = FollowService();

  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String get _targetUserId => widget.userId ?? _authService.currentUser?.uid ?? '';

  Future<void> _loadUserData() async {
    if (_targetUserId.isNotEmpty) {
      final data = await _dbService.getUserData(_targetUserId);
      setState(() {
        _userData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Belum Login')));
    }

    final isMe = widget.userId == null || widget.userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(_userData?['username'] ?? 'Profile'),
        actions: [
          if (isMe)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            )
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: _dbService.getUserPosts(_targetUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data ?? [];

          return Column(
            children: [
              // Statistics
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Posts', posts.length.toString(), null),
                          StreamBuilder<int>(
                            stream: _followService.getFollowerCount(_targetUserId),
                            builder: (context, snapshot) {
                              return _buildStatColumn('Followers', snapshot.data?.toString() ?? '0', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowListScreen(
                                      userId: _targetUserId,
                                      title: 'Pengikut',
                                      isFollowers: true,
                                    ),
                                  ),
                                );
                              });
                            },
                          ),
                          StreamBuilder<int>(
                            stream: _followService.getFollowingCount(_targetUserId),
                            builder: (context, snapshot) {
                              return _buildStatColumn('Following', snapshot.data?.toString() ?? '0', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FollowListScreen(
                                      userId: _targetUserId,
                                      title: 'Mengikuti',
                                      isFollowers: false,
                                    ),
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _userData?['email'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: StreamBuilder<bool>(
                      stream: _followService.isFollowing(currentUserId, _targetUserId),
                      builder: (context, followSnapshot) {
                        final isFollowing = followSnapshot.data ?? false;
                        
                        return ElevatedButton(
                          onPressed: () {
                            if (isFollowing) {
                              _followService.unfollowUser(currentUserId, _targetUserId);
                            } else {
                              _followService.followUser(currentUserId, _targetUserId);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey[900] : Colors.white,
                            foregroundColor: isFollowing ? Colors.white : Colors.black,
                          ),
                          child: Text(isFollowing ? 'Mengikuti' : 'Ikuti'),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Grid View
              Expanded(
                child: posts.isEmpty
                    ? const Center(child: Text('Belum ada postingan.'))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    posts: posts,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              color: Colors.grey[800],
                              child: post.isVideo
                                  ? const Center(child: Icon(Icons.videocam, color: Colors.white, size: 40))
                                  : Image.network(post.mediaUrl, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String count, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
