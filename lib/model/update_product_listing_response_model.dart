class UpdateProductListingResponseModel {
  int? serialNo;
  String? medicineName;
  String? genericName;
  String? manufacturedBy;
  String? indication;
  String? referenceLink;
  String? medicalField;
  String? summary;
  String? brandNames;
  String? background;
  String? type;
  String? groups;
  String? chemicalFormula;
  String? synonyms;
  String? biologicClassification;
  String? pharmacodynamics;
  String? mechanismOfAction;
  String? absorption;
  String? metabolism;
  String? routeOfElimination;
  String? halfLife;
  String? clearance;
  String? toxicity;
  String? foodInteractions;
  String? drugCategories;
  int? status;
  String? createdDatetime;
  String? updatedDatetime;

  UpdateProductListingResponseModel(
      {this.serialNo,
        this.medicineName,
        this.genericName,
        this.manufacturedBy,
        this.indication,
        this.referenceLink,
        this.medicalField,
        this.summary,
        this.brandNames,
        this.background,
        this.type,
        this.groups,
        this.chemicalFormula,
        this.synonyms,
        this.biologicClassification,
        this.pharmacodynamics,
        this.mechanismOfAction,
        this.absorption,
        this.metabolism,
        this.routeOfElimination,
        this.halfLife,
        this.clearance,
        this.toxicity,
        this.foodInteractions,
        this.drugCategories,
        this.status,
        this.createdDatetime,
        this.updatedDatetime});

  UpdateProductListingResponseModel.fromJson(Map<String, dynamic> json) {
    serialNo = json['serialNo'];
    medicineName = json['medicineName'];
    genericName = json['genericName'];
    manufacturedBy = json['manufacturedBy'];
    indication = json['indication'];
    referenceLink = json['referenceLink'];
    medicalField = json['medicalField'];
    summary = json['summary'];
    brandNames = json['brandNames'];
    background = json['background'];
    type = json['type'];
    groups = json['groups'];
    chemicalFormula = json['chemicalFormula'];
    synonyms = json['synonyms'];
    biologicClassification = json['biologicClassification'];
    pharmacodynamics = json['pharmacodynamics'];
    mechanismOfAction = json['mechanismOfAction'];
    absorption = json['absorption'];
    metabolism = json['metabolism'];
    routeOfElimination = json['routeOfElimination'];
    halfLife = json['halfLife'];
    clearance = json['clearance'];
    toxicity = json['toxicity'];
    foodInteractions = json['foodInteractions'];
    drugCategories = json['drugCategories'];
    status = json['status'];
    createdDatetime = json['createdDatetime'];
    updatedDatetime = json['updatedDatetime'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['serialNo'] = this.serialNo;
    data['medicineName'] = this.medicineName;
    data['genericName'] = this.genericName;
    data['manufacturedBy'] = this.manufacturedBy;
    data['indication'] = this.indication;
    data['referenceLink'] = this.referenceLink;
    data['medicalField'] = this.medicalField;
    data['summary'] = this.summary;
    data['brandNames'] = this.brandNames;
    data['background'] = this.background;
    data['type'] = this.type;
    data['groups'] = this.groups;
    data['chemicalFormula'] = this.chemicalFormula;
    data['synonyms'] = this.synonyms;
    data['biologicClassification'] = this.biologicClassification;
    data['pharmacodynamics'] = this.pharmacodynamics;
    data['mechanismOfAction'] = this.mechanismOfAction;
    data['absorption'] = this.absorption;
    data['metabolism'] = this.metabolism;
    data['routeOfElimination'] = this.routeOfElimination;
    data['halfLife'] = this.halfLife;
    data['clearance'] = this.clearance;
    data['toxicity'] = this.toxicity;
    data['foodInteractions'] = this.foodInteractions;
    data['drugCategories'] = this.drugCategories;
    data['status'] = this.status;
    data['createdDatetime'] = this.createdDatetime;
    data['updatedDatetime'] = this.updatedDatetime;
    return data;
  }
}