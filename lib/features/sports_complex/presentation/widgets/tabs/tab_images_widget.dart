import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sports_complex_provider.dart';

class TabImagesWidget extends StatefulWidget {
  final String stadiumId;

  const TabImagesWidget({super.key, required this.stadiumId});

  @override
  State<TabImagesWidget> createState() => _TabImagesWidgetState();
}

class _TabImagesWidgetState extends State<TabImagesWidget> {
  @override
  void initState() {
    super.initState();
    // Gọi API lấy hình ảnh khi tab này được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SportsComplexProvider>().fetchStadiumImages(widget.stadiumId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SportsComplexProvider>(
      builder: (context, provider, child) {
        if (provider.isImagesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.imagesErrorMessage != null) {
          return Center(child: Text('Có lỗi xảy ra: ${provider.imagesErrorMessage}'));
        }

        final images = provider.currentStadiumImages;

        if (images.isEmpty) {
          return const Center(child: Text('Không có hình ảnh nào.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                images[index].imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                (loadingProgress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
