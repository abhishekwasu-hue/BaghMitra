import '../../../l10n/app_localizations.dart';
import '../domain/market_link.dart';

/// The role's name as on its card (spec v1.5 §2.1); the broker is "मध्यस्थ (दलाल)".
String roleLabel(AppLocalizations t, MarketRole role) => switch (role) {
  MarketRole.grower => t.mlRoleGrower,
  MarketRole.trader => t.mlRoleTrader,
  MarketRole.broker => t.mlRoleBroker,
  MarketRole.exporter => t.mlRoleExporter,
  MarketRole.provider => t.mlRoleProvider,
};
