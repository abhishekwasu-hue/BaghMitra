// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

enum AcceptInRole {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('grower')
  grower('grower'),
  @JsonValue('trader')
  trader('trader'),
  @JsonValue('exporter')
  exporter('exporter'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider'),
  @JsonValue('representative')
  representative('representative');

  final String? value;

  const AcceptInRole(this.value);
}

enum ActionInAction {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('verify')
  verify('verify'),
  @JsonValue('warn')
  warn('warn'),
  @JsonValue('hide')
  hide('hide'),
  @JsonValue('suspend')
  suspend('suspend'),
  @JsonValue('restore')
  restore('restore');

  final String? value;

  const ActionInAction(this.value);
}

enum ActionInReasonCode {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('fake_identity')
  fakeIdentity('fake_identity'),
  @JsonValue('fake_lot')
  fakeLot('fake_lot'),
  @JsonValue('impersonation')
  impersonation('impersonation'),
  @JsonValue('fake_rating')
  fakeRating('fake_rating'),
  @JsonValue('abuse')
  abuse('abuse'),
  @JsonValue('duplicate_user')
  duplicateUser('duplicate_user'),
  @JsonValue('checks_passed')
  checksPassed('checks_passed'),
  @JsonValue('appeal_upheld')
  appealUpheld('appeal_upheld');

  final String? value;

  const ActionInReasonCode(this.value);
}

enum ActionInSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider'),
  @JsonValue('lot')
  lot('lot'),
  @JsonValue('rating')
  rating('rating'),
  @JsonValue('user')
  user('user');

  final String? value;

  const ActionInSubjectType(this.value);
}

enum AdminProviderInKind {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('weighbridge')
  weighbridge('weighbridge'),
  @JsonValue('transporter')
  transporter('transporter'),
  @JsonValue('labour_gang')
  labourGang('labour_gang'),
  @JsonValue('crate_supplier')
  crateSupplier('crate_supplier');

  final String? value;

  const AdminProviderInKind(this.value);
}

enum AppealDecisionInOutcome {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('upheld')
  upheld('upheld'),
  @JsonValue('rejected')
  rejected('rejected');

  final String? value;

  const AppealDecisionInOutcome(this.value);
}

enum AppealInReason {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('identity_genuine')
  identityGenuine('identity_genuine'),
  @JsonValue('lot_genuine')
  lotGenuine('lot_genuine'),
  @JsonValue('rating_genuine')
  ratingGenuine('rating_genuine'),
  @JsonValue('behaviour_proper')
  behaviourProper('behaviour_proper'),
  @JsonValue('not_duplicate')
  notDuplicate('not_duplicate');

  final String? value;

  const AppealInReason(this.value);
}

enum BadgeOutKind {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('checked')
  checked('checked'),
  @JsonValue('registered_from')
  registeredFrom('registered_from'),
  @JsonValue('place_photo')
  placePhoto('place_photo'),
  @JsonValue('gst_checked')
  gstChecked('gst_checked'),
  @JsonValue('apmc_seen')
  apmcSeen('apmc_seen'),
  @JsonValue('fssai_checked')
  fssaiChecked('fssai_checked'),
  @JsonValue('iec_active')
  iecActive('iec_active'),
  @JsonValue('apeda_listed')
  apedaListed('apeda_listed');

  final String? value;

  const BadgeOutKind(this.value);
}

enum BlockedClaimOutReason {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('banned')
  banned('banned'),
  @JsonValue('restricted_for_crop')
  restrictedForCrop('restricted_for_crop');

  final String? value;

  const BlockedClaimOutReason(this.value);
}

enum ChangeOp {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('upsert')
  upsert('upsert'),
  @JsonValue('delete')
  delete('delete');

  final String? value;

  const ChangeOp(this.value);
}

