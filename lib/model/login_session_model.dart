class LoginSessionModel {
  List<Sessions>? sessions;
  int? totalCount;

  LoginSessionModel({this.sessions, this.totalCount});

  LoginSessionModel.fromJson(Map<String, dynamic> json) {
    if (json['sessions'] != null) {
      sessions = <Sessions>[];
      json['sessions'].forEach((v) {
        sessions!.add(new Sessions.fromJson(v));
      });
    }
    totalCount = json['totalCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.sessions != null) {
      data['sessions'] = this.sessions!.map((v) => v.toJson()).toList();
    }
    data['totalCount'] = this.totalCount;
    return data;
  }
}

class Sessions {
  int? sessionId;
  int? userSno;
  String? name;
  String? email;
  String? loginTime;
  String? logoutTime;
  bool? active;

  Sessions(
      {this.sessionId,
        this.userSno,
        this.name,
        this.email,
        this.loginTime,
        this.logoutTime,
        this.active});

  Sessions.fromJson(Map<String, dynamic> json) {
    sessionId = json['sessionId'];
    userSno = json['userSno'];
    name = json['name'];
    email = json['email'];
    loginTime = json['loginTime'];
    logoutTime = json['logoutTime'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sessionId'] = this.sessionId;
    data['userSno'] = this.userSno;
    data['name'] = this.name;
    data['email'] = this.email;
    data['loginTime'] = this.loginTime;
    data['logoutTime'] = this.logoutTime;
    data['active'] = this.active;
    return data;
  }
}