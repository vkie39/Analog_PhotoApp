import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/photo_trade_model.dart';
import 'package:flutter_application_sajindongnae/screen/photo/sell_detail.dart';

class PhotoTradeCard extends StatelessWidget {
  final PhotoTradeModel trade;
  final bool small; // 마이페이지용으로 살짝 작게 쓸 때

  const PhotoTradeCard({
    super.key,
    required this.trade,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = small;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellDetailScreen(photo: trade),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              trade.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "₩${trade.price}",
              style: TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
