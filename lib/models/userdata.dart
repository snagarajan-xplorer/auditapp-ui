class UserData {
  String? messgae;
  String? token;
  int? userId;
  List<String>? clientid;
  String? parentid;
  String? mvalue;
  String? name;
  String? mobile;
  String? logintime;
  String? email;
  String? image;
  String? changepass;
  String? role;
  String? rolename;

  UserData(
      {this.messgae,
        this.token,
        this.userId,
        this.clientid,
        this.parentid,
        this.logintime,
        this.mvalue,
        this.name,
        this.image,
        this.mobile,
        this.email,
        this.changepass,
        this.rolename,
        this.role});

  UserData.fromJson(Map<String, dynamic> json) {
    messgae = json['messgae'];
    token = json['token'];
    userId = json['user_id'];
    // clientid can be a String ("1" or "1,2") from API, or a List when
    // reloaded from localStorage — handle both safely
    final rawClient = json['clientid'];
    if (rawClient is List) {
      clientid = rawClient.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } else {
      clientid = rawClient?.toString().split(",").map((s) => s.trim()).where((s) => s.isNotEmpty).toList() ?? [];
    }
    parentid = json['parentid'];
    mvalue = json['mvalue'];
    logintime = json['logintime'];
    name = json['name'];
    image = json["image"];
    mobile = json['mobile'];
    email = json['email'];
    changepass = json['changepass'];
    role = json['role'];
    rolename = json['rolename'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['messgae'] = this.messgae;
    data['token'] = this.token;
    data['logintime'] = this.logintime;
    data['user_id'] = this.userId;
    // Store as comma-separated string so fromJson can always parse it correctly
    data['clientid'] = this.clientid?.join(",") ?? "";
    data['parentid'] = this.parentid;
    data['mvalue'] = this.mvalue;
    data['name'] = this.name;
    data['mobile'] = this.mobile;
    data['email'] = this.email;
    data['changepass'] = this.changepass;
    data['role'] = this.role;
    data['rolename'] = this.rolename;
    return data;
  }
}