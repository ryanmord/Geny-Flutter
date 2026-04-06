import 'dart:io';

class PlatformUtils {
  /// Finds the Node.js binary path, searching common locations.
  static Future<String?> findNodePath() async {
    if (Platform.isMacOS) {
      return _findNodeMacOS();
    } else if (Platform.isWindows) {
      return _findNodeWindows();
    }
    return null;
  }

  static Future<String?> _findNodeMacOS() async {
    // Check NVM first (highest version)
    final nvmDir = Directory('${Platform.environment['HOME']}/.nvm/versions/node');
    if (nvmDir.existsSync()) {
      final versions = nvmDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split('/').last)
          .where((v) => v.startsWith('v'))
          .toList()
        ..sort(_compareVersions);
      if (versions.isNotEmpty) {
        final path = '${nvmDir.path}/${versions.last}/bin/node';
        if (File(path).existsSync()) return path;
      }
    }

    // Check common paths
    for (final path in [
      '/usr/local/bin/node',
      '/opt/homebrew/bin/node',
      '/usr/bin/node',
    ]) {
      if (File(path).existsSync()) return path;
    }

    // Try PATH
    return _findInPath('node');
  }

  static Future<String?> _findNodeWindows() async {
    // Check NVM for Windows
    final appdata = Platform.environment['APPDATA'];
    if (appdata != null) {
      final nvmDir = Directory('$appdata\\nvm');
      if (nvmDir.existsSync()) {
        final versions = nvmDir
            .listSync()
            .whereType<Directory>()
            .map((d) => d.path.split('\\').last)
            .where((v) => v.startsWith('v'))
            .toList()
          ..sort(_compareVersions);
        if (versions.isNotEmpty) {
          final path = '${nvmDir.path}\\${versions.last}\\node.exe';
          if (File(path).existsSync()) return path;
        }
      }
    }

    // Check Program Files
    final programFiles = Platform.environment['ProgramFiles'];
    if (programFiles != null) {
      final path = '$programFiles\\nodejs\\node.exe';
      if (File(path).existsSync()) return path;
    }

    // Try PATH
    return _findInPath('node');
  }

  static Future<String?> _findInPath(String executable) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [executable],
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim().split('\n').first;
      }
    } catch (_) {
      // Command not found
    }
    return null;
  }

  /// Given a node path, derive the npx path.
  static String npxPath(String nodePath) {
    final dir = nodePath.substring(0, nodePath.lastIndexOf(Platform.pathSeparator));
    final ext = Platform.isWindows ? '.cmd' : '';
    return '$dir${Platform.pathSeparator}npx$ext';
  }

  /// Find the backend directory path.
  static Future<String?> findBackendPath() async {
    // Production: bundled alongside the executable
    final execDir = File(Platform.resolvedExecutable).parent.path;

    if (Platform.isMacOS) {
      // In .app bundle: Contents/MacOS/geny_flutter -> Contents/Resources/backend
      final bundledPath =
          '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/backend';
      if (Directory(bundledPath).existsSync()) return bundledPath;
    } else if (Platform.isWindows) {
      // Adjacent to executable
      final bundledPath = '$execDir\\backend';
      if (Directory(bundledPath).existsSync()) return bundledPath;
    }

    // Development: look for backend relative to project
    // Walk up from the executable to find the Geny project
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

    final devPaths = [
      '$home/Developer/Geny/backend',
      '$home/developer/Geny/backend',
      '$home/Projects/Geny/backend',
    ];

    for (final path in devPaths) {
      if (Directory(path).existsSync()) return path;
    }

    return null;
  }

  static int _compareVersions(String a, String b) {
    final aParts = a.replaceFirst('v', '').split('.').map(int.tryParse).toList();
    final bParts = b.replaceFirst('v', '').split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final av = i < aParts.length ? (aParts[i] ?? 0) : 0;
      final bv = i < bParts.length ? (bParts[i] ?? 0) : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}
