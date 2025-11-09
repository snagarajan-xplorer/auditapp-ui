import 'dart:convert';
import '../constants.dart';
import '../dropdown/drop_down.dart';
import '../models/selected_list_item.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../models/dynamicfield.dart';
import '../models/selectionobj.dart';
import '../services/api_service.dart';

class SelectInputComp extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final String fieldName;
  final int? id;
  final int? mid;
  final DynamicField fieldObj;
  final Function(SelectionObj) onSaved;
  final Function(SelectionObj) selectionChange;
  const SelectInputComp({Key? key, required this.fieldName, this.id, this.mid, required this.fieldObj, required this.onSaved, required this.selectionChange, required this.formKey}) : super(key: key);

  @override
  State<SelectInputComp> createState() => _SelectInputCompState();
}

class _SelectInputCompState extends State<SelectInputComp>  with TickerProviderStateMixin, AutomaticKeepAliveClientMixin{
  late double width;
  late double height;
  TextEditingController txtController = new TextEditingController(text: "");

  SelectedListItem? _selectedListItem;

  @override
  void dispose() {
    // TODO: implement dispose
    txtController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if(widget.fieldObj.options!.length != 0){
      //selectItem();
    }

  }
  /*
  void selectItem(){
    Future.delayed(Duration(milliseconds: 400))
        .then((value){

      List<SelectedListItem>? list = [];
      if(widget.fieldObj.fieldValue.toString().isNotEmpty){
        list = widget.fieldObj.options?.where((element) => element.value.toString() == widget.fieldObj.fieldValue.toString()).toList();
      }else if(widget.fieldObj.defaultYN != null){
        list = widget.fieldObj.options?.where((element) => element.value.toString() == widget.fieldObj.defaultYN.toString()).toList();
      }else {
        if(txtController.text.isNotEmpty){
          list = widget.fieldObj.options?.where((element) => element.value.toString() == txtController.text.toString()).toList();
        }
      }
      if(list != null){
        if(list.length != 0){
          if(list[0].name.toString().isNotEmpty){
            widget.formKey.currentState?.patchValue({
              widget.fieldObj.fieldName!:list[0].name.toString()
            });
          }

        }
      }
    });
  }

   */


  Widget newSearch(){
    var width = (MediaQuery.of(context).size.width-kFieldWidth)/2;
    return Visibility(
        visible: widget.fieldObj.visibility == "Y"?true:false,
        child: Container(
          height: 80,
          child: FormBuilderDropdown<String>(

            name: widget.fieldObj.fieldName!,
            validator: widget.fieldObj.validator == null ? null: widget.fieldObj.validator,
            // initialValue: "",
            //initialValue: widget.fieldObj.fieldValue == null ? "":widget.fieldObj.fieldValue.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onSaved:(value){
              // if(_selectedListItem != null){
              //   SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: _selectedListItem?.value.toString(),keyvalue: _selectedListItem?.name);
              //   widget.onSaved(dataobj2);
              // }else{
              //   List<SelectedListItem>? item = widget.fieldObj.options?.where((element) => element.name == value).toList();
              //   if(item?.length != 0){
              //     SelectionObj dataobj2 = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: item![0].value.toString(),keyvalue: item![0].name);
              //     widget.onSaved(dataobj2);
              //   }
              // }
              SelectionObj dataobj = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value ?? "",keyvalue: value ?? "");
              widget.onSaved(dataobj);
            },
            onChanged: (value){
              SelectionObj dataobj = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value,keyvalue: value);
              widget.onSaved(dataobj);
            },
            //initialValue: widget.fieldObj.fieldValue == null ? "":widget.fieldObj.fieldValue,
            //validator: widget.fieldObj.validator,
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
              hintText:"",

              enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
              focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
              errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: Colors.red, width: 1.0)),
            ), items: widget.fieldObj.options!,
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return newSearch();
  }
  Widget getItemContainer(context,item,str){
    return Text(item ?? "",);
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
