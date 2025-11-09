
import 'package:audit_app/responsive.dart';
import 'package:audit_app/services/utility.dart';
import 'package:audit_app/widget/buttoncomp.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'dart:io' show Platform;
import '../dropdown/drop_down.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'checkboxgroupinput.dart';
import 'switchinput.dart';
import 'dateinput.dart';

import 'selectinput.dart';
import 'textinput.dart';
import '../localization/app_translations.dart';

import '../models/dynamicfield.dart';
import '../models/selectionobj.dart';

import 'checkboxinput.dart';

class DynamicForm extends StatefulWidget {
  final double? width;
  final GlobalKey<FormBuilderState> formKey;
  final double? height;
  final String? transactionType;
  final int? id;
  final bool? showCancelBtn;
  final bool? enableBtn;
  final bool? visibleBtn;
  final Function(Map<String, dynamic>) callback;
  final Function(SelectionObj) selectionChange;
  final String buttonName;
  final List<DynamicField> dynamicArr;
  final List<Widget>? buttons;
  DynamicForm({
    Key? key,
    this.width,
    required this.formKey,
    this.height,
    this.id,
    this.showCancelBtn = true,
    required this.callback,
    required this.selectionChange,
    required this.buttonName,
    required this.dynamicArr,
    this.visibleBtn = true,
    this.buttons,
    this.enableBtn = true, this.transactionType="FQ",
  }) : super(key: key);

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<Widget> column = [];
  int kid = 0;
  int num = 0;
  int total = 4;
  List<Widget> row1Obj = [];
  List<Widget> row2Obj = [];
  List<Widget> row3Obj = [];
  List<Widget> row4Obj = [];
  List<Widget> wdtcolumn = [];
  final FocusNode _node = FocusNode();
  List<Widget> fieldElement = [];
  Map<String, dynamic> controls = {};
  List<Widget> childs = [];
  Widget btnContainer = Container();
  bool showBtn = false;
  int numValue = 0;
  Widget getQuestion() {
    int mid = 0;
    setState(() {
      widget.dynamicArr.sort((a, b) => a.fieldDisplayOrder!.compareTo(b.fieldDisplayOrder!));
      wdtcolumn = [];
      column = [];
      row1Obj = [];
      row2Obj = [];
      row3Obj = [];
      row4Obj = [];
      num = 0;
      numValue = (widget.dynamicArr.length / 2).round();
    });
    widget.dynamicArr.map((element) {
      Widget k = Container();
      //element.notifier = DynamicNotifier(element);
      //element.validator = element.fieldValidation;
      UtilityService().addValidators(element);
      if (element.fieldType == "Text") {
        if(element.inputFormatters?.length == 0){
          element.inputFormatters = [
            FilteringTextInputFormatter.singleLineFormatter,
          ];
          if (element.caseType != null) {
            if (element.caseType.toString().toLowerCase() == "u") {
              // element.inputFormatters = [
              //   UpperCaseTextFormatter()
              // ];
              if (element.dataType == "ANH") {
                element.inputFormatters!.add(FilteringTextInputFormatter.allow(RegExp("[A-Z0-9-]")));
              }else if (element.dataType == "AN") {
                element.inputFormatters!.add(FilteringTextInputFormatter.allow(RegExp("[A-Z0-9]")));
              }else if (element.dataType == "ANS") {
                element.inputFormatters!.add(FilteringTextInputFormatter.allow(RegExp("[A-Z ]")));
              }
            }
          }
        }

        element.textInputType = TextInputType.text;
        if (element.dataType == "Numeric") {
          element.inputFormatters = [FilteringTextInputFormatter.digitsOnly];

          element.textInputType = TextInputType.numberWithOptions(signed: true, decimal: false);
        } else if (element.dataType == "Tel") {
          element.inputFormatters = [
            FilteringTextInputFormatter.digitsOnly,
            FilteringTextInputFormatter.allow(RegExp("[0-9]"))
          ];

          element.textInputType =
              TextInputType.numberWithOptions(signed: true, decimal: false);
        } else {
          if (element.fieldName!.toLowerCase().contains("email")) {
            element.inputFormatters = [
              FilteringTextInputFormatter.allow(RegExp("[a-zA-Z0-9@.]")),
            ];
            element.textInputType = TextInputType.emailAddress;
          }else{
            if (element.allowSpecialCharactor == false) {
              element.inputFormatters = [
                FilteringTextInputFormatter.allow(RegExp("[A-Z0-9 -]"))
              ];
              if (element.dataType == "ANH") {
                element.inputFormatters = [
                  FilteringTextInputFormatter.allow(RegExp("[A-Z0-9-]"))
                ];
              }else if (element.dataType == "A") {
                element.inputFormatters = [
                  FilteringTextInputFormatter.allow(RegExp("[A-Z]"))
                ];
              }else if (element.dataType == "N") {
                element.inputFormatters = [
                  FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                ];
              }else if (element.dataType == "ANU") {
                element.inputFormatters = [
                  FilteringTextInputFormatter.allow(RegExp("[A-Z0-9]"))
                ];
              }else if (element.dataType == "ANS") {
                element.inputFormatters = [
                  FilteringTextInputFormatter.allow(RegExp("[A-Z ]"))
                ];
              }
              element.textInputType = TextInputType.text;
            }
          }
        }
        k = TextInputComp(
          id: widget.id,
          formKey: widget.formKey,
          mid: mid,
          fieldObj: element,
          onSaved: (obj) {
            setState(() {
              controls[obj.fieldname] = obj.fieldvalue;
            });
          },
          selectionChange: (obj) {
            //_formKey.currentState.;
            //obj.globalkey = _formKey;

            widget.formKey.currentState?.save();
            widget.selectionChange(obj);
          },
          fieldName: element.fieldName!,
        );
      } else if (element.fieldType!.contains("Numeric")) {
        element.inputFormatters = [FilteringTextInputFormatter.digitsOnly];
        element.textInputType = TextInputType.numberWithOptions(signed: true, decimal: false);
        k = TextInputComp(
          id: widget.id,
          mid: mid,
          fieldObj: element,
          onSaved: (obj) {
            setState(() {
              controls[obj.fieldname] = obj.fieldvalue;
            });
          },
          selectionChange: (obj) {
            //_formKey.currentState.;
            //obj.globalkey = _formKey;
            widget.formKey.currentState?.save();
            widget.selectionChange(obj);
          },
          fieldName: element.fieldName!,
          formKey: widget.formKey,
        );
      }else if (element.fieldType!.contains("CheckBoxInput")) {
        k = CheckboxInputComp(
          id: widget.id,
          mid: mid,
          fieldObj: element,
          onSaved: (obj) {
            setState(() {
              controls[obj.fieldname] = obj.fieldvalue;
            });
          },
          selectionChange: (obj) {
            //_formKey.currentState.;
            //obj.globalkey = _formKey;
            widget.formKey.currentState?.save();
            widget.selectionChange(obj);
          },
          fieldName: element.fieldName!,
          formKey: widget.formKey,
        );
      }else if (element.fieldType!.contains("Select")) {
        k = SelectInputComp(
          id: widget.id,
          mid: mid,
          fieldObj: element,
          onSaved: (obj) {
            setState(() {
              controls[obj.fieldname] = obj.fieldvalue;
            });
          },
          selectionChange: (obj) {
            //_formKey.currentState.;
            //obj.globalkey = _formKey;
            widget.formKey.currentState?.save();
            widget.selectionChange(obj);
          },
          fieldName: element.fieldName!,
          formKey: widget.formKey,
        );
      }else if (element.fieldType!.contains("CheckBoxGroup")) {
        k = CheckboxGroupInput(
          id: widget.id,
          mid: mid,
          fieldObj: element,
          onSaved: (obj) {
            setState(() {
              controls[obj.fieldname] = obj.fieldvalue;
            });
          },
          selectionChange: (obj) {
            //_formKey.currentState.;
            //obj.globalkey = _formKey;
            widget.formKey.currentState?.save();
            widget.selectionChange(obj);
          },
          fieldName: element.fieldName!,
          formKey: widget.formKey,
        );
      }else if (element.fieldType!.contains("SwitchBox")) {
        k = SwitchInputComp(
          id: widget.id,
          mid: mid,
          fieldObj: element,
          onSaved: (obj) {
            setState(() {
              obj.pos = 0;
              controls[obj.fieldname] = obj.fieldvalue;
            });
          },
          selectionChange: (obj) {
            //_formKey.currentState.;
            //obj.globalkey = _formKey;

            obj.pos = -1;
            widget.selectionChange(obj);

            setState(() {

            });
          },
          fieldName: element.fieldName!,
          formKey: widget.formKey,
        );
      } else if (element.fieldType!.contains("Date")) {
        k = DateInputComp(
          id: widget.id,
          mid: mid,
          fieldObj: element,
          onSaved: (obj) {
            setState(() {
              controls[obj.fieldname] = obj.fieldvalue;
            });
          },
          selectionChange: (obj) {
            //_formKey.currentState.;
            //obj.globalkey = _formKey;
            widget.formKey.currentState?.save();
            widget.selectionChange(obj);
          },
          fieldName: element.fieldName!,
        );
      } else if (element.fieldType == "Select") {

        k = SelectInputComp(
          fieldObj: element,
          formKey: widget.formKey,
          selectionChange: (obj) {
            setState(() {
              obj.pos = -1;
            });
            //widget.formKey.currentState?.save();
            widget.selectionChange(obj);
          },
          onSaved: (obj) {
            setState(() {
              obj.pos = 0;
              controls[obj.fieldname] = obj.fieldvalue;
            });

            widget.selectionChange(obj);
          },
          fieldName: element.fieldName!,
        );
      }
      if (k != null) {
        if (num == 0) {
          row1Obj.add(k);
          num = 1;
        } else if (num == 1) {
          row2Obj.add(k);
          num = 2;
        }else if (num == 2) {
          row4Obj.add(k);
          num = 0;
        }
        setState(() {});
        if (element.widgetType == "Row") {
          if (kid == 0) {
            fieldElement.add(Flexible(flex: 1, child: k));
            fieldElement.add(SizedBox(
              width: 10,
            ));

            kid = 1;
          } else if (kid == 1) {
            fieldElement.add(Flexible(flex: 1, child: k));
            column.add(Row(
              children: fieldElement,
            ));
            kid = 0;
            fieldElement = [];
          }
        } else {
          column.add(k);
          row3Obj.add(Container(
            child: k,
          ));
        }

        // if(mid < numValue){
        //   row1Obj.add(k);
        // }else{
        //   row2Obj.add(k);
        // }
        //loadQuestionInTab(mid,k,element);
      }
      mid++;
    }).toList();
    if (column.length != 0) {
      column.add(Flexible(child: SizedBox(
        height: 20,
      )));
      if (widget.buttons != null) {
        if (widget.buttons?.length != 0) {
          setState(() {
            btnContainer = Flexible(
                flex: 1,
                child: Row(
                  children: widget.buttons!,
                ));
          });
        }
      } else {
        btnContainer = Container();
      }
      column.add(Flexible(child: SizedBox(
        height: 5,
      )));

      //column.add(bottomMenuItem());
      if (Responsive.isMobile(context)) {
        column.add(Flexible(child: SizedBox(
          height: 5,
        )));

        //column.add(bottomMenuItem());
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
                flex:8,
                child: Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: FormBuilder(
                    key: widget.formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: column,
                    ),
                  ),
                )),
            SizedBox(
              height: 5,
            ),
            Flexible(child: btnContainer),
            SizedBox(
              height: 5,
            ),
            Flexible(flex: 1, child: bottomMenuItem()),

          ],
        );
      } else {
        //wdtcolumn.add(bottomMenuItem());
        return row1Obj.length != 0
            ?
        TabFormData()
            : Center(
          child: CircularProgressIndicator(),
        );
      }
    } else {
      return Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
  Widget FormWrapData() {
    return FormBuilder(
      key: widget.formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
              flex: 2,
              child: SizedBox(
                child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 10,
                    runSpacing: 10,
                    direction: Axis.horizontal,
                    children:row3Obj
                ),
              )
          ),
          SizedBox(
            height: 20,
          ),
          bottomMenuItem()
        ],
      ),
    );
  }

  Widget TabFormData() {
    return FormBuilder(
      key: widget.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min ,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(

            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                  child: Column(

                mainAxisAlignment: MainAxisAlignment.start,
                children: row1Obj,
              )),
              SizedBox(
                width: 20.0,
              ),
              Flexible(
                  child: Column(

                mainAxisAlignment: MainAxisAlignment.start,
                children: row2Obj,
              )),
              SizedBox(
                width: 20.0,
              ),
              Flexible(
                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.start,
                    children: row4Obj,
                  )),
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Flexible(
                  child: Container()),
              Flexible(
                  child: bottomMenuItem()),
              Flexible(
                  child: Container()),

            ],
          )
        ],
      ),
    );
  }

  Widget bottomMenuItem() {
    return Visibility(
      visible: widget.visibleBtn!,
        child: ButtonComp(width:double.infinity,label:AppTranslations.of(context)!.text("key_btn_proceed"), onPressed: (){
          if (widget.enableBtn!) {
            onSubmitData();
          }
        })
    );
  }

  onSubmitData() {
    setState(() {
      if (widget.formKey.currentState!.saveAndValidate()) {
        Map<String, dynamic> dataobj = {};
        dataobj["id"] = widget.id;
        // widget.formKey.currentState.value.forEach((key, value) {
        //   setState((){
        //     controls[key] = value;
        //   });
        // });
        dataobj["formdata"] = controls;
        widget.callback(dataobj);
      } else {
        showToast(AppTranslations.of(context)!.text("key_message_47"),context:context,position: StyledToastPosition.center);

        //Toast.show("Please enter mandatory fields",  duration: Toast.lengthLong, gravity:  Toast.center);
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  /*
  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.grey[200],
      nextFocus: true,
      actions: [
        KeyboardActionsItem(
          focusNode: _node,
          toolbarButtons: [
            //button 1
                (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "CLOSE",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              );
            },
            //button 2
                (node) {
              return GestureDetector(
                onTap: () => node.unfocus(),
                child: Container(
                  color: Colors.black,
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "DONE",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          ],
        ),
      ],
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    return getQuestion();
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
