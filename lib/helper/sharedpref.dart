// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:societymanagement/commonscreen/login.dart';
// import 'package:societymanagement/modal/FlatTypeResponseModal.dart';
// import 'package:societymanagement/modal/GetAdditionalMemberListForList.dart';
// import 'package:societymanagement/modal/GetFlatModal.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:async';
// import 'package:http/http.dart' as http;
// import 'package:societymanagement/modal/GetSingleFlatModal.dart';
// import 'package:societymanagement/modal/GetSubRolesListModal.dart';
// import 'package:societymanagement/modal/PrimaryMemberListModal.dart';
// import 'package:societymanagement/modal/SocietyGeographyModal.dart';
// import 'package:societymanagement/modal/StaffListModal.dart';
// import 'package:societymanagement/modal/UploadSocietyImageResponsemodal.dart';
// import 'package:societymanagement/modal/VisitorCategoryModal.dart';
// import 'package:societymanagement/modal/app_version_modal.dart';
// import 'package:societymanagement/modal/generatepasswordmodal.dart';
// import 'package:societymanagement/modal/guestListModal.dart';
// import 'package:societymanagement/modal/societyoffer_modal.dart';
// import 'package:societymanagement/network/modal/rewrite_modal.dart';
// import 'package:societymanagement/services/SessionManager.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../helper/color.dart';
// import '../modal/ApprovalModal.dart';
// import '../modal/ApproveCoResidentModal.dart';
// import '../modal/CommentLogModals.dart';
// import '../modal/CreateFlatAdditionalMemberModal.dart';
// import '../modal/CreateFlatMemberResponseModal.dart';
// import '../modal/CreateManagementRoleModal.dart';
// import '../modal/CreateSocietymanagementUserModal.dart';
// import '../modal/CreateSocityAdminResponseModal.dart';
// import '../modal/CreateSocityResponseModal.dart';
// import '../modal/CreateStaffResponseModal.dart';
// import '../modal/CreateSubRoleModal.dart';
// import '../modal/CreateUpdateNotificationModal.dart';
// import '../modal/CreateUpdateOfferModal.dart';
// import '../modal/FlatTypeListResponseModal.dart';
// import '../modal/FlatTypeModel.dart';
// import '../modal/ForgotPasswordResponseModal.dart';
// import '../modal/GetPrimaryMemberListForList.dart';
// import '../modal/GetSingleFlatModal.dart';
// import '../modal/GetSingleGuestByMobileModal.dart';
// import '../modal/GetSingleSocietyByIdModals.dart';
// import '../modal/GetSocietyBlocModal.dart';
// import '../modal/GetUserSocietyAdminModal.dart';
// import '../modal/LoginResponseModal.dart';
// import '../modal/ManagementRoleListModal.dart';
// import '../modal/ModelGetSocietyBlockFloors.dart';
// import '../modal/PhoneNumberUpdateSendOTPModal.dart';
// import '../modal/RolesListModal.dart';
// import '../modal/SendNotificationModal.dart';
// import '../modal/SendNotificationSocietyAdminModal.dart';
// import '../modal/SocietyAdminListModal.dart';
// import '../modal/SocietyImagesModal.dart';
// import '../modal/SosNotificationResponseModal.dart';
// import '../modal/UpdateFlatModal.dart';
// import '../modal/UpdatePhoneNumberVerifyOTPModal.dart';
// import '../modal/UpdateSocietyResponseModal.dart';
// import '../modal/addnoticemodal.dart';
// import '../modal/changePasswordResponseModal.dart';
// import '../modal/comlaintListModal.dart';
// import '../modal/create_update_intrest_modal.dart';
// import '../modal/deleteSocietyModal.dart';
// import '../modal/getSocietyManagementUsersModal.dart';
// import '../modal/guestListResponseModal.dart';
// import '../modal/intrestModal.dart';
// import '../modal/intrest_modal.dart';
// import '../modal/loginViaOtpResponseModal.dart';
// import '../modal/logoutModal.dart';
// import '../modal/noticelistmodal.dart';
// import '../modal/privacyandtermsmodal.dart';
// import '../modal/sendOtpResponseModal.dart';
// import '../modal/signinsignoutmodal.dart';
// import '../modal/updateMemberModal.dart';
// import '../modal/updatePhoneResidentModal.dart';
// import '../modal/updateProfileModal.dart';
// import '../modal/updateSubRoleModal.dart';
// import '../modal/userDetailsModal.dart';
// import '../modal/verifyotpResponseModal.dart';
// import '../modal/verifyuserflatmodal.dart';
// import 'BaseUrl.dart';
//
// class Restapi {
//   static late String? flatIdForApi = '';
//   static late String? roleIdForApi = '';
//   static late String? subroleIdForApi = '';
//   static late String? socityIdForApi = '';
//   static late String? primmarymemberIdForApi = '';
//   static late String? SocietyManagementRolesIdForApi = '';
//   static late String? SocietyBlockIdForApi = '';
//   static late String? FlatTypeIdForApi = '';
//   static late String? FloorIdForApi = '';
//   static int flatId = 0;
//   static int sblockId = 0;
//   static int flattypeId = 0;
//   static int roleId = 0;
//   static int subroleId = 0;
//   static int societyId = 0;
//   static int primaryMemberId = 0;
//   static int smId = 0;
//   static int floornoid = 1;
//   static String floornoids = '1';
//   static List<String> dataOfFlats = ['No Flats'];
//   static List<String> dataOfIntrest = ['Interests'];
//   static List<String?> dataOfFlatNo = ['Select Flats'];
//   static List<String?> dataOfFlatBloc = ['Select Flats'];
//   static List<String> dataOfFlatss = ['Select Flats'];
//   static List<String> dataOfSociety = ['Select Society'];
//   static List<String> dataOfSocietyblock = ['Select Block'];
//   static List<String> dataOfFlatType = ['Select Flat Type'];
//   static List<String> dataOfFloorNo = ['Floor No'];
//   static List<String> dataOfPrimaryMembersdropdown = ['Select Members'];
//   static List<dynamic> dataOfPrimaryMembers = [''];
//   static List<dynamic> dataOfSocietyMembers = [''];
//   static List<String> dataOfManagementRoles = [''];
//   static List<dynamic> dataOfSocietyAdminUser = [''];
//   static List<dynamic> dataOfAdditionalMembers = [''];
//   static List<int> dataOfFlatId = [0];
//   static List<String> dataOfFlatIds = ['0'];
//   static List<String> dataOfIntrestIds = ['0'];
//   static List<int> dataOfManagementRoleId = [0];
//   static List<int> dataOfsocietyId = [0];
//   static List<String> dataOfPrimaryMembersId = ['0'];
//   static List<String> dataOfRoles = ['Select Staff SRole'];
//   static List<String> dataOfroleId = ['0'];
//   static List<String> dataOfsubRoles = ['Select Sub Role'];
//   static List<int> dataOfsubroleId = [0];
//   static List<int> dataOfsocietyblockid = [0];
//   static List<int> dataOfflattypeid = [0];
//   static List<String> dataOfflattypeidString = ['0'];
//   static List<int> dataOffloornoid = [0];
//   static List<String> dataOffloornoidString = ['0'];
//   Future<String?> getImageBase64(String imageUrl) async {
//     try {
//       showProgress();
//       http.Response response = await http.get(Uri.parse(imageUrl));
//       final bytes = response.bodyBytes;
//       hideProgress();
//       return (base64Encode(bytes));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static launchURL(String urls) async {
//     try {
//       final Uri url = Uri.parse(urls);
//       if (!await launchUrl(url)) {
//         throw Exception('Could not launch $url');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<intrestModal> getInterest() async {
//     try {
//       dataOfIntrest.clear();
//       dataOfIntrestIds.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       //    String? urlSession = prefs.getString('url');
//       //     final uri = Uri.parse(
//       //         "$urlSession${AppConstant.getIncidentsSummary}?CustomerId=$customerIdForApi");
//       // var uri = Uri.http(BaseUrl.BaseUrlForOther, BaseUrl.getInterest);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.getInterest);
//       showProgress();
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       // print(uri);
//       // print(response.body);
//       hideProgress();
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         Map<String, dynamic> map = resBody;
//         if (map['result'] != null) {
//           List<dynamic> data = map['result'];
//           for (int i = 0; i < data.length; i++) {
//             if (data[i]['title'] != null) {
//               dataOfIntrest.add(data[i]['title']);
//               // Map<String, dynamic> json = {
//               //   'Id': data[i]['id'].toString(),
//               //   "Title": data[i]['title'].toString(),
//               //   "UserId": data[i]['createdDatetime'].toString(),
//               // };
//               dataOfIntrestIds.add(data[i]['id'].toString());
//             }
//           }
//         }
//         return intrestModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<GetFlatModal> getFlatData(String societId) async {
//     //debugPrint('countForFlat');
//     try {
//       dataOfFlatIds.clear();
//       dataOfFlatId.clear();
//       dataOfFlats.clear();
//       dataOfFlatss.clear();
//       dataOfFlatBloc.clear();
//       dataOfFlatNo.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getFaltUrl}?societyId=$societId");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint('-----Get Flats-------');
//       debugPrint(response.body);
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         Map<String, dynamic> map = resBody;
//         if (map['result'] != null) {
//           List<dynamic> data = map['result'];
//           for (int i = 0; i < data.length; i++) {
//             if (data[i]['blockName'] != null) {
//               dataOfFlats
//                   .add(data[i]['blockName'] + '-' + data[i]['flatNumber']);
//               dataOfFlatNo.add(data[i]['flatNumber']);
//               dataOfFlatBloc.add(data[i]['blockName']);
//               dataOfFlatss.add(data[i]['blockName'] +
//                   '-' +
//                   data[i]['flatNumber'] +
//                   '#' +
//                   data[i]['id'].toString());
//               dataOfFlatId.add(data[i]['id']);
//
//               dataOfFlatIds.add(data[i]['id'].toString());
//             }
//           }
//         }
//         return GetFlatModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   /*===============Get Flat Data For Visitors============*/
//
//   /*Variables for current visitor data*/
//   static List<int> dataOfFlatIdCurrentTabVisitor = [0];
//   static List<String> dataOfBlocksCurrentTabVisitor = ['0'];
//   static List<String> dataOfFlatNoCurrentTabVisitor = ['0'];
//   static List<String> dataOfFlatBlockNoCurrentTabVisitor = ['0'];
//   static int flatIdvisitorcurrentTab = 0;
//   static late String? flatIdForApiVisitorcurrentTab = '';
//   /*Variables for current visitor data*/
//   static Future<GetFlatModal> getFlatDropdownDataForCurrentVisitorTab(
//       String societyId) async {
//     //debugPrint('countForFlat');
//     try {
//       dataOfFlatIdCurrentTabVisitor.clear();
//       dataOfBlocksCurrentTabVisitor.clear();
//       dataOfFlatNoCurrentTabVisitor.clear();
//       dataOfFlatBlockNoCurrentTabVisitor.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getFaltUrl}?societyId=$societyId");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint('-----Get Flats Visitor Current Tab-------');
//       debugPrint(response.body);
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         Map<String, dynamic> map = resBody;
//         if (map['result'] != null) {
//           List<dynamic> data = map['result'];
//           for (int i = 0; i < data.length; i++) {
//             if (data[i]['blockName'] != null) {
//               dataOfFlatBlockNoCurrentTabVisitor
//                   .add(data[i]['blockName'] + '-' + data[i]['flatNumber']);
//               dataOfFlatNoCurrentTabVisitor.add(data[i]['flatNumber']);
//               dataOfBlocksCurrentTabVisitor.add(data[i]['blockName']);
//               dataOfFlatIdCurrentTabVisitor.add(data[i]['id']);
//             }
//           }
//         }
//         return GetFlatModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   /*Variables for history visitor data*/
//   static List<int> dataOfFlatIdHistoryTabVisitor = [0];
//   static List<String> dataOfBlocksHistoryTabVisitor = ['0'];
//   static List<String> dataOfFlatNoHistoryTabVisitor = ['0'];
//   static List<String> dataOfFlatBlockNoHistoryTabVisitor = ['0'];
//   static int flatIdvisitorhistoryTab = 0;
//   static late String? flatIdForApiVisitorhistoryTab = '';
//   /*Variables for history visitor data*/
//
//   static Future<GetFlatModal> getFlatDropdownDataForHistoryVisitorTab(
//       String societyId) async {
//     //debugPrint('countForFlat');
//     try {
//       dataOfFlatIdHistoryTabVisitor.clear();
//       dataOfBlocksHistoryTabVisitor.clear();
//       dataOfFlatNoHistoryTabVisitor.clear();
//       dataOfFlatBlockNoHistoryTabVisitor.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getFaltUrl}?societyId=$societyId");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint('-----Get Flats Visitor Current Tab-------');
//       debugPrint(response.body);
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         Map<String, dynamic> map = resBody;
//         if (map['result'] != null) {
//           List<dynamic> data = map['result'];
//           for (int i = 0; i < data.length; i++) {
//             if (data[i]['blockName'] != null) {
//               dataOfFlatBlockNoHistoryTabVisitor
//                   .add(data[i]['blockName'] + '-' + data[i]['flatNumber']);
//               dataOfFlatNoHistoryTabVisitor.add(data[i]['flatNumber']);
//               dataOfBlocksHistoryTabVisitor.add(data[i]['blockName']);
//               dataOfFlatIdHistoryTabVisitor.add(data[i]['id']);
//             }
//           }
//         }
//         return GetFlatModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   /*Variables for history visitor data*/
//   static List<int> dataOfFlatIdUpcomingTabVisitor = [0];
//   static List<String> dataOfBlocksUpcomingTabVisitor = ['0'];
//   static List<String> dataOfFlatNoUpcomingTabVisitor = ['0'];
//   static List<String> dataOfFlatBlockNoUpcomingTabVisitor = ['0'];
//   static int flatIdvisitorupcomingTab = 0;
//   static late String? flatIdForApiVisitorupcomingTab = '';
//   /*Variables for history visitor data*/
//
//   static Future<GetFlatModal> getFlatDropdownDataForUpcomingVisitorTab(
//       String societyId) async {
//     //debugPrint('countForFlat');
//     try {
//       dataOfFlatIdUpcomingTabVisitor.clear();
//       dataOfBlocksUpcomingTabVisitor.clear();
//       dataOfFlatNoUpcomingTabVisitor.clear();
//       dataOfFlatBlockNoUpcomingTabVisitor.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getFaltUrl}?societyId=$societyId");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint('-----Get Flats Visitor Current Tab-------');
//       debugPrint(response.body);
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         Map<String, dynamic> map = resBody;
//         if (map['result'] != null) {
//           List<dynamic> data = map['result'];
//           for (int i = 0; i < data.length; i++) {
//             if (data[i]['blockName'] != null) {
//               dataOfFlatBlockNoUpcomingTabVisitor
//                   .add(data[i]['blockName'] + '-' + data[i]['flatNumber']);
//               dataOfFlatNoUpcomingTabVisitor.add(data[i]['flatNumber']);
//               dataOfBlocksUpcomingTabVisitor.add(data[i]['blockName']);
//               dataOfFlatIdUpcomingTabVisitor.add(data[i]['id']);
//             }
//           }
//         }
//         return GetFlatModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   /*===============Get Flat Data For Visitors End Here============*/
//
//   static Future<StaffListModal> getStaffList(String sId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           '${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetStaffList}?SocietyId=$sId');
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       // debugPrint(response.body );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return StaffListModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<IntrestModal> getIntrestList() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.getInterestList);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return IntrestModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateUpdateIntrestModal> createIntrest(String title) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {"Id": '0', "Title": title};
//       final jsonString = json.encode(body);
//       showProgress();
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateInterest);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateUpdateIntrestModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<GetFlatModal> getFlatForSocietyAdmin(
//       String societyId, String blockId) async {
//     try {
//       dataOfFlatIds.clear();
//       dataOfFlatId.clear();
//       dataOfFlats.clear();
//       dataOfFlatss.clear();
//       dataOfFlatBloc.clear();
//       dataOfFlatNo.clear();
//       final queryParameters = {
//         'societyId': societyId,
//         'BlockId': blockId,
//       };
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getFlatForSocietyAdmin}?societyId=$societyId&BlockId=$blockId");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         Map<String, dynamic> map = resBody;
//         if (map['result'] != '[]') {
//           List<dynamic> data = map['result'];
//           for (int i = 0; i < data.length; i++) {
//             if (data[i]['blockName'] != null) {
//               dataOfFlats
//                   .add(data[i]['blockName'] + '-' + data[i]['flatNumber']);
//               dataOfFlatNo.add(data[i]['flatNumber']);
//               dataOfFlatBloc.add(data[i]['blockName']);
//               dataOfFlatss.add(data[i]['blockName'] +
//                   '-' +
//                   data[i]['flatNumber'] +
//                   '#' +
//                   data[i]['id'].toString());
//               dataOfFlatId.add(data[i]['id']);
//
//               dataOfFlatIds.add(data[i]['id'].toString());
//             }
//           }
//         }
//         return GetFlatModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<RoleListModal> getRoleList() async {
//     try {
//       dataOfRoles.clear();
//       dataOfroleId.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.GetRolesList);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         if (resBody['result'][0]['name'] != null) {
//           dataOfRoles.add(resBody['result'][0]['name']);
//           dataOfroleId.add(resBody['result'][0]['id']);
//         }
//         return RoleListModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<RoleListModal> getRoleListmain() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.GetRolesList);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return RoleListModal.fromJson(resBody);
//       } else {
//         throw Exception('No data');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<GetSubRolesListModal> getSubRoleList() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.GetSubRolesList);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       dataOfsubroleId.clear();
//       dataOfsubRoles.clear();
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         print(resBody);
//         for (int i = 0; i < resBody['result'].length; i++) {
//           if (resBody['result'][i]['name'] != null) {
//             dataOfsubRoles.add(resBody['result'][i]['name']);
//             dataOfsubroleId.add(resBody['result'][i]['id']);
//           }
//         }
//         return GetSubRolesListModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<PrimaryMemberListModal> getPrimaryMember(String flatId) async {
//     try {
//       final queryParameters = {
//         'FlatId': flatId,
//       };
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetPrimaryMember}?FlatId=$flatId");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       // print(uri);
//       // print(response.body);
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return PrimaryMemberListModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<GetPrimaryMemberListForList> getPrimaryMemberList(
//       String sId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           '${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetPrimaryMemberList}?SocietyId=$sId');
//
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint('Resident List');
//       debugPrint(response.body.toString());
//       debugPrint(response.statusCode.toString());
//       if (response.statusCode == 200) {
//         return GetPrimaryMemberListForList.fromJson(json.decode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<GetPrimaryMemberListForList> getPrimaryMemberDropDownList(
//       String sId) async {
//     try {
//       dataOfPrimaryMembers.clear();
//       dataOfPrimaryMembersId.clear();
//       dataOfPrimaryMembersdropdown.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       log(token.toString());
//       final uri = Uri.parse(
//           '${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetPrimaryMemberList}?SocietyId=$sId');
//       // print(uri);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       log(response.body);
//
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         dataOfPrimaryMembers.add(resBody['result']);
//         if (resBody['result'] != '[]') {
//           for (int i = 0; i < resBody['result'].length; i++) {
//             if (resBody['result'][i]['firstName'] != null) {
//               dataOfPrimaryMembersdropdown.add(resBody['result'][i]
//               ['firstName'] +
//                   " (" +
//                   resBody['result'][i]['blockName'] +
//                   '-' +
//                   resBody['result'][i]['flatNumber'] +
//                   ")");
//               dataOfPrimaryMembersId.add(resBody['result'][i]['id']);
//             }
//           }
//         } else {}
//         return GetPrimaryMemberListForList.fromJson(json.decode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<SocietyAdminListModal> getSocieties() async {
//     try {
//       dataOfSocietyMembers.clear();
//       dataOfSociety.clear();
//       dataOfsocietyId.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.GetSocietyList);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         dataOfSocietyMembers = resBody['result'];
//         for (int i = 0; i < resBody['result'].length; i++) {
//           if (resBody['result'][i]['societyName'] != null) {
//             dataOfSociety.add(resBody['result'][i]['societyName']);
//             dataOfsocietyId.add(resBody['result'][i]['id']);
//           }
//         }
//         return SocietyAdminListModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<ManagementRoleListModal> getManagementRoleList() async {
//     try {
//       dataOfManagementRoles.clear();
//       dataOfManagementRoleId.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.GetSocietyManagementRoles);
//
//
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       log(uri.toString());
//       log(response.body);
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         for (int i = 0; i < resBody['result'].length; i++) {
//           dataOfManagementRoles.add(resBody['result'][i]['roleName']);
//           dataOfManagementRoleId.add(resBody['result'][i]['id']);
//         }
//         return ManagementRoleListModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<GetAdditionalMemberListForList> getAdditionalMemberList(
//       String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final queryParameters = {
//         'PrimarymemberId': id,
//       };
//
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetAdditionalMember}?PrimarymemberId=$id");
//       print(uri);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         //print(resBody['result'].length);
//         return GetAdditionalMemberListForList.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<GetUserSocietyAdminModal> getUserSocietyAdminModal(
//       String sid) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetSocietyAdmin}?societyId=$sid");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return GetUserSocietyAdminModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<GetSingleSocietyByIdModals> getSingleSocietyById(sAid) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       showProgress();
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getSingleSocietyById}?Id=$sAid");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return GetSingleSocietyByIdModals.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<getSocietyManagementUsersModal> getSocietyManagementUsers(sAid) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getSocietyManagementUsers}?SocietyId=$sAid");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return getSocietyManagementUsersModal
//             .fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<userDetailsModal> getUserDetails(uid) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getUserById}?UserId=$uid");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return userDetailsModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<guestListModal> getguestListModal(flatid) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getUserById}?Id=$flatid");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return guestListModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<LoginResponseModal> loginRequest(
//       String username, String password) async {
//     try {
//       final url = Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.loginUrl);
//       Map<String, String> headers = {
//         'Content-Type': 'application/json',
//         'authorization': 'Basic c3R1ZHlkb3RlOnN0dWR5ZG90ZTEyMw=='
//       };
//       final msg = jsonEncode({"UserName": username, "Password": password});
//
//       showProgress();
//       final response = await post(url, headers: headers, body: msg).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       debugPrint(response.body);
//       if (response.statusCode == 400) {
//         Get.showSnackbar(
//           const GetSnackBar(
//             title: 'Error',
//             message: 'something went wrong !',
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//       return LoginResponseModal.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<sendotpResponseModal> sendOTPRequest(String mobileNo) async {
//     try {
//       final url = Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.sendOTP);
//       Map<String, String> headers = {'Content-Type': 'application/json'};
//       final msg = jsonEncode({
//         "mobileNumber": mobileNo,
//       });
//       showProgress();
//       final response = await post(url, headers: headers, body: msg).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 400) {
//         Get.showSnackbar(
//           const GetSnackBar(
//             title: 'Error',
//             message: 'something went wrong !',
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//       return sendotpResponseModal.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<PhoneNumberUpdateSendOTPModal> PhoneNumberUpdateSendOTP(
//       String oldPhoneno, String mobileNo) async {
//     try {
//       final url = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.PhoneNumberUpdateSendOTP);
//       Map<String, String> headers = {'Content-Type': 'application/json'};
//       final msg = jsonEncode(
//           {"id": 0, "oldPhoneNumber": oldPhoneno, "newPhoneNumber": mobileNo});
//       showProgress();
//       final response = await post(url, headers: headers, body: msg).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 400) {
//         Get.showSnackbar(
//           const GetSnackBar(
//             title: 'Error',
//             message: 'something went wrong !',
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//       return PhoneNumberUpdateSendOTPModal.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<loginViaOtpResponse> loginviaOTPRequest(
//       String userHashcode, String otp) async {
//     try {
//       final url =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.loginViaOTP);
//       Map<String, String> headers = {'Content-Type': 'application/json'};
//       showProgress();
//       final msg = jsonEncode({"userHashCode": userHashcode, "otp": otp});
//       final response = await post(url, headers: headers, body: msg).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 400) {
//         Get.showSnackbar(
//           const GetSnackBar(
//             title: 'Error',
//             message: 'something went wrong !',
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//       return loginViaOtpResponse.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<UpdateSocietyResponseModal> updateSocietyRequest(
//       String id,
//       String sname,
//       String pNo,
//       String address,
//       String email,
//       String helplinNo,
//       String builder,
//       String societycreatedbyid,
//       String createdDate,
//       String flats,
//       String sImage) async {
//     try {
//       final body = {
//         "Id": id,
//         "SocityName": sname,
//         "Address": address,
//         "PhoneNumber": pNo,
//         "Email": email,
//         "HelplineNumber": helplinNo,
//         "Builder": builder,
//         "SocityCreatedById": societycreatedbyid,
//         "Logo": sImage
//       };
//       final jsonString = json.encode(body);
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       var uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.updateSociety);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer ${token!}',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return UpdateSocietyResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateSocityResponseModal> createFlat(
//       String blockId,
//       String siD,
//       String flatNo,
//       String floor,
//       String parkingZone,
//       String fTypeid,
//       String sba,
//       String ca) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "id": 0,
//         "blockId": blockId,
//         "societyId": siD,
//         "flatNumber": flatNo,
//         "floor": floor,
//         "parkingZone": parkingZone,
//         "flatTypeId": fTypeid,
//         "superBuildUpArea": sba,
//         "carpetArea": ca
//       };
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateFlat);
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer ${token!}',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocityResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<UpdateFlatModal> updateFlat(
//       String id,
//       String blockId,
//       String siD,
//       String flatNo,
//       String floor,
//       String parkingZone,
//       String fTypeid,
//       String sba,
//       String ca) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "Id": id,
//         "blockId": blockId,
//         "societyId": siD,
//         "flatNumber": flatNo,
//         "floor": floor,
//         "parkingZone": parkingZone,
//         "flatTypeId": fTypeid,
//         "superBuildUpArea": sba,
//         "carpetArea": ca
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.updateFlat);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return UpdateFlatModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<UpdateSubRoleModal> updateSubRole(
//       String srId, String subRoleName) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? userid = prefs.getString('userID');
//       final body = {"Id": srId, "Name": subRoleName, "AspNetRoleId": userid};
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.updateSubRole);
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return UpdateSubRoleModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateManagementRoleModal> updateManagementRoles(
//       String srId, String managementRoleName) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "roleName": managementRoleName,
//         "isActive": true,
//         "id": srId
//       };
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateManagementRoles);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return CreateManagementRoleModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateFlatMemberResponseModal> CreateUpdateResident(
//       String image,
//       String firstName,
//       String lastName,
//       String Email,
//       String Address,
//       String dob,
//       String phoneNumber,
//       String wpNumber,
//       String flatNo,
//       String Gender,
//       String sId,
//       ) async {
//     try {
//       final body = {
//         "id": "",
//         "email": Email,
//         "firstName": firstName,
//         "lastName": lastName,
//         "gender": Gender,
//         "whatsAppNumber": wpNumber,
//         "phoneNumber": phoneNumber,
//         "dob": dob,
//         "flatId": int.parse(flatNo),
//         "societyId": int.parse(sId),
//         "image": image,
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateResident);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateFlatMemberResponseModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateStaffResponseModal> CreateStaff(
//       String Email,
//       String Password,
//       String ConfirmPassword,
//       String FirstName,
//       String LastName,
//       String PhoneNumber,
//       String Address,
//       String RoleName,
//       String Gender,
//       String Image,
//       String Dob,
//       String WhatsAppNumber,
//       String SubRoleId,
//       String SocietyId) async {
//     try {
//       final body = {
//         "id": "",
//         "email": Email,
//         "password": Password,
//         "confirmPassword": ConfirmPassword,
//         "userName": PhoneNumber,
//         "firstName": FirstName,
//         "lastName": LastName,
//         "phoneNumber": PhoneNumber,
//         "address": Address,
//         "dob": Dob,
//         "gender": Gender,
//         "whatsAppNumber": WhatsAppNumber,
//         "subRoleId": SubRoleId,
//         "societyId": SocietyId,
//         "image": Image
//       };
//       final jsonString = json.encode(body);
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       showProgress();
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateStaff);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateStaffResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateStaffResponseModal> UpdateStaff(
//       String id,
//       String Email,
//       String FirstName,
//       String LastName,
//       String PhoneNumber,
//       String Address,
//       String RoleName,
//       String Gender,
//       String Image,
//       String Dob,
//       String WhatsAppNumber,
//       String SubRoleId,
//       String SocietyId) async {
//     try {
//       final body = {
//         "id": id,
//         "email": Email,
//         "password": 'Pass@123',
//         "confirmPassword": 'Pass@123',
//         "userName": PhoneNumber,
//         "firstName": FirstName,
//         "lastName": LastName,
//         "phoneNumber": PhoneNumber,
//         "address": Address,
//         "dob": Dob,
//         "gender": Gender,
//         "whatsAppNumber": WhatsAppNumber,
//         "subRoleId": SubRoleId,
//         "societyId": SocietyId,
//         "image": Image
//       };
//       final jsonString = json.encode(body);
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       showProgress();
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateStaff);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateStaffResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateFlatAdditionalMemberModal> CreateUpdateCoResident(
//       String firstName,
//       String lastName,
//       String email,
//       String phoneNumber,
//       String wpNumber,
//       String gender,
//       String userReferenceId,
//       String image,
//       String dob,
//       String pid) async {
//     try {
//       final body = {
//         "id": "",
//         "Email": email,
//         "FirstName": firstName,
//         "LastName": lastName,
//         "Gender": gender,
//         "PhoneNumber": phoneNumber,
//         "DOB": dob,
//         "Image": image,
//         "WhatsAppNumber": wpNumber,
//         "UserReferenceId": pid,
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateCoResident);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateFlatAdditionalMemberModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateSocietymanagementUserModal> CreateUpdateManagementUser(
//       String pmId, String sId, String smrId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "Id": 0,
//         "UserId": pmId,
//         "CreatedById": "",
//         "SocietyId": sId,
//         "SocietyManagementRoleId": smrId
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateManagementUser);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocietymanagementUserModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateSocityAdminResponseModal> createSocityAdmin(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "userId": id,
//       };
//       showProgress();
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup +
//           BaseUrl.CreateSocietyAdmin +
//           '?' +
//           "userId=$id" +
//           "&IsActive=true");
//       var response = await http.post(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       });
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocityAdminResponseModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateSocityAdminResponseModal> updateSocityAdmin(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       showProgress();
//       final uri = Uri.parse(
//           '${BaseUrl.BaseUrlForloginsignup}${BaseUrl.updateSocietyAdmin}?userId=$id&IsActive=false');
//       var response = await http.post(
//         uri,
//         headers: {
//           HttpHeaders.authorizationHeader: 'Bearer $token',
//           HttpHeaders.contentTypeHeader: 'application/json',
//         },
//       ).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocityAdminResponseModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateSocityResponseModal> processSocietyGuestsRequest(
//       String? fullName,
//       String? address,
//       String? purpose,
//       String? vehicleNo,
//       String? contactNumber,
//       String? image,
//       String? sId,
//       String? fid,
//       String? approval,
//       String meetingRequestApprovalStatus,
//       String isAdavnceApproved,
//       String checkInDate,
//       String checkInTime,
//       String selectedcategoriesData,
//       ) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? userid = prefs.getString('userID');
//       final body = {
//         "id": 0,
//         "name": fullName,
//         "address": address,
//         "phoneNumber": contactNumber,
//         "idProofImage": '',
//         "image": image,
//         "purposeToMeet": purpose,
//         "meetingRequestApprovalStatus": true,
//         "requestApprovedById": userid,
//         "checkInDate": checkInDate,
//         "checkInTime": checkInTime,
//         "isAdavnceApproved": true,
//         "vechicalNumber": vehicleNo,
//         "visitingFlatId": fid,
//         "societyID": sId,
//         "blockId": 0,
//         "visitorCategoriesId": selectedcategoriesData
//       };
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.processsocietyguestsRequest);
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocityResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
// //---------------- For guard
//
//   Future<CreateSocityResponseModal> processSocietyGuestsRequestGuard(
//       String? fullName,
//       String? address,
//       String? purpose,
//       String? vehicleNo,
//       String? contactNumber,
//       String? image,
//       String? sId,
//       String? fid,
//       String? approval,
//       String meetingRequestApprovalStatus,
//       String isAdavnceApproved,
//       String checkInDate,
//       String checkInTime,
//       String selectedcategoriesData,
//       ) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? userid = prefs.getString('userID');
//       final body = {
//         "id": 0,
//         "name": fullName,
//         "address": address,
//         "phoneNumber": contactNumber,
//         "idProofImage": '',
//         "image": image,
//         "purposeToMeet": purpose,
//         "meetingRequestApprovalStatus": false,
//         "requestApprovedById": userid,
//         "requestGeneratedById": "",
//         "checkInDate": checkInDate,
//         "checkInTime": checkInTime,
//         "isAdavnceApproved": false,
//         "vechicalNumber": vehicleNo,
//         "visitingFlatId": fid,
//         "societyID": sId,
//         "guestVisitingId": 0,
//         "blockId": 0,
//         "visitorCategoriesId": selectedcategoriesData
//       };
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.processsocietyguestsRequest);
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocityResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateSocityResponseModal> updateprocessSocietyGuestsRequest(
//       String id,
//       String Gvid,
//       String? fullName,
//       String? address,
//       String? purpose,
//       String? vehicleNo,
//       String? contactNumber,
//       String? image,
//       String? sId,
//       String? fid,
//       String? approval,
//       String MeetingRequestApprovalStatus,
//       String IsAdavnceApproved,
//       String checkindate,
//       String checkintime,
//       String selectedcategoriesData,
//       ) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "id": id,
//         "name": fullName,
//         "address": address,
//         "purposeToMeet": purpose,
//         "phoneNumber": contactNumber,
//         "visitingFlatId": fid,
//         "societyID": sId,
//         "vechicalNumber": vehicleNo,
//         "guestVisitingId": Gvid,
//         "meetingRequestApprovalStatus": true,
//         "requestApprovedById": id,
//         "requestGeneratedById": "",
//         "isAdavnceApproved": true,
//         "idProofImage": "",
//         "checkInDate": checkindate.toString(),
//         "checkInTime": checkintime.toString(),
//         "visitorCategoriesId": selectedcategoriesData,
//         "Image": image
//       };
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.processsocietyguestsRequest);
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocityResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<GetSingleGuestByMobileModal> getSingleGuestByMobile(phonNo) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getSingleGuestByMobile}?Mobile=$phonNo");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return GetSingleGuestByMobileModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateSubRoleModal> createSubRole(String subRoleName) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? userID = prefs.getString('userID');
//       final body = {"Id": "0", "Name": subRoleName, "AspNetRoleId": userID};
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateSubRoles);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return CreateSubRoleModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<changePasswordResponseModal> changePassword(
//       String oldpassword, String newpassword, String cnfpassword) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? userName = prefs.getString('userName');
//       final body = {
//         "UserName": userName,
//         "OldPassword": oldpassword,
//         "NewPassword": newpassword,
//         "ConfirmPassword": cnfpassword
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.changePassword);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return changePasswordResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<guestListResponseModal> getguestListResponseModal(
//       String? Id, String? siD, String? vname) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getGuestList}?SocietyId=$siD&FlatId=$Id&searchString=$vname");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return guestListResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<VisitorCategoryModal> getVisitorCategories() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.getVisitorCategories);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return VisitorCategoryModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<comlaintListModal> getComplaints(String siD) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getcomplaintList}?SocietyId=$siD");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint(response.body.toString());
//       if (response.statusCode == 200) {
//         return comlaintListModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<comlaintListModal> getComplaintsSuperAdmin(String siD) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getcomplaintListSuperAdmin}?SocietyId=$siD");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint(response.body.toString());
//       if (response.statusCode == 200) {
//         return comlaintListModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<privacyandtermsmodal> societyRulesAndPrivacyList() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.SocietyRulesAndPrivacyList);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return privacyandtermsmodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
// //data array map is implemented here
//   Future<CreateSocityResponseModal> createSociety(
//       String societyName,
//       String address,
//       String phoneNumber,
//       String email,
//       String helplineNumber,
//       String builder,
//       String maintenanceType,
//       String maintenance,
//       String year,
//       String logo,
//       String rangeAllowed,
//       List<Map<String, dynamic>> dataArray,
//       String latitude,
//       String longitude,
//       List aminity) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? userid = prefs.getString('userID');
//       String? token = prefs.getString('token');
//       Map<String, dynamic>? jsons;
//       if (dataArray.isEmpty) {
//         jsons = {'TemId': '0', 'BlockName': societyName, 'NoOfFloors': '0'};
//         dataArray.add(jsons);
//       }
//       final body = {
//         "Id": "0",
//         "societyName": societyName,
//         "Address": address,
//         "PhoneNumber": phoneNumber,
//         "Email": email,
//         "HelplineNumber": helplineNumber,
//         "Builder": builder,
//         "SocityCreatedById": userid.toString(),
//         "MaintainanceChargePerSquaeFit": maintenance,
//         "YearOfConstruction": year,
//         "rangeAllowed": rangeAllowed,
//         "latitude": latitude,
//         "longitude": longitude,
//         "BlocksViewModels": dataArray,
//         "ammenities": aminity,
//         "maintainanceChargeType": maintenanceType,
//         "Logo": logo.toString(),
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateSociety);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateSocityResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<UploadSocietyImageResponsemodal> uploadSocietyImages(
//       String images, String sid, String gpath) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "Id": 0,
//         "Image": images,
//         "SocietyId": sid,
//         "GallaryPath": gpath
//       };
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.uploadSocietyImage);
//       debugPrint(uri.toString());
//       debugPrint(body.toString());
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return UploadSocietyImageResponsemodal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateUpdateOfferModal> uploadOfferImages(
//       String images, String sid, String gpath) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//
//       final body = {
//         "id": 0,
//         "banner": images,
//         "isActive": true,
//         "url": gpath,
//         "societyId": sid
//       };
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.uploadOfferImage);
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return CreateUpdateOfferModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<updateProfileModal> updateProfile(
//       String email,
//       String userName,
//       String fname,
//       String lname,
//       String address,
//       String image,
//       String gender,
//       String wpNo,
//       String phoneNo,
//       String dob) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? userType = prefs.getString('roleName');
//       final body = {
//         "email": email,
//         "userName": userName,
//         "firstName": fname,
//         "lastName": lname,
//         "imageUrl": image,
//         "gender": gender,
//         "whatsAppNumber": wpNo,
//         "phoneNumber": phoneNo,
//         "dob": dob,
//         "usertype": userType,
//         "intrestsModel": []
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.updateProfile);
//       var response = await http.post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString);
//       hideProgress();
//       if (response.statusCode == 200) {
//         return updateProfileModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<updateMemberModal> updateMember(
//       String userReferenceId,
//       String id,
//       String email,
//       String userName,
//       String fname,
//       String lname,
//       String address,
//       String image,
//       String gender,
//       String sid,
//       String wpNo,
//       String phoneNo,
//       String dob,
//       bool isActive) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "id": id,
//         "firstName": fname,
//         "lastName": lname,
//         "isActive": isActive,
//         "societyId": sid,
//         "whatsAppNumber": wpNo,
//         "dob": dob,
//         "address": address,
//         "email": email,
//         "gender": gender,
//         "userName": userName,
//         "phoneNumber": phoneNo,
//         "Image": image,
//         "userReferenceId": userReferenceId
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.updateMember);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       debugPrint(body.toString());
//       debugPrint(response.statusCode.toString());
//       debugPrint(response.body);
//       if (response.statusCode == 200) {
//         return updateMemberModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<updateMemberModal> updateResident(
//       String userType,
//       String id,
//       String email,
//       String userName,
//       String fname,
//       String lname,
//       String address,
//       String image,
//       String gender,
//       String sid,
//       String wpNo,
//       String phoneNo,
//       String dob,
//       String fid,
//       bool isActive) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "id": id,
//         "email": email,
//         "firstName": fname,
//         "lastName": lname,
//         "image": image,
//         "gender": gender,
//         "whatsAppNumber": wpNo,
//         "phoneNumber": phoneNo,
//         "dob": dob,
//         "flatId": fid,
//         "societyId": sid
//       };
//
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.updatePrimaryMember);
//       var response = await http.post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString);
//       hideProgress();
//       if (response.statusCode == 200) {
//         return updateMemberModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<ForgotPasswordResponseModal> forgotPassword(String otp,
//       String username, String newpassword, String cnfpassword) async {
//     try {
//       final body = {
//         "UserName": username,
//         "OTP": otp,
//         "NewPassword": newpassword,
//         "ConfirmPassword": cnfpassword
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.forgotpassword);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return ForgotPasswordResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<verifyotpResponseModal> verifyotp(String username, String otp) async {
//     try {
//       final body = {"UserName": username, "OTP": otp};
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.verifyotp);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return verifyotpResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<UpdatePhoneNumberVerifyOTPModal> UpdatePhoneNumberVerifyOTP(
//       String username, String otp) async {
//     try {
//       final body = {"newPhoneNumber": username, "otp": otp};
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.UpdatePhoneNumberVerifyOTP);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return UpdatePhoneNumberVerifyOTPModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<noticelistmodal> getsocietyNotice(String siD) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getsocietyNotice}?societyId=$siD");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return noticelistmodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<deleteSocietyModal> deleteSocietyImage(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.DeleteSocietyImage}?Id=$id");
//       showProgress();
//       var response = await http.post(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return deleteSocietyModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<deleteSocietyModal> deleteOfferImages(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.DeleteOfferImage}?Id=$id");
//       showProgress();
//       var response = await http.post(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return deleteSocietyModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<GetSocietyModal> getsocietyBlock(String siD) async {
//     try {
//       dataOfSocietyblock.clear();
//       dataOfsocietyblockid.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getBlockNo}?societyId=$siD");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         for (int i = 0; i < resBody['result'].length; i++) {
//           if (resBody['result'][i]['blockName'] != null) {
//             dataOfSocietyblock.add(resBody['result'][i]['blockName']);
//             dataOfsocietyblockid.add(resBody['result'][i]['id']);
//           }
//         }
//         return GetSocietyModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<FlatTypeModel> getFlatType(String siD) async {
//     try {
//       dataOfFlatType.clear();
//       dataOfflattypeid.clear();
//       dataOfflattypeidString.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getFlatType}?SocietyId=$siD");
//       showProgress();
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         for (int i = 0; i < resBody['result'].length; i++) {
//           if (resBody['result'][i]['flatType'] != null) {
//             dataOfFlatType.add(resBody['result'][i]['flatType']);
//             dataOfflattypeid.add(resBody['result'][i]['id']);
//             dataOfflattypeidString.add(resBody['result'][i]['id'].toString());
//           }
//         }
//         return FlatTypeModel.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<ModelGetSocietyBlockFloors> getsocietyFloors(
//       String siD, String blockiD) async {
//     try {
//       dataOfFloorNo.clear();
//       dataOffloornoid.clear();
//       dataOffloornoidString.clear();
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getSocietyBlockFloors}?SocietyId=$siD&BlockId=$blockiD");
//       showProgress();
//       debugPrint(uri.toString());
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       debugPrint(response.body);
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         for (int i = 0; i < resBody['result']['floors'].length; i++) {
//           dataOfFloorNo.add(resBody['result']['floors'][i]['floor'].toString());
//           dataOffloornoid.add(resBody['result']['floors'][i]['id']);
//           dataOffloornoidString
//               .add(resBody['result']['floors'][i]['id'].toString());
//         }
//         return ModelGetSocietyBlockFloors.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<addnoticemodal> createNotice(String title, String description,
//       String siD, String date, String index) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? userid = prefs.getString('userID');
//       String? token = prefs.getString('token');
//       String? userName = prefs.getString('userName');
//       final body = {
//         "Id": 0,
//         "Title": title,
//         "Description": description,
//         "IsActive": true,
//         "ValidUpTo": date,
//         "SocietyId": /*int.parse(siD)*/ siD,
//         "Index": index
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.addNotice);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return addnoticemodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<addnoticemodal> updateNotice(String id, String title,
//       String description, String siD, String date, String index) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "Id": id,
//         "Title": title,
//         "Description": description,
//         "IsActive": true,
//         "ValidUpTo": date,
//         "SocietyId": siD,
//         "Index": index
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.addNotice);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return addnoticemodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SocietyImagesModal> getsocietyImages(String sId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getsocietyImages}?Id=$sId");
//       showProgress();
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       return SocietyImagesModal.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SocietyOfferModal> getofferImages(String sId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.getofferImages}?societyId=$sId");
//       showProgress();
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       return SocietyOfferModal.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<GetSingleFlatModal> GetSingleFlat(String sId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetSingleFlat}?flatId=$sId");
//       debugPrint(uri.toString());
//       showProgress();
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       return GetSingleFlatModal.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<verifyuserflatmodal> VerifyUsersFlat(String fid, String uid) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.VerifyUsersFlat}?flatId=$fid&UserId=$uid");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return verifyuserflatmodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<ComplaintLogModal> getcomplaintlogUrl(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.complaintlogUrl}?ComplaintId=$id");
//       showProgress();
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       log(uri.toString());
//       log(response.body);
//       hideProgress();
//       if (response.statusCode == 200) {
//         return ComplaintLogModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateUpdateNotificationModal> CreateUpdateFireBaseId(
//       String sId, Stringftoken, String dId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "FireBaseId": Stringftoken,
//         "DeviceId": dId,
//         "SocietyId": sId
//       };
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateFireBaseId);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       debugPrint(body.toString());
//       if (response.statusCode == 200) {
//         return CreateUpdateNotificationModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SendNotificationModal> SendNotification(
//       String sId, String title, String message) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {"SocietyId": sId, "MessageBody": message, "Title": title};
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.SendNotification);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return SendNotificationModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SendNotificationModal> SendNotificationToGateKeeper(
//       String flatid,
//       String title,
//       String message,
//       String visiorname,
//       String visitordate,
//       String visitortime) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');
//     final body = {
//       "Title": title,
//       "MessageBody": message,
//       "FlatId": flatid,
//       "VisitorName": visiorname,
//       "VisitingDate": visitordate,
//       "VisitingTime": visitortime
//     };
//     showProgress();
//     final jsonString = json.encode(body);
//     final uri = Uri.parse(
//         BaseUrl.BaseUrlForloginsignup + BaseUrl.SendNotificationToGatekeeper);
//     var response = await http
//         .post(uri,
//         headers: {
//           HttpHeaders.authorizationHeader: 'Bearer $token',
//           HttpHeaders.contentTypeHeader: 'application/json',
//         },
//         body: jsonString)
//         .timeout(
//       const Duration(minutes: 2),
//       onTimeout: () {
//         return http.Response('Error', 408);
//       },
//     );
//     hideProgress();
//     if (response.statusCode == 200) {
//       return SendNotificationModal.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load album');
//     }
//   }
//
//   Future<SendNotificationModal> SendNotificationToGateKeeperSuperSocietyAdmin(
//       String societyId,
//       String flatName,
//       String flatid,
//       String title,
//       String message,
//       String visiorname,
//       String visitordate,
//       String visitortime,
//       String _sourceId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "FlatName": flatName,
//         "SocietyId": societyId,
//         "FlatId": flatid,
//         "VisitorName": visiorname,
//         "VisitingDate": visitordate,
//         "VisitingTime": visitortime,
//         "Title": "",
//         "MessageBody": "",
//         "SourceId": int.parse(_sourceId)
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup +
//           BaseUrl.SendNotificationToGatekeeperByAdminForVisitor);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return SendNotificationModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SendNotificationModal> CoResidentSendNotificationToGatekeeper(
//       String flatid,
//       String title,
//       String message,
//       String visiorname,
//       String visitordate,
//       String visitortime,
//       ) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "Title": title,
//         "MessageBody": message,
//         "FlatId": flatid,
//         "VisitorName": visiorname,
//         "VisitingDate": visitordate,
//         "VisitingTime": visitortime
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(BaseUrl.BaseUrlForloginsignup +
//           BaseUrl.CoResidentSendNotificationToGatekeeper);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return SendNotificationModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SendNotificationModal> SendNotificationToOwner(String flatid,
//       String title, String message, String sId, String GuestId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "Title": title,
//         "MessageBody": message,
//         "FlatId": flatid,
//         "societyId": sId,
//         "sourceId": 0,
//         "societyGuestId": GuestId
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.SendNotificationToOwner);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return SendNotificationModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<CreateUpdateIntrestModal> approveVisitor(String title) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {"Id": '0', "Title": title};
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateInterest);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return CreateUpdateIntrestModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<ApprovalModal> ApproveGuestVisitingRequest(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.ApproveGuestVisitingRequest}?Id=$id");
//       showProgress();
//       var response = await http.post(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       log(response.body);
//       hideProgress();
//       if (response.statusCode == 200) {
//         return ApprovalModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<ApprovalModal> RejectGuestVisitingRequest(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.RejectGuestVisitingRequest}?Id=$id");
//       showProgress();
//       log(uri.toString());
//       var response = await http.post(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       log(response.body);
//       hideProgress();
//       if (response.statusCode == 200) {
//         return ApprovalModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<ApprovalModal> CheckOutGuestVisiting(String id) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? userid = prefs.getString('userID');
//       String? token = prefs.getString('token');
//       String? userName = prefs.getString('userName');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.CheckOutGuestVisiting}?Id=$id");
//       showProgress();
//       log(uri.toString());
//       var response = await http.post(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       log(response.body);
//       hideProgress();
//       if (response.statusCode == 200) {
//         return ApprovalModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<ApproveCoResidentModal> ApproveUserLogin(
//       String uid, String isActive) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.ApproveUserLogin}?UserId=$uid&IsActive=$isActive");
//       showProgress();
//       var response = await http.post(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return ApproveCoResidentModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SendNotificationSocietyAdminModal> SendNotificationSocietyAdmin(
//       String title, String sId, String fid, String message) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "SocietyId": sId,
//         "FlatId": fid,
//         "Title": title,
//         "MessageBody": message
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.SocietyAdminSendNotification);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return SendNotificationSocietyAdminModal.fromJson(
//             jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<FlatTypeResponseModal> CreateUpdateFlatType(
//       String ftypeId, String type, String sId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {"Id": ftypeId, "Type": type, "SocietyId": sId};
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.CreateUpdateFlatType);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return FlatTypeResponseModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<FlatTypeListResponseModal> GetFlatTypes(String sId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           "${BaseUrl.BaseUrlForloginsignup + BaseUrl.GetFlatTypes}?SocietyId=$sId");
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return FlatTypeListResponseModal.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SosNotificationResponseModal> SoSSendNotification(String sId) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');
//     final body = {
//       "SocietyId": sId,
//       "MessageBody": "",
//       "FlatId": 0,
//       "Title": "SoS-Emergency"
//     };
//     showProgress();
//     final jsonString = json.encode(body);
//     final uri =
//     Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.SoSSendNotification);
//     var response = await http
//         .post(uri,
//         headers: {
//           HttpHeaders.authorizationHeader: 'Bearer $token',
//           HttpHeaders.contentTypeHeader: 'application/json',
//         },
//         body: jsonString)
//         .timeout(
//       const Duration(minutes: 2),
//       onTimeout: () {
//         return http.Response('Error', 408);
//       },
//     );
//     hideProgress();
//     debugPrint('-----Get Sos Response-----');
//     debugPrint(response.body);
//     if (response.statusCode == 200) {
//       return SosNotificationResponseModal.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load album');
//     }
//   }
//
//   Future<logoutModal> logoutFromServices(
//       String fid, String sId, String dId) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       String? userid = prefs.getString('userID');
//       final body = {
//         "UserId": userid,
//         "FireBaseId": fid,
//         "DeviceId": dId,
//         "SocietyId": sId == '' ? '0' : sId
//       };
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.logoutFromServices);
//       debugPrint(uri.toString());
//       debugPrint(jsonEncode(body.toString()));
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return logoutModal.fromJson(jsonDecode(response.body));
//       } else {
//         Session().logout();
//         Get.to(const Login());
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<generatepasswordmodal> generatePassword(
//       String NewPassword, String ConfirmPassword) async {
//     try {
//       final body = {
//         "NewPassword": NewPassword,
//         "ConfirmPassword": ConfirmPassword
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.generatePassword);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return generatepasswordmodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load album');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<SocietyGeographyModal> getSocietyGeography() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.getSocietyGeography);
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       if (response.statusCode == 200) {
//         return SocietyGeographyModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<updatePhoneResidentModal> updatePhoneNo(
//       String userHash, String otp, String oldNumber, String phoneNo) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "userHashCode": userHash,
//         "otp": otp,
//         "oldNumber": oldNumber,
//         "newNumber": phoneNo
//       };
//       final jsonString = json.encode(body);
//       final uri = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.UpdatePhoneResident);
//       showProgress();
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return updatePhoneResidentModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<signinsignoutmodal> staffsignin(
//       String signInImage, String signInLat, String signInLong) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "id": 0,
//         "signInImage": signInImage,
//         "signInLat": signInLat,
//         "signInLong": signInLong
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.StaffSignIn);
//       var response = await http.post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString);
//       print(body.toString());
//       print(signInImage);
//       hideProgress();
//       print("==========================");
//       print(response.body);
//       if (response.statusCode == 200) {
//         return signinsignoutmodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<signinsignoutmodal> staffsignout(
//       String signOutImage, String signOutLat, String signOutLong) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {
//         "id": 0,
//         "signOutImage": signOutImage,
//         "signOutLat": signOutLat,
//         "signOutLong": signOutLong
//       };
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.StaffSignOut);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 200) {
//         return signinsignoutmodal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<RewriteModal> addWrite(String? bio) async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? token = prefs.getString('token');
//       final body = {"userMessage": bio};
//       showProgress();
//       final jsonString = json.encode(body);
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.AIAssistanceUrl);
//       var response = await http
//           .post(uri,
//           headers: {
//             HttpHeaders.authorizationHeader: 'Bearer $token',
//             HttpHeaders.contentTypeHeader: 'application/json',
//           },
//           body: jsonString)
//           .timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       print(uri.toString());
//       print(response.body.toString());
//       hideProgress();
//       if (response.statusCode == 200) {
//         return RewriteModal.fromJson(jsonDecode(response.body));
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   Future<sendotpResponseModal> createUpdateIntrest(String mobileNo) async {
//     try {
//       final url = Uri.parse(
//           BaseUrl.BaseUrlForloginsignup + BaseUrl.createUpdateUserInterest);
//       Map<String, String> headers = {'Content-Type': 'application/json'};
//       final msg = jsonEncode({
//         "mobileNumber": mobileNo,
//       });
//       showProgress();
//       final response = await post(url, headers: headers, body: msg).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       hideProgress();
//       if (response.statusCode == 400) {
//         Get.showSnackbar(
//           const GetSnackBar(
//             title: 'Error',
//             message: 'something went wrong !',
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//       return sendotpResponseModal.fromJson(jsonDecode(response.body));
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
//   static Future<AppVersion> getPlayStoreVersion() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');
//     try {
//       final uri =
//       Uri.parse(BaseUrl.BaseUrlForloginsignup + BaseUrl.app_version);
//       showProgress();
//       var response = await http.get(uri, headers: {
//         HttpHeaders.authorizationHeader: 'Bearer $token',
//         HttpHeaders.contentTypeHeader: 'application/json',
//       }).timeout(
//         const Duration(minutes: 2),
//         onTimeout: () {
//           return http.Response('Error', 408);
//         },
//       );
//       print(uri);
//       print(response.statusCode);
//       print(response.body);
//       hideProgress();
//       if (response.statusCode == 200) {
//         var resBody = json.decode(response.body);
//         return AppVersion.fromJson(resBody);
//       } else {
//         throw Exception('Failed to load');
//       }
//     } on Exception catch (e) {
//       rethrow;
//     }
//   }
//
// }
