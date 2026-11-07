import '../../../l10n/app_localizations.dart';
import '../domain/registration.dart';

String roleLabel(AppLocalizations t, RegistrationRole role) => switch (role) {
  RegistrationRole.trader => t.mlRoleTrader,
  RegistrationRole.exporter => t.mlRoleExporter,
  RegistrationRole.broker => t.mlRoleBroker,
  RegistrationRole.provider => t.mlRoleProvider,
};

String providerKindLabel(AppLocalizations t, ProviderKind kind) =>
    switch (kind) {
      ProviderKind.weighbridge => t.mlKindWeighbridge,
      ProviderKind.transporter => t.mlKindTransporter,
      ProviderKind.labourGang => t.mlKindLabourGang,
      ProviderKind.crateSupplier => t.mlKindCrateSupplier,
    };
