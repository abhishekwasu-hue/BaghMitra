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
