class AllEnquiryResponseModel {
  List<AllEnquiry>? data;
  String? responseMessage;
  int? totalCount;
  int? responseCode;

  AllEnquiryResponseModel(
      {this.data, this.responseMessage, this.totalCount, this.responseCode});

  AllEnquiryResponseModel.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <AllEnquiry>[];
      json['data'].forEach((v) {
        data!.add(new AllEnquiry.fromJson(v));
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

class AllEnquiry {
  int? id;
  int? empId;
  String? empName;
  String? medicineName;
  int? status;
  int? read;

  AllEnquiry(
      {this.id,
        this.empId,
        this.empName,
        this.medicineName,
        this.status,
        this.read});

  AllEnquiry.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    empId = json['empId'];
    empName = json['empName'];
    medicineName = json['medicineName'];
    status = json['status'];
    read = json['read'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['empId'] = this.empId;
    data['empName'] = this.empName;
    data['medicineName'] = this.medicineName;
    data['status'] = this.status;
    data['read'] = this.read;
    return data;
  }
}