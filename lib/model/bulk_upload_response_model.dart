class BulkUploadResponseModel {
  int? responseCode;
  String? responseMessage;

  BulkUploadResponseModel({this.responseCode, this.responseMessage});

  BulkUploadResponseModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['responseCode'];
    responseMessage = json['responseMessage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['responseCode'] = this.responseCode;
    data['responseMessage'] = this.responseMessage;
    return data;
  }
}