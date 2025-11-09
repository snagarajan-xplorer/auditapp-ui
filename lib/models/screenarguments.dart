enum ArgumentData{
  CLIENT,
  USER
}

class ScreenArgument{
  final ArgumentData? argument;
  final String? mode;
  final Map<String,dynamic>? editData;
  final dynamic mapData;
  const ScreenArgument({this.argument, this.mapData,this.mode="Add",this.editData = null});
  factory ScreenArgument.fromJson(Map<String, dynamic> json) {
    return ScreenArgument(
      argument: json['argument'] != null
          ? ArgumentData.values.firstWhere(
            (e) => e.toString().split('.').last == json['argument'],
        orElse: () => ArgumentData.CLIENT, // or null
      )
          : null,
      mode: json['mode'] ?? "Add",
      editData: json['editData'] != null
          ? Map<String, dynamic>.from(json['editData'])
          : null,
      mapData: json['mapData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'argument': argument?.toString().split('.').last,
      'mode': mode,
      'editData': editData,
      'mapData': mapData,
    };
  }
}