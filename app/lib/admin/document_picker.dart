import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Same cap as the server (`MAX_DOCUMENT_BYTES` in api feed/gr_portal.py, 20 MiB); larger
/// uploads are refused there with 413, so they are refused here before encoding.
const maxDocumentBytes = 20 * 1024 * 1024;

const documentExtensions = ['pdf', 'html', 'htm'];

/// A picked GR document: its name, bytes and the API `document_type` (`pdf` | `html`).
class PickedDocument {
  const PickedDocument(this.name, this.bytes);
  final String name;
  final Uint8List bytes;

  String get type => name.toLowerCase().endsWith('.pdf') ? 'pdf' : 'html';
}

class DocumentTooLarge implements Exception {
  const DocumentTooLarge();
}

class DocumentTypeNotAllowed implements Exception {
  const DocumentTypeNotAllowed();
}

/// Lets the reviewer choose one PDF / HTML file; null when cancelled. Throws
/// [DocumentTooLarge] or [DocumentTypeNotAllowed].
abstract interface class DocumentPicker {
  Future<PickedDocument?> pick();
}

/// `file_picker` adapter (web and desktop); the flow is covered by tests with a fake.
class FilePickerDocuments implements DocumentPicker {
  const FilePickerDocuments();

  @override
  Future<PickedDocument?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: documentExtensions,
    );
    if (file == null) return null;
    if (!documentExtensions.contains(file.extension?.toLowerCase())) {
      throw const DocumentTypeNotAllowed();
    }
    if ((file.lengthSync() ?? 0) > maxDocumentBytes) {
      throw const DocumentTooLarge();
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxDocumentBytes) throw const DocumentTooLarge();
    return PickedDocument(file.name, bytes);
  }
}
