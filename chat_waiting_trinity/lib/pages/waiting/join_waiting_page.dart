import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/join_waiting_controller.dart';

class JoinWaitingPage extends StatefulWidget {
  @override
  _JoinWaitingPageState createState() => _JoinWaitingPageState();
}

enum SelectTime { nowPick, userPick }

class _JoinWaitingPageState extends State<JoinWaitingPage> {
  final _formKey = GlobalKey<FormState>();
  var _name = '';
  var _phone = '';
  var _people = '';
  DateTime _reserveAt;
  String _waitingStatus;
  // String _reserveDate;
  // String _reserveTime;
  var _isLoading = false;
  TextEditingController _reserveAtController = TextEditingController();
  // TextEditingController _reserveDateController = TextEditingController();
  // TextEditingController _reserveTimeController = TextEditingController();
  var _selectedReserveTime;
  // DateTime _selectedDate;
  // DateTime _selectedTime;

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Reservation Time',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlatButton(
                child: Text('Now'),
                onPressed: () {
                  setState(() {
                    _selectedReserveTime = SelectTime.nowPick;
                    _waitingStatus =
                        JoinWaitingController.instance.defaultStatus;
                  });
                  print(_selectedReserveTime);

                  // setState(() {
                  // _reserveAt = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
                  _reserveAtController.text = _roundUpTime(DateTime.now());

                  // });
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Later'),
                onPressed: () {
                  setState(() {
                    _selectedReserveTime = SelectTime.userPick;
                  });
                  print(_selectedReserveTime);

                  Navigator.of(context).pop();
                  _reserveAtPicker();
                },
              ),
              // FlatButton(
              //   child: Text('Cancel'),
              //   onPressed: () {
              //     Navigator.of(context).pop();
              //   },
              // ),
            ],
          ),
          // actions: [

          // ],
        );
      },
    );
  }

  String _roundUpTime(DateTime dt) {
    DateTime roundUpTime = dt.add(Duration(minutes: (5 - dt.minute % 5)));
    _reserveAt = roundUpTime;

    return DateFormat('yyyy/MM/dd HH:mm').format(roundUpTime);
  }

  bool _timePassed(String pickedTime) {
    final DateTime now = DateTime.now();
    final DateTime picked = DateFormat('yyyy/MM/dd HH:mm').parse(pickedTime);
    print('picked: $picked');
    // final nowformatted = DateFormat('yyyy/MM/dd HH:mm').format(now);
    final earlier = now.subtract(const Duration(minutes: 5));
    // final earlierFormatted = DateFormat('yyyy/MM/dd HH:mm').format(now);
    // print(pickedTime);
    final passed = earlier.isBefore(picked);
    // print(pickedTime);
    print('earllier: $earlier');
    print(passed);
    final diff = now.difference(picked);
    print(diff);

    return passed;
  }

  // Future<void> _reserveDatePicker() async {
  //   try {
  //     final selectedDate = await showDatePicker(
  //         context: context,
  //         initialDate: DateTime.now(),
  //         firstDate: DateTime.now(),
  //         lastDate: DateTime.now().add(
  //           Duration(days: 100),
  //         ));
  //     // setState(() {
  //     //   _reserveDate = DateFormat('yyyy/MM/dd').format(selectedDate);
  //     // });
  //     _reserveDateController.text = DateFormat('yyyy/MM/dd').format(selectedDate);
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  // Future<void> _reserveTimePicker() async {
  //   try {
  //     final selectedTime = await showTimePicker(
  //       context: context,
  //       initialTime: TimeOfDay.now(),
  //     );
  //     // setState(() {
  //     //   _reserveTime = selectedTime.toString();
  //     // });
  //     print(selectedTime);
  //     _reserveTimeController.text = selectedTime.format(context);
  //     // selectedTime
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  Future<void> _reserveAtPicker() async {
    try {
      final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(
            Duration(days: 100),
          ));
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      DateTime resultTime = DateTime(selectedDate.year, selectedDate.month,
          selectedDate.day, selectedTime.hour, selectedTime.minute);
      // DateTime roundUpTime =
      //     resultTime.add(Duration(minutes: (5 - resultTime.minute % 5)));
      // print('rounduptime $roundUpTime');
      // setState(() {
      //   _reserveAt = DateTime(selectedDate.year, selectedDate.month,
      //       selectedDate.day, selectedTime.hour, selectedTime.minute);

      // _reserveAtController.text = DateFormat('yyyy/MM/dd HH:mm').format(roundUpTime);;
      _reserveAtController.text = _roundUpTime(resultTime);

      // });
      // print(_reserveAt);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getStatus() async {
    final value = await JoinWaitingController.instance.getStatus(_reserveAt);
    // .then((String value) {
    // print('getstatus value $value');
    setState(() {
      _waitingStatus = value;
    });
    // print('waitingstatus getstatus $_waitingStatus');
    // });
  }

  Future<void> _makeReservation() async {
    final isValid = _formKey.currentState.validate();
    var reservationNumber = 0;
    final DateTime now = DateTime.now();
    if (isValid) {
      _formKey.currentState.save();
      // final docId = _reserveAt.substring(0,10);
      // final docId = DateFormat('yyyy/MM/dd').format(DateTime.now());
      final docId = DateFormat("yyyy/MM/dd").format(_reserveAt);
      bool isToday = true;
      if (_reserveAt.difference(now).inDays != 0) {
        isToday = false;
      }

      // final docId = '2020/11/18';
      print('makereservation docId:$docId');

      try {
        DocumentReference result;

        final docSnap = await FirebaseFirestore.instance
            .collection('waiting')
            .doc(docId)
            .collection('list')
            // .where('waitingStatus', isEqualTo: 'waiting')
            .get();
        print('docsnap length : ${docSnap.docs.length}');
        int currentWaitingTime;

        int currentWaitingTimeUpdated;
        // docSnap.docs['currentWaitingTime'];
        if (docSnap.docs.length == 0) {
          reservationNumber = 1;
          await FirebaseFirestore.instance
              .collection('waiting')
              .doc(docId)
              .set({'currentWaitingTime': 0});
          currentWaitingTime = 0;
          currentWaitingTimeUpdated = 0;
        } else {
          final docRef = await FirebaseFirestore.instance
              .collection('waiting')
              .doc(DateFormat('yyyy/MM/dd').format(now))
              .get();
// print('docref length : ${docRef.data().length}');
          currentWaitingTime = docRef.data()['currentWaitingTime'];
          print('current wait time $currentWaitingTime');
          reservationNumber = docSnap.docs.length + 1;
          var counterActive = 0;
          // var currentWaitingTime = 0;
          docSnap.docs.map((e) {
            // print(e['waitingStatus']);
            if (e['waitingStatus'] == 'waiting') {
              counterActive++;
            }
          }).toList();
          print('counteractive $counterActive');
          if (counterActive < 2) {
            currentWaitingTimeUpdated = 0;
          } else if (counterActive < 5) {
            currentWaitingTimeUpdated = 10;
          } else if (counterActive < 10) {
            currentWaitingTimeUpdated = 30;
          } else if (counterActive < 20) {
            currentWaitingTimeUpdated = 45;
          } else if (counterActive < 30) {
            currentWaitingTimeUpdated = 60;
          } else {
            currentWaitingTimeUpdated = 90;
          }
          print('current wainting updated time $currentWaitingTimeUpdated');
        }
        if (currentWaitingTime != currentWaitingTimeUpdated) {
          await FirebaseFirestore.instance
              .collection('waiting')
              .doc(docId)
              .set({'currentWaitingTime': currentWaitingTimeUpdated});
          await JoinWaitingController.instance
              .pendingCheck(currentWaitingTimeUpdated);
        }

        if (_selectedReserveTime == SelectTime.userPick) {
          await _getStatus();
          // print('joinwaitingControllergetStatus triggerred');
        }
        print('_waitingStatus $_waitingStatus');
        // if(_waitingStatus == null){
        //   Timer(Duration(seconds: 1), (){print('_getstatus null why');});
        // }
        result = await FirebaseFirestore.instance
            .collection('waiting')
            .doc(docId)
            .collection('list')
            .add({
          'createdAt': now,
          'name': _name,
          'people': _people,
          'phone': _phone,
          'reserveAt': _reserveAt,
          'reservationNumber': reservationNumber,
          'waitingStatus': _waitingStatus
        });
        print(result.path);
        if (_waitingStatus == 'pending' && isToday) {
          final diff = _reserveAt.difference(now);
          final triggerTime = diff - Duration(minutes: currentWaitingTime);
          print('trigger time $triggerTime');
          // Timer(Duration(seconds: 15, minutes: 0), () {
          Timer(triggerTime, () {
            print("Yeah, this line is printed after $triggerTime ");
            JoinWaitingController.instance.pendingToWaiting(result.path);
          });
        }
      } catch (e) {
        print(e);
      }
      print('$_name $_phone $_people $_reserveAt');
      // Timer(Duration(seconds: 15, minutes: 0), () {
      //   print("Yeah, this line is printed after 15 second");
      //   JoinWaitingController.instance.pendingCheck();
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Wainting List'),
      ),
      body: InkWell(
        splashColor: Colors.transparent,
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Card(
          margin: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // if (!_isSignIn) UserImagePicker(_pickedImage),
                    TextFormField(
                      key: ValueKey('guest_name'),
                      // autocorrect: false,
                      textCapitalization: TextCapitalization.words,
                      enableSuggestions: false,
                      validator: (value) {
                        if (value.isEmpty || value.length < 2) {
                          return 'Prease name at least 2 characters';
                        }

                        return null;
                      },
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Name',
                      ),
                      onSaved: (value) {
                        _name = value;
                      },
                    ),

                    TextFormField(
                      key: ValueKey('guest_phone'),
                      validator: (value) {
                        if (value.isEmpty || value.length < 6) {
                          return 'Password must be at least 6 characters long.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(labelText: 'phone'),
                      // obscureText: true,
                      onSaved: (value) {
                        _phone = value;
                      },
                    ),

                    TextFormField(
                      key: ValueKey('guest_people'),
                      initialValue: '0',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (int.parse(value) < 1) {
                          return 'Please choose number of people.';
                        }
                        if (int.parse(value) > 10) {
                          return 'more than 10 people need to contact to the restaurant.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(labelText: 'People'),
                      // obscureText: true,
                      onSaved: (value) {
                        _people = value;
                      },
                    ),

                    TextFormField(
                      key: ValueKey('guest_ReserveAt'),
                      // initialValue: DateTime.now().toString(),
                      controller: _reserveAtController,
                      validator: (value) {
                        if (value.isEmpty || !_timePassed(value)) {
                          return 'Please pick a time for the reservation.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'reserveAt',
                        suffixIcon: IconButton(
                          onPressed: () => _reserveAtController.clear(),
                          icon: Icon(Icons.clear),
                        ),
                      ),
                      // obscureText: true,
                      onSaved: (value) {
                        // _reserveAt =
                        //     DateFormat('yyyy/MM/dd HH:mm').parse(value);
                        // JoinWaitingController.instance.getStatus(_reserveAt).then((String value) { _waitingStatus = value; });
                      },
                      onTap: _showMyDialog,
                    ),

                    // TextFormField(
                    //   key: ValueKey('guest_Reserve_Date'),
                    //   // initialValue:
                    //   //     DateFormat('yyyy/MM/dd').format(DateTime.now()),
                    //   controller: _reserveDateController,
                    //   validator: (value) {
                    //     if (value.isEmpty) {
                    //       return 'Please pick a time for the reservation.';
                    //     }
                    //     return null;
                    //   },
                    //   decoration: InputDecoration(
                    //     labelText: 'reserveDate',
                    //     // suffixIcon: IconButton(
                    //     //   onPressed: () => _reserveAtController.clear(),
                    //     //   icon: Icon(Icons.clear),
                    //     // ),
                    //   ),
                    //   // obscureText: true,
                    //   onSaved: (value) {
                    //     // setState(() {
                    //     _reserveDate = value;
                    //     // DateFormat("yyyy-MM-dd hh:mm:ss").parse(value);
                    //     // });
                    //   },
                    //   onTap: _reserveDatePicker,
                    // ),
                    // TextFormField(
                    //   key: ValueKey('guest_Reserve_Time'),
                    //   // initialValue:
                    //   //     DateFormat('HH:mm').format(DateTime.now()),
                    //   controller: _reserveTimeController,
                    //   validator: (value) {
                    //     if (value.isEmpty) {
                    //       return 'Please pick a time for the reservation.';
                    //     }
                    //     return null;
                    //   },
                    //   decoration: InputDecoration(
                    //     labelText: 'reserveTime',
                    //     // suffixIcon: IconButton(
                    //     //   onPressed: () => _reserveAtController.clear(),
                    //     //   icon: Icon(Icons.clear),
                    //     // ),
                    //   ),
                    //   // obscureText: true,
                    //   onSaved: (value) {
                    //     // setState(() {
                    //     _reserveTime = value;
                    //     // DateFormat("yyyy-MM-dd hh:mm:ss").parse(value);
                    //     // });
                    //   },
                    //   onTap: _reserveTimePicker,
                    // ),

                    SizedBox(height: 12),
                    if (_isLoading) CircularProgressIndicator(),
                    if (!_isLoading)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RaisedButton(
                            child: Text('Reserve'),
                            onPressed: _makeReservation,
                          ),
                          FlatButton(
                            child: Text('Back to List'),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/home');
                            },
                          )
                        ],
                      ),
                    // if (!widget.isLoading)
                    //   FlatButton(
                    //     textColor: Theme.of(context).primaryColor,
                    //     onPressed: () {
                    //       setState(() {
                    //         _isSignIn = !_isSignIn;
                    //       });
                    //     },
                    //     child: Text(_isSignIn
                    //         ? 'Creat new account'
                    //         : 'I already have an account'),
                    //   ),
                    // SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
