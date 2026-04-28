import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';
import 'package:mini_sosmed_app/models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final String username;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.username,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final StoryController controller = StoryController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyItems = widget.stories.map((story) {
      if (story.isVideo) {
        return StoryItem.pageVideo(
          story.mediaUrl,
          controller: controller,
          caption: story.location != null ? Text(story.location!) : null, 
        );
      } else {
        return StoryItem.pageImage(
          url: story.mediaUrl,
          controller: controller,
          caption: story.location != null
              ? Text(
                  story.location!,
                  style: const TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                    fontSize: 18,
                  ),
                )
              : null,
        );
      }
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          StoryView(
            storyItems: storyItems,
            controller: controller,
            onComplete: () {
              Navigator.pop(context);
            },
            onVerticalSwipeComplete: (direction) {
              if (direction == Direction.down) {
                Navigator.pop(context);
              }
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0, left: 16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