enum CheckInKind {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('gstin')
  gstin('gstin'),
  @JsonValue('apmc')
  apmc('apmc'),
  @JsonValue('fssai')
  fssai('fssai'),
  @JsonValue('iec')
  iec('iec'),
  @JsonValue('apeda')
  apeda('apeda'),
  @JsonValue('phone_call')
  phoneCall('phone_call'),
  @JsonValue('place_photo')
  placePhoto('place_photo');

  final String? value;

  const CheckInKind(this.value);
}

enum CheckInResult {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('passed')
  passed('passed'),
  @JsonValue('failed')
  failed('failed'),
  @JsonValue('cancelled')
  cancelled('cancelled');

  final String? value;

  const CheckInResult(this.value);
}

enum DealStateOutMyRole {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('grower')
  grower('grower'),
  @JsonValue('trader')
  trader('trader'),
  @JsonValue('broker')
  broker('broker');

  final String? value;

  const DealStateOutMyRole(this.value);
}

enum DealStateOutRates {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('grower')
  grower('grower'),
  @JsonValue('trader')
  trader('trader'),
  @JsonValue('broker')
  broker('broker');

  final String? value;

  const DealStateOutRates(this.value);
}

enum DecisionInStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('approved')
  approved('approved'),
  @JsonValue('rejected')
  rejected('rejected');

  final String? value;

  const DecisionInStatus(this.value);
}

enum DeviceInPlatform {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('android')
  android('android'),
  @JsonValue('ios')
  ios('ios'),
  @JsonValue('web')
  web('web');

  final String? value;

  const DeviceInPlatform(this.value);
}

enum FeedAdminItemInType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('gr')
  gr('gr'),
  @JsonValue('circular')
  circular('circular'),
  @JsonValue('scheme')
  scheme('scheme'),
  @JsonValue('alert')
  alert('alert'),
  @JsonValue('news')
  news('news');

  final String? value;

  const FeedAdminItemInType(this.value);
}

enum FeedAdminTermsInTermsStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('unknown')
  unknown('unknown'),
  @JsonValue('allowed')
  allowed('allowed'),
  @JsonValue('disallowed')
  disallowed('disallowed');

  final String? value;

  const FeedAdminTermsInTermsStatus(this.value);
}

enum FeedCheckResponseVerdict {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('official_match')
  officialMatch('official_match'),
  @JsonValue('possible_match')
  possibleMatch('possible_match'),
  @JsonValue('no_official_match')
  noOfficialMatch('no_official_match');

  final String? value;

  const FeedCheckResponseVerdict(this.value);
}

enum FeedItemOutTrust {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('official')
  official('official'),
  @JsonValue('news')
  news('news');

  final String? value;

  const FeedItemOutTrust(this.value);
}

enum FeedPreferencesBodyOptedOut {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('deadline')
  deadline('deadline'),
  @JsonValue('payment')
  payment('payment'),
  @JsonValue('window_open')
  windowOpen('window_open');

  final String? value;

  const FeedPreferencesBodyOptedOut(this.value);
}

enum GivenRatingOutRateeRole {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('grower')
  grower('grower'),
  @JsonValue('trader')
  trader('trader'),
  @JsonValue('broker')
  broker('broker');

  final String? value;

  const GivenRatingOutRateeRole(this.value);
}

enum GrantInSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('farmer')
  farmer('farmer'),
  @JsonValue('organisation')
  organisation('organisation');

  final String? value;

  const GrantInSubjectType(this.value);
}

enum InterestInBasis {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('per_tonne')
  perTonne('per_tonne'),
  @JsonValue('per_crate')
  perCrate('per_crate'),
  @JsonValue('lump_sum')
  lumpSum('lump_sum');

  final String? value;

  const InterestInBasis(this.value);
}

enum LabelClaimOutCategory {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('chemical')
  chemical('chemical'),
  @JsonValue('bio')
  bio('bio');

  final String? value;

  const LabelClaimOutCategory(this.value);
}

enum MutationOp {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('upsert')
  upsert('upsert'),
  @JsonValue('delete')
  delete('delete');

  final String? value;

