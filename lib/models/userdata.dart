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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['messgae'] = messgae;
    data['token'] = token;
    data['logintime'] = logintime;
    data['user_id'] = userId;
    // Store as comma-separated string so fromJson can always parse it correctly
    data['clientid'] = clientid?.join(",") ?? "";
    data['parentid'] = parentid;
    data['mvalue'] = mvalue;
    data['name'] = name;
    data['image'] = image;
    data['mobile'] = mobile;
    data['email'] = email;
    data['changepass'] = changepass;
    data['role'] = role;
    data['rolename'] = rolename;
    return data;
  }
}