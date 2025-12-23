import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../models/dynamicfield.dart';
import '../models/selectionobj.dart';

class SwitchInputComp extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final String fieldName;
  final int? id;
  final int? mid;
  final DynamicField fieldObj;
  final Function(SelectionObj) onSaved;
  final Function(SelectionObj) selectionChange;
  const SwitchInputComp({Key? key, required this.fieldName,  this.id,  this.mid, required this.fieldObj, required this.selectionChange, required this.onSaved, required this.formKey}) : super(key: key);

  @override
  State<SwitchInputComp> createState() => _SwitchInputCompState();
}

class _SwitchInputCompState extends State<SwitchInputComp>  with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late double width;
  late double height;

  FocusNode focusNode = FocusNode();
  late SelectionObj dataobj;

  @override
  Widget build(BuildContext context) {
    bool switchCont = true;
    //DynamicField field = Provider.of<DynamicNotifier>(context).quote.sections[0].blocks[widget.id].dynamicField[widget.mid];
    width = MediaQuery.of(context).size.width;
    height = 50.0;

    return Visibility(
      visible: widget.fieldObj.visibility == "Y"?true:false,
      child: Container(

        child: FormBuilderSwitch(
          activeColor: Colors.blue.shade900,
          name: widget.fieldObj.fieldName!,
          title: Text(widget.fieldObj.labelName! ?? "",),
          initialValue: widget.fieldObj.defaultYN ?? switchCont,
          onSaved: (value){
            SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value);
            widget.onSaved(dataobj2);
          },
          onChanged: (value){
            setState(() {
              widget.fieldObj.defaultYN = value;
              SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value);
              widget.selectionChange(dataobj2);
            });
          },
          controlAffinity: ListTileControlAffinity.trailing,
          decoration: InputDecoration(border: InputBorder.none),
        ),
        padding: EdgeInsets.only(bottom :3,top: 3),
        margin: EdgeInsets.only(top: 4, right: 4,),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
