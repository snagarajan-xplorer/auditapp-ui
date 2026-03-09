class ReportObj {
  String? zone;
  String? state;
  String? city;
  String? auditname;
  int? length;
  double? total;
  double? score;
  int? percentage;
  List<Children>? children;

  ReportObj({this.zone, this.state,this.total, this.children,this.city,this.auditname,this.score,this.percentage});

  ReportObj.fromJson(Map<String, dynamic> json) {
    zone = json['zone'];
    state = json['state'];
    total = json['total']?? 0;
    city = json['city'] ?? "";
    auditname = json['auditname'] ?? "";
    score = json['score'] ?? 0;
    length = json['length'] ?? 0;
    percentage = json['score'] ?? 0;
    if (json['children'] != null) {
      children = <Children>[];
      json['children'].forEach((v) {
        children!.add(Children.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['zone'] = zone;
    data['state'] = state;
    data['total'] = total;
    data['city'] = city;
    data['auditname'] = auditname;
    data['score'] = score;
    data['length'] = length;
    data['percentage'] = percentage;
    if (children != null) {
      data['children'] = children!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Children {
  String? key;
  int? value;
  double? scorevalue;
  double? totalvalue;

  Children({this.key, this.value,this.scorevalue,this.totalvalue});

  Children.fromJson(Map<String, dynamic> json) {
    key = json['key'];
    value = json['value'];
    scorevalue = json['scorevalue'];
    totalvalue = json['totalvalue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    data['scorevalue'] = scorevalue;
    data['totalvalue'] = totalvalue;
    return data;
  }
}