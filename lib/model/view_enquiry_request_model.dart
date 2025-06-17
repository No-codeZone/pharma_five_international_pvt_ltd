class ViewEnquiryRequestModel {
  int? read;

  ViewEnquiryRequestModel({this.read});

  ViewEnquiryRequestModel.fromJson(Map<String, dynamic> json) {
    read = json['read'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['read'] = this.read;
    return data;
  }
}