# Project: a_g_sur_back_office

## Architecture & Code Style
- FlutterFlow-generated project — maintain FlutterFlow code style (verbatim widget nesting, serializeParam, safeSetState, etc.)
- Backend: Supabase (UsersTable, queryRows, eqOrNull pattern)
- State: FlutterFlowModel per widget/page; local state on model classes

## Admin Master Pattern
- User profile check: `_model.user?.firstOrNull?.profileType == 'Admin Master'`
- Loading user in initState (via SchedulerBinding.instance.addPostFrameCallback):
  ```dart
  _model.user = await UsersTable().queryRows(
    queryFn: (q) => q.eqOrNull('id', currentUserUid),
  );
  ```
- Required imports for this pattern:
  - `import '/auth/supabase_auth/auth_util.dart';` (provides `currentUserUid`)
  - `import 'package:flutter/scheduler.dart';` (provides `SchedulerBinding`)
- Model field declaration: `List<UsersRow>? user;`

## Key Files
- `lib/proposal/proposals/proposals_widget.dart` — proposals list; arrow button navigates to ViewEditProposal with conditional typeAccess ('edit' for Admin Master, 'view' otherwise)
- `lib/proposal/proposals/proposals_model.dart` — model for proposals list
- `lib/contract/view_contract/view_contract_widget.dart` — reference implementation for Admin Master edit button pattern
- `lib/proposal/view_edit_proposal/view_edit_proposal_widget.dart` — receives `typeAccess` param ('view'|'edit')
