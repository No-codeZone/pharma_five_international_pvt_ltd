class AllEnquiryResponseModel {
  List<Data>? data;
  String? responseMessage;
  int? totalCount;
  int? responseCode;

  AllEnquiryResponseModel(
      {this.data, this.responseMessage, this.totalCount, this.responseCode});

  AllEnquiryResponseModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    responseMessage = json['responseMessage'];
    totalCount = json['totalCount'];
    responseCode = json['responseCode'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['responseMessage'] = this.responseMessage;
    data['totalCount'] = this.totalCount;
    data['responseCode'] = this.responseCode;
    return data;
  }
}

class Data {
  int? id;
  int? empId;
  String? empName;
  String? medicineName;
  int? status;

  Data({this.id, this.empId, this.empName, this.medicineName, this.status});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    empId = json['empId'];
    empName = json['empName'];
    medicineName = json['medicineName'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['empId'] = this.empId;
    data['empName'] = this.empName;
    data['medicineName'] = this.medicineName;
    data['status'] = this.status;
    return data;
  }
}