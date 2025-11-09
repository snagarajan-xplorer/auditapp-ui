import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:jiffy/jiffy.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/dynamicfield.dart';
import '../models/selectionobj.dart';

class DateInputComp extends StatefulWidget {
  final String fieldName;
  final int? id;
  final int? mid;
  final DynamicField fieldObj;
  final Function(SelectionObj) onSaved;
  final Function(SelectionObj) selectionChange;
  const DateInputComp({Key? key, required this.fieldName, this.id, this.mid, required this.fieldObj, required this.onSaved, required this.selectionChange}) : super(key: key);

  @override
  State<DateInputComp> createState() => _DateInputCompState();
}

class _DateInputCompState extends State<DateInputComp> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin{
  late double width;
  late double height;
  DateTime getInitialDate(){
    DateTime dateTime = Jiffy.now().dateTime;
    if(widget.fieldObj.maxDate.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch){
      if(widget.fieldObj.minDate.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch){
        return widget.fieldObj.minDate;
      }else{
        return DateTime.now();
      }
    }else{
      return widget.fieldObj.minDate;
    }
    return dateTime;
  }

  @override
  Widget build(BuildContext context) {
    var width = (MediaQuery.of(context).size.width-kFieldWidth)/2;
    return Visibility(
        visible: widget.fieldObj.visibility == "Y"?true:false,
        child: Container(
          height: 80,
          child:  FormBuilderDateTimePicker(
            enabled: widget.fieldObj.disabledYN == "N"?true:false,
            name: widget.fieldObj.fieldName!,
            textInputAction: TextInputAction.done,
            validator: widget.fieldObj.validator == null ? null: widget.fieldObj.validator,
            timePickerInitialEntryMode: TimePickerEntryMode.dialOnly,
            style: Theme.of(context).textTheme.bodyMedium,
            inputType: widget.fieldObj.enableTime == false ? InputType.date:InputType.both,
            format: widget.fieldObj.enableTime == false ?DateFormat('dd/MM/yyyy'):DateFormat('dd/MM/yyyy HH:mm:ss'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            //initialValue: widget.fieldObj?.fieldValue == null?widget.fieldObj.maxDate:widget.fieldObj?.fieldValue,
            onSaved: (DateTime? value){
              String format= widget.fieldObj.enableTime == false ? 'yyyy-MM-dd' : 'yyyy-MM-ddTHH:mm:ss';
              SelectionObj dataobj = SelectionObj(fieldname: widget.fieldObj.fieldName!,fieldvalue: value);
              widget.onSaved(dataobj);
            },
            initialDate: widget.fieldObj.maxDate.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch?
            widget.fieldObj.minDate.millisecondsSinceEpoch > DateTime.now().millisecondsSinceEpoch?widget.fieldObj.minDate:DateTime.now()
                :widget.fieldObj.maxDate,
            firstDate: widget.fieldObj.minDate,
            lastDate: widget.fieldObj.maxDate,
            //onSaved: widget.onSaved,
            onChanged: (date){
              if(date != null){
                setState((){
                  //widget.fieldObj.fieldValue = date;
                });
                String datestr = Jiffy.now().format(pattern: "yyyy-MM-dd");
                if(widget.fieldObj.enableTime == true){
                  datestr = Jiffy.now().format(pattern: "yyyy-MM-ddTHH:mm:ss");
                }
                widget.selectionChange(SelectionObj(fieldname: widget.fieldName,fieldvalue: datestr,id: widget.id,mid: widget.mid,keyvalue: ""));
              }

            },

            //initialValue: widget.fieldObj.fieldValue == null ? widget.fieldObj.defaultValue:widget.fieldObj.fieldValue,
            //validator: widget.validator,
            //inputType: widget.inputType,
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

              counterText: "",
              contentPadding: EdgeInsets.only(left: 20),
              enabledBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
              focusedBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: ThemeData().primaryColor, width: 1.0)),
              errorBorder: OutlineInputBorder(borderRadius:BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: Colors.red, width: 1.0)),

              errorMaxLines: 3,


              suffixIcon: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 20.0,
              ),
            ),
          ),

        )
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
