import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';

import '/auth/base_auth_user_provider.dart';

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? HomePageWidget() : LoginWidget(),
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) =>
              appStateNotifier.loggedIn ? HomePageWidget() : LoginWidget(),
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          requireAuth: true,
          builder: (context, params) => HomePageWidget(),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => LoginWidget(),
        ),
        FFRoute(
          name: GuaranteesWidget.routeName,
          path: GuaranteesWidget.routePath,
          builder: (context, params) => GuaranteesWidget(),
        ),
        FFRoute(
          name: ProfileWidget.routeName,
          path: ProfileWidget.routePath,
          builder: (context, params) => ProfileWidget(),
        ),
        FFRoute(
          name: ProfileEditWidget.routeName,
          path: ProfileEditWidget.routePath,
          builder: (context, params) => ProfileEditWidget(),
        ),
        FFRoute(
          name: ServicesOfferingWidget.routeName,
          path: ServicesOfferingWidget.routePath,
          builder: (context, params) => ServicesOfferingWidget(),
        ),
        FFRoute(
          name: RegistedAircraftWidget.routeName,
          path: RegistedAircraftWidget.routePath,
          builder: (context, params) => RegistedAircraftWidget(),
        ),
        FFRoute(
          name: ResetPasswordWidget.routeName,
          path: ResetPasswordWidget.routePath,
          builder: (context, params) => ResetPasswordWidget(),
        ),
        FFRoute(
          name: CertificatesWidget.routeName,
          path: CertificatesWidget.routePath,
          builder: (context, params) => CertificatesWidget(),
        ),
        FFRoute(
          name: ViewTrackingWidget.routeName,
          path: ViewTrackingWidget.routePath,
          builder: (context, params) => ViewTrackingWidget(
            userAircraftId: params.getParam(
              'userAircraftId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AircraftDetailsWidget.routeName,
          path: AircraftDetailsWidget.routePath,
          builder: (context, params) => AircraftDetailsWidget(
            aircraftId: params.getParam(
              'aircraftId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ClientsWidget.routeName,
          path: ClientsWidget.routePath,
          builder: (context, params) => ClientsWidget(),
        ),
        FFRoute(
          name: EmployeesWidget.routeName,
          path: EmployeesWidget.routePath,
          builder: (context, params) => EmployeesWidget(),
        ),
        FFRoute(
          name: PartQuoteWidget.routeName,
          path: PartQuoteWidget.routePath,
          builder: (context, params) => PartQuoteWidget(),
        ),
        FFRoute(
          name: ProfileAnalysisWidget.routeName,
          path: ProfileAnalysisWidget.routePath,
          builder: (context, params) => ProfileAnalysisWidget(),
        ),
        FFRoute(
          name: LeadsWidget.routeName,
          path: LeadsWidget.routePath,
          builder: (context, params) => LeadsWidget(),
        ),
        FFRoute(
          name: SellersWidget.routeName,
          path: SellersWidget.routePath,
          builder: (context, params) => SellersWidget(),
        ),
        FFRoute(
          name: PilotsWidget.routeName,
          path: PilotsWidget.routePath,
          builder: (context, params) => PilotsWidget(),
        ),
        FFRoute(
          name: CreateAircraftWidget.routeName,
          path: CreateAircraftWidget.routePath,
          builder: (context, params) => CreateAircraftWidget(),
        ),
        FFRoute(
          name: CreateItemsStandardWidget.routeName,
          path: CreateItemsStandardWidget.routePath,
          builder: (context, params) => CreateItemsStandardWidget(),
        ),
        FFRoute(
          name: CreateItemsOptionsWidget.routeName,
          path: CreateItemsOptionsWidget.routePath,
          builder: (context, params) => CreateItemsOptionsWidget(),
        ),
        FFRoute(
          name: CreateCategoryWidget.routeName,
          path: CreateCategoryWidget.routePath,
          builder: (context, params) => CreateCategoryWidget(),
        ),
        FFRoute(
          name: CreateProposalWidget.routeName,
          path: CreateProposalWidget.routePath,
          builder: (context, params) => CreateProposalWidget(),
        ),
        FFRoute(
          name: ProposalsWidget.routeName,
          path: ProposalsWidget.routePath,
          builder: (context, params) => ProposalsWidget(),
        ),
        FFRoute(
          name: ViewEditProposalWidget.routeName,
          path: ViewEditProposalWidget.routePath,
          builder: (context, params) => ViewEditProposalWidget(
            proposalId: params.getParam(
              'proposalId',
              ParamType.String,
            ),
            typeAccess: params.getParam(
              'typeAccess',
              ParamType.String,
            ),
            companyName: params.getParam(
              'companyName',
              ParamType.String,
            ),
            sellerName: params.getParam(
              'sellerName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ContractsWidget.routeName,
          path: ContractsWidget.routePath,
          builder: (context, params) => ContractsWidget(),
        ),
        FFRoute(
          name: ViewEditLeadWidget.routeName,
          path: ViewEditLeadWidget.routePath,
          builder: (context, params) => ViewEditLeadWidget(
            leadId: params.getParam(
              'leadId',
              ParamType.String,
            ),
            typeAccess: params.getParam(
              'typeAccess',
              ParamType.String,
            ),
            fullname: params.getParam(
              'fullname',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: TrackingsWidget.routeName,
          path: TrackingsWidget.routePath,
          builder: (context, params) => TrackingsWidget(),
        ),
        FFRoute(
          name: OficinaWidget.routeName,
          path: OficinaWidget.routePath,
          builder: (context, params) => OficinaWidget(),
        ),
        FFRoute(
          name: OficinaDetailsWidget.routeName,
          path: OficinaDetailsWidget.routePath,
          builder: (context, params) => OficinaDetailsWidget(
            isEdit: params.getParam(
              'isEdit',
              ParamType.bool,
            ),
            userId: params.getParam(
              'userId',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ViewEditPilotsWidget.routeName,
          path: ViewEditPilotsWidget.routePath,
          builder: (context, params) => ViewEditPilotsWidget(
            pilotId: params.getParam(
              'pilotId',
              ParamType.String,
            ),
            typeAccess: params.getParam(
              'typeAccess',
              ParamType.String,
            ),
            fullname: params.getParam(
              'fullname',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ViewEditSellerWidget.routeName,
          path: ViewEditSellerWidget.routePath,
          builder: (context, params) => ViewEditSellerWidget(
            sellerId: params.getParam(
              'sellerId',
              ParamType.String,
            ),
            typeAccess: params.getParam(
              'typeAccess',
              ParamType.String,
            ),
            fullname: params.getParam(
              'fullname',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ViewEditEmployeesWidget.routeName,
          path: ViewEditEmployeesWidget.routePath,
          builder: (context, params) => ViewEditEmployeesWidget(
            employeId: params.getParam(
              'employeId',
              ParamType.String,
            ),
            typeAccess: params.getParam(
              'typeAccess',
              ParamType.String,
            ),
            fullname: params.getParam(
              'fullname',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ViewEditClientWidget.routeName,
          path: ViewEditClientWidget.routePath,
          builder: (context, params) => ViewEditClientWidget(
            leadId: params.getParam(
              'leadId',
              ParamType.String,
            ),
            typeAccess: params.getParam(
              'typeAccess',
              ParamType.String,
            ),
            fullname: params.getParam(
              'fullname',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: CreateRatesWidget.routeName,
          path: CreateRatesWidget.routePath,
          builder: (context, params) => CreateRatesWidget(
            idFinancialRate: params.getParam(
              'idFinancialRate',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ViewEditRatesWidget.routeName,
          path: ViewEditRatesWidget.routePath,
          builder: (context, params) => ViewEditRatesWidget(),
        ),
        FFRoute(
          name: ViewContractWidget.routeName,
          path: ViewContractWidget.routePath,
          builder: (context, params) => ViewContractWidget(
            proposalId: params.getParam(
              'proposalId',
              ParamType.String,
            ),
            typeAccess: params.getParam(
              'typeAccess',
              ParamType.String,
            ),
            companyName: params.getParam(
              'companyName',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: ViewEditContractTermsWidget.routeName,
          path: ViewEditContractTermsWidget.routePath,
          builder: (context, params) => ViewEditContractTermsWidget(),
        ),
        FFRoute(
          name: CreateContractTermsWidget.routeName,
          path: CreateContractTermsWidget.routePath,
          builder: (context, params) => CreateContractTermsWidget(
            idContractTerms: params.getParam(
              'idContractTerms',
              ParamType.String,
            ),
            type: params.getParam(
              'type',
              ParamType.String,
            ),
          ),
        ),
        FFRoute(
          name: AvailableAircraftsWidget.routeName,
          path: AvailableAircraftsWidget.routePath,
          builder: (context, params) => AvailableAircraftsWidget(),
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/login';
          }
          return null;
        },
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = appStateNotifier.loading
              ? isWeb
                  ? Container()
                  : Container(
                      color: FlutterFlowTheme.of(context).primaryText,
                      child: Center(
                        child: Image.asset(
                          'assets/images/Logo_AEROTG_NEGATIVO_V.png',
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
              : page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
