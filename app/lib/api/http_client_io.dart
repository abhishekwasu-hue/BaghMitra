import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Phone build: a client whose connection attempt gives up after [connectTimeout].
http.Client defaultHttpClient(Duration connectTimeout) =>
    IOClient(HttpClient()..connectionTimeout = connectTimeout);