  const MutationOp(this.value);
}

enum MutationResultStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('applied')
  applied('applied'),
  @JsonValue('duplicate')
  duplicate('duplicate'),
  @JsonValue('stale')
  stale('stale'),
  @JsonValue('rejected')
  rejected('rejected');

  final String? value;

  const MutationResultStatus(this.value);
}

enum PackageGrantInMethod {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('upi')
  upi('upi'),
  @JsonValue('cash')
  cash('cash'),
  @JsonValue('bank')
  bank('bank');

  final String? value;

  const PackageGrantInMethod(this.value);
}

enum PlanInKind {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('grower')
  grower('grower'),
  @JsonValue('organisation')
  organisation('organisation');

  final String? value;

  const PlanInKind(this.value);
}

enum ProviderInKind {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('weighbridge')
  weighbridge('weighbridge'),
  @JsonValue('transporter')
  transporter('transporter'),
  @JsonValue('labour_gang')
  labourGang('labour_gang'),
  @JsonValue('crate_supplier')
  crateSupplier('crate_supplier');

  final String? value;

  const ProviderInKind(this.value);
}

enum RatingTagInStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('draft')
  draft('draft'),
  @JsonValue('active')
  active('active'),
  @JsonValue('retired')
  retired('retired');

  final String? value;

  const RatingTagInStatus(this.value);
}

enum ReportDecisionInAction {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('warn')
  warn('warn'),
  @JsonValue('hide')
  hide('hide'),
  @JsonValue('suspend')
  suspend('suspend');

  final String? value;

  const ReportDecisionInAction(this.value);
}

enum ReportDecisionInReasonCode {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('fake_identity')
  fakeIdentity('fake_identity'),
  @JsonValue('fake_lot')
  fakeLot('fake_lot'),
  @JsonValue('impersonation')
  impersonation('impersonation'),
  @JsonValue('fake_rating')
  fakeRating('fake_rating'),
  @JsonValue('abuse')
  abuse('abuse'),
  @JsonValue('duplicate_user')
  duplicateUser('duplicate_user'),
  @JsonValue('checks_passed')
  checksPassed('checks_passed'),
  @JsonValue('appeal_upheld')
  appealUpheld('appeal_upheld');

  final String? value;

  const ReportDecisionInReasonCode(this.value);
}

enum ReportInReason {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('fake_identity')
  fakeIdentity('fake_identity'),
  @JsonValue('fake_lot')
  fakeLot('fake_lot'),
  @JsonValue('impersonation')
  impersonation('impersonation'),
  @JsonValue('fake_rating')
  fakeRating('fake_rating'),
  @JsonValue('abuse')
  abuse('abuse');

  final String? value;

  const ReportInReason(this.value);
}

enum ReportInSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider'),
  @JsonValue('lot')
  lot('lot'),
  @JsonValue('rating')
  rating('rating'),
  @JsonValue('user')
  user('user');

  final String? value;

  const ReportInSubjectType(this.value);
}

enum ReviewInDecision {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('approve')
  approve('approve'),
  @JsonValue('edit')
  edit('edit'),
  @JsonValue('reject')
  reject('reject');

  final String? value;

  const ReviewInDecision(this.value);
}

enum TermsDocOutKind {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('terms')
  terms('terms'),
  @JsonValue('privacy')
  privacy('privacy'),
  @JsonValue('disclaimer')
  disclaimer('disclaimer');

  final String? value;

  const TermsDocOutKind(this.value);
}

enum V1AdminFeedItemsGetStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('draft')
  draft('draft'),
  @JsonValue('in_review')
  inReview('in_review'),
  @JsonValue('published')
  published('published'),
  @JsonValue('withdrawn')
  withdrawn('withdrawn');

  final String? value;

  const V1AdminFeedItemsGetStatus(this.value);
}

enum V1AdminFeedItemsItemIdTextsLangPutLang {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('en')
  en('en'),
  @JsonValue('mr')
  mr('mr'),
  @JsonValue('hi')
  hi('hi');

