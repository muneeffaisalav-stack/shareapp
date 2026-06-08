import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ServerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class ServerProvider with ChangeNotifier {
  HttpServer? _server;
  String? _ipAddress;
  final int _port = 8080;
  List<File> _files = [];
  String? _errorMessage;

  bool get isRunning => _server != null;
  String? get ipAddress => _ipAddress;
  int get port => _port;
  List<File> get files => _files;
  String? get errorMessage => _errorMessage;

  Future<void> pickFiles() async {
    FilePickerResult? result = await FilePicker.pickFiles(allowMultiple: true);

    if (result != null) {
      _files.addAll(
        result.files.where((f) => f.path != null).map((f) => File(f.path!)),
      );
      notifyListeners();
    }
  }

  void clearFiles() {
    _files = [];
    notifyListeners();
  }

  Future<String?> _getIpAddress() async {
    for (var interface in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    )) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return null;
  }

  Future<void> startServer() async {
    if (isRunning) return;

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _errorMessage =
          "You're not connected to any network. Please connect to a Wi-Fi or hotspot to share files.";
      notifyListeners();
      return;
    }

    try {
      _ipAddress = await _getIpAddress();
      if (_ipAddress == null) {
        _errorMessage =
            "Could not get IP address. Make sure you're connected to a Wi-Fi or hotspot.";
        notifyListeners();
        return;
      }

      final router = shelf_router.Router();

      // router.get('/', (shelf.Request request) {
      //   String fileList = _files
      //       .map(
      //         (file) =>
      //             '<li><a href="/download/${_files.indexOf(file)}">${file.path.split('/').last}</a></li>',
      //       )
      //       .join('\n');
      //   return shelf.Response.ok(
      //     '<h1>Available Files:</h1><ul>$fileList</ul>',
      //     headers: {'Content-Type': 'text/html'},
      //   );
      // });
        router.get('/', (shelf.Request request) async {
    String fileCards = '';

    for (int i = 0; i < _files.length; i++) {
      final file = _files[i];
      final sizeKB = (await file.length()) / 1024;

      fileCards += '''
        <div class="file-card">
          <div class="file-info">
            <div class="file-icon">📄</div>
            <div>
              <div class="file-name">${file.path.split('/').last}</div>
              <div class="file-size">${sizeKB.toStringAsFixed(2)} KB</div>
            </div>
          </div>

          <a class="download-btn" href="/download/$i">
            Download
          </a>
        </div>
      ''';
    }

    return shelf.Response.ok(
      '''
  <!DOCTYPE html>
  <html>
  <head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <title>HotShare</title>

  <style>

  *{
    margin:0;
    padding:0;
    box-sizing:border-box;
  }

  body{
    font-family: Inter, Segoe UI, sans-serif;
    background: linear-gradient(
      135deg,
      #0f172a,
      #1e293b
    );
    min-height:100vh;
    color:white;
  }

  .container{
    max-width:900px;
    margin:auto;
    padding:40px 20px;
  }

  .header{
    text-align:center;
    margin-bottom:40px;
  }

  .logo{
    font-size:60px;
  }

  .title{
    font-size:36px;
    font-weight:700;
    margin-top:12px;
  }

  .subtitle{
    opacity:.7;
    margin-top:8px;
  }

  .files{
    display:flex;
    flex-direction:column;
    gap:16px;
  }

  .file-card{
    background:rgba(255,255,255,.08);
    backdrop-filter: blur(16px);
    border:1px solid rgba(255,255,255,.1);
    border-radius:20px;
    padding:20px;
    display:flex;
    justify-content:space-between;
    align-items:center;
    transition:.25s;
  }

  .file-card:hover{
    transform:translateY(-3px);
    background:rgba(255,255,255,.12);
  }

  .file-info{
    display:flex;
    align-items:center;
    gap:16px;
  }

  .file-icon{
    font-size:32px;
  }

  .file-name{
    font-size:18px;
    font-weight:600;
    word-break:break-all;
  }

  .file-size{
    margin-top:6px;
    opacity:.7;
    font-size:14px;
  }

  .download-btn{
    text-decoration:none;
    color:white;
    background:#6366f1;
    padding:12px 24px;
    border-radius:12px;
    font-weight:600;
    transition:.2s;
  }

  .download-btn:hover{
    background:#4f46e5;
  }

  .empty{
    text-align:center;
    padding:80px 20px;
    opacity:.7;
  }

  @media(max-width:700px){

    .file-card{
      flex-direction:column;
      gap:20px;
      align-items:flex-start;
    }

    .download-btn{
      width:100%;
      text-align:center;
    }

  }

  </style>
  </head>

  <body>

  <div class="container">

    <div class="header">
        <div class="logo">🚀</div>
        <div class="title">HotShare</div>
        <div class="subtitle">
          Fast local file sharing
        </div>
    </div>

    <div class="files">
      ${fileCards.isEmpty
          ? '<div class="empty">No files available</div>'
          : fileCards}
    </div>

  </div>

  </body>
  </html>
  ''',
      headers: {'Content-Type': 'text/html'},
    );
  });

      router.get('/download/<index>', (shelf.Request request, String index) {
        final int fileIndex = int.parse(index);
        if (fileIndex >= 0 && fileIndex < _files.length) {
          final file = _files[fileIndex];
          final fileStream = file.openRead();
          final headers = {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition':
                'attachment; filename="${file.path.split('/').last}"',
          };
          return shelf.Response.ok(fileStream, headers: headers);
        }
        return shelf.Response.notFound('File not found');
      });

      final handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .addHandler(router.call);
      _server = await io.serve(handler, '0.0.0.0', _port);
      _errorMessage = null; // Clear error on success
      notifyListeners();
    } catch (e, s) {
      _errorMessage = "Failed to start the server. Please try again.";
      developer.log('Error starting server', error: e, stackTrace: s);
      notifyListeners();
    }
  }

  void stopServer() {
    if (_server != null) {
      _server!.close();
      _server = null;
      _ipAddress = null;
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Colors.deepPurple;

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 57,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: appTextTheme,
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: appTextTheme,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'HotShare',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final serverProvider = Provider.of<ServerProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    String url = serverProvider.isRunning && serverProvider.ipAddress != null
        ? 'http://${serverProvider.ipAddress}:${serverProvider.port}'
        : 'Server not running';

    return Scaffold(
      appBar: AppBar(
        title: const Text('HotShare'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (serverProvider.isRunning) ...[
              Text(
                'Scan QR Code to Connect',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.1).round()),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 220.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Or enter this URL in your browser:',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SelectableText(
                url,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ] else if (serverProvider.errorMessage != null) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 100,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        serverProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: serverProvider.startServer,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
  child: serverProvider.files.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_to_photos,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Add files to share',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        )
      : Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Files (${serverProvider.files.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: serverProvider.clearFiles,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: serverProvider.files.length,
                itemBuilder: (context, index) {
                  final file = serverProvider.files[index];

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.path.split('/').last),
                      subtitle: FutureBuilder<int>(
                        future: file.length(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              '${(snapshot.data! / 1024).toStringAsFixed(2)} KB',
                            );
                          }
                          return const Text('...');
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!serverProvider.isRunning)
            FloatingActionButton.extended(
              heroTag: 'add_files',
              onPressed: serverProvider.pickFiles,
              label: const Text('Add Files'),
              icon: const Icon(Icons.add),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'start_stop_server',
            onPressed: () {
              if (serverProvider.isRunning) {
                serverProvider.stopServer();
              } else {
                serverProvider.startServer();
              }
            },
            label: Text(
              serverProvider.isRunning ? 'Stop Server' : 'Start Server',
            ),
            icon: Icon(
              serverProvider.isRunning ? Icons.stop : Icons.play_arrow,
            ),
          ),
        ],
      ),
    );
  }
}
