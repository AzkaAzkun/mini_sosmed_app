import 'package:flutter/material.dart';
import 'package:mini_sosmed_app/models/post_model.dart';
import 'package:mini_sosmed_app/models/story_model.dart';
import 'package:mini_sosmed_app/screens/notifications/notification_screen.dart';
import 'package:mini_sosmed_app/screens/story/create_story_screen.dart';
import 'package:mini_sosmed_app/screens/profile/post_detail_screen.dart';
import 'package:mini_sosmed_app/screens/profile/profile_screen.dart';
import 'package:mini_sosmed_app/screens/story/story_viewer_screen.dart';
import 'package:mini_sosmed_app/services/db_service.dart';
import 'package:mini_sosmed_app/services/story_service.dart';
import 'package:mini_sosmed_app/services/auth_service.dart';
import 'package:mini_sosmed_app/services/follow_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StoryService _storyService = StoryService();

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: FollowService().getFollowingIds(currentUserId),
        builder: (context, followingSnapshot) {
          final followingIds = followingSnapshot.data ?? [];
          final allowedIds = [currentUserId, ...followingIds];

          return Column(
            children: [
          SizedBox(
            height: 100,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateStoryScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[100],
                          child: const Icon(Icons.add, color: Colors.blue, size: 30),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Your Story', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                // Story List
                Expanded(
                  child: StreamBuilder<List<StoryModel>>(
                    stream: _storyService.getActiveStories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final stories = snapshot.data!.where((s) => allowedIds.contains(s.userId)).toList();
                      
                      // Group stories by userId
                      final Map<String, List<StoryModel>> groupedStories = {};
                      for (var story in stories) {
                        groupedStories.putIfAbsent(story.userId, () => []).add(story);
                      }
                      
                      final userIds = groupedStories.keys.toList();

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: userIds.length,
                        itemBuilder: (context, index) {
                          final userId = userIds[index];
                          final userStories = groupedStories[userId]!;
                          
                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _dbService.getUserData(userId),
                            builder: (context, userSnapshot) {
                              final username = userSnapshot.data?['username'] ?? 'User';
                              final coverUrl = userStories.first.mediaUrl;
                              
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StoryViewerScreen(
                                          stories: userStories,
                                          username: username,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.redAccent,
                                        child: CircleAvatar(
                                          radius: 27,
                                          backgroundColor: Colors.black,
                                          backgroundImage: userStories.first.isVideo 
                                              ? null 
                                              : NetworkImage(coverUrl),
                                          child: userStories.first.isVideo
                                              ? const Icon(Icons.videocam, color: Colors.white)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(username, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Posts Section
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _dbService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Belum ada postingan.'));
                }

                final posts = snapshot.data!;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isSuggested = !allowedIds.contains(post.userId);
                    return _PostCard(post: post, dbService: _dbService, isSuggested: isSuggested);
                  },
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
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final DatabaseService dbService;
  final bool isSuggested;

  const _PostCard({required this.post, required this.dbService, this.isSuggested = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSuggested)
            const Padding(
              padding: EdgeInsets.only(left: 16.0, top: 12.0),
              child: Text(
                '✨ Disarankan untuk Anda',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          // Header: Username
          FutureBuilder<Map<String, dynamic>?>(
            future: dbService.getUserData(post.userId),
            builder: (context, snapshot) {
              String username = 'Loading...';
              if (snapshot.hasData && snapshot.data != null) {
                username = snapshot.data!['username'] ?? 'Unknown User';
              } else if (snapshot.hasError) {
                username = 'Error loading user';
              }

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen(userId: post.userId)),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                title: Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),

          // Media
          if (!post.isVideo)
            Image.network(
              post.mediaUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 200,
                child: Center(child: Text('Gambar tidak dapat dimuat')),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.black12,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline, size: 50, color: Colors.black54),
                    Text('Video (Video Player Belum Diimplementasi)'),
                  ],
                ),
              ),
            ),
          if (post.createdAt == DateTime.now())
            Text('Baru saja'),
          else
            Text(post.createdAt.toString()), 
          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(post.caption),
            ),
        ],
      ),
    );
  }
}
