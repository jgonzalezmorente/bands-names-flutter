import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import 'package:bands_names/models/models.dart';
import 'package:bands_names/services/socket_service.dart';


class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}


class _HomeScreenState extends State<HomeScreen> {

  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>( context, listen: false );
    socketService.socket.on( 'active-bands', _handleActiveBands );
    super.initState();
  }

  _handleActiveBands( dynamic payload ) {
    bands = ( payload as List ).map( (band) => Band.fromMap(band) ).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>( context, listen: false );
    socketService.socket.off( 'active-bands' );
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final socketService = Provider.of<SocketService>( context );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BandNames', style: TextStyle( color: Colors.black87 )),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only( right: 10 ),
            child: ( socketService.serverStatus == ServerStatus.online ) 
              ? Icon( Icons.check_circle, color: Colors.blue[300] )
              : const Icon( Icons.offline_bolt, color: Colors.red ),
          )
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          Expanded(
            child: ListView.builder(
              itemCount: bands.length,
              itemBuilder: ( _, i) => _bandTile( bands[i] )
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        elevation: 1,
        onPressed: addNewBand,
      ),
    );
  }

  Dismissible _bandTile(Band band) {
    final socketService = Provider.of<SocketService>( context, listen: false );
    
    return Dismissible(
      key: Key(band.id!),
      direction: DismissDirection.startToEnd,
      onDismissed: ( _ ) => socketService.emit( 'delete-band', { 'id': band.id } ),      
      background: Container(
        padding: const EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle( color: Colors.white))
          )
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text( band.name!.substring(0,2)),
          backgroundColor: Colors.blue[100],        
        ),
        title: Text(band.name!),
        trailing: Text('${band.votes}', style: const TextStyle(fontSize: 20)),
        onTap: () => socketService.emit('vote-band', { 'id': band.id }),
      ),
    );
  }

  addNewBand() {

    final textController = TextEditingController();

    if (Platform.isAndroid) {
      showDialog(
        context: context, 
        builder: ( _ ) => AlertDialog(
          title: const Text('New band name:'),
          content: TextField(
            controller: textController,
          ),
          actions: [
            MaterialButton(
              child: const Text('Add'),
              elevation: 5,
              textColor: Colors.blue,
              onPressed: () => addBandToList( textController.text ),              
            )
          ],
        )
      );
      return;
    }

    showCupertinoDialog(
      context: context, 
      builder: ( _ ) => CupertinoAlertDialog(
        title: const Text('New band name:'),
        content: CupertinoTextField(
          controller: textController,
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () => addBandToList( textController.text ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,              
            child: const Text('Dismiss'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      )      
    );
    

  }

  void addBandToList( String name ) {

    if (name.length > 1) {
      final socketService = Provider.of<SocketService>( context, listen: false );
      socketService.emit( 'add-band', { 'name': name } );
    }

    Navigator.pop(context);

  }

  Widget _showGraph() {

    if (bands.isEmpty) {
      return const SizedBox();
    }
    
    Map<String, double> dataMap = { for( final band in bands ) band.name! : band.votes!.toDouble() };

    final List<Color> colorList = [
      Colors.blue[50]!,
      Colors.blue[200]!,
      Colors.pink[50]!,
      Colors.pink[200]!,
      Colors.yellow[50]!,
      Colors.yellow[200]!,
    ];

    return Container(
      padding: const EdgeInsets.only( left: 15, top: 10 ),
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        animationDuration: const Duration(milliseconds: 800),        
        //chartRadius: MediaQuery.of(context).size.width / 2.7,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 32,        
        legendOptions: const LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
          ),
      ),
      chartValuesOptions: const ChartValuesOptions(
        showChartValueBackground: true,
        showChartValues: true,
        showChartValuesInPercentage: false,
        showChartValuesOutside: false,
        decimalPlaces: 0,        
      ),
    )
    );
  }

}