import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Carrega imagens de `assets/` via DefaultAssetBundle.load + Image.memory.
///
/// Substitui Image.asset porque Image.asset falha silenciosamente em produção
/// no nosso build do Flutter web (não dispara errorBuilder e nem loga; o
/// AssetImage entra em algum estado quebrado). rootBundle.load funciona,
/// então pegamos os bytes manualmente e usamos Image.memory.
class AppAssetImage extends StatefulWidget {
  const AppAssetImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  State<AppAssetImage> createState() => _AppAssetImageState();
}

class _AppAssetImageState extends State<AppAssetImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await DefaultAssetBundle.of(context).load(widget.path);
      if (!mounted) return;
      setState(() => _bytes = data.buffer.asUint8List());
    } catch (e) {
      debugPrint('[AppAssetImage] load err ${widget.path}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    return Image.memory(
      _bytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
    );
  }
}
