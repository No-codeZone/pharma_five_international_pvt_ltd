class GetProductSearchResponseModel {
  int? totalCount;
  List<SearchProducts>? searchProducts;

  GetProductSearchResponseModel({this.totalCount, this.searchProducts});

  GetProductSearchResponseModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['products'] != null) {
      searchProducts = <SearchProducts>[];
      json['products'].forEach((v) {
        searchProducts!.add(new SearchProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    if (this.searchProducts != null) {
      data['products'] = this.searchProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SearchProducts {
  int? serialNo;
  String? medicineName;
  String? genericName;

  SearchProducts({this.serialNo, this.medicineName, this.genericName});

  SearchProducts.fromJson(Map<String, dynamic> json) {
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