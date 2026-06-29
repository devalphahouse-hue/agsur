import '/flutter_flow/upload_data.dart';
import '../supabase.dart';

/// Sem teto de tamanho por padrão (`null` = não valida tamanho no cliente).
/// O limite real passa a ser o do backend: `file_size_limit` do bucket +
/// o teto global de upload do projeto (Studio → Storage → Settings).
/// Override por chamada via [maxBytes] se algum fluxo quiser um teto próprio
/// (ex.: o chat passa 20 MB explicitamente).
const int? _kDefaultMaxUploadBytes = null;

/// Whitelist de extensões aceitas, mapeadas para content-type.
/// Se a extensão não estiver aqui, o upload é rejeitado.
const Map<String, String> _kAllowedExtensions = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'csv': 'text/csv',
};

class StorageUploadException implements Exception {
  StorageUploadException(this.message);
  final String message;
  @override
  String toString() => 'StorageUploadException: $message';
}

String _inferContentType(String filename) {
  final ext = filename.toLowerCase().split('.').last;
  final type = _kAllowedExtensions[ext];
  if (type == null) {
    throw StorageUploadException(
      'Extensão "$ext" não permitida. Tipos aceitos: ${_kAllowedExtensions.keys.join(", ")}',
    );
  }
  return type;
}

void _validateUpload(SelectedFile file, {required int? maxBytes}) {
  if (maxBytes != null && file.bytes.lengthInBytes > maxBytes) {
    final mb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
    throw StorageUploadException('Arquivo excede o limite de ${mb}MB');
  }
  if (file.bytes.lengthInBytes == 0) {
    throw StorageUploadException('Arquivo vazio');
  }
}

Future<List<String>> uploadSupabaseStorageFiles({
  required String bucketName,
  required List<SelectedFile> selectedFiles,
  int? maxBytes = _kDefaultMaxUploadBytes,
}) =>
    Future.wait(
      selectedFiles.map(
        (media) => uploadSupabaseStorageFile(
          bucketName: bucketName,
          selectedFile: media,
          maxBytes: maxBytes,
        ),
      ),
    );

Future<String> uploadSupabaseStorageFile({
  required String bucketName,
  required SelectedFile selectedFile,
  int? maxBytes = _kDefaultMaxUploadBytes,
}) async {
  _validateUpload(selectedFile, maxBytes: maxBytes);
  final contentType = _inferContentType(selectedFile.storagePath);

  final storageBucket = SupaFlow.client.storage.from(bucketName);
  await storageBucket.uploadBinary(
    selectedFile.storagePath,
    selectedFile.bytes,
    fileOptions: FileOptions(contentType: contentType),
  );
  return storageBucket.getPublicUrl(selectedFile.storagePath);
}

Future deleteSupabaseFileFromPublicUrl(String publicUrl) async {
  final storagePath = SupaFlow.client.storage.pathFromPublicUrl(publicUrl);
  if (storagePath == null) {
    return;
  }

  final bucketName = storagePath.split('/').first;
  final filePath = storagePath.split('/').skip(1).join('/');
  await SupaFlow.client.storage.from(bucketName).remove([filePath]);
}

extension _SupabaseBucketExtensions on SupabaseStorageClient {
  String? pathFromPublicUrl(String publicUrl) {
    final publicUrlPrefix = '$url/object/public/';
    final urlParts = publicUrl.split(publicUrlPrefix);
    if (urlParts.length != 2) {
      return null;
    }
    final fullStoragePath = urlParts.last;
    final storagePathParts = fullStoragePath.split('/');
    if (storagePathParts.length <= 1) {
      return null;
    }
    return fullStoragePath;
  }
}
