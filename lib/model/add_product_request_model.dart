class AddProductRequestModel {
  String? medicineName;
  String? genericName;
  String? manufacturedBy;
  String? indication;

  AddProductRequestModel(
      {this.medicineName,
        this.genericName,
        this.manufacturedBy,
        this.indication});

  AddProductRequestModel.fromJson(Map<String, dynamic> json) {
    medicineName = json['medicineName'];
    genericName = json['genericName'];
    manufacturedBy = json['manufacturedBy'];
    indication = json['indication'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['medicineName'] = this.medicineName;
    data['genericName'] = this.genericName;
    data['manufacturedBy'] = this.manufacturedBy;
    data['indication'] = this.indication;
    return data;
  }
}