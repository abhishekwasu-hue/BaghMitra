import 'dart:io';

/// A small on-device log the grower can send from Settings. Keeps the newest [maxBytes] only.
abstract interface class AppLog {
  void log(String message);
  Future<String> read();
}

class MemoryAppLog implements AppLog {
  final lines = <String>[];

  @override
  void log(String message) => lines.add(message);

  @override
  Future<String> read() async => lines.join('\n');
}

class FileAppLog implements AppLog {
  FileAppLog(this._file, {this.maxBytes = 256 * 1024, DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final File _file;
  final int maxBytes;
  final DateTime Function() _now;

  @override
  void log(String message) {
    try {
      _file.parent.createSync(recursive: true);
      _file.writeAsStringSync(
        '${_now().toIso8601String()} $message\n',
        mode: FileMode.append,
        flush: true,
      );
      _trim();
    } on FileSystemException {
      // Logging must never break the app.
    }
  }

  void _trim() {
    if (_file.lengthSync() <= maxBytes) return;
    final text = _file.readAsStringSync();
    final tail = text.substring(text.length - maxBytes ~/ 2);
    _file.writeAsStringSync(tail.substring(tail.indexOf('\n') + 1));
  }

  @override
  Future<String> read() async => _file.existsSync() ? _file.readAsString() : '';
}
