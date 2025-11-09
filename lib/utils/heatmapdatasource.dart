import 'dart:math';

import 'package:audit_app/models/reportobj.dart';
import 'package:flutter/material.dart';

class HeatmapDataSource extends DataTableSource{
  List<ReportObj> data;
  HeatmapDataSource(this.data);
  @override
  DataRow? getRow(int index) {
    ReportObj obj = data[index];
    print(obj.toJson());
    List<DataCell> cell = [];
    DataCell col_01 = DataCell(Center(child: Text(obj.zone!)));
    DataCell col_02 = DataCell(Center(child: Text(obj.state!)));
    DataCell col_03 = DataCell(Center(child: Text(obj.total.toString())));
    cell.add(col_01);
    cell.add(col_02);
    cell.add(col_03);
    obj.children!.forEach((kobj){

      int maxIndex = 0;
      Color col = Colors.red;
      if(maxIndex != -1){
        if(maxIndex == 0){
          col = Colors.red;
        }else if(maxIndex == 1){
          col = Colors.orange;
        }else if(maxIndex == 2){
          col = Colors.yellow.shade400;
        }else if(maxIndex == 3){
          col = Colors.green;
        }
      }
      DataCell col_04 = DataCell(Container(
        color: col,
        width: 100,
        child: Center(child: Text("")),
      ));
      cell.add(col_04);
    });
    DataRow row = DataRow(
        cells: cell
    );
    return row;
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => false;

  @override
  // TODO: implement rowCount
  int get rowCount => data.length;

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => 0;

}