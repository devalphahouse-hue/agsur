import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class CreateAccountAnotherUserCall {
  static Future<ApiCallResponse> call({
    String? email = '',
    String? password = '',
  }) async {
    final ffApiRequestBody = '''
{
  "email": "${escapeStringForJson(email)}",
  "password": "${escapeStringForJson(password)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Create account another user',
      apiUrl: 'https://bkzybtmxxzpxtztesdye.supabase.co/auth/v1/signup',
      callType: ApiCallType.POST,
      headers: {
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? userID(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.user.id''',
      ));
  static String? emailUser(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.user.email''',
      ));
}

class GetLeadDetailsForProposalCall {
  static Future<ApiCallResponse> call({
    String? pLeadId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_lead_id": "${escapeStringForJson(pLeadId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get lead details for proposal',
      apiUrl:
          'https://bkzybtmxxzpxtztesdye.supabase.co/rest/v1/rpc/get_lead_details_proposal',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic? objLeadProposal(dynamic response) => getJsonField(
        response,
        r'''$[:].lead''',
      );
  static dynamic? objSellerProposal(dynamic response) => getJsonField(
        response,
        r'''$[:].seller''',
      );
  static dynamic? objCompanyProposal(dynamic response) => getJsonField(
        response,
        r'''$[:].company''',
      );
  static dynamic? objAddressProposal(dynamic response) => getJsonField(
        response,
        r'''$[:].address''',
      );
}

class GetAircraftDetailsForProposalCall {
  static Future<ApiCallResponse> call({
    String? pAircraftId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_aircraft_id": "${escapeStringForJson(pAircraftId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get aircraft details for proposal',
      apiUrl:
          'https://bkzybtmxxzpxtztesdye.supabase.co/rest/v1/rpc/get_aircraft_details_proposal',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic? objAircraft(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
  static List<ItemsSeriesStruct>? objItemsSeries(dynamic response) =>
      (getJsonField(
        response,
        r'''$[:].items_series''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => ItemsSeriesStruct.maybeFromMap(x))
          .withoutNulls
          .toList();
  static String? idAircraft(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].id''',
      ));
  static String? aircraftModel(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_model''',
      ));
  static String? aircraftYear(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_year''',
      ));
  static String? aircraftDescription(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_description''',
      ));
  static String? aircraftPhotoUrl(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_photo_url''',
      ));
  static double? aircraftHopper(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$[:].hopper''',
      ));
  static double? aircraftPrice(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$[:].price''',
      ));
}

class GetProposalDetailsCall {
  static Future<ApiCallResponse> call({
    String? pProposalId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_proposal_id": "${escapeStringForJson(pProposalId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get proposal details',
      apiUrl:
          'https://bkzybtmxxzpxtztesdye.supabase.co/rest/v1/rpc/get_proposal_details',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? seriesItemName(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_series_items[:].item_name''',
      ));
  static String? seriesItemType(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_series_items[:].item_type''',
      ));
  static int? seriesItemQty(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$[:].proposal_series_items[:].qty''',
      ));
  static double? seriesItemPrice(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$[:].proposal_series_items[:].price''',
      ));
  static String? seriesItemCategoryId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_series_items[:].category_id''',
      ));
  static String? seriesItemCategoryName(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_series_items[:].category_name''',
      ));
  static String? optionalId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].id''',
      ));
  static String? optionalPropostaId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].proposal_id''',
      ));
  static String? optionalAircraftId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].aircraft_item_id''',
      ));
  static String? optionalCreatedAt(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].created_at''',
      ));
  static String? optionalItemId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].item.id''',
      ));
  static int? optionalitemQty(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].item.qty''',
      ));
  static double? optionalitemPrice(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].item.price''',
      ));
  static String? optionalitemCategoryId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].item.category_id''',
      ));
  static String? optionalitemName(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].item.item_name''',
      ));
  static String? optionalitemCategoryName(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].item.category_name''',
      ));
  static ProposalStruct? objProposal(dynamic response) =>
      ProposalStruct.maybeFromMap(getJsonField(
        response,
        r'''$[:].proposal''',
      ));
  static ProposalLeadStruct? objProposalLead(dynamic response) =>
      ProposalLeadStruct.maybeFromMap(getJsonField(
        response,
        r'''$[:].proposal_lead''',
      ));
  static ProposalCompanyStruct? objProposalCompany(dynamic response) =>
      ProposalCompanyStruct.maybeFromMap(getJsonField(
        response,
        r'''$[:].proposal_company''',
      ));
  static ProposalAddressStruct? objProposalAddress(dynamic response) =>
      ProposalAddressStruct.maybeFromMap(getJsonField(
        response,
        r'''$[:].proposal_address''',
      ));
  static ProposalAircraftStruct? objProposalAircraft(dynamic response) =>
      ProposalAircraftStruct.maybeFromMap(getJsonField(
        response,
        r'''$[:].proposal_aircraft''',
      ));
  static List<ProposalSeriesItemsStruct>? objProposalSeriesItem(
          dynamic response) =>
      (getJsonField(
        response,
        r'''$[:].proposal_series_items''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => ProposalSeriesItemsStruct.maybeFromMap(x))
          .withoutNulls
          .toList();
  static List<ProposalOptionalItemsStruct>? objProposalOptionItems(
          dynamic response) =>
      (getJsonField(
        response,
        r'''$[:].proposal_optional_items''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => ProposalOptionalItemsStruct.maybeFromMap(x))
          .withoutNulls
          .toList();
  static ItemStruct? objItem(dynamic response) =>
      ItemStruct.maybeFromMap(getJsonField(
        response,
        r'''$[:].proposal_optional_items[:].item''',
      ));
}

class GetAircraftDetailsByProposalIdCall {
  static Future<ApiCallResponse> call({
    String? pProposalId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_proposal_id": "${escapeStringForJson(pProposalId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get aircraft details by proposal id',
      apiUrl:
          'https://bkzybtmxxzpxtztesdye.supabase.co/rest/v1/rpc/get_aircraft_details_by_proposal',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static double? price(dynamic response) => castToType<double>(getJsonField(
        response,
        r'''$.price''',
      ));
  static String? aircraftmodel(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.aircraft_model''',
      ));
  static String? aircraftyear(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.aircraft_year''',
      ));
  static String? aircraftdescription(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.aircraft_description''',
      ));
  static String? aircraftphotourl(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.aircraft_photo_url''',
      ));
}

class GetLeadDetailsCall {
  static Future<ApiCallResponse> call({
    String? pLeadId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_lead_id": "${escapeStringForJson(pLeadId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get lead details',
      apiUrl:
          'https://bkzybtmxxzpxtztesdye.supabase.co/rest/v1/rpc/get_lead_details',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? leadId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].id''',
      ));
  static String? leadFullname(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].fullname''',
      ));
  static String? leadCpf(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].cpf''',
      ));
  static String? leadEmail(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].email''',
      ));
  static String? leadPhone(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].phone''',
      ));
  static String? leadCity(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].city''',
      ));
  static String? leadState(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].state''',
      ));
  static String? sellerId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].seller_id''',
      ));
  static String? sellerFullname(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].seller_name''',
      ));
  static String? leadJob(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].job_title''',
      ));
  static String? leadCompanyName(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].company_name''',
      ));
  static String? leadName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].name''',
      ));
  static String? leadLastname(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].last_name''',
      ));
}

class GetTrackingCall {
  static Future<ApiCallResponse> call({
    String? pAircraftId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_aircraft_user_id": "${escapeStringForJson(pAircraftId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get tracking',
      apiUrl:
          'https://bkzybtmxxzpxtztesdye.supabase.co/rest/v1/rpc/get_tracking',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<TrackingStruct>? objTracking(dynamic response) => (getJsonField(
        response,
        r'''$.tracking''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => TrackingStruct.maybeFromMap(x))
          .withoutNulls
          .toList();
  static TrackUserAircraftStruct? objTrackUaircraft(dynamic response) =>
      TrackUserAircraftStruct.maybeFromMap(getJsonField(
        response,
        r'''$.track_user_aircraft''',
      ));
  static TrackProposalStruct? objTrackProposal(dynamic response) =>
      TrackProposalStruct.maybeFromMap(getJsonField(
        response,
        r'''$.track_proposal''',
      ));
  static TrackLeadStruct? objTrackLead(dynamic response) =>
      TrackLeadStruct.maybeFromMap(getJsonField(
        response,
        r'''$.track_lead''',
      ));
  static TrackCompanyStruct? objTrackCompany(dynamic response) =>
      TrackCompanyStruct.maybeFromMap(getJsonField(
        response,
        r'''$.track_company''',
      ));
  static TrackSalesStruct? objTrackSales(dynamic response) =>
      TrackSalesStruct.maybeFromMap(getJsonField(
        response,
        r'''$.track_sales''',
      ));
  static TrackFinancialStruct? objTrackFinancial(dynamic response) =>
      TrackFinancialStruct.maybeFromMap(getJsonField(
        response,
        r'''$.track_financial''',
      ));
}

class GetListAvailableAircraftsCall {
  static Future<ApiCallResponse> call({
    String? pEntryYear = '',
    String? pStatus = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_entry_year": "${escapeStringForJson(pEntryYear)}",
  "p_status": "${escapeStringForJson(pStatus)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Get list available aircrafts',
      apiUrl:
          'https://bkzybtmxxzpxtztesdye.supabase.co/rest/v1/rpc/fn_available_aircrafts',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? id(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].id''',
      ));
  static String? aircraftModelid(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_model_id''',
      ));
  static String? serialNumber(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].serial_number''',
      ));
  static String? manufactureDate(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].manufacture_date''',
      ));
  static String? configurationDeadline(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].configuration_deadline''',
      ));
  static String? deliveryDate(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].delivery_date''',
      ));
  static String? status(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].status''',
      ));
  static String? createdAt(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].created_at''',
      ));
  static String? createdBy(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].created_by''',
      ));
  static String? updateBy(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].update_by''',
      ));
  static String? entryYear(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].entry_year''',
      ));
  static String? aircraftId(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_id''',
      ));
  static String? aircraftModel(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_model''',
      ));
  static String? aircraftImage(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$[:].aircraft_photo_url''',
      ));
}

class GetBCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GET B',
      apiUrl: 'https://google.com',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetCCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GET C',
      apiUrl: 'https://google.com',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetDCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GET D',
      apiUrl: 'https://google.com',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetECall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GET E',
      apiUrl: 'https://google.com',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class GetFCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GET F',
      apiUrl: 'https://google.com',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ViaCepCall {
  static Future<ApiCallResponse> call({
    String? cep = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'via cep',
      apiUrl: 'viacep.com.br/ws/${cep}/json/',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? cep(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.cep''',
      ));
  static String? logradouro(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.logradouro''',
      ));
  static String? bairro(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.bairro''',
      ));
  static String? localidade(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.localidade''',
      ));
  static String? uf(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.uf''',
      ));
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
