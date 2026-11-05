import 'package:http/http.dart' as http;

/// Web (admin) build: the browser owns connection handling, so a plain client is used and
/// only the answer timeout ([ApiTimeouts.receive]) applies.
http.Client defaultHttpClient(Duration connectTimeout) => http.Client();
