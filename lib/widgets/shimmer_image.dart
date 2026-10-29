import 'package:flutter/material.dart';

/// صورة مع تأثير Shimmer أثناء التحميل + Hero Animation
class ShimmerHeroImage extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final double size;
  final IconData fallbackIcon;

  const ShimmerHeroImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.size = 52,
    this.fallbackIcon = Icons.book,
  });

  @override
  State<ShimmerHeroImage> createState() => _ShimmerHeroImageState();
}

class _ShimmerHeroImageState extends State<ShimmerHeroImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  bool _loaded = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrl = widget.imageUrl.startsWith('http');

    // ═══ بدون صورة → أيقونة عادية ═══
    if (widget.imageUrl.isEmpty) {
      return Hero(
        tag: widget.heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Icon(widget.fallbackIcon,
              size: widget.size, color: Colors.teal),
        ),
      );
    }

    return Hero(
      tag: widget.heroTag,
      child: Material(
        type: MaterialType.transparency,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: isUrl
                ? _buildNetworkImage()
                : _buildIconFallback(),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ═══ Shimmer أثناء التحميل ═══
        if (!_loaded && !_error)
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 - 2 * _shimmerCtrl.value, 0),
                    end: Alignment(1.0 - 2 * _shimmerCtrl.value, 0),
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                  ),
                ),
              );
            },
          ),

        // ═══ الصورة الفعلية ═══
        Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_error) setState(() => _error = true);
            });
            return _buildIconFallback();
          },
          frameBuilder: (_, child, frame, wasSync) {
            if (frame != null && !_loaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _loaded = true);
              });
            }
            return AnimatedOpacity(
              opacity: _loaded ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
        ),
      ],
    );
  }

  Widget _buildIconFallback() {
    return Container(
      color: Colors.teal.withValues(alpha: 0.1),
      child: Icon(widget.fallbackIcon,
          size: widget.size * 0.6, color: Colors.teal),
    );
  }
}
