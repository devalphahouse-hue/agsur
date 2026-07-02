import '/backend/supabase/database/tables/users.dart';

/// Níveis de acesso do painel (RBAC).
///
/// Fonte da verdade única para "quem vê o quê". O menu (`menu_widget`) e o
/// router (`nav.dart`) consultam esta camada; telas com edição condicional
/// (ex.: `view_tracking`) usam [AccessControl.canEditTracking].
///
/// Mapeamento a partir de `users`:
///   profile_type = 'Admin Master'                    → adminMaster (vê tudo)
///   profile_type = 'Vendedor'                        → vendedor
///   profile_type = 'Admin' + access_level='documentacao' → adminDocumentacao
///   profile_type = 'Admin' + access_level (outro/NULL)   → adminRecepcao
enum PanelRole { adminMaster, adminRecepcao, adminDocumentacao, vendedor, none }

class AccessControl {
  AccessControl._();

  /// Papel do usuário logado, cacheado para uso síncrono no router.
  /// Setado no login e a cada build do menu; limpo no logout.
  static PanelRole current = PanelRole.none;

  static PanelRole roleOf(UsersRow? user) {
    final p = user?.profileType;
    if (p == 'Admin Master') return PanelRole.adminMaster;
    if (p == 'Vendedor') return PanelRole.vendedor;
    if (p == 'Admin') {
      return user?.accessLevel == 'documentacao'
          ? PanelRole.adminDocumentacao
          : PanelRole.adminRecepcao;
    }
    return PanelRole.none;
  }

  /// Deriva o papel a partir das strings cruas (usado no login, antes de
  /// carregar um UsersRow completo).
  static PanelRole roleOfStrings(String? profileType, String? accessLevel) {
    if (profileType == 'Admin Master') return PanelRole.adminMaster;
    if (profileType == 'Vendedor') return PanelRole.vendedor;
    if (profileType == 'Admin') {
      return accessLevel == 'documentacao'
          ? PanelRole.adminDocumentacao
          : PanelRole.adminRecepcao;
    }
    return PanelRole.none;
  }

  // ── Grupos de rotas (por routeName) ──────────────────────────────────────
  static const _common = {'HomePage', 'Chat', 'ChatDetail', 'Profile', 'ProfileEdit'};
  static const _solicitacoes = {'ProfileAnalysis'};
  static const _funil = {
    'Leads', 'ViewEditLead', 'Proposals', 'ViewEditProposal', 'CreateProposal',
    'Contracts', 'ViewContract', 'Clients', 'ViewEditClient',
  };
  static const _pilotos = {'Pilots', 'ViewEditPilots'};
  static const _oficinas = {'oficina', 'oficina_details'};
  static const _vendedores = {'Sellers', 'ViewEditSeller'};
  static const _colaboradores = {'Employees', 'ViewEditEmployees'};
  static const _rastreio = {'Trackings', 'ViewTracking'};
  static const _aeronaves = {
    'RegistedAircraft', 'CreateAircraft', 'AircraftDetails',
    'AvailableAircrafts', 'CreateCategory',
  };
  static const _cartaServico = {'ServicesOffering'};
  static const _cotacao = {'PartQuote'};
  static const _garantias = {'Guarantees'};
  static const _certificados = {'Certificates'};
  static const _taxas = {'ViewEditRates', 'CreateRates'};
  static const _termos = {'ViewEditContractTerms', 'CreateContractTerms'};

  /// Conjunto de rotas permitidas para o papel. adminMaster = tudo.
  static Set<String> allowedRoutes(PanelRole role) {
    switch (role) {
      case PanelRole.adminMaster:
        return _all;
      case PanelRole.adminRecepcao:
        return {
          ..._common, ..._pilotos, ..._oficinas, ..._garantias,
          ..._certificados, ..._cartaServico, ..._cotacao,
        };
      case PanelRole.adminDocumentacao:
        return {
          ..._common, ..._solicitacoes, ..._funil, ..._rastreio,
          ..._aeronaves, ..._cartaServico, ..._garantias, ..._taxas, ..._termos,
        };
      case PanelRole.vendedor:
        return {..._common, ..._funil, ..._rastreio};
      case PanelRole.none:
        return _common;
    }
  }

  static final Set<String> _all = {
    ..._common, ..._solicitacoes, ..._funil, ..._pilotos, ..._oficinas,
    ..._vendedores, ..._colaboradores, ..._rastreio, ..._aeronaves,
    ..._cartaServico, ..._cotacao, ..._garantias, ..._certificados,
    ..._taxas, ..._termos,
  };

  static bool canView(PanelRole role, String routeName) =>
      role == PanelRole.adminMaster || allowedRoutes(role).contains(routeName);

  /// Só master e documentação podem editar/checar o rastreio. Vendedor
  /// visualiza (view-only); recepção nem vê a tela.
  static bool canEditTracking(PanelRole role) =>
      role == PanelRole.adminMaster || role == PanelRole.adminDocumentacao;
}
