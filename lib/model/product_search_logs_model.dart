class ProductSearchLogs {
  int? sno;
  String? search;
  String? createdDatetime;

  ProductSearchLogs({this.sno, this.search, this.createdDatetime});

  ProductSearchLogs.fromJson(Map<String, dynamic> json) {
    sno = json['sno'];
    search = json['search'];
    createdDatetime = json['createdDatetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['sno'] = this.sno;
    data['search'] = this.search;
    data['createdDatetime'] = this.createdDatetime;
    return data;
  }
}