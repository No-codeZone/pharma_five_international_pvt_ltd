/*
class ProductListingResponseModel {
  int? serialNo;
  String? medicineName;
  String? genericName;
  String? manufacturedBy;
  String? indication;
  DateTime? createdDatetime;
  DateTime? updatedDatetime;

  ProductListingResponseModel({
    this.serialNo,
    this.medicineName,
    this.genericName,
    this.manufacturedBy,
    this.indication,
    this.createdDatetime,
    this.updatedDatetime,
  });

  ProductListingResponseModel.fromJson(Map<String, dynamic> json) {
    serialNo = json['serialNo'];
    medicineName = json['medicineName'];
    genericName = json['genericName'];
    manufacturedBy = json['manufacturedBy'];
    indication = json['indication'];
    createdDatetime = DateTime.tryParse(json['createdDatetime'] ?? '');
    updatedDatetime = DateTime.tryParse(json['updatedDatetime'] ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['serialNo'] = serialNo;
    data['medicineName'] = medicineName;
    data['genericName'] = genericName;
    data['manufacturedBy'] = manufacturedBy;
    data['indication'] = indication;
    data['createdDatetime'] = createdDatetime?.toIso8601String();
    data['updatedDatetime'] = updatedDatetime?.toIso8601String();
    return data;
  }
}*/
