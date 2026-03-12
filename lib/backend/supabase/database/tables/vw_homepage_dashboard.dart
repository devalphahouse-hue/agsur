import '../database.dart';

class VwHomepageDashboardTable extends SupabaseTable<VwHomepageDashboardRow> {
  @override
  String get tableName => 'vw_homepage_dashboard';

  @override
  VwHomepageDashboardRow createRow(Map<String, dynamic> data) =>
      VwHomepageDashboardRow(data);
}

class VwHomepageDashboardRow extends SupabaseDataRow {
  VwHomepageDashboardRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwHomepageDashboardTable();

  int? get leadsCurrent => getField<int>('leads_current');
  set leadsCurrent(int? value) => setField<int>('leads_current', value);

  int? get leadsLast => getField<int>('leads_last');
  set leadsLast(int? value) => setField<int>('leads_last', value);

  double? get leadsGrowthPercentage =>
      getField<double>('leads_growth_percentage');
  set leadsGrowthPercentage(double? value) =>
      setField<double>('leads_growth_percentage', value);

  int? get proposalsCurrent => getField<int>('proposals_current');
  set proposalsCurrent(int? value) => setField<int>('proposals_current', value);

  int? get proposalsLast => getField<int>('proposals_last');
  set proposalsLast(int? value) => setField<int>('proposals_last', value);

  double? get proposalsGrowthPercentage =>
      getField<double>('proposals_growth_percentage');
  set proposalsGrowthPercentage(double? value) =>
      setField<double>('proposals_growth_percentage', value);

  int? get salesCurrent => getField<int>('sales_current');
  set salesCurrent(int? value) => setField<int>('sales_current', value);

  int? get salesLast => getField<int>('sales_last');
  set salesLast(int? value) => setField<int>('sales_last', value);

  double? get salesGrowthPercentage =>
      getField<double>('sales_growth_percentage');
  set salesGrowthPercentage(double? value) =>
      setField<double>('sales_growth_percentage', value);

  int? get deliveredCurrent => getField<int>('delivered_current');
  set deliveredCurrent(int? value) => setField<int>('delivered_current', value);

  int? get deliveredLast => getField<int>('delivered_last');
  set deliveredLast(int? value) => setField<int>('delivered_last', value);

  double? get deliveredGrowthPercentage =>
      getField<double>('delivered_growth_percentage');
  set deliveredGrowthPercentage(double? value) =>
      setField<double>('delivered_growth_percentage', value);

  int? get availableCurrent => getField<int>('available_current');
  set availableCurrent(int? value) => setField<int>('available_current', value);

  int? get availableLast => getField<int>('available_last');
  set availableLast(int? value) => setField<int>('available_last', value);

  double? get availableGrowthPercentage =>
      getField<double>('available_growth_percentage');
  set availableGrowthPercentage(double? value) =>
      setField<double>('available_growth_percentage', value);

  double? get companyCommissionCurrent =>
      getField<double>('company_commission_current');
  set companyCommissionCurrent(double? value) =>
      setField<double>('company_commission_current', value);

  double? get companyCommissionLast =>
      getField<double>('company_commission_last');
  set companyCommissionLast(double? value) =>
      setField<double>('company_commission_last', value);

  double? get companyCommissionGrowthPercentage =>
      getField<double>('company_commission_growth_percentage');
  set companyCommissionGrowthPercentage(double? value) =>
      setField<double>('company_commission_growth_percentage', value);

  double? get sellerCommissionCurrent =>
      getField<double>('seller_commission_current');
  set sellerCommissionCurrent(double? value) =>
      setField<double>('seller_commission_current', value);

  double? get sellerCommissionLast =>
      getField<double>('seller_commission_last');
  set sellerCommissionLast(double? value) =>
      setField<double>('seller_commission_last', value);

  double? get sellerCommissionGrowthPercentage =>
      getField<double>('seller_commission_growth_percentage');
  set sellerCommissionGrowthPercentage(double? value) =>
      setField<double>('seller_commission_growth_percentage', value);

  double? get revenueCurrent => getField<double>('revenue_current');
  set revenueCurrent(double? value) =>
      setField<double>('revenue_current', value);

  double? get revenueLast => getField<double>('revenue_last');
  set revenueLast(double? value) => setField<double>('revenue_last', value);

  double? get revenueGrowthPercentage =>
      getField<double>('revenue_growth_percentage');
  set revenueGrowthPercentage(double? value) =>
      setField<double>('revenue_growth_percentage', value);
}
