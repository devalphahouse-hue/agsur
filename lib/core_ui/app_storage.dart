import 'package:flutter/material.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart' show launchURL;

/// Acesso a arquivos do Supabase Storage com **signed URLs**.
///
/// Hoje os buckets `AGSur`/`service-letters` são públicos e o app guarda URLs
/// públicas (`.../object/public/<bucket>/<path>`). Para tornar os buckets
/// privados sem quebrar nada, troque as leituras por estes utilitários: eles
/// assinam a URL na hora. **Fallback-safe**: se não der pra assinar (bucket
/// ainda público, erro de rede, URL externa), devolvem a URL original — então
/// é seguro adotar ANTES de privar o bucket.
///
/// Roteiro: (1) trocar as leituras por `signedUrlFor` / `SignedNetworkImage` /
/// `openStorageDoc`; (2) testar exibição nos dois apps; (3) só então
/// `update storage.buckets set public=false`.

/// Extrai (bucket, path) de uma URL pública do Supabase Storage. Retorna null
/// se não for uma URL pública reconhecível.
({String bucket, String path})? parseStoragePublicUrl(String url) {
  const marker = '/storage/v1/object/public/';
  final i = url.indexOf(marker);
  if (i < 0) return null;
  var rest = url.substring(i + marker.length);
  final q = rest.indexOf('?');
  if (q >= 0) rest = rest.substring(0, q);
  final slash = rest.indexOf('/');
  if (slash <= 0 || slash >= rest.length - 1) return null;
  final bucket = Uri.decodeComponent(rest.substring(0, slash));
  final path = rest.substring(slash + 1);
  return (bucket: bucket, path: path);
}

/// Assina uma URL pública do Storage. Devolve a própria URL se não der pra
/// assinar (mantém o comportamento atual com bucket público).
Future<String> signedUrlFor(String url, {int expiresInSeconds = 3600}) async {
  if (url.isEmpty) return url;
  final parsed = parseStoragePublicUrl(url);
  if (parsed == null) return url; // URL externa ou já não-pública
  try {
    return await SupaFlow.client.storage
        .from(parsed.bucket)
        .createSignedUrl(parsed.path, expiresInSeconds);
  } catch (_) {
    return url; // fallback: não quebra a leitura
  }
}

/// Abre um documento do Storage em nova aba/visualizador, assinando a URL.
Future<void> openStorageDoc(String url, {int expiresInSeconds = 3600}) async {
  final signed = await signedUrlFor(url, expiresInSeconds: expiresInSeconds);
  await launchURL(signed);
}

/// Drop-in para `Image.network(publicUrl)` que assina a URL antes de carregar.
/// Use os mesmos parâmetros visuais (fit, width, height, errorBuilder).
class SignedNetworkImage extends StatefulWidget {
  const SignedNetworkImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.expiresInSeconds = 3600,
  });

  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final int expiresInSeconds;

  @override
  State<SignedNetworkImage> createState() => _SignedNetworkImageState();
}

class _SignedNetworkImageState extends State<SignedNetworkImage> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = signedUrlFor(widget.url, expiresInSeconds: widget.expiresInSeconds);
  }

  @override
  void didUpdateWidget(covariant SignedNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _future =
          signedUrlFor(widget.url, expiresInSeconds: widget.expiresInSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return widget.loadingBuilder?.call(context) ??
              SizedBox(
                width: widget.width,
                height: widget.height,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFC2D51C)),
                  ),
                ),
              );
        }
        return Image.network(
          snap.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: widget.errorBuilder,
        );
      },
    );
  }
}
