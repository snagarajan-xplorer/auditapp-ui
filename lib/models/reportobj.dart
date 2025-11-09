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
        children!.add(new Children.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['zone'] = this.zone;
    data['state'] = this.state;
    data['total'] = this.total;
    data['city'] = this.city;
    data['auditname'] = this.auditname;
    data['score'] = this.score;
    data['length'] = this.length;
    data['percentage'] = this.percentage;
    if (this.children != null) {
      data['children'] = this.children!.map((v) => v.toJson()).toList();
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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['key'] = this.key;
    data['value'] = this.value;
    data['scorevalue'] = this.scorevalue;
    data['totalvalue'] = this.totalvalue;
    return data;
  }
}