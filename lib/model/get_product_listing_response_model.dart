class GetProductListingResponseModel {
  int? totalCount;
  List<GetProducts>? getProducts;

  GetProductListingResponseModel({this.totalCount, this.getProducts});

  GetProductListingResponseModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['products'] != null) {
      getProducts = <GetProducts>[];
      json['products'].forEach((v) {
        getProducts!.add(new GetProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    if (this.getProducts != null) {
      data['products'] = this.getProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GetProducts {
  int? serialNo;
  String? medicineName;
  String? genericName;

  GetProducts({this.serialNo, this.medicineName, this.genericName});

  GetProducts.fromJson(Map<String, dynamic> json) {
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