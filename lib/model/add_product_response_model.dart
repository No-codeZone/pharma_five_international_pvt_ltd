class AddProductResponseModel {
  int? serialNo;
  String? medicineName;
  String? genericName;
  String? manufacturedBy;
  String? indication;
  String? createdDatetime;
  String? updatedDatetime;

  AddProductResponseModel(
      {this.serialNo,
        this.medicineName,
        this.genericName,
        this.manufacturedBy,
        this.indication,
        this.createdDatetime,
        this.updatedDatetime});

  AddProductResponseModel.fromJson(Map<String, dynamic> json) {
    serialNo = json['serialNo'];
    medicineName = json['medicineName'];
    genericName = json['genericName'];
    manufacturedBy = json['manufacturedBy'];
    indication = json['indication'];
    createdDatetime = json['createdDatetime'];
    updatedDatetime = json['updatedDatetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['serialNo'] = this.serialNo;
    data['medicineName'] = this.medicineName;
    data['genericName'] = this.genericName;
    data['manufacturedBy'] = this.manufacturedBy;
    data['indication'] = this.indication;
    data['createdDatetime'] = this.createdDatetime;
    data['updatedDatetime'] = this.updatedDatetime;
    return data;
  }
}