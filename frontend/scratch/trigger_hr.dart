import 'dart:convert';
import 'dart:io';

void main() async {
  final wsUrl = 'ws://127.0.0.1:61310/DEhLnEaCOes=/ws';
  print('Connecting to $wsUrl ...');
  try {
    final ws = await WebSocket.connect(wsUrl).timeout(Duration(seconds: 2));
    print('Connected!');
    
    // Get VM first to see isolates
    ws.add(jsonEncode({
      'jsonrpc': '2.0',
      'method': 'getVM',
      'id': 'getVM',
    }));
    
    await for (final message in ws) {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final id = data['id'];
      if (id == 'getVM') {
        final result = data['result'] as Map<String, dynamic>;
        final isolates = result['isolates'] as List<dynamic>? ?? [];
        if (isolates.isEmpty) {
          print('No isolates found!');
          exit(1);
        }
        final isolateId = isolates.first['id'] as String;
        print('Found isolate: $isolateId. Triggering ext.flutter.reassemble...');
        ws.add(jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ext.flutter.reassemble',
          'params': {'isolateId': isolateId},
          'id': 'reassemble',
        }));
      } else if (id == 'reassemble') {
        print('Reassemble response: $data');
        if (data.containsKey('error')) {
          print('Error: ${data['error']}');
          exit(1);
        } else {
          print('HOT RESTART / REASSEMBLE SUCCESSFUL!');
          exit(0);
        }
      }
    }
  } catch (e) {
    print('Failed: $e');
    exit(1);
  }
}
