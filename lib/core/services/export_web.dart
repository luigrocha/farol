import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void downloadOnWeb(List<int> bytes, String filename, String mimeType) {
  final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final jsBytes = [uint8List.toJS].toJS;
  final blob = web.Blob(jsBytes, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..setAttribute('download', filename)
    ..click();
  
  // Optional: delay revocation to ensure browser started the download
  web.window.setTimeout(() {
    web.URL.revokeObjectURL(url);
    anchor.remove();
  }.toJS, 0.toJS);
}

