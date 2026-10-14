import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../core/config.dart';
import 'api_client.dart';

sealed class RealtimeMessage {}

class EventUpserted extends RealtimeMessage {
  EventUpserted(this.event, this.actorId);
  final Map<String, dynamic> event;
  final String? actorId;
}

class EventDeleted extends RealtimeMessage {
  EventDeleted(this.id, this.actorId);
  final String id;
  final String? actorId;
}

class GroupsChanged extends RealtimeMessage {}

class GroupRemoved extends RealtimeMessage {
  GroupRemoved(this.groupId);
  final String groupId;
}

/// (Re)connected — klient powinien dociągnąć zmiany, które przegapił.
class RealtimeReady extends RealtimeMessage {}

class RealtimeDisconnected extends RealtimeMessage {}

/// Połączenie WebSocket z serwerem (Socket.IO). Automatyczny reconnect + odświeżenie tokenu.
class RealtimeClient {
  RealtimeClient(this._api);

  final ApiClient _api;
  io.Socket? _socket;
  final _messages = StreamController<RealtimeMessage>.broadcast();
  bool _refreshingToken = false;

  Stream<RealtimeMessage> get messages => _messages.stream;
  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    disconnect();
    final token = _api.tokens.accessToken;
    if (token == null) return;

    final socket = io.io(
      AppConfig.apiUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(15000)
          .build(),
    );
    _socket = socket;

    Map<String, dynamic> asMap(dynamic data) => data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};

    socket
      ..on('ready', (_) => _messages.add(RealtimeReady()))
      ..on('event:upsert', (data) {
        final map = asMap(data);
        final event = map['event'];
        if (event is Map) _messages.add(EventUpserted(event.cast<String, dynamic>(), map['actorId'] as String?));
      })
      ..on('event:delete', (data) {
        final map = asMap(data);
        final id = map['id'];
        if (id is String) _messages.add(EventDeleted(id, map['actorId'] as String?));
      })
      ..on('groups:changed', (_) => _messages.add(GroupsChanged()))
      ..on('group:removed', (data) {
        final id = asMap(data)['groupId'];
        if (id is String) _messages.add(GroupRemoved(id));
      })
      ..onDisconnect((_) => _messages.add(RealtimeDisconnected()))
      ..onConnectError((error) => _handleConnectError(error));

    socket.connect();
  }

  /// Token wygasł → odśwież i połącz ponownie z nowym tokenem.
  Future<void> _handleConnectError(dynamic error) async {
    final message = error is Map ? error['message'] : error?.toString();
    if (_refreshingToken || message == null || !message.toString().contains('TOKEN')) return;
    _refreshingToken = true;
    try {
      await _api.refresh();
      connect();
    } catch (_) {
      // Brak sieci — Socket.IO ponowi próbę samodzielnie.
    } finally {
      _refreshingToken = false;
    }
  }

  void disconnect() {
    _socket
      ?..clearListeners()
      ..dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messages.close();
  }
}
