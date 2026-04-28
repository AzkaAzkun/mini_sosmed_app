import 'package:flutter/material.dart';
import 'package:mini_sosmed_app/models/post_model.dart';
import 'package:mini_sosmed_app/screens/profile/post_detail_screen.dart';
import 'package:mini_sosmed_app/screens/profile/profile_screen.dart';
import 'package:mini_sosmed_app/services/auth_service.dart';
import 'package:mini_sosmed_app/services/db_service.dart';
import 'package:mini_sosmed_app/services/follow_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final FollowService _followService = FollowService();
  final AuthService _authService = AuthService();
  
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari username...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim();
            });
          },
        ),
      ),
      body: _searchQuery.isEmpty
          ? StreamBuilder<List<PostModel>>(
              stream: _dbService.getPosts(), // Fetch all posts globally
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Center(child: Text('Ketik username untuk mencari, atau jelajahi Explore nanti.'));
                }

                return GridView.builder(
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
                );
              },
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _dbService.searchUsers(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final users = snapshot.data ?? [];
                
                if (users.isEmpty) {
                  return const Center(child: Text('User tidak ditemukan'));
                }
                
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final targetUserId = user['uid'] as String;
                    final isMe = targetUserId == currentUserId;

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: targetUserId),
                          ),
                        );
                      },
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(user['username'] ?? ''),
                      subtitle: Text(user['email'] ?? ''),
                      trailing: isMe || currentUserId == null
                          ? null
                          : StreamBuilder<bool>(
                              stream: _followService.isFollowing(currentUserId, targetUserId),
                              builder: (context, followSnapshot) {
                                final isFollowing = followSnapshot.data ?? false;
                                
                                return ElevatedButton(
                                  onPressed: () {
                                    if (isFollowing) {
                                      _followService.unfollowUser(currentUserId, targetUserId);
                                    } else {
                                      _followService.followUser(currentUserId, targetUserId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Anda mulai mengikuti ${user['username']}')),
                                      );
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
                    );
                  },
                );
              },
            ),
    );
  }
}
