import 'package:flutter/material.dart';

class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Widget? preloader;

  const LazyIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.preloader,
  }) : super(key: key);

  @override
  _LazyIndexedStackState createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _loaded;

  @override
  void initState() {
    super.initState();
    _loaded = List<bool>.filled(widget.children.length, false);
    if (widget.index >= 0 && widget.index < widget.children.length) {
      _loaded[widget.index] = true;
    }
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (widget.index >= 0 && widget.index < widget.children.length) {
        _loaded[widget.index] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.children.length, (i) {
        if (_loaded[i]) {
          return widget.children[i];
        } else {
          return widget.preloader ?? const SizedBox.shrink();
        }
      }),
    );
  }
}
