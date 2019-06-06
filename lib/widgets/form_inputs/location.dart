import 'package:flutter/material.dart';
import 'package:map_view/map_view.dart';

class LocationInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {

  }
}

class _LocationInputState extends State<LocationInput> {

  final FocusNode _addressInputFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
       TextFormField(
         onEditingComplete: ,
       )
    ],);
  }
}