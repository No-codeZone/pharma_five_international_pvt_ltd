class ProductSearchLogsModel {
  final String? search;
  final int? count;

  ProductSearchLogsModel({this.search, this.count});

  factory ProductSearchLogsModel.fromJson(Map<String, dynamic> json) {
    return ProductSearchLogsModel(
      search: json['search'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() => {
    'search': search,
    'count': count,
  };
}