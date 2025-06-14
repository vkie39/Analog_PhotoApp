import 'dart:math';
import 'package:flutter/material.dart';

const Duration _duration = Duration(milliseconds: 300);

class ExpandableFab extends StatefulWidget {
  final double distance;
  final List<Widget> children;

  const ExpandableFab({
    Key? key,
    required this.distance,
    required this.children,
  }) : super(key: key);

  @override
  _ExpandableFabState createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0.0,
      duration: _duration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ..._buildExpandableActionButtons(),
          _buildMainFab(),
        ],
      ),
    );
  }

  Widget _buildMainFab() {
    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: _open ? Colors.white : const Color(0xFFDDECC7),
      elevation: 3,
      splashColor: Colors.transparent,
      onPressed: toggle,
      child: AnimatedSwitcher(
        duration: _duration,
        child: _open
            ? Icon(Icons.close, key: const ValueKey('close'), color: const Color(0xFFDDECC7))
            : Icon(Icons.add, key: const ValueKey('add'), color: const Color.fromARGB(255, 26, 25, 25)),
      ),
    );
  }

  List<Widget> _buildExpandableActionButtons() {
    final count = widget.children.length;
    final double startAngle = 5; // 오른쪽
    final double endAngle = 90; // 위쪽

    return List.generate(count, (i) {
      final double angle = startAngle + (endAngle - startAngle) * (i / (count - 1));
      return _ExpandableActionButton(
        distance: widget.distance,
        degree: angle,
        progress: _expandAnimation,
        child: widget.children[i],
      );
    });
  }
}

class _ExpandableActionButton extends StatelessWidget {
  final double distance;
  final double degree;
  final Animation<double> progress;
  final Widget child;

  const _ExpandableActionButton({
    Key? key,
    required this.distance,
    required this.degree,
    required this.progress,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final Offset offset = Offset.fromDirection(
          degree * (pi / 180),
          progress.value * distance,
        );
        return Positioned(
          right: offset.dx + 4,
          bottom: offset.dy + 4,
          child: child!,
        );
      },
      child: child,
    );
  }
}
