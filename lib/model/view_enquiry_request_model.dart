class ViewEnquiryRequestModel {
  bool? read;
  bool? status;

  ViewEnquiryRequestModel({this.read, this.status});

  ViewEnquiryRequestModel.fromJson(Map<String, dynamic> json) {
    read = json['read'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['read'] = this.read;
    data['status'] = this.status;
    return data;
  }
}