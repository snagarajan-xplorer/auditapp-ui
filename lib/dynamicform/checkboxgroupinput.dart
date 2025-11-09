import 'package:audit_app/theme/themes.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';


import '../constants.dart';
import '../models/dynamicfield.dart';
import '../models/selectionobj.dart';

class CheckboxGroupInput extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final String fieldName;
  final int? id;
  final int? mid;
  final DynamicField fieldObj;
  final Function(SelectionObj) onSaved;
  final Function(SelectionObj) selectionChange;
  const CheckboxGroupInput({super.key,required this.fieldName,  this.id,  this.mid, required this.fieldObj, required this.selectionChange, required this.onSaved, required this.formKey});

  @override
  State<CheckboxGroupInput> createState() => _CheckboxGroupInputState();
}

class _CheckboxGroupInputState extends State<CheckboxGroupInput> {
  late double width;
  late double height;
  GlobalKey btnKey = GlobalKey();
  bool showPass = false!;
  bool micOn = false!;
  FocusNode focusNode = FocusNode();
  late SelectionObj dataobj = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: "",keyvalue: "");
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: widget.fieldObj.visibility == "Y"?true:false,
      child: Container(
        child: FormBuilderCheckboxGroup<String>(
          name: widget.fieldObj.fieldName!,
          activeColor: kPrimaryColor,
          checkColor: Colors.white,

          enabled: widget.fieldObj.disabledYN == "N"?true:false,
          autovalidateMode: AutovalidateMode.onUserInteraction,


          onSaved:(value){
            SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value);
            widget.onSaved(dataobj2);
          },
          onChanged: (value){
            setState(() {
              dataobj.fieldvalue = value;;

            });
          },

          //initialValue: widget.fieldObj.fieldValue == null ? widget.fieldObj.defaultValue == null?"":widget.fieldObj.defaultValue:widget.fieldObj.fieldValue,
          validator: widget.fieldObj.validator == null ? null: widget.fieldObj.validator,

          decoration:  InputDecoration(
            label: widget.fieldObj.mandatory! == "Y"?RichText(
              text: TextSpan(
                text: widget.fieldObj.labelName! ?? "",
                children: [
                  TextSpan(
                      style: TextStyle(color: Colors.red),
                      text: ' *'
                  )
                ],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ):Text(widget.fieldObj.labelName! ?? "",style: Theme.of(context).textTheme.bodyMedium,),

            contentPadding: EdgeInsets.only(left: 20),
            counterText: "",
            errorMaxLines: 3,
            border: InputBorder.none,

            suffixIcon: null,

          ), options: widget.fieldObj.lovData!.map<FormBuilderFieldOption<String>>((ele)=>FormBuilderFieldOption(value: ele["clientid"].toString(),child: Text(ele["clientname"].toString()),)).toList(),
        ),
      ),
    );;
  }
}
