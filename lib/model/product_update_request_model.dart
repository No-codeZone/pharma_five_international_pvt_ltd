class ProductUpdateRequestModel {
  int? serialNo;
  String? medicineName;
  String? genericName;
  String? manufacturedBy;
  String? indication;

  ProductUpdateRequestModel(
      {this.serialNo,
        this.medicineName,
        this.genericName,
        this.manufacturedBy,
        this.indication});

  ProductUpdateRequestModel.fromJson(Map<String, dynamic> json) {
    serialNo = json['serialNo'];
    medicineName = json['medicineName'];
    genericName = json['genericName'];
    manufacturedBy = json['manufacturedBy'];
    indication = json['indication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['serialNo'] = this.serialNo;
    data['medicineName'] = this.medicineName;
    data['genericName'] = this.genericName;
    data['manufacturedBy'] = this.manufacturedBy;
    data['indication'] = this.indication;
    return data;
  }
}