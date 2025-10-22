// lib/widgets/watermarked_image.dart
// 각주: 어떤 ImageProvider든 화면에 그릴 때 대각선 반복 텍스트 워터마크를 오버레이로 얹어준다.
//      실제 파일은 변형하지 않으며, 리스트/상세/홈 등 어디든 재사용 가능.

import 'dart:math' as math;
import 'package:flutter/material.dart';

class WatermarkedImage extends StatelessWidget {
  final ImageProvider image;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  // 워터마크 옵션
  final String watermarkText;
  final double opacity;        // 각주: 텍스트 투명도 (0.0 ~ 1.0)
  final double paddingFactor;  // 각주: 텍스트 간격 스케일
  final double angleDeg;       // 각주: 회전 각도 (deg). 음수면 ↘ 방향
  final bool antiAlias;        // 각주: 페인팅 안티알리어싱

  const WatermarkedImage({
    super.key,
    required this.image,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,

    // 워터마크 기본값
    this.watermarkText = '사진동네',
    this.opacity = 0.18,
    this.paddingFactor = 2.5,
    this.angleDeg = -45,
    this.antiAlias = true,
  });

  /// 자주 쓰는 에셋/파일/네트워크 헬퍼들
  factory WatermarkedImage.asset(
      String assetName, {
        Key? key,
        BoxFit fit = BoxFit.cover,
        double? width,
        double? height,
        BorderRadius? borderRadius,
        String watermarkText = '사진동네',
        double opacity = 0.18,
        double paddingFactor = 2.5,
        double angleDeg = -45,
        bool antiAlias = true,
      }) {
    return WatermarkedImage(
      key: key,
      image: AssetImage(assetName),
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
      watermarkText: watermarkText,
      opacity: opacity,
      paddingFactor: paddingFactor,
      angleDeg: angleDeg,
      antiAlias: antiAlias,
    );
  }

  factory WatermarkedImage.network(
      String url, {
        Key? key,
        BoxFit fit = BoxFit.cover,
        double? width,
        double? height,
        BorderRadius? borderRadius,
        String watermarkText = '사진동네',
        double opacity = 0.18,
        double paddingFactor = 2.5,
        double angleDeg = -45,
        bool antiAlias = true,
      }) {
    return WatermarkedImage(
      key: key,
      image: NetworkImage(url),
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
      watermarkText: watermarkText,
      opacity: opacity,
      paddingFactor: paddingFactor,
      angleDeg: angleDeg,
      antiAlias: antiAlias,
    );
  }

  factory WatermarkedImage.file(
      FileImage fileImage, {
        Key? key,
        BoxFit fit = BoxFit.cover,
        double? width,
        double? height,
        BorderRadius? borderRadius,
        String watermarkText = '사진동네',
        double opacity = 0.18,
        double paddingFactor = 2.5,
        double angleDeg = -45,
        bool antiAlias = true,
      }) {
    return WatermarkedImage(
      key: key,
      image: fileImage,
      fit: fit,
      width: width,
      height: height,
      borderRadius: borderRadius,
      watermarkText: watermarkText,
      opacity: opacity,
      paddingFactor: paddingFactor,
      angleDeg: angleDeg,
      antiAlias: antiAlias,
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = Image(
      image: image,
      fit: fit,
      width: width,
      height: height,
      // 각주: 이미지 로딩 중 레이아웃 흔들림 방지용
      gaplessPlayback: true,
    );

    final content = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: img),
        // 각주: 포인터 이벤트는 차단(아래 이미지로 전달)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RepeatingTextWatermarkPainter(
                text: watermarkText,
                opacity: opacity,
                paddingFactor: paddingFactor,
                angleDeg: angleDeg,
                antiAlias: antiAlias,
              ),
            ),
          ),
        ),
      ],
    );

    if (borderRadius != null) {
      return ClipRRect(
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
    final fontSize = shortest * 0.04; // 각주: 화면 크기 비례
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

    // 3) 대각선 전체 채우기
    //   회전된 상태이므로 실제로는 화면 바깥까지 반복해 빈 곳 없게
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    for (double y = -diagonal; y < diagonal; y += stepY) {
      for (double x = -diagonal; x < diagonal; x += stepX) {
        final offset = Offset(x, y);
        // 의사 외곽선(가독성↑)
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
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  @override
  bool shouldRepaint(covariant _RepeatingTextWatermarkPainter old) {
    // 각주: 옵션 값이 바뀌면 리페인트
    return text != old.text ||
        opacity != old.opacity ||
        paddingFactor != old.paddingFactor ||
        angleDeg != old.angleDeg ||
        antiAlias != old.antiAlias;
  }
}
