import '../../../l10n/app_localizations.dart';

/// Report and admin reason codes in the app language (spec v1.5 §4, Q82, Q93).
String reasonLabel(AppLocalizations t, String code) => switch (code) {
  'fake_identity' => t.mlReasonFakeIdentity,
  'fake_lot' => t.mlReasonFakeLot,
  'impersonation' => t.mlReasonImpersonation,
  'fake_rating' => t.mlReasonFakeRating,
  'abuse' => t.mlReasonAbuse,
  'duplicate_user' => t.mlReasonDuplicateUser,
  'checks_passed' => t.mlReasonChecksPassed,
  'appeal_upheld' => t.mlReasonAppealUpheld,
  _ => code,
};

String actionLabel(AppLocalizations t, String action) => switch (action) {
  'verify' => t.mlActionVerify,
  'warn' => t.mlActionWarn,
  'hide' => t.mlActionHide,
  'suspend' => t.mlActionSuspend,
  'restore' => t.mlActionRestore,
  _ => action,
};

String appealReasonLabel(AppLocalizations t, String code) => switch (code) {
  'identity_genuine' => t.mlAppealIdentityGenuine,
  'lot_genuine' => t.mlAppealLotGenuine,
  'rating_genuine' => t.mlAppealRatingGenuine,
  'behaviour_proper' => t.mlAppealBehaviourProper,
  'not_duplicate' => t.mlAppealNotDuplicate,
  _ => code,
};

String appealStateLabel(AppLocalizations t, String state) => switch (state) {
  'appealed' => t.mlAppealStateAppealed,
  'upheld' => t.mlAppealStateUpheld,
  'rejected' => t.mlAppealStateRejected,
  _ => state,
};
