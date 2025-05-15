class GetFieldProductListingModel {
  int? totalCount;
  List<FieldProducts>? fieldProducts;

  GetFieldProductListingModel({this.totalCount, this.fieldProducts});

  GetFieldProductListingModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['products'] != null) {
      fieldProducts = <FieldProducts>[];
      json['products'].forEach((v) {
        fieldProducts!.add(new FieldProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    if (this.fieldProducts != null) {
      data['products'] = this.fieldProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FieldProducts {
  int? serialNo;
  String? medicineName;
  String? genericName;

  FieldProducts({this.serialNo, this.medicineName, this.genericName});

  FieldProducts.fromJson(Map<String, dynamic> json) {
    serialNo = json['serialNo'];
    medicineName = json['medicineName'];
    genericName = json['genericName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['serialNo'] = this.serialNo;
    data['medicineName'] = this.medicineName;
    data['genericName'] = this.genericName;
    return data;
  }
}