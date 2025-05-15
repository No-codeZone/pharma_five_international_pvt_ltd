class RequestEnquiryModel {
  int? empId;
  int? productId;

  RequestEnquiryModel({this.empId, this.productId});

  RequestEnquiryModel.fromJson(Map<String, dynamic> json) {
    empId = json['empId'];
    productId = json['productId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['empId'] = this.empId;
    data['productId'] = this.productId;
    return data;
  }
}