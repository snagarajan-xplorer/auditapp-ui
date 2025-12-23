import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';


import '../constants.dart';
import '../models/dynamicfield.dart';
import '../models/selectionobj.dart';


class TextInputComp extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final String fieldName;
  final int? id;
  final int? mid;
  final DynamicField fieldObj;
  final Function(SelectionObj) onSaved;
  final Function(SelectionObj) selectionChange;
   TextInputComp({Key? key, required this.fieldName,  this.id,  this.mid, required this.fieldObj, required this.selectionChange, required this.onSaved, required this.formKey}) : super(key: key);

  @override
  State<TextInputComp> createState() => _TextInputCompState();
}

class _TextInputCompState extends State<TextInputComp>  with TickerProviderStateMixin, AutomaticKeepAliveClientMixin{
  late double width;
  late double height;
  GlobalKey btnKey = GlobalKey();
  bool showPass = false!;
  bool micOn = false!;
  FocusNode focusNode = FocusNode();
  late SelectionObj dataobj = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: "",keyvalue: "");
  List<TextInputFormatter> inputArr = [];

  String _lastWords = '';
  final FocusNode _node = FocusNode();




  @override
  void initState() {
    // TODO: implement initState
    Future.delayed(Duration.zero)
    .then((value){


        setState(() {
        //dataobj = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: "",keyvalue: "");
        showPass = widget.fieldObj.isPassword!;
      });
      focusNode.addListener(() {
        if(!focusNode.hasFocus && dataobj.fieldvalue.toString().isNotEmpty){
          widget.selectionChange(dataobj);
        }
      });
    });

    super.initState();
  }


  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.



  @override
  void dispose() {
    // TODO: implement dispose
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //DynamicField field = Provider.of<DynamicNotifier>(context).quote.sections[0].blocks[widget.id].dynamicField[widget.mid];

    // Divide and round
    var width = (MediaQuery.of(context).size.width-kFieldWidth)/2;

    return Visibility(
      visible: widget.fieldObj.visibility == "Y"?true:false,
      child: Container(
        height: 80,

        child: FormBuilderTextField(

          enableInteractiveSelection:false,
          name: widget.fieldObj.fieldName!,
          maxLength: widget.fieldObj.maxLen,

          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          textCapitalization: widget.fieldObj.caseType == null ? TextCapitalization.none:widget.fieldObj.caseType.toString().toLowerCase() == "u"?TextCapitalization.characters:TextCapitalization.none,
          textInputAction: TextInputAction.done,
          keyboardType:widget.fieldObj.textInputType,
          obscureText: showPass,
          initialValue: widget.fieldObj.fieldValue == null ? "":widget.fieldObj.fieldValue,
          enabled: widget.fieldObj.disabledYN == "N"?true:false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: Theme.of(context).textTheme.bodyMedium,
          focusNode: focusNode,
          onSaved:(value){
            SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value);
            widget.onSaved(dataobj2);
          },
          onChanged: (value){
            setState(() {
              if(widget.fieldObj.isCurrency!){
                if(value.toString() == "0"){
                  dataobj.fieldvalue = value;
                }else{
                  // var str = value.toString().split(GlobalData.currency);
                  // if(str.length == 2){
                  //   String p = str[1].toString().replaceAll(",", "");
                  //   double? price = double.tryParse(p);
                  //
                  // }
                  dataobj.fieldvalue = value;
                }

              }else{
                dataobj.fieldvalue = value;
              }
              dataobj.keyvalue = "";

            });
          },

          //initialValue: widget.fieldObj.fieldValue == null ? widget.fieldObj.defaultValue == null?"":widget.fieldObj.defaultValue:widget.fieldObj.fieldValue,
          validator: widget.fieldObj.validator == null ? null: widget.fieldObj.validator,
          inputFormatters: widget.fieldObj.inputFormatters,
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
            border:OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)) ,
            enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
            focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
            errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                borderSide: BorderSide(color: Colors.red, width: 1.0)),
            suffixIcon: null,

          ),
        ),
      ),
    );
  }


  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
