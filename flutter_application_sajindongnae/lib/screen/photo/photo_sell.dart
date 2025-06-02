import 'package:flutter/material.dart';


class PhotoSellScreen extends StatefulWidget {
  const PhotoSellScreen({super.key});
  
  @override
  State<PhotoSellScreen> createState() => _PhotoSellScreenState();
} 

class _PhotoSellScreenState extends State<PhotoSellScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('사진 판매'),),
    );
  }
}