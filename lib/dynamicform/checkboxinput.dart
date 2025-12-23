import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../models/dynamicfield.dart';
import '../models/selectionobj.dart';

class CheckboxInputComp extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final String fieldName;
  final int? id;
  final int? mid;
  final DynamicField fieldObj;
  final Function(SelectionObj) onSaved;
  final Function(SelectionObj) selectionChange;
  CheckboxInputComp({Key? key, required this.fieldName,  this.id,  this.mid, required this.fieldObj, required this.selectionChange, required this.onSaved, required this.formKey}) : super(key: key);


  @override
  State<CheckboxInputComp> createState() => _CheckboxInputCompState();
}

class _CheckboxInputCompState extends State<CheckboxInputComp> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late double width;
  late double height;

  FocusNode focusNode = FocusNode();
  late SelectionObj dataobj;



  @override
  Widget build(BuildContext context) {
    //DynamicField field = Provider.of<DynamicNotifier>(context).quote.sections[0].blocks[widget.id].dynamicField[widget.mid];
    width = MediaQuery.of(context).size.width;
    height = 50.0;

    return Visibility(
      visible: widget.fieldObj.visibility == "Y"?true:false,
      child: Container(
        child:  Column(
          children: [
            FormBuilderCheckbox(
              name: widget.fieldObj.fieldName!,
              //validator: widget.fieldObj.validator!,
              initialValue: widget.fieldObj.fieldValue == null ? false:widget.fieldObj.fieldValue,
              enabled: widget.fieldObj.disabledYN == "N"?true:false,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              focusNode: focusNode,
              onSaved:(value){
                SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value);
                widget.onSaved(dataobj2);

              },
              onChanged: (value){
                setState(() {
                  SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value);
                  widget.selectionChange(dataobj2);
                });
              },
              //initialValue: widget.fieldObj.fieldValue == null ? widget.fieldObj.defaultValue == null?"":widget.fieldObj.defaultValue:widget.fieldObj.fieldValue,
              //validator: widget.fieldObj.validator,

              decoration:  InputDecoration(
                  contentPadding: EdgeInsets.only(bottom: 0, left: 2, right: 0,top: 0 ),
                  filled: false,
                  errorMaxLines: 3,
                  border:UnderlineInputBorder(
                    borderSide: BorderSide(width: 2.0),
                  ),
                  focusedBorder: UnderlineInputBorder(

                    borderSide: BorderSide(
                      width: 2,
                      color: Color(0xffE5E5E5),
                    ),
                  ),
                  disabledBorder: UnderlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(
                      width: 2,
                      color: Color(0xffE5E5E5),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(

                    borderSide: BorderSide(
                      width: 2,
                      color: Color(0xffE5E5E5),
                    ),
                  ),
                  errorBorder: UnderlineInputBorder(

                      borderSide: BorderSide(
                        width: 2,
                        color: Colors.red,
                      )
                  ),
                  focusedErrorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      width: 2,
                      color: Colors.red,
                    ),
                  ),
              ), title: widget.fieldObj.mandatory! == "Y"?RichText(
              text: TextSpan(
                  text: widget.fieldObj.labelName! ?? "",
                  children: [
                    TextSpan(
                        style: TextStyle(color: Colors.red),
                        text: ' *'
                    )
                  ],
                  ),
            ):Text(widget.fieldObj.labelName! ?? "",),
            ),
          ],
        ),
        padding: EdgeInsets.only(bottom :4),
        margin: EdgeInsets.only(top: 4, right: 4,),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
