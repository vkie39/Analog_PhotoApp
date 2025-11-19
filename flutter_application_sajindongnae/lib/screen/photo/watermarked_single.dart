import 'package:flutter/material.dart';

class CenterWatermarkImage extends StatelessWidget {
  final ImageProvider image;
  final BoxFit fit;
  final String watermarkText;
  final double opacity;
  final double fontSizeRatio;

  const CenterWatermarkImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.watermarkText = '사진동네',
    this.opacity = 0.25,
    this.fontSizeRatio = 0.06, // 이미지 짧은 변의 6%
  });

  factory CenterWatermarkImage.network(
    String url, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    String watermarkText = '사진동네',
    double opacity = 0.25,
    double fontSizeRatio = 0.06,
  }) {
    return CenterWatermarkImage(
      key: key,
      image: NetworkImage(url),
      fit: fit,
      watermarkText: watermarkText,
      opacity: opacity,
      fontSizeRatio: fontSizeRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final shortestSide =
            constraints.biggest.shortestSide * fontSizeRatio;

        return Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: image,
              fit: fit,
            ),

            // 중앙 워터마크
            Center(
              child: Text(
                watermarkText,
                style: TextStyle(
                  fontSize: shortestSide.clamp(16, 48),
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(opacity),
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black.withOpacity(opacity * 0.8),
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
