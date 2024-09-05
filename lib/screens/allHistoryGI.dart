import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:test/class/ListAllHistoryGI.dart';
import 'package:test/class/SelectDODetail.dart';
import 'package:test/screens/allHistoryGI.dart';

class AllHistoryGI extends StatefulWidget {
  @override
  _AllHistoryGIState createState() => _AllHistoryGIState();
}

class _AllHistoryGIState extends State<AllHistoryGI> {
  List<ListAllHistoryGI> list = [];
  String configs = '';
  String accessToken = "";
  String dono = "";
  String plandate = "";
  late Timer timer;

  TextEditingController documentNumberController = TextEditingController();

  bool documentNumberVisible = true;
  bool documentNumberReadonly = true;
  Color documentNumberColor = Color(0xFFEEEEEE);
  String documentNumberInput = '';

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  Future<void> getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      configs = prefs.getString('configs');
      accessToken = prefs.getString('token');
      dono = prefs.getString('donoAllHistoryGI');
      plandate = prefs.getString('plandateAllHistoryGI');
    });

    await onload();
  }

  void showErrorDialog(String error) {
    //MyWidget.showMyAlertDialog(context, "Error", error);
    alertDialog(error, 'Error');
  }

  void showSuccessDialog(String success) {
    //MyWidget.showMyAlertDialog(context, "Success", success);
    alertDialog(success, 'Success');
  }

  void alertDialog(String msg, String type) {
    Icon icon = Icon(Icons.info_outline, color: Colors.lightBlue);
    switch (type) {
      case "Success":
        icon = Icon(Icons.check_circle_outline, color: Colors.lightGreen);
        break;
      case "Error":
        icon = Icon(Icons.error_outline, color: Colors.redAccent);
        break;
      case "Warning":
        icon = Icon(Icons.warning_amber_outlined, color: Colors.orangeAccent);
        break;
      case "Infomation":
        icon = Icon(Icons.info_outline, color: Colors.lightBlue);
        break;
    }

    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          timer = Timer(Duration(seconds: 5), () {
            Navigator.of(context, rootNavigator: true).pop();
          });

          return AlertDialog(
            title: Row(children: [icon, Text(" " + type)]),
            content: Text(msg),
          );
        }).then((val) {
      if (timer.isActive) {
        timer.cancel();
      }
    });
  }

  Future<void> showProgressLoading(bool finish) async {
    ProgressDialog pr = ProgressDialog(context);
    pr = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true, showLogs: true);
    pr.style(
        progress: 50.0,
        message: "Please wait...",
        progressWidget: Container(
            padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    if (finish == false) {
      await pr.show();
    } else {
      await pr.hide();
    }
  }

  Future<void> onload() async {
    await showProgressLoading(false);
    setState(() {
      documentNumberController.text = dono;
    });

    try {
      var url = Uri.parse('http://' +
          configs +
          '/api/LoadTracking/SelectLTLoadedHistByDONoPlandateList/' +
          dono +
          '/' +
          plandate +
          '/0');

      var headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": "Bearer " + accessToken
      };

      http.Response response = await http.get(url, headers: headers);
      var data = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          list = (json.decode(response.body) as List)
              .map((data) => ListAllHistoryGI.fromJson(data))
              .toList();
        });
        await showProgressLoading(true);
      } else {
        await showProgressLoading(true);
        showErrorDialog('ไม่พบข้อมูลสินค้า');
      }
    } catch (e) {
      await showProgressLoading(true);
      showErrorDialog('Error occured while History');
    }
  }

  DataTable _createDataTable() {
    return DataTable(
        headingRowColor: MaterialStateColor.resolveWith(
          (states) => Colors.grey[200]!,
        ),
        columnSpacing: 5,
        //border: TableBorder.all(width: 1),
        columns: _createColumns(),
        rows: _createRows());
  }

  List<DataColumn> _createColumns() {
    return [
       DataColumn(
          label: Expanded(
              child: (Text('Mat',
                  softWrap: true,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black))))),
      DataColumn(
          label: Expanded(
              child: (Text('Lot',
                  softWrap: true,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black))))),
      DataColumn(
          label: Expanded(
              child: Text('Pallet NO',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)))),
      DataColumn(
          label: Expanded(
              child: Text('Qty',
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)))),
    ];
  }

  List<DataRow> _createRows() {
    return list
        .map((list) => DataRow(
                // color: MaterialStateColor.resolveWith((states) {
                //   return int.parse(list.id!) % 2 != 0
                //       ? Colors.transparent
                //       : Colors.grey[200]!; //make tha magic!
                // }),
                cells: [
                  DataCell(Container(
                      width: 70, //SET width
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            list.matno.toString(),
                            textAlign: TextAlign.start,
                          )))),
                  DataCell(Container(
                      width: 70, //SET width
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            list.batch.toString(),
                            textAlign: TextAlign.start,
                          )))),
                  DataCell(Container(
                      width: 70, //SET width
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            list.palletno.toString(),
                            textAlign: TextAlign.start,
                          )))),
                  DataCell(Container(
                      width: 70, //SET width
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            list.quantity.toString(),
                            textAlign: TextAlign.start,
                          )))),
                ]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 50,
          leading: BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          title: Text(
            'AllHistory',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(children: [
              SizedBox(height: 25),
              Container(
                  padding: new EdgeInsets.only(
                      left: MediaQuery.of(context).size.width / 5,
                      right: MediaQuery.of(context).size.width / 5),
                  child: Visibility(
                      visible: documentNumberVisible,
                      child: TextFormField(
                        readOnly: documentNumberReadonly,
                        textInputAction: TextInputAction.go,
                        style: TextStyle(fontSize: 13),
                        onFieldSubmitted: (value) {},
                        decoration: InputDecoration(
                          //icon: const Icon(Icons.person),
                          fillColor: documentNumberColor,
                          filled: true,
                          hintText: 'Enter Document No.',
                          labelText: 'Document Number',
                          labelStyle: TextStyle(fontSize: 13),
                          border: OutlineInputBorder(),
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(14), //
                        ),
                        controller: documentNumberController,
                      ))),
              SizedBox(height: 20),
              Center(
                  child: Container(
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),
                height: MediaQuery.of(context).size.height / 2.05,
                child: SingleChildScrollView(
                    child: Column(children: [
                  _createDataTable(),
                ])),
              )),
              SizedBox(height: 20),
              Center(
                child: new ButtonBar(
                  mainAxisSize: MainAxisSize
                      .min, // this will take space as minimum as posible(to center)
                  children: <Widget>[
                    Container(
                      width: 100.0,
                      height: 45.0,
                      child: new RaisedButton(
                        color: Colors.red,
                        child: const Text('Back',
                            style: TextStyle(
                              color: Colors.white,
                            )),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              )
            ])));
  }
}

Widget buildDetailRow(String palletNo, String lot, String weight) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5),
    child: Column(
      children: <Widget>[
        SizedBox(height: 12),
        Container(height: 2, color: Colors.redAccent),
        SizedBox(height: 12),
        Row(
          children: <Widget>[
            //CircleAvatar(backgroundImage: AssetImage(imageAsset)),
            SizedBox(width: 20),
            Text(palletNo),
            Spacer(),
            SizedBox(width: 10),
            Text(lot),
            Spacer(),
            Text(weight),
            SizedBox(width: 20),
          ],
        ),
      ],
    ),
  );
}