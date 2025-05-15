class GetProductMoreResponseModel {
  int? totalCount;
  List<GetProductsContent>? getProductsContent;

  GetProductMoreResponseModel({this.totalCount, this.getProductsContent});

  GetProductMoreResponseModel.fromJson(Map<String, dynamic> json) {
    totalCount = json['totalCount'];
    if (json['products'] != null) {
      getProductsContent = <GetProductsContent>[];
      json['products'].forEach((v) {
        getProductsContent!.add(new GetProductsContent.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['totalCount'] = this.totalCount;
    if (this.getProductsContent != null) {
      data['products'] = this.getProductsContent!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class GetProductsContent {
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
  String? createdDatetime;
  String? updatedDatetime;
  List<PackSizes>? packSizes;
  List<DrugInteractions>? drugInteractions;
  List<BrandPrescriptions>? brandPrescriptions;

  GetProductsContent(
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
        this.createdDatetime,
        this.updatedDatetime,
        this.packSizes,
        this.drugInteractions,
        this.brandPrescriptions});

  GetProductsContent.fromJson(Map<String, dynamic> json) {
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
    createdDatetime = json['createdDatetime'];
    updatedDatetime = json['updatedDatetime'];
    if (json['packSizes'] != null) {
      packSizes = <PackSizes>[];
      json['packSizes'].forEach((v) {
        packSizes!.add(new PackSizes.fromJson(v));
      });
    }
    if (json['drugInteractions'] != null) {
      drugInteractions = <DrugInteractions>[];
      json['drugInteractions'].forEach((v) {
        drugInteractions!.add(new DrugInteractions.fromJson(v));
      });
    }
    if (json['brandPrescriptions'] != null) {
      brandPrescriptions = <BrandPrescriptions>[];
      json['brandPrescriptions'].forEach((v) {
        brandPrescriptions!.add(new BrandPrescriptions.fromJson(v));
      });
    }
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
    data['createdDatetime'] = this.createdDatetime;
    data['updatedDatetime'] = this.updatedDatetime;
    if (this.packSizes != null) {
      data['packSizes'] = this.packSizes!.map((v) => v.toJson()).toList();
    }
    if (this.drugInteractions != null) {
      data['drugInteractions'] =
          this.drugInteractions!.map((v) => v.toJson()).toList();
    }
    if (this.brandPrescriptions != null) {
      data['brandPrescriptions'] =
          this.brandPrescriptions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PackSizes {
  int? id;
  String? strength;
  String? packSize;
  String? storage;

  PackSizes({this.id, this.strength, this.packSize, this.storage});

  PackSizes.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    strength = json['strength'];
    packSize = json['packSize'];
    storage = json['storage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['strength'] = this.strength;
    data['packSize'] = this.packSize;
    data['storage'] = this.storage;
    return data;
  }
}

class DrugInteractions {
  int? id;
  String? drug;
  String? interaction;

  DrugInteractions({this.id, this.drug, this.interaction});

  DrugInteractions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    drug = json['drug'];
    interaction = json['interaction'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['drug'] = this.drug;
    data['interaction'] = this.interaction;
    return data;
  }
}

class BrandPrescriptions {
  int? id;
  String? dosage;
  String? strength;
  String? route;
  String? labeller;
  String? marketingStart;
  String? marketingEnd;

  BrandPrescriptions(
      {this.id,
        this.dosage,
        this.strength,
        this.route,
        this.labeller,
        this.marketingStart,
        this.marketingEnd});

  BrandPrescriptions.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dosage = json['dosage'];
    strength = json['strength'];
    route = json['route'];
    labeller = json['labeller'];
    marketingStart = json['marketingStart'];
    marketingEnd = json['marketingEnd'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['dosage'] = this.dosage;
    data['strength'] = this.strength;
    data['route'] = this.route;
    data['labeller'] = this.labeller;
    data['marketingStart'] = this.marketingStart;
    data['marketingEnd'] = this.marketingEnd;
    return data;
  }
}