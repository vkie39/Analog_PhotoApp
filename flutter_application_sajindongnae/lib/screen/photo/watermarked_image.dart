// lib/screen/photo/watermarked_image.dart
// 화면에 그릴 때만 대각선 반복 텍스트 워터마크를 오버레이로 얹어준다.
// 실제 파일/원본은 변형하지 않음.

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class WatermarkedImage extends StatelessWidget {
  /// 실제 이미지를 그리는 위젯(Image.network, Image.asset 등)
  final Widget child;

  // 워터마크 옵션
  final String watermarkText;
  final double opacity;        // 텍스트 투명도
  final double paddingFactor;  // 텍스트 간격
  final double angleDeg;       // 회전 각도
  final bool antiAlias;
  final BorderRadius? borderRadius;

  const WatermarkedImage({
    super.key,
    required this.child,
    this.watermarkText = '사진동네',
    this.opacity = 0.18,
    this.paddingFactor = 2.5,
    this.angleDeg = -45,
    this.antiAlias = true,
    this.borderRadius,
  });

  /// 헬퍼: 네트워크 이미지 + 기본 로딩/에러 처리
  factory WatermarkedImage.network(
    String url, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    String watermarkText = '사진동네',
    double opacity = 0.18,
    double paddingFactor = 2.5,
    double angleDeg = -45,
    bool antiAlias = true,
    BorderRadius? borderRadius,
  }) {
    final fallback = Container(
      color: const Color(0xFFF2F2F2),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
    );

    return WatermarkedImage(
      key: key,
      watermarkText: watermarkText,
      opacity: opacity,
      paddingFactor: paddingFactor,
      angleDeg: angleDeg,
      antiAlias: antiAlias,
      borderRadius: borderRadius,
      child: Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          final loaded = progress.cumulativeBytesLoaded;
          return Center(
            child: CircularProgressIndicator(
              value: total != null ? loaded / total : null,
            ),
          );
        },
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  /// 헬퍼: 에셋 이미지
  factory WatermarkedImage.asset(
    String assetName, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    String watermarkText = '사진동네',
    double opacity = 0.18,
    double paddingFactor = 2.5,
    double angleDeg = -45,
    bool antiAlias = true,
    BorderRadius? borderRadius,
  }) {
    return WatermarkedImage(
      key: key,
      watermarkText: watermarkText,
      opacity: opacity,
      paddingFactor: paddingFactor,
      angleDeg: angleDeg,
      antiAlias: antiAlias,
      borderRadius: borderRadius,
      child: Image.asset(
        assetName,
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }

  /// 헬퍼: 파일 이미지
  factory WatermarkedImage.file(
    File file, {
    Key? key,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    String watermarkText = '사진동네',
    double opacity = 0.18,
    double paddingFactor = 2.5,
    double angleDeg = -45,
    bool antiAlias = true,
    BorderRadius? borderRadius,
  }) {
    return WatermarkedImage(
      key: key,
      watermarkText: watermarkText,
      opacity: opacity,
      paddingFactor: paddingFactor,
      angleDeg: angleDeg,
      antiAlias: antiAlias,
      borderRadius: borderRadius,
      child: Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = CustomPaint(
      foregroundPainter: _RepeatingTextWatermarkPainter(
        text: watermarkText,
        opacity: opacity,
        paddingFactor: paddingFactor,
        angleDeg: angleDeg,
        antiAlias: antiAlias,
      ),
      child: child,
    );

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}

class _RepeatingTextWatermarkPainter extends CustomPainter {
  final String text;
  final double opacity;
  final double paddingFactor;
  final double angleDeg;
  final bool antiAlias;

  _RepeatingTextWatermarkPainter({
    required this.text,
    required this.opacity,
    required this.paddingFactor,
    required this.angleDeg,
    required this.antiAlias,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // 1) 회전 좌표계 설정 (중심 기준)
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angleDeg * math.pi / 180);
    canvas.translate(-size.width / 2, -size.height / 2);

    // 2) 폰트 크기/간격 계산
    final shortest = math.min(size.width, size.height);
    final fontSize = shortest * 0.04;
    final clamped = fontSize.clamp(18.0, 64.0);

    final fillPainter = _spanPainter(
      text,
      color: Colors.white.withOpacity(opacity),
      fontSize: clamped.toDouble(),
      fontWeight: FontWeight.w700,
    );

    final strokePainter = _spanPainter(
      text,
      color: Colors.black.withOpacity((opacity - 0.06).clamp(0.0, 1.0)),
      fontSize: clamped.toDouble(),
      fontWeight: FontWeight.w700,
    );

    final stepX = fillPainter.width + clamped * paddingFactor;
    final stepY = fillPainter.height + clamped * paddingFactor;

    final diagonal =
        math.sqrt(size.width * size.width + size.height * size.height);

    for (double y = -diagonal; y < diagonal; y += stepY) {
      for (double x = -diagonal; x < diagonal; x += stepX) {
        final offset = Offset(x, y);
        // 살짝 어두운 외곽선 + 흰 글자
        strokePainter.paint(canvas, offset + const Offset(1, 1));
        fillPainter.paint(canvas, offset);
      }
    }

    canvas.restore();
  }

  TextPainter _spanPainter(
    String text, {
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  @override
  bool shouldRepaint(covariant _RepeatingTextWatermarkPainter old) {
    return text != old.text ||
        opacity != old.opacity ||
        paddingFactor != old.paddingFactor ||
        angleDeg != old.angleDeg ||
        antiAlias != old.antiAlias;
  }
}
