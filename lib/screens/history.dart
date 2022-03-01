import 'package:flutter/material.dart';
import 'package:flutter_session/flutter_session.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/class/resvalidatepalletitem.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/services.dart';

class History extends StatefulWidget {
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  var session = FlutterSession();
  int isDocumentId = 0;
  String documentId = "";

  String isAppbar = "";
  String appBar = "";

  late ResValidatePalletitem? resultValPalletCheckCancel;
  late Palletitem? resultPalletCheckCancel;
  late List<Palletitem> listHistoryPalletitem = [];
  TextEditingController gradeCancelHistory = TextEditingController();
  bool gradeCancelHistoryVisible = true;
  bool gradeCancelHistoryReadonly = false;
  Color gradeCancelHistoryColor = Color(0xFFFFFFFF);
  bool cancelHistoryEnabled = false;
  late Timer timer;
  int step = 0;
  String gradeInputCancle = '';
  late List<FocusNode> focusNodes = List.generate(2, (index) => FocusNode());
  String configs = '';

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
    setState(() {
      step = 0;
    });
    setVisible();
    setReadOnly();
    setColor();
    setText();
    setFocus();
    onload();
  }

  void setVisible() {
    if (step == 0) {
      setState(() {
        gradeCancelHistoryVisible = true;
      });
    } else if (step == 1) {
      setState(() {
        gradeCancelHistoryVisible = true;
      });
    }
  }

  void setReadOnly() {
    if (step == 0) {
      setState(() {
        gradeCancelHistoryReadonly = false;
        cancelHistoryEnabled = false;
      });
    } else if (step == 1) {
      setState(() {
        gradeCancelHistoryReadonly = true;
        cancelHistoryEnabled = true;
      });
    }
  }

  void setColor() {
    if (step == 0) {
      setState(() {
        gradeCancelHistoryColor = Color(0xFFFFFFFF);
      });
    } else if (step == 1) {
      setState(() {
        gradeCancelHistoryColor = Color(0xFFEEEEEE);
      });
    }
  }

  void setText() {
    if (step == 0) {
      setState(() {
        gradeCancelHistory.text = '';
      });
    } else if (step == 1) {
      setState(() {
        gradeCancelHistory.text = gradeInputCancle;
      });
    }
  }

  void setFocus() {
    if (step == 0) {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => FocusScope.of(context).requestFocus(focusNodes[0]));
    } else if (step == 1) {
      Future.delayed(Duration(milliseconds: 100))
          .then((_) => FocusScope.of(context).requestFocus(focusNodes[1]));
    }
  }

  Future<void> getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      configs = prefs.getString('configs');
    });
  }

  Future<void> onload() async {
    isDocumentId = await FlutterSession().get("token_documentID");
    isAppbar =
        await FlutterSession().get("token_historyAppBarSession") + 'History';
    setState(() {
      documentId = isDocumentId.toString();
      appBar = isAppbar;
    });
    var url = Uri.parse(configs + '/api/api/palletitem/getbydoc/' + documentId);
    http.Response response = await http.get(url);
    //var data = json.decode(response.body) as List;
    setState(() {
      listHistoryPalletitem = (json.decode(response.body) as List)
          .map((data) => Palletitem.fromJson(data))
          .toList();
    });
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
          timer = Timer(Duration(seconds: 2), () {
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

  Future<void> gradeCancelCheck() async {
    setState(() {
      gradeInputCancle = gradeCancelHistory.text;
    });

    var url = Uri.parse(configs +
        '/api/api/palletitem/validatecancel/' +
        documentId +
        '/' +
        gradeInputCancle);
    http.Response response = await http.get(url);
    var data = json.decode(response.body);

    setState(() {
      resultValPalletCheckCancel = ResValidatePalletitem.fromJson(data);
      resultPalletCheckCancel = resultValPalletCheckCancel?.palletitem;
    });

    if (resultPalletCheckCancel == null) {
      showErrorDialog(resultValPalletCheckCancel!.errorMsg.toString());
    } else {
      setState(() {
        step++;
      });
    }
    setVisible();
    setReadOnly();
    setColor();
    setText();
    setFocus();
  }

  Future<void> cancelHistory() async {
    resultPalletCheckCancel!.isDeleted = true;
    String tempAPI = configs + '/api/api/palletitem/updateandpost/';
    final uri = Uri.parse(tempAPI);
    final headers = {'Content-Type': 'application/json'};
    var jsonBody = jsonEncode(resultPalletCheckCancel?.toJson());
    final encoding = Encoding.getByName('utf-8');
    http.Response response = await http.post(
      uri,
      headers: headers,
      body: jsonBody,
      encoding: encoding,
    );
    var data = json.decode(response.body);
    setState(() {
      resultPalletCheckCancel = Palletitem.fromJson(data);
      step = 0;
    });

    showSuccessDialog('Cancel Order Complete');
    onload();
    setVisible();
    setReadOnly();
    setColor();
    setText();
    setFocus();
  }

  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (step == 0) {
      setState(() {
        gradeCancelHistory.text = barcodeScanRes;
      });
      gradeCancelCheck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          title: Text(
            isAppbar.toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
          actions: <Widget>[
            IconButton(
                icon: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.black,
                ),
                onPressed: scanQR)
          ],
        ),
        body: Container(
            child: SingleChildScrollView(
                child: Form(
                    child: Column(children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height / 1.5,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                SizedBox(height: 20),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5),
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.yellow[900],
                                borderRadius: BorderRadius.circular(20)),
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 20),
                            child: Text('No'),
                          ),
                          Spacer(),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.yellow[900],
                                borderRadius: BorderRadius.circular(20)),
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 20),
                            child: Text('lot'),
                          ),
                          Spacer(),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.yellow[900],
                                borderRadius: BorderRadius.circular(20)),
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 20),
                            child: Text('weight'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                for (var data in listHistoryPalletitem)
                  buildHistoryRow(
                      '${data.palletNo}', '${data.lot}', '${data.weight}'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5),
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: 12),
                      Container(height: 2, color: Colors.redAccent),
                      SizedBox(height: 9),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                    padding: new EdgeInsets.only(
                        left: MediaQuery.of(context).size.width / 8,
                        right: MediaQuery.of(context).size.width / 8),
                    child: Visibility(
                        visible: gradeCancelHistoryVisible,
                        child: TextFormField(
                          focusNode: focusNodes[0],
                          readOnly: gradeCancelHistoryReadonly,
                          textInputAction: TextInputAction.go,
                          onFieldSubmitted: (value) {
                            gradeCancelCheck();
                          },
                          decoration: InputDecoration(
                            //icon: const Icon(Icons.person),
                            fillColor: gradeCancelHistoryColor,
                            filled: true,
                            hintText: 'Enter Grade Label Cancel',
                            labelText: 'GradeLabelCancel',
                            border: OutlineInputBorder(),
                            isDense: true, // Added this
                            contentPadding: EdgeInsets.all(15), //
                          ),
                          controller: gradeCancelHistory,
                        ))),
                SizedBox(height: 20),
                new Center(
                  child: new ButtonBar(
                    mainAxisSize: MainAxisSize
                        .min, // this will take space as minimum as posible(to center)
                    children: <Widget>[
                      new RaisedButton(
                        focusNode: focusNodes[1],
                        color: Colors.redAccent,
                        child: const Text('Cancel',
                            style: TextStyle(
                              color: Colors.white,
                            )),
                        onPressed: cancelHistoryEnabled
                            ? () {
                                cancelHistory();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ])))));
  }
}

Widget buildHistoryRow(String palletNo, String lot, String weight) {
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