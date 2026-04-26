import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadOnWeb(List<int> bytes, String filename, String mimeType) {
  final jsBytes = bytes.map((b) => b.toJS).toList().toJS;
  final blob = web.Blob(jsBytes, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..setAttribute('download', filename)
    ..click();
  web.URL.revokeObjectURL(url);
  anchor.remove();
}
