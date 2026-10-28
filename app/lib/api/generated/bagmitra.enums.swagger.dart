// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

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
