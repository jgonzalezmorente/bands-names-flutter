
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;


enum ServerStatus {
  online,
  offline,
  connecting
}

class SocketService with ChangeNotifier {

  ServerStatus _serverStatus = ServerStatus.connecting;
  late io.Socket _socket;

  ServerStatus get serverStatus => _serverStatus;
  
  io.Socket get socket => _socket;
  Function get emit => _socket.emit;

  SocketService() {
    _initConfig();
  }

  void _initConfig() {
    _socket = io.io( 'http://10.0.2.2:3000/', 
      io.OptionBuilder()
        .setTransports(['websocket'])
        .enableAutoConnect()
        .build()
    );

    _socket.onConnect((_) {
      _serverStatus = ServerStatus.online;
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      _serverStatus = ServerStatus.offline;
      notifyListeners();
    });

    // socket.on('nuevo-mensaje', ( payload ) {
    //   print( 'nuevo-mensaje:' );
    //   print( 'nombre:' + payload['nombre']);
    //   print( payload.containsKey('mensaje2') ? payload['mensaje2'] : 'no hay');
    // });
  }

}