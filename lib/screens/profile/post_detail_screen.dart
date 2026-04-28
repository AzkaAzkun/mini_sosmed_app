import 'package:flutter/material.dart';
import 'package:mini_sosmed_app/models/post_model.dart';
import 'package:mini_sosmed_app/services/db_service.dart';

class PostDetailScreen extends StatelessWidget {
  final List<PostModel> posts;
  final int initialIndex;

  const PostDetailScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(initialPage: initialIndex);
    
    // We can use a PageView or ListView. Since the user asked to "scroll nanti akan nunjukan captionnya"
    // a ListView starting at a specific index is usually better for Instagram style.
    // However, scrolling a ListView to a specific index in Flutter requires ScrollablePositionedList
    // or just an initialScrollOffset if we know heights. 
    // To keep it simple without extra packages, we can use a PageView with scrollDirection: Axis.vertical.
    // Let's just use ListView and we can't easily start at index, so PageView is cleaner.
    // Wait, Instagram profile click opens a ListView, but the user is scrolled to that item.
    // Another approach: ListView.builder, but it doesn't support initialIndex easily unless items have fixed height.
    // Let's use a PageView for simplicity so it snaps, or just a ListView and we only show from that index onwards.
    // Or we can use ScrollController with estimated height. Let's try ScrollController.
    // Let's just use a vertical PageView.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: PageView.builder(
        controller: pageController,
        scrollDirection: Axis.vertical,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return _DetailPostCard(post: post);
        },
      ),
    );
  }
}

class _DetailPostCard extends StatelessWidget {
  final PostModel post;
  final DatabaseService _dbService = DatabaseService();

  _DetailPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Username
          FutureBuilder<Map<String, dynamic>?>(
            future: _dbService.getUserData(post.userId),
            builder: (context, snapshot) {
              String username = 'Loading...';
              if (snapshot.hasData && snapshot.data != null) {
                username = snapshot.data!['username'] ?? 'Unknown User';
              }
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person, color: Colors.grey),
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
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 300,
                child: Center(child: Text('Gambar tidak dapat dimuat')),
              ),
            )
          else
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.black12,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_outline, size: 50, color: Colors.black54),
                    Text('Video Player'),
                  ],
                ),
              ),
            ),

          // Caption
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(
                      text: 'Caption: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              post.createdAt.toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
