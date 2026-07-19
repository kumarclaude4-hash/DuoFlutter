import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/colors.dart';
import '../../security/app_lock_manager.dart';

class MediaViewerScreen extends StatefulWidget {
  final String? localPath;
  final String? networkUrl;
  final String? mediaType;
  final String? heroTag;

  const MediaViewerScreen({
    super.key,
    this.localPath,
    this.networkUrl,
    this.mediaType,
    this.heroTag,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    AppLockManager.instance.onScreenStarted();
  }

  @override
  void dispose() {
    AppLockManager.instance.onScreenStopped();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            _buildMediaContent(),
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.download_outlined, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.mediaType == 'image') {
      if (widget.localPath != null) {
        return PhotoView(
          imageProvider: FileImage(File(widget.localPath!)),
          heroAttributes: widget.heroTag != null
              ? PhotoViewHeroAttributes(tag: widget.heroTag!)
              : null,
        );
      } else if (widget.networkUrl != null) {
        return PhotoView(
          imageProvider: NetworkImage(widget.networkUrl!),
          heroAttributes: widget.heroTag != null
              ? PhotoViewHeroAttributes(tag: widget.heroTag!)
              : null,
        );
      }
    }
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.white54, size: 80),
    );
  }
}