  final String? value;

  const V1AdminFeedItemsItemIdTextsLangPutLang(this.value);
}

enum V1AdminKbImportsKindPostKind {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('claims')
  claims('claims'),
  @JsonValue('restrictions')
  restrictions('restrictions');

  final String? value;

  const V1AdminKbImportsKindPostKind(this.value);
}

enum V1AdminMarketLinkAppealsGetState {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('appealed')
  appealed('appealed'),
  @JsonValue('upheld')
  upheld('upheld'),
  @JsonValue('rejected')
  rejected('rejected');

  final String? value;

  const V1AdminMarketLinkAppealsGetState(this.value);
}

enum V1AdminMarketLinkReportsGetStatus {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('open')
  open('open'),
  @JsonValue('actioned')
  actioned('actioned'),
  @JsonValue('dismissed')
  dismissed('dismissed');

  final String? value;

  const V1AdminMarketLinkReportsGetStatus(this.value);
}

enum V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType(
    this.value,
  );
}

enum V1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPostSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1AdminMarketLinkVerificationsSubjectTypeSubjectIdChecksPostSubjectType(
    this.value,
  );
}

enum V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType(
    this.value,
  );
}

enum V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType(
    this.value,
  );
}

enum V1FeedGetLang {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('en')
  en('en'),
  @JsonValue('mr')
  mr('mr'),
  @JsonValue('hi')
  hi('hi');

  final String? value;

  const V1FeedGetLang(this.value);
}

enum V1FeedCheckPostLang {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('en')
  en('en'),
  @JsonValue('mr')
  mr('mr'),
  @JsonValue('hi')
  hi('hi');

  final String? value;

  const V1FeedCheckPostLang(this.value);
}

enum V1InsuranceDeadlinesGetLang {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('en')
  en('en'),
  @JsonValue('mr')
  mr('mr'),
  @JsonValue('hi')
  hi('hi');

  final String? value;

  const V1InsuranceDeadlinesGetLang(this.value);
}

enum V1MarketLinkDealsDealIdRatingsRateeRolePutRateeRole {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('grower')
  grower('grower'),
  @JsonValue('trader')
  trader('trader'),
  @JsonValue('broker')
  broker('broker');

  final String? value;

  const V1MarketLinkDealsDealIdRatingsRateeRolePutRateeRole(this.value);
}

enum V1MarketLinkProfilesGetRole {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('trader')
  trader('trader'),
  @JsonValue('exporter')
  exporter('exporter'),
  @JsonValue('broker')
  broker('broker');

  final String? value;

  const V1MarketLinkProfilesGetRole(this.value);
}

enum V1MarketLinkProfilesGetSort {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('rating')
  rating('rating'),
  @JsonValue('deals')
  deals('deals');

  final String? value;

  const V1MarketLinkProfilesGetSort(this.value);
}

enum V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType(this.value);
}

enum V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType(
    this.value,
  );
}

enum V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType(
    this.value,
  );
}

enum V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('gst')
  gst('gst'),
  @JsonValue('apmc')
  apmc('apmc'),
  @JsonValue('fssai')
  fssai('fssai'),
  @JsonValue('iec')
  iec('iec'),
  @JsonValue('apeda')
  apeda('apeda'),
  @JsonValue('certificate')
  certificate('certificate');

  final String? value;

  const V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc(this.value);
}

enum V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('buyer')
  buyer('buyer'),
  @JsonValue('broker')
  broker('broker'),
  @JsonValue('provider')
  provider('provider');

  final String? value;

  const V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType(
    this.value,
  );
}

enum V1MarketPricesGetScope {
  @JsonValue(null)
  swaggerGeneratedUnknown(null),

  @JsonValue('all')
  all('all'),
  @JsonValue('local')
  local('local'),
  @JsonValue('major')
  major('major');

  final String? value;

  const V1MarketPricesGetScope(this.value);
}
