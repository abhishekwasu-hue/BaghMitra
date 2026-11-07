// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';

import 'dart:convert';

import 'bagmitra.enums.swagger.dart' as enums;

part 'bagmitra.models.swagger.g.dart';

@JsonSerializable(explicitToJson: true)
class AcceptIn {
  const AcceptIn({
    required this.adultDeclared,
    required this.disclaimerVersion,
    required this.privacyVersion,
    required this.role,
    required this.termsVersion,
  });

  factory AcceptIn.fromJson(Map<String, dynamic> json) =>
      _$AcceptInFromJson(json);

  static const toJsonFactory = _$AcceptInToJson;
  Map<String, dynamic> toJson() => _$AcceptInToJson(this);

  @JsonKey(name: 'adult_declared', includeIfNull: false)
  final bool adultDeclared;
  @JsonKey(name: 'disclaimer_version', includeIfNull: false)
  final String disclaimerVersion;
  @JsonKey(name: 'privacy_version', includeIfNull: false)
  final String privacyVersion;
  @JsonKey(
    name: 'role',
    includeIfNull: false,
    toJson: acceptInRoleToJson,
    fromJson: acceptInRoleFromJson,
  )
  final enums.AcceptInRole role;
  @JsonKey(name: 'terms_version', includeIfNull: false)
  final String termsVersion;
  static const fromJsonFactory = _$AcceptInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AcceptIn &&
            (identical(other.adultDeclared, adultDeclared) ||
                const DeepCollectionEquality().equals(
                  other.adultDeclared,
                  adultDeclared,
                )) &&
            (identical(other.disclaimerVersion, disclaimerVersion) ||
                const DeepCollectionEquality().equals(
                  other.disclaimerVersion,
                  disclaimerVersion,
                )) &&
            (identical(other.privacyVersion, privacyVersion) ||
                const DeepCollectionEquality().equals(
                  other.privacyVersion,
                  privacyVersion,
                )) &&
            (identical(other.role, role) ||
                const DeepCollectionEquality().equals(other.role, role)) &&
            (identical(other.termsVersion, termsVersion) ||
                const DeepCollectionEquality().equals(
                  other.termsVersion,
                  termsVersion,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(adultDeclared) ^
      const DeepCollectionEquality().hash(disclaimerVersion) ^
      const DeepCollectionEquality().hash(privacyVersion) ^
      const DeepCollectionEquality().hash(role) ^
      const DeepCollectionEquality().hash(termsVersion) ^
      runtimeType.hashCode;
}

extension $AcceptInExtension on AcceptIn {
  AcceptIn copyWith({
    bool? adultDeclared,
    String? disclaimerVersion,
    String? privacyVersion,
    enums.AcceptInRole? role,
    String? termsVersion,
  }) {
    return AcceptIn(
      adultDeclared: adultDeclared ?? this.adultDeclared,
      disclaimerVersion: disclaimerVersion ?? this.disclaimerVersion,
      privacyVersion: privacyVersion ?? this.privacyVersion,
      role: role ?? this.role,
      termsVersion: termsVersion ?? this.termsVersion,
    );
  }

  AcceptIn copyWithWrapped({
    Wrapped<bool>? adultDeclared,
    Wrapped<String>? disclaimerVersion,
    Wrapped<String>? privacyVersion,
    Wrapped<enums.AcceptInRole>? role,
    Wrapped<String>? termsVersion,
  }) {
    return AcceptIn(
      adultDeclared: (adultDeclared != null
          ? adultDeclared.value
          : this.adultDeclared),
      disclaimerVersion: (disclaimerVersion != null
          ? disclaimerVersion.value
          : this.disclaimerVersion),
      privacyVersion: (privacyVersion != null
          ? privacyVersion.value
          : this.privacyVersion),
      role: (role != null ? role.value : this.role),
      termsVersion: (termsVersion != null
          ? termsVersion.value
          : this.termsVersion),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AcceptanceOut {
  const AcceptanceOut({
    required this.acceptedAt,
    required this.docKind,
    required this.role,
    required this.version,
  });

  factory AcceptanceOut.fromJson(Map<String, dynamic> json) =>
      _$AcceptanceOutFromJson(json);

  static const toJsonFactory = _$AcceptanceOutToJson;
  Map<String, dynamic> toJson() => _$AcceptanceOutToJson(this);

  @JsonKey(name: 'accepted_at', includeIfNull: false)
  final DateTime acceptedAt;
  @JsonKey(name: 'doc_kind', includeIfNull: false)
  final String docKind;
  @JsonKey(name: 'role', includeIfNull: false)
  final String role;
  @JsonKey(name: 'version', includeIfNull: false)
  final String version;
  static const fromJsonFactory = _$AcceptanceOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AcceptanceOut &&
            (identical(other.acceptedAt, acceptedAt) ||
                const DeepCollectionEquality().equals(
                  other.acceptedAt,
                  acceptedAt,
                )) &&
            (identical(other.docKind, docKind) ||
                const DeepCollectionEquality().equals(
                  other.docKind,
                  docKind,
                )) &&
            (identical(other.role, role) ||
                const DeepCollectionEquality().equals(other.role, role)) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(acceptedAt) ^
      const DeepCollectionEquality().hash(docKind) ^
      const DeepCollectionEquality().hash(role) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $AcceptanceOutExtension on AcceptanceOut {
  AcceptanceOut copyWith({
    DateTime? acceptedAt,
    String? docKind,
    String? role,
    String? version,
  }) {
    return AcceptanceOut(
      acceptedAt: acceptedAt ?? this.acceptedAt,
      docKind: docKind ?? this.docKind,
      role: role ?? this.role,
      version: version ?? this.version,
    );
  }

  AcceptanceOut copyWithWrapped({
    Wrapped<DateTime>? acceptedAt,
    Wrapped<String>? docKind,
    Wrapped<String>? role,
    Wrapped<String>? version,
  }) {
    return AcceptanceOut(
      acceptedAt: (acceptedAt != null ? acceptedAt.value : this.acceptedAt),
      docKind: (docKind != null ? docKind.value : this.docKind),
      role: (role != null ? role.value : this.role),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AccountDeleted {
  const AccountDeleted({
    required this.photosDeleted,
    required this.rowsDeleted,
    required this.signInAccountRemoved,
  });

  factory AccountDeleted.fromJson(Map<String, dynamic> json) =>
      _$AccountDeletedFromJson(json);

  static const toJsonFactory = _$AccountDeletedToJson;
  Map<String, dynamic> toJson() => _$AccountDeletedToJson(this);

  @JsonKey(name: 'photos_deleted', includeIfNull: false)
  final int photosDeleted;
  @JsonKey(name: 'rows_deleted', includeIfNull: false)
  final int rowsDeleted;
  @JsonKey(name: 'sign_in_account_removed', includeIfNull: false)
  final bool signInAccountRemoved;
  static const fromJsonFactory = _$AccountDeletedFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AccountDeleted &&
            (identical(other.photosDeleted, photosDeleted) ||
                const DeepCollectionEquality().equals(
                  other.photosDeleted,
                  photosDeleted,
                )) &&
            (identical(other.rowsDeleted, rowsDeleted) ||
                const DeepCollectionEquality().equals(
                  other.rowsDeleted,
                  rowsDeleted,
                )) &&
            (identical(other.signInAccountRemoved, signInAccountRemoved) ||
                const DeepCollectionEquality().equals(
                  other.signInAccountRemoved,
                  signInAccountRemoved,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(photosDeleted) ^
      const DeepCollectionEquality().hash(rowsDeleted) ^
      const DeepCollectionEquality().hash(signInAccountRemoved) ^
      runtimeType.hashCode;
}

extension $AccountDeletedExtension on AccountDeleted {
  AccountDeleted copyWith({
    int? photosDeleted,
    int? rowsDeleted,
    bool? signInAccountRemoved,
  }) {
    return AccountDeleted(
      photosDeleted: photosDeleted ?? this.photosDeleted,
      rowsDeleted: rowsDeleted ?? this.rowsDeleted,
      signInAccountRemoved: signInAccountRemoved ?? this.signInAccountRemoved,
    );
  }

  AccountDeleted copyWithWrapped({
    Wrapped<int>? photosDeleted,
    Wrapped<int>? rowsDeleted,
    Wrapped<bool>? signInAccountRemoved,
  }) {
    return AccountDeleted(
      photosDeleted: (photosDeleted != null
          ? photosDeleted.value
          : this.photosDeleted),
      rowsDeleted: (rowsDeleted != null ? rowsDeleted.value : this.rowsDeleted),
      signInAccountRemoved: (signInAccountRemoved != null
          ? signInAccountRemoved.value
          : this.signInAccountRemoved),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AddressIn {
  const AddressIn({this.address});

  factory AddressIn.fromJson(Map<String, dynamic> json) =>
      _$AddressInFromJson(json);

  static const toJsonFactory = _$AddressInToJson;
  Map<String, dynamic> toJson() => _$AddressInToJson(this);

  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  static const fromJsonFactory = _$AddressInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AddressIn &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(other.address, address)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(address) ^ runtimeType.hashCode;
}

extension $AddressInExtension on AddressIn {
  AddressIn copyWith({String? address}) {
    return AddressIn(address: address ?? this.address);
  }

  AddressIn copyWithWrapped({Wrapped<String?>? address}) {
    return AddressIn(address: (address != null ? address.value : this.address));
  }
}

@JsonSerializable(explicitToJson: true)
class AdminFixOut {
  const AdminFixOut({
    required this.accuracyM,
    required this.capturedAt,
    required this.district,
    required this.isMocked,
    required this.lat,
    required this.lon,
    required this.pin,
    required this.place,
    required this.state,
  });

  factory AdminFixOut.fromJson(Map<String, dynamic> json) =>
      _$AdminFixOutFromJson(json);

  static const toJsonFactory = _$AdminFixOutToJson;
  Map<String, dynamic> toJson() => _$AdminFixOutToJson(this);

  @JsonKey(name: 'accuracy_m', includeIfNull: false)
  final double accuracyM;
  @JsonKey(name: 'captured_at', includeIfNull: false)
  final DateTime capturedAt;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'is_mocked', includeIfNull: false)
  final bool isMocked;
  @JsonKey(name: 'lat', includeIfNull: false)
  final double lat;
  @JsonKey(name: 'lon', includeIfNull: false)
  final double lon;
  @JsonKey(name: 'pin', includeIfNull: false)
  final String? pin;
  @JsonKey(name: 'place', includeIfNull: false)
  final String? place;
  @JsonKey(name: 'state', includeIfNull: false)
  final String? state;
  static const fromJsonFactory = _$AdminFixOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AdminFixOut &&
            (identical(other.accuracyM, accuracyM) ||
                const DeepCollectionEquality().equals(
                  other.accuracyM,
                  accuracyM,
                )) &&
            (identical(other.capturedAt, capturedAt) ||
                const DeepCollectionEquality().equals(
                  other.capturedAt,
                  capturedAt,
                )) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.isMocked, isMocked) ||
                const DeepCollectionEquality().equals(
                  other.isMocked,
                  isMocked,
                )) &&
            (identical(other.lat, lat) ||
                const DeepCollectionEquality().equals(other.lat, lat)) &&
            (identical(other.lon, lon) ||
                const DeepCollectionEquality().equals(other.lon, lon)) &&
            (identical(other.pin, pin) ||
                const DeepCollectionEquality().equals(other.pin, pin)) &&
            (identical(other.place, place) ||
                const DeepCollectionEquality().equals(other.place, place)) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(accuracyM) ^
      const DeepCollectionEquality().hash(capturedAt) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(isMocked) ^
      const DeepCollectionEquality().hash(lat) ^
      const DeepCollectionEquality().hash(lon) ^
      const DeepCollectionEquality().hash(pin) ^
      const DeepCollectionEquality().hash(place) ^
      const DeepCollectionEquality().hash(state) ^
      runtimeType.hashCode;
}

extension $AdminFixOutExtension on AdminFixOut {
  AdminFixOut copyWith({
    double? accuracyM,
    DateTime? capturedAt,
    String? district,
    bool? isMocked,
    double? lat,
    double? lon,
    String? pin,
    String? place,
    String? state,
  }) {
    return AdminFixOut(
      accuracyM: accuracyM ?? this.accuracyM,
      capturedAt: capturedAt ?? this.capturedAt,
      district: district ?? this.district,
      isMocked: isMocked ?? this.isMocked,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      pin: pin ?? this.pin,
      place: place ?? this.place,
      state: state ?? this.state,
    );
  }

  AdminFixOut copyWithWrapped({
    Wrapped<double>? accuracyM,
    Wrapped<DateTime>? capturedAt,
    Wrapped<String?>? district,
    Wrapped<bool>? isMocked,
    Wrapped<double>? lat,
    Wrapped<double>? lon,
    Wrapped<String?>? pin,
    Wrapped<String?>? place,
    Wrapped<String?>? state,
  }) {
    return AdminFixOut(
      accuracyM: (accuracyM != null ? accuracyM.value : this.accuracyM),
      capturedAt: (capturedAt != null ? capturedAt.value : this.capturedAt),
      district: (district != null ? district.value : this.district),
      isMocked: (isMocked != null ? isMocked.value : this.isMocked),
      lat: (lat != null ? lat.value : this.lat),
      lon: (lon != null ? lon.value : this.lon),
      pin: (pin != null ? pin.value : this.pin),
      place: (place != null ? place.value : this.place),
      state: (state != null ? state.value : this.state),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AdminProviderIn {
  const AdminProviderIn({
    this.address,
    this.capacityT,
    this.carrierRegNo,
    this.certValidUntil,
    required this.district,
    this.fix,
    required this.kind,
    required this.name,
    required this.phone,
    this.refrigerated,
    this.serviceAreas,
    this.taluka,
    this.vehicleNumbers,
    required this.village,
  });

  factory AdminProviderIn.fromJson(Map<String, dynamic> json) =>
      _$AdminProviderInFromJson(json);

  static const toJsonFactory = _$AdminProviderInToJson;
  Map<String, dynamic> toJson() => _$AdminProviderInToJson(this);

  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'capacity_t', includeIfNull: false)
  final double? capacityT;
  @JsonKey(name: 'carrier_reg_no', includeIfNull: false)
  final String? carrierRegNo;
  @JsonKey(name: 'cert_valid_until', includeIfNull: false, toJson: _dateToJson)
  final DateTime? certValidUntil;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'fix', includeIfNull: false)
  final RegistrationFixIn? fix;
  @JsonKey(
    name: 'kind',
    includeIfNull: false,
    toJson: adminProviderInKindToJson,
    fromJson: adminProviderInKindFromJson,
  )
  final enums.AdminProviderInKind kind;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String phone;
  @JsonKey(name: 'refrigerated', includeIfNull: false)
  final bool? refrigerated;
  @JsonKey(
    name: 'service_areas',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? serviceAreas;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(
    name: 'vehicle_numbers',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? vehicleNumbers;
  @JsonKey(name: 'village', includeIfNull: false)
  final String village;
  static const fromJsonFactory = _$AdminProviderInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AdminProviderIn &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.capacityT, capacityT) ||
                const DeepCollectionEquality().equals(
                  other.capacityT,
                  capacityT,
                )) &&
            (identical(other.carrierRegNo, carrierRegNo) ||
                const DeepCollectionEquality().equals(
                  other.carrierRegNo,
                  carrierRegNo,
                )) &&
            (identical(other.certValidUntil, certValidUntil) ||
                const DeepCollectionEquality().equals(
                  other.certValidUntil,
                  certValidUntil,
                )) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.fix, fix) ||
                const DeepCollectionEquality().equals(other.fix, fix)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.refrigerated, refrigerated) ||
                const DeepCollectionEquality().equals(
                  other.refrigerated,
                  refrigerated,
                )) &&
            (identical(other.serviceAreas, serviceAreas) ||
                const DeepCollectionEquality().equals(
                  other.serviceAreas,
                  serviceAreas,
                )) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.vehicleNumbers, vehicleNumbers) ||
                const DeepCollectionEquality().equals(
                  other.vehicleNumbers,
                  vehicleNumbers,
                )) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(capacityT) ^
      const DeepCollectionEquality().hash(carrierRegNo) ^
      const DeepCollectionEquality().hash(certValidUntil) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(fix) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(refrigerated) ^
      const DeepCollectionEquality().hash(serviceAreas) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(vehicleNumbers) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $AdminProviderInExtension on AdminProviderIn {
  AdminProviderIn copyWith({
    String? address,
    double? capacityT,
    String? carrierRegNo,
    DateTime? certValidUntil,
    String? district,
    RegistrationFixIn? fix,
    enums.AdminProviderInKind? kind,
    String? name,
    String? phone,
    bool? refrigerated,
    List<String>? serviceAreas,
    String? taluka,
    List<String>? vehicleNumbers,
    String? village,
  }) {
    return AdminProviderIn(
      address: address ?? this.address,
      capacityT: capacityT ?? this.capacityT,
      carrierRegNo: carrierRegNo ?? this.carrierRegNo,
      certValidUntil: certValidUntil ?? this.certValidUntil,
      district: district ?? this.district,
      fix: fix ?? this.fix,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      refrigerated: refrigerated ?? this.refrigerated,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      taluka: taluka ?? this.taluka,
      vehicleNumbers: vehicleNumbers ?? this.vehicleNumbers,
      village: village ?? this.village,
    );
  }

  AdminProviderIn copyWithWrapped({
    Wrapped<String?>? address,
    Wrapped<double?>? capacityT,
    Wrapped<String?>? carrierRegNo,
    Wrapped<DateTime?>? certValidUntil,
    Wrapped<String>? district,
    Wrapped<RegistrationFixIn?>? fix,
    Wrapped<enums.AdminProviderInKind>? kind,
    Wrapped<String>? name,
    Wrapped<String>? phone,
    Wrapped<bool?>? refrigerated,
    Wrapped<List<String>?>? serviceAreas,
    Wrapped<String?>? taluka,
    Wrapped<List<String>?>? vehicleNumbers,
    Wrapped<String>? village,
  }) {
    return AdminProviderIn(
      address: (address != null ? address.value : this.address),
      capacityT: (capacityT != null ? capacityT.value : this.capacityT),
      carrierRegNo: (carrierRegNo != null
          ? carrierRegNo.value
          : this.carrierRegNo),
      certValidUntil: (certValidUntil != null
          ? certValidUntil.value
          : this.certValidUntil),
      district: (district != null ? district.value : this.district),
      fix: (fix != null ? fix.value : this.fix),
      kind: (kind != null ? kind.value : this.kind),
      name: (name != null ? name.value : this.name),
      phone: (phone != null ? phone.value : this.phone),
      refrigerated: (refrigerated != null
          ? refrigerated.value
          : this.refrigerated),
      serviceAreas: (serviceAreas != null
          ? serviceAreas.value
          : this.serviceAreas),
      taluka: (taluka != null ? taluka.value : this.taluka),
      vehicleNumbers: (vehicleNumbers != null
          ? vehicleNumbers.value
          : this.vehicleNumbers),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AlertOut {
  const AlertOut({
    required this.cardId,
    required this.createdAt,
    required this.detail,
    required this.id,
    required this.kind,
  });

  factory AlertOut.fromJson(Map<String, dynamic> json) =>
      _$AlertOutFromJson(json);

  static const toJsonFactory = _$AlertOutToJson;
  Map<String, dynamic> toJson() => _$AlertOutToJson(this);

  @JsonKey(name: 'card_id', includeIfNull: false)
  final String? cardId;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'detail', includeIfNull: false)
  final String detail;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  static const fromJsonFactory = _$AlertOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AlertOut &&
            (identical(other.cardId, cardId) ||
                const DeepCollectionEquality().equals(other.cardId, cardId)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.detail, detail) ||
                const DeepCollectionEquality().equals(other.detail, detail)) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cardId) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(detail) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(kind) ^
      runtimeType.hashCode;
}

extension $AlertOutExtension on AlertOut {
  AlertOut copyWith({
    String? cardId,
    DateTime? createdAt,
    String? detail,
    String? id,
    String? kind,
  }) {
    return AlertOut(
      cardId: cardId ?? this.cardId,
      createdAt: createdAt ?? this.createdAt,
      detail: detail ?? this.detail,
      id: id ?? this.id,
      kind: kind ?? this.kind,
    );
  }

  AlertOut copyWithWrapped({
    Wrapped<String?>? cardId,
    Wrapped<DateTime>? createdAt,
    Wrapped<String>? detail,
    Wrapped<String>? id,
    Wrapped<String>? kind,
  }) {
    return AlertOut(
      cardId: (cardId != null ? cardId.value : this.cardId),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      detail: (detail != null ? detail.value : this.detail),
      id: (id != null ? id.value : this.id),
      kind: (kind != null ? kind.value : this.kind),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AlertsResponse {
  const AlertsResponse({required this.alerts});

  factory AlertsResponse.fromJson(Map<String, dynamic> json) =>
      _$AlertsResponseFromJson(json);

  static const toJsonFactory = _$AlertsResponseToJson;
  Map<String, dynamic> toJson() => _$AlertsResponseToJson(this);

  @JsonKey(name: 'alerts', includeIfNull: false, defaultValue: <AlertOut>[])
  final List<AlertOut> alerts;
  static const fromJsonFactory = _$AlertsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AlertsResponse &&
            (identical(other.alerts, alerts) ||
                const DeepCollectionEquality().equals(other.alerts, alerts)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(alerts) ^ runtimeType.hashCode;
}

extension $AlertsResponseExtension on AlertsResponse {
  AlertsResponse copyWith({List<AlertOut>? alerts}) {
    return AlertsResponse(alerts: alerts ?? this.alerts);
  }

  AlertsResponse copyWithWrapped({Wrapped<List<AlertOut>>? alerts}) {
    return AlertsResponse(
      alerts: (alerts != null ? alerts.value : this.alerts),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AppVersionResponse {
  const AppVersionResponse({
    required this.downloadUrl,
    required this.latestVersionCode,
    required this.latestVersionName,
    required this.minVersionCode,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$AppVersionResponseFromJson(json);

  static const toJsonFactory = _$AppVersionResponseToJson;
  Map<String, dynamic> toJson() => _$AppVersionResponseToJson(this);

  @JsonKey(name: 'download_url', includeIfNull: false)
  final String downloadUrl;
  @JsonKey(name: 'latest_version_code', includeIfNull: false)
  final int latestVersionCode;
  @JsonKey(name: 'latest_version_name', includeIfNull: false)
  final String latestVersionName;
  @JsonKey(name: 'min_version_code', includeIfNull: false)
  final int minVersionCode;
  static const fromJsonFactory = _$AppVersionResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AppVersionResponse &&
            (identical(other.downloadUrl, downloadUrl) ||
                const DeepCollectionEquality().equals(
                  other.downloadUrl,
                  downloadUrl,
                )) &&
            (identical(other.latestVersionCode, latestVersionCode) ||
                const DeepCollectionEquality().equals(
                  other.latestVersionCode,
                  latestVersionCode,
                )) &&
            (identical(other.latestVersionName, latestVersionName) ||
                const DeepCollectionEquality().equals(
                  other.latestVersionName,
                  latestVersionName,
                )) &&
            (identical(other.minVersionCode, minVersionCode) ||
                const DeepCollectionEquality().equals(
                  other.minVersionCode,
                  minVersionCode,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(downloadUrl) ^
      const DeepCollectionEquality().hash(latestVersionCode) ^
      const DeepCollectionEquality().hash(latestVersionName) ^
      const DeepCollectionEquality().hash(minVersionCode) ^
      runtimeType.hashCode;
}

extension $AppVersionResponseExtension on AppVersionResponse {
  AppVersionResponse copyWith({
    String? downloadUrl,
    int? latestVersionCode,
    String? latestVersionName,
    int? minVersionCode,
  }) {
    return AppVersionResponse(
      downloadUrl: downloadUrl ?? this.downloadUrl,
      latestVersionCode: latestVersionCode ?? this.latestVersionCode,
      latestVersionName: latestVersionName ?? this.latestVersionName,
      minVersionCode: minVersionCode ?? this.minVersionCode,
    );
  }

  AppVersionResponse copyWithWrapped({
    Wrapped<String>? downloadUrl,
    Wrapped<int>? latestVersionCode,
    Wrapped<String>? latestVersionName,
    Wrapped<int>? minVersionCode,
  }) {
    return AppVersionResponse(
      downloadUrl: (downloadUrl != null ? downloadUrl.value : this.downloadUrl),
      latestVersionCode: (latestVersionCode != null
          ? latestVersionCode.value
          : this.latestVersionCode),
      latestVersionName: (latestVersionName != null
          ? latestVersionName.value
          : this.latestVersionName),
      minVersionCode: (minVersionCode != null
          ? minVersionCode.value
          : this.minVersionCode),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BadgeOut {
  const BadgeOut({required this.kind, required this.on, this.place});

  factory BadgeOut.fromJson(Map<String, dynamic> json) =>
      _$BadgeOutFromJson(json);

  static const toJsonFactory = _$BadgeOutToJson;
  Map<String, dynamic> toJson() => _$BadgeOutToJson(this);

  @JsonKey(
    name: 'kind',
    includeIfNull: false,
    toJson: badgeOutKindToJson,
    fromJson: badgeOutKindFromJson,
  )
  final enums.BadgeOutKind kind;
  @JsonKey(name: 'on', includeIfNull: false, toJson: _dateToJson)
  final DateTime on;
  @JsonKey(name: 'place', includeIfNull: false)
  final String? place;
  static const fromJsonFactory = _$BadgeOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BadgeOut &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.on, on) ||
                const DeepCollectionEquality().equals(other.on, on)) &&
            (identical(other.place, place) ||
                const DeepCollectionEquality().equals(other.place, place)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(on) ^
      const DeepCollectionEquality().hash(place) ^
      runtimeType.hashCode;
}

extension $BadgeOutExtension on BadgeOut {
  BadgeOut copyWith({enums.BadgeOutKind? kind, DateTime? on, String? place}) {
    return BadgeOut(
      kind: kind ?? this.kind,
      on: on ?? this.on,
      place: place ?? this.place,
    );
  }

  BadgeOut copyWithWrapped({
    Wrapped<enums.BadgeOutKind>? kind,
    Wrapped<DateTime>? on,
    Wrapped<String?>? place,
  }) {
    return BadgeOut(
      kind: (kind != null ? kind.value : this.kind),
      on: (on != null ? on.value : this.on),
      place: (place != null ? place.value : this.place),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BlockedClaimOut {
  const BlockedClaimOut({
    required this.activeIngredient,
    required this.formulation,
    required this.labelCrop,
    required this.notification,
    required this.reason,
    required this.target,
  });

  factory BlockedClaimOut.fromJson(Map<String, dynamic> json) =>
      _$BlockedClaimOutFromJson(json);

  static const toJsonFactory = _$BlockedClaimOutToJson;
  Map<String, dynamic> toJson() => _$BlockedClaimOutToJson(this);

  @JsonKey(name: 'active_ingredient', includeIfNull: false)
  final String activeIngredient;
  @JsonKey(name: 'formulation', includeIfNull: false)
  final String formulation;
  @JsonKey(name: 'label_crop', includeIfNull: false)
  final String labelCrop;
  @JsonKey(name: 'notification', includeIfNull: false)
  final String notification;
  @JsonKey(
    name: 'reason',
    includeIfNull: false,
    toJson: blockedClaimOutReasonToJson,
    fromJson: blockedClaimOutReasonFromJson,
  )
  final enums.BlockedClaimOutReason reason;
  @JsonKey(name: 'target', includeIfNull: false)
  final String target;
  static const fromJsonFactory = _$BlockedClaimOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BlockedClaimOut &&
            (identical(other.activeIngredient, activeIngredient) ||
                const DeepCollectionEquality().equals(
                  other.activeIngredient,
                  activeIngredient,
                )) &&
            (identical(other.formulation, formulation) ||
                const DeepCollectionEquality().equals(
                  other.formulation,
                  formulation,
                )) &&
            (identical(other.labelCrop, labelCrop) ||
                const DeepCollectionEquality().equals(
                  other.labelCrop,
                  labelCrop,
                )) &&
            (identical(other.notification, notification) ||
                const DeepCollectionEquality().equals(
                  other.notification,
                  notification,
                )) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.target, target) ||
                const DeepCollectionEquality().equals(other.target, target)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activeIngredient) ^
      const DeepCollectionEquality().hash(formulation) ^
      const DeepCollectionEquality().hash(labelCrop) ^
      const DeepCollectionEquality().hash(notification) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(target) ^
      runtimeType.hashCode;
}

extension $BlockedClaimOutExtension on BlockedClaimOut {
  BlockedClaimOut copyWith({
    String? activeIngredient,
    String? formulation,
    String? labelCrop,
    String? notification,
    enums.BlockedClaimOutReason? reason,
    String? target,
  }) {
    return BlockedClaimOut(
      activeIngredient: activeIngredient ?? this.activeIngredient,
      formulation: formulation ?? this.formulation,
      labelCrop: labelCrop ?? this.labelCrop,
      notification: notification ?? this.notification,
      reason: reason ?? this.reason,
      target: target ?? this.target,
    );
  }

  BlockedClaimOut copyWithWrapped({
    Wrapped<String>? activeIngredient,
    Wrapped<String>? formulation,
    Wrapped<String>? labelCrop,
    Wrapped<String>? notification,
    Wrapped<enums.BlockedClaimOutReason>? reason,
    Wrapped<String>? target,
  }) {
    return BlockedClaimOut(
      activeIngredient: (activeIngredient != null
          ? activeIngredient.value
          : this.activeIngredient),
      formulation: (formulation != null ? formulation.value : this.formulation),
      labelCrop: (labelCrop != null ? labelCrop.value : this.labelCrop),
      notification: (notification != null
          ? notification.value
          : this.notification),
      reason: (reason != null ? reason.value : this.reason),
      target: (target != null ? target.value : this.target),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BrokerIn {
  const BrokerIn({
    this.address,
    this.crops,
    required this.district,
    required this.fix,
    required this.name,
    required this.phone,
    this.serviceAreas,
    this.taluka,
    required this.village,
  });

  factory BrokerIn.fromJson(Map<String, dynamic> json) =>
      _$BrokerInFromJson(json);

  static const toJsonFactory = _$BrokerInToJson;
  Map<String, dynamic> toJson() => _$BrokerInToJson(this);

  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'crops', includeIfNull: false, defaultValue: <String>[])
  final List<String>? crops;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'fix', includeIfNull: false)
  final RegistrationFixIn fix;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String phone;
  @JsonKey(
    name: 'service_areas',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? serviceAreas;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'village', includeIfNull: false)
  final String village;
  static const fromJsonFactory = _$BrokerInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BrokerIn &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.crops, crops) ||
                const DeepCollectionEquality().equals(other.crops, crops)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.fix, fix) ||
                const DeepCollectionEquality().equals(other.fix, fix)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.serviceAreas, serviceAreas) ||
                const DeepCollectionEquality().equals(
                  other.serviceAreas,
                  serviceAreas,
                )) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(crops) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(fix) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(serviceAreas) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $BrokerInExtension on BrokerIn {
  BrokerIn copyWith({
    String? address,
    List<String>? crops,
    String? district,
    RegistrationFixIn? fix,
    String? name,
    String? phone,
    List<String>? serviceAreas,
    String? taluka,
    String? village,
  }) {
    return BrokerIn(
      address: address ?? this.address,
      crops: crops ?? this.crops,
      district: district ?? this.district,
      fix: fix ?? this.fix,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
    );
  }

  BrokerIn copyWithWrapped({
    Wrapped<String?>? address,
    Wrapped<List<String>?>? crops,
    Wrapped<String>? district,
    Wrapped<RegistrationFixIn>? fix,
    Wrapped<String>? name,
    Wrapped<String>? phone,
    Wrapped<List<String>?>? serviceAreas,
    Wrapped<String?>? taluka,
    Wrapped<String>? village,
  }) {
    return BrokerIn(
      address: (address != null ? address.value : this.address),
      crops: (crops != null ? crops.value : this.crops),
      district: (district != null ? district.value : this.district),
      fix: (fix != null ? fix.value : this.fix),
      name: (name != null ? name.value : this.name),
      phone: (phone != null ? phone.value : this.phone),
      serviceAreas: (serviceAreas != null
          ? serviceAreas.value
          : this.serviceAreas),
      taluka: (taluka != null ? taluka.value : this.taluka),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BuyerIn {
  const BuyerIn({
    this.address,
    this.apedaNo,
    this.apmcLicenceNo,
    this.crops,
    required this.district,
    this.firm,
    required this.fix,
    this.fssaiNo,
    this.gstNo,
    this.iecNo,
    this.markets,
    required this.name,
    required this.phone,
    this.taluka,
  });

  factory BuyerIn.fromJson(Map<String, dynamic> json) =>
      _$BuyerInFromJson(json);

  static const toJsonFactory = _$BuyerInToJson;
  Map<String, dynamic> toJson() => _$BuyerInToJson(this);

  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'apeda_no', includeIfNull: false)
  final String? apedaNo;
  @JsonKey(name: 'apmc_licence_no', includeIfNull: false)
  final String? apmcLicenceNo;
  @JsonKey(name: 'crops', includeIfNull: false, defaultValue: <String>[])
  final List<String>? crops;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'firm', includeIfNull: false)
  final String? firm;
  @JsonKey(name: 'fix', includeIfNull: false)
  final RegistrationFixIn fix;
  @JsonKey(name: 'fssai_no', includeIfNull: false)
  final String? fssaiNo;
  @JsonKey(name: 'gst_no', includeIfNull: false)
  final String? gstNo;
  @JsonKey(name: 'iec_no', includeIfNull: false)
  final String? iecNo;
  @JsonKey(name: 'markets', includeIfNull: false, defaultValue: <String>[])
  final List<String>? markets;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String phone;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  static const fromJsonFactory = _$BuyerInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BuyerIn &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.apedaNo, apedaNo) ||
                const DeepCollectionEquality().equals(
                  other.apedaNo,
                  apedaNo,
                )) &&
            (identical(other.apmcLicenceNo, apmcLicenceNo) ||
                const DeepCollectionEquality().equals(
                  other.apmcLicenceNo,
                  apmcLicenceNo,
                )) &&
            (identical(other.crops, crops) ||
                const DeepCollectionEquality().equals(other.crops, crops)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.firm, firm) ||
                const DeepCollectionEquality().equals(other.firm, firm)) &&
            (identical(other.fix, fix) ||
                const DeepCollectionEquality().equals(other.fix, fix)) &&
            (identical(other.fssaiNo, fssaiNo) ||
                const DeepCollectionEquality().equals(
                  other.fssaiNo,
                  fssaiNo,
                )) &&
            (identical(other.gstNo, gstNo) ||
                const DeepCollectionEquality().equals(other.gstNo, gstNo)) &&
            (identical(other.iecNo, iecNo) ||
                const DeepCollectionEquality().equals(other.iecNo, iecNo)) &&
            (identical(other.markets, markets) ||
                const DeepCollectionEquality().equals(
                  other.markets,
                  markets,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(apedaNo) ^
      const DeepCollectionEquality().hash(apmcLicenceNo) ^
      const DeepCollectionEquality().hash(crops) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(firm) ^
      const DeepCollectionEquality().hash(fix) ^
      const DeepCollectionEquality().hash(fssaiNo) ^
      const DeepCollectionEquality().hash(gstNo) ^
      const DeepCollectionEquality().hash(iecNo) ^
      const DeepCollectionEquality().hash(markets) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(taluka) ^
      runtimeType.hashCode;
}

extension $BuyerInExtension on BuyerIn {
  BuyerIn copyWith({
    String? address,
    String? apedaNo,
    String? apmcLicenceNo,
    List<String>? crops,
    String? district,
    String? firm,
    RegistrationFixIn? fix,
    String? fssaiNo,
    String? gstNo,
    String? iecNo,
    List<String>? markets,
    String? name,
    String? phone,
    String? taluka,
  }) {
    return BuyerIn(
      address: address ?? this.address,
      apedaNo: apedaNo ?? this.apedaNo,
      apmcLicenceNo: apmcLicenceNo ?? this.apmcLicenceNo,
      crops: crops ?? this.crops,
      district: district ?? this.district,
      firm: firm ?? this.firm,
      fix: fix ?? this.fix,
      fssaiNo: fssaiNo ?? this.fssaiNo,
      gstNo: gstNo ?? this.gstNo,
      iecNo: iecNo ?? this.iecNo,
      markets: markets ?? this.markets,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      taluka: taluka ?? this.taluka,
    );
  }

  BuyerIn copyWithWrapped({
    Wrapped<String?>? address,
    Wrapped<String?>? apedaNo,
    Wrapped<String?>? apmcLicenceNo,
    Wrapped<List<String>?>? crops,
    Wrapped<String>? district,
    Wrapped<String?>? firm,
    Wrapped<RegistrationFixIn>? fix,
    Wrapped<String?>? fssaiNo,
    Wrapped<String?>? gstNo,
    Wrapped<String?>? iecNo,
    Wrapped<List<String>?>? markets,
    Wrapped<String>? name,
    Wrapped<String>? phone,
    Wrapped<String?>? taluka,
  }) {
    return BuyerIn(
      address: (address != null ? address.value : this.address),
      apedaNo: (apedaNo != null ? apedaNo.value : this.apedaNo),
      apmcLicenceNo: (apmcLicenceNo != null
          ? apmcLicenceNo.value
          : this.apmcLicenceNo),
      crops: (crops != null ? crops.value : this.crops),
      district: (district != null ? district.value : this.district),
      firm: (firm != null ? firm.value : this.firm),
      fix: (fix != null ? fix.value : this.fix),
      fssaiNo: (fssaiNo != null ? fssaiNo.value : this.fssaiNo),
      gstNo: (gstNo != null ? gstNo.value : this.gstNo),
      iecNo: (iecNo != null ? iecNo.value : this.iecNo),
      markets: (markets != null ? markets.value : this.markets),
      name: (name != null ? name.value : this.name),
      phone: (phone != null ? phone.value : this.phone),
      taluka: (taluka != null ? taluka.value : this.taluka),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BuyerLotOut {
  const BuyerLotOut({
    required this.askingRatePaise,
    required this.basis,
    required this.crop,
    required this.district,
    required this.harvestFrom,
    required this.harvestTo,
    required this.id,
    required this.photos,
    required this.publishedAt,
    required this.quality,
    required this.quantityT,
    required this.taluka,
    required this.variety,
    required this.village,
  });

  factory BuyerLotOut.fromJson(Map<String, dynamic> json) =>
      _$BuyerLotOutFromJson(json);

  static const toJsonFactory = _$BuyerLotOutToJson;
  Map<String, dynamic> toJson() => _$BuyerLotOutToJson(this);

  @JsonKey(name: 'asking_rate_paise', includeIfNull: false)
  final int? askingRatePaise;
  @JsonKey(name: 'basis', includeIfNull: false)
  final String basis;
  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'harvest_from', includeIfNull: false, toJson: _dateToJson)
  final DateTime harvestFrom;
  @JsonKey(name: 'harvest_to', includeIfNull: false, toJson: _dateToJson)
  final DateTime harvestTo;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'photos', includeIfNull: false, defaultValue: <LotPhotoView>[])
  final List<LotPhotoView> photos;
  @JsonKey(name: 'published_at', includeIfNull: false)
  final DateTime publishedAt;
  @JsonKey(name: 'quality', includeIfNull: false)
  final String? quality;
  @JsonKey(name: 'quantity_t', includeIfNull: false)
  final double quantityT;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'variety', includeIfNull: false)
  final String? variety;
  @JsonKey(name: 'village', includeIfNull: false)
  final String? village;
  static const fromJsonFactory = _$BuyerLotOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BuyerLotOut &&
            (identical(other.askingRatePaise, askingRatePaise) ||
                const DeepCollectionEquality().equals(
                  other.askingRatePaise,
                  askingRatePaise,
                )) &&
            (identical(other.basis, basis) ||
                const DeepCollectionEquality().equals(other.basis, basis)) &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.harvestFrom, harvestFrom) ||
                const DeepCollectionEquality().equals(
                  other.harvestFrom,
                  harvestFrom,
                )) &&
            (identical(other.harvestTo, harvestTo) ||
                const DeepCollectionEquality().equals(
                  other.harvestTo,
                  harvestTo,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.photos, photos) ||
                const DeepCollectionEquality().equals(other.photos, photos)) &&
            (identical(other.publishedAt, publishedAt) ||
                const DeepCollectionEquality().equals(
                  other.publishedAt,
                  publishedAt,
                )) &&
            (identical(other.quality, quality) ||
                const DeepCollectionEquality().equals(
                  other.quality,
                  quality,
                )) &&
            (identical(other.quantityT, quantityT) ||
                const DeepCollectionEquality().equals(
                  other.quantityT,
                  quantityT,
                )) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.variety, variety) ||
                const DeepCollectionEquality().equals(
                  other.variety,
                  variety,
                )) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(askingRatePaise) ^
      const DeepCollectionEquality().hash(basis) ^
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(harvestFrom) ^
      const DeepCollectionEquality().hash(harvestTo) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(photos) ^
      const DeepCollectionEquality().hash(publishedAt) ^
      const DeepCollectionEquality().hash(quality) ^
      const DeepCollectionEquality().hash(quantityT) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(variety) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $BuyerLotOutExtension on BuyerLotOut {
  BuyerLotOut copyWith({
    int? askingRatePaise,
    String? basis,
    String? crop,
    String? district,
    DateTime? harvestFrom,
    DateTime? harvestTo,
    String? id,
    List<LotPhotoView>? photos,
    DateTime? publishedAt,
    String? quality,
    double? quantityT,
    String? taluka,
    String? variety,
    String? village,
  }) {
    return BuyerLotOut(
      askingRatePaise: askingRatePaise ?? this.askingRatePaise,
      basis: basis ?? this.basis,
      crop: crop ?? this.crop,
      district: district ?? this.district,
      harvestFrom: harvestFrom ?? this.harvestFrom,
      harvestTo: harvestTo ?? this.harvestTo,
      id: id ?? this.id,
      photos: photos ?? this.photos,
      publishedAt: publishedAt ?? this.publishedAt,
      quality: quality ?? this.quality,
      quantityT: quantityT ?? this.quantityT,
      taluka: taluka ?? this.taluka,
      variety: variety ?? this.variety,
      village: village ?? this.village,
    );
  }

  BuyerLotOut copyWithWrapped({
    Wrapped<int?>? askingRatePaise,
    Wrapped<String>? basis,
    Wrapped<String>? crop,
    Wrapped<String?>? district,
    Wrapped<DateTime>? harvestFrom,
    Wrapped<DateTime>? harvestTo,
    Wrapped<String>? id,
    Wrapped<List<LotPhotoView>>? photos,
    Wrapped<DateTime>? publishedAt,
    Wrapped<String?>? quality,
    Wrapped<double>? quantityT,
    Wrapped<String?>? taluka,
    Wrapped<String?>? variety,
    Wrapped<String?>? village,
  }) {
    return BuyerLotOut(
      askingRatePaise: (askingRatePaise != null
          ? askingRatePaise.value
          : this.askingRatePaise),
      basis: (basis != null ? basis.value : this.basis),
      crop: (crop != null ? crop.value : this.crop),
      district: (district != null ? district.value : this.district),
      harvestFrom: (harvestFrom != null ? harvestFrom.value : this.harvestFrom),
      harvestTo: (harvestTo != null ? harvestTo.value : this.harvestTo),
      id: (id != null ? id.value : this.id),
      photos: (photos != null ? photos.value : this.photos),
      publishedAt: (publishedAt != null ? publishedAt.value : this.publishedAt),
      quality: (quality != null ? quality.value : this.quality),
      quantityT: (quantityT != null ? quantityT.value : this.quantityT),
      taluka: (taluka != null ? taluka.value : this.taluka),
      variety: (variety != null ? variety.value : this.variety),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class BuyerLotsResponse {
  const BuyerLotsResponse({required this.lots});

  factory BuyerLotsResponse.fromJson(Map<String, dynamic> json) =>
      _$BuyerLotsResponseFromJson(json);

  static const toJsonFactory = _$BuyerLotsResponseToJson;
  Map<String, dynamic> toJson() => _$BuyerLotsResponseToJson(this);

  @JsonKey(name: 'lots', includeIfNull: false, defaultValue: <BuyerLotOut>[])
  final List<BuyerLotOut> lots;
  static const fromJsonFactory = _$BuyerLotsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BuyerLotsResponse &&
            (identical(other.lots, lots) ||
                const DeepCollectionEquality().equals(other.lots, lots)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(lots) ^ runtimeType.hashCode;
}

extension $BuyerLotsResponseExtension on BuyerLotsResponse {
  BuyerLotsResponse copyWith({List<BuyerLotOut>? lots}) {
    return BuyerLotsResponse(lots: lots ?? this.lots);
  }

  BuyerLotsResponse copyWithWrapped({Wrapped<List<BuyerLotOut>>? lots}) {
    return BuyerLotsResponse(lots: (lots != null ? lots.value : this.lots));
  }
}

@JsonSerializable(explicitToJson: true)
class CardOut {
  const CardOut({
    required this.crop,
    required this.hasChemicalOptions,
    required this.id,
    required this.reviewDueAt,
    required this.status,
    required this.title,
    required this.topic,
    required this.version,
  });

  factory CardOut.fromJson(Map<String, dynamic> json) =>
      _$CardOutFromJson(json);

  static const toJsonFactory = _$CardOutToJson;
  Map<String, dynamic> toJson() => _$CardOutToJson(this);

  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'has_chemical_options', includeIfNull: false)
  final bool hasChemicalOptions;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'review_due_at', includeIfNull: false)
  final DateTime? reviewDueAt;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(name: 'topic', includeIfNull: false)
  final String topic;
  @JsonKey(name: 'version', includeIfNull: false)
  final int version;
  static const fromJsonFactory = _$CardOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CardOut &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.hasChemicalOptions, hasChemicalOptions) ||
                const DeepCollectionEquality().equals(
                  other.hasChemicalOptions,
                  hasChemicalOptions,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.reviewDueAt, reviewDueAt) ||
                const DeepCollectionEquality().equals(
                  other.reviewDueAt,
                  reviewDueAt,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.topic, topic) ||
                const DeepCollectionEquality().equals(other.topic, topic)) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(hasChemicalOptions) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(reviewDueAt) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(topic) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $CardOutExtension on CardOut {
  CardOut copyWith({
    String? crop,
    bool? hasChemicalOptions,
    String? id,
    DateTime? reviewDueAt,
    String? status,
    String? title,
    String? topic,
    int? version,
  }) {
    return CardOut(
      crop: crop ?? this.crop,
      hasChemicalOptions: hasChemicalOptions ?? this.hasChemicalOptions,
      id: id ?? this.id,
      reviewDueAt: reviewDueAt ?? this.reviewDueAt,
      status: status ?? this.status,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      version: version ?? this.version,
    );
  }

  CardOut copyWithWrapped({
    Wrapped<String>? crop,
    Wrapped<bool>? hasChemicalOptions,
    Wrapped<String>? id,
    Wrapped<DateTime?>? reviewDueAt,
    Wrapped<String>? status,
    Wrapped<String>? title,
    Wrapped<String>? topic,
    Wrapped<int>? version,
  }) {
    return CardOut(
      crop: (crop != null ? crop.value : this.crop),
      hasChemicalOptions: (hasChemicalOptions != null
          ? hasChemicalOptions.value
          : this.hasChemicalOptions),
      id: (id != null ? id.value : this.id),
      reviewDueAt: (reviewDueAt != null ? reviewDueAt.value : this.reviewDueAt),
      status: (status != null ? status.value : this.status),
      title: (title != null ? title.value : this.title),
      topic: (topic != null ? topic.value : this.topic),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CardSourceOut {
  const CardSourceOut({
    required this.checked,
    required this.publisher,
    required this.title,
    required this.url,
  });

  factory CardSourceOut.fromJson(Map<String, dynamic> json) =>
      _$CardSourceOutFromJson(json);

  static const toJsonFactory = _$CardSourceOutToJson;
  Map<String, dynamic> toJson() => _$CardSourceOutToJson(this);

  @JsonKey(name: 'checked', includeIfNull: false, toJson: _dateToJson)
  final DateTime? checked;
  @JsonKey(name: 'publisher', includeIfNull: false)
  final String publisher;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  static const fromJsonFactory = _$CardSourceOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CardSourceOut &&
            (identical(other.checked, checked) ||
                const DeepCollectionEquality().equals(
                  other.checked,
                  checked,
                )) &&
            (identical(other.publisher, publisher) ||
                const DeepCollectionEquality().equals(
                  other.publisher,
                  publisher,
                )) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(checked) ^
      const DeepCollectionEquality().hash(publisher) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(url) ^
      runtimeType.hashCode;
}

extension $CardSourceOutExtension on CardSourceOut {
  CardSourceOut copyWith({
    DateTime? checked,
    String? publisher,
    String? title,
    String? url,
  }) {
    return CardSourceOut(
      checked: checked ?? this.checked,
      publisher: publisher ?? this.publisher,
      title: title ?? this.title,
      url: url ?? this.url,
    );
  }

  CardSourceOut copyWithWrapped({
    Wrapped<DateTime?>? checked,
    Wrapped<String>? publisher,
    Wrapped<String>? title,
    Wrapped<String>? url,
  }) {
    return CardSourceOut(
      checked: (checked != null ? checked.value : this.checked),
      publisher: (publisher != null ? publisher.value : this.publisher),
      title: (title != null ? title.value : this.title),
      url: (url != null ? url.value : this.url),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CardText {
  const CardText({
    this.cultural,
    this.summary,
    this.title,
    this.warnings,
    this.whenToCallExpert,
  });

  factory CardText.fromJson(Map<String, dynamic> json) =>
      _$CardTextFromJson(json);

  static const toJsonFactory = _$CardTextToJson;
  Map<String, dynamic> toJson() => _$CardTextToJson(this);

  @JsonKey(name: 'cultural', includeIfNull: false)
  final String? cultural;
  @JsonKey(name: 'summary', includeIfNull: false)
  final String? summary;
  @JsonKey(name: 'title', includeIfNull: false)
  final String? title;
  @JsonKey(name: 'warnings', includeIfNull: false)
  final String? warnings;
  @JsonKey(name: 'when_to_call_expert', includeIfNull: false)
  final String? whenToCallExpert;
  static const fromJsonFactory = _$CardTextFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CardText &&
            (identical(other.cultural, cultural) ||
                const DeepCollectionEquality().equals(
                  other.cultural,
                  cultural,
                )) &&
            (identical(other.summary, summary) ||
                const DeepCollectionEquality().equals(
                  other.summary,
                  summary,
                )) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.warnings, warnings) ||
                const DeepCollectionEquality().equals(
                  other.warnings,
                  warnings,
                )) &&
            (identical(other.whenToCallExpert, whenToCallExpert) ||
                const DeepCollectionEquality().equals(
                  other.whenToCallExpert,
                  whenToCallExpert,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cultural) ^
      const DeepCollectionEquality().hash(summary) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(warnings) ^
      const DeepCollectionEquality().hash(whenToCallExpert) ^
      runtimeType.hashCode;
}

extension $CardTextExtension on CardText {
  CardText copyWith({
    String? cultural,
    String? summary,
    String? title,
    String? warnings,
    String? whenToCallExpert,
  }) {
    return CardText(
      cultural: cultural ?? this.cultural,
      summary: summary ?? this.summary,
      title: title ?? this.title,
      warnings: warnings ?? this.warnings,
      whenToCallExpert: whenToCallExpert ?? this.whenToCallExpert,
    );
  }

  CardText copyWithWrapped({
    Wrapped<String?>? cultural,
    Wrapped<String?>? summary,
    Wrapped<String?>? title,
    Wrapped<String?>? warnings,
    Wrapped<String?>? whenToCallExpert,
  }) {
    return CardText(
      cultural: (cultural != null ? cultural.value : this.cultural),
      summary: (summary != null ? summary.value : this.summary),
      title: (title != null ? title.value : this.title),
      warnings: (warnings != null ? warnings.value : this.warnings),
      whenToCallExpert: (whenToCallExpert != null
          ? whenToCallExpert.value
          : this.whenToCallExpert),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CardsResponse {
  const CardsResponse({required this.cards});

  factory CardsResponse.fromJson(Map<String, dynamic> json) =>
      _$CardsResponseFromJson(json);

  static const toJsonFactory = _$CardsResponseToJson;
  Map<String, dynamic> toJson() => _$CardsResponseToJson(this);

  @JsonKey(name: 'cards', includeIfNull: false, defaultValue: <CardOut>[])
  final List<CardOut> cards;
  static const fromJsonFactory = _$CardsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CardsResponse &&
            (identical(other.cards, cards) ||
                const DeepCollectionEquality().equals(other.cards, cards)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cards) ^ runtimeType.hashCode;
}

extension $CardsResponseExtension on CardsResponse {
  CardsResponse copyWith({List<CardOut>? cards}) {
    return CardsResponse(cards: cards ?? this.cards);
  }

  CardsResponse copyWithWrapped({Wrapped<List<CardOut>>? cards}) {
    return CardsResponse(cards: (cards != null ? cards.value : this.cards));
  }
}

@JsonSerializable(explicitToJson: true)
class Change {
  const Change({
    required this.data,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.seq,
    required this.updatedAt,
  });

  factory Change.fromJson(Map<String, dynamic> json) => _$ChangeFromJson(json);

  static const toJsonFactory = _$ChangeToJson;
  Map<String, dynamic> toJson() => _$ChangeToJson(this);

  @JsonKey(name: 'data', includeIfNull: false)
  final Map<String, dynamic> data;
  @JsonKey(name: 'entity', includeIfNull: false)
  final String entity;
  @JsonKey(name: 'entity_id', includeIfNull: false)
  final String entityId;
  @JsonKey(
    name: 'op',
    includeIfNull: false,
    toJson: changeOpToJson,
    fromJson: changeOpFromJson,
  )
  final enums.ChangeOp op;
  @JsonKey(name: 'seq', includeIfNull: false)
  final int seq;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime updatedAt;
  static const fromJsonFactory = _$ChangeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Change &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)) &&
            (identical(other.entity, entity) ||
                const DeepCollectionEquality().equals(other.entity, entity)) &&
            (identical(other.entityId, entityId) ||
                const DeepCollectionEquality().equals(
                  other.entityId,
                  entityId,
                )) &&
            (identical(other.op, op) ||
                const DeepCollectionEquality().equals(other.op, op)) &&
            (identical(other.seq, seq) ||
                const DeepCollectionEquality().equals(other.seq, seq)) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(data) ^
      const DeepCollectionEquality().hash(entity) ^
      const DeepCollectionEquality().hash(entityId) ^
      const DeepCollectionEquality().hash(op) ^
      const DeepCollectionEquality().hash(seq) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      runtimeType.hashCode;
}

extension $ChangeExtension on Change {
  Change copyWith({
    Map<String, dynamic>? data,
    String? entity,
    String? entityId,
    enums.ChangeOp? op,
    int? seq,
    DateTime? updatedAt,
  }) {
    return Change(
      data: data ?? this.data,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      seq: seq ?? this.seq,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Change copyWithWrapped({
    Wrapped<Map<String, dynamic>>? data,
    Wrapped<String>? entity,
    Wrapped<String>? entityId,
    Wrapped<enums.ChangeOp>? op,
    Wrapped<int>? seq,
    Wrapped<DateTime>? updatedAt,
  }) {
    return Change(
      data: (data != null ? data.value : this.data),
      entity: (entity != null ? entity.value : this.entity),
      entityId: (entityId != null ? entityId.value : this.entityId),
      op: (op != null ? op.value : this.op),
      seq: (seq != null ? seq.value : this.seq),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DecisionIn {
  const DecisionIn({this.reason, required this.status});

  factory DecisionIn.fromJson(Map<String, dynamic> json) =>
      _$DecisionInFromJson(json);

  static const toJsonFactory = _$DecisionInToJson;
  Map<String, dynamic> toJson() => _$DecisionInToJson(this);

  @JsonKey(name: 'reason', includeIfNull: false)
  final String? reason;
  @JsonKey(
    name: 'status',
    includeIfNull: false,
    toJson: decisionInStatusToJson,
    fromJson: decisionInStatusFromJson,
  )
  final enums.DecisionInStatus status;
  static const fromJsonFactory = _$DecisionInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DecisionIn &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $DecisionInExtension on DecisionIn {
  DecisionIn copyWith({String? reason, enums.DecisionInStatus? status}) {
    return DecisionIn(
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  DecisionIn copyWithWrapped({
    Wrapped<String?>? reason,
    Wrapped<enums.DecisionInStatus>? status,
  }) {
    return DecisionIn(
      reason: (reason != null ? reason.value : this.reason),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DeviceIn {
  const DeviceIn({required this.platform, required this.token});

  factory DeviceIn.fromJson(Map<String, dynamic> json) =>
      _$DeviceInFromJson(json);

  static const toJsonFactory = _$DeviceInToJson;
  Map<String, dynamic> toJson() => _$DeviceInToJson(this);

  @JsonKey(
    name: 'platform',
    includeIfNull: false,
    toJson: deviceInPlatformToJson,
    fromJson: deviceInPlatformFromJson,
  )
  final enums.DeviceInPlatform platform;
  @JsonKey(name: 'token', includeIfNull: false)
  final String token;
  static const fromJsonFactory = _$DeviceInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DeviceIn &&
            (identical(other.platform, platform) ||
                const DeepCollectionEquality().equals(
                  other.platform,
                  platform,
                )) &&
            (identical(other.token, token) ||
                const DeepCollectionEquality().equals(other.token, token)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(platform) ^
      const DeepCollectionEquality().hash(token) ^
      runtimeType.hashCode;
}

extension $DeviceInExtension on DeviceIn {
  DeviceIn copyWith({enums.DeviceInPlatform? platform, String? token}) {
    return DeviceIn(
      platform: platform ?? this.platform,
      token: token ?? this.token,
    );
  }

  DeviceIn copyWithWrapped({
    Wrapped<enums.DeviceInPlatform>? platform,
    Wrapped<String>? token,
  }) {
    return DeviceIn(
      platform: (platform != null ? platform.value : this.platform),
      token: (token != null ? token.value : this.token),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DeviceOut {
  const DeviceOut({required this.token});

  factory DeviceOut.fromJson(Map<String, dynamic> json) =>
      _$DeviceOutFromJson(json);

  static const toJsonFactory = _$DeviceOutToJson;
  Map<String, dynamic> toJson() => _$DeviceOutToJson(this);

  @JsonKey(name: 'token', includeIfNull: false)
  final String token;
  static const fromJsonFactory = _$DeviceOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DeviceOut &&
            (identical(other.token, token) ||
                const DeepCollectionEquality().equals(other.token, token)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(token) ^ runtimeType.hashCode;
}

extension $DeviceOutExtension on DeviceOut {
  DeviceOut copyWith({String? token}) {
    return DeviceOut(token: token ?? this.token);
  }

  DeviceOut copyWithWrapped({Wrapped<String>? token}) {
    return DeviceOut(token: (token != null ? token.value : this.token));
  }
}

@JsonSerializable(explicitToJson: true)
class EntitlementsOut {
  const EntitlementsOut({
    required this.computedAt,
    required this.features,
    required this.plans,
    required this.validUntil,
  });

  factory EntitlementsOut.fromJson(Map<String, dynamic> json) =>
      _$EntitlementsOutFromJson(json);

  static const toJsonFactory = _$EntitlementsOutToJson;
  Map<String, dynamic> toJson() => _$EntitlementsOutToJson(this);

  @JsonKey(name: 'computed_at', includeIfNull: false)
  final String computedAt;
  @JsonKey(name: 'features', includeIfNull: false)
  final Map<String, dynamic> features;
  @JsonKey(name: 'plans', includeIfNull: false, defaultValue: <String>[])
  final List<String> plans;
  @JsonKey(name: 'valid_until', includeIfNull: false)
  final String validUntil;
  static const fromJsonFactory = _$EntitlementsOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EntitlementsOut &&
            (identical(other.computedAt, computedAt) ||
                const DeepCollectionEquality().equals(
                  other.computedAt,
                  computedAt,
                )) &&
            (identical(other.features, features) ||
                const DeepCollectionEquality().equals(
                  other.features,
                  features,
                )) &&
            (identical(other.plans, plans) ||
                const DeepCollectionEquality().equals(other.plans, plans)) &&
            (identical(other.validUntil, validUntil) ||
                const DeepCollectionEquality().equals(
                  other.validUntil,
                  validUntil,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(computedAt) ^
      const DeepCollectionEquality().hash(features) ^
      const DeepCollectionEquality().hash(plans) ^
      const DeepCollectionEquality().hash(validUntil) ^
      runtimeType.hashCode;
}

extension $EntitlementsOutExtension on EntitlementsOut {
  EntitlementsOut copyWith({
    String? computedAt,
    Map<String, dynamic>? features,
    List<String>? plans,
    String? validUntil,
  }) {
    return EntitlementsOut(
      computedAt: computedAt ?? this.computedAt,
      features: features ?? this.features,
      plans: plans ?? this.plans,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  EntitlementsOut copyWithWrapped({
    Wrapped<String>? computedAt,
    Wrapped<Map<String, dynamic>>? features,
    Wrapped<List<String>>? plans,
    Wrapped<String>? validUntil,
  }) {
    return EntitlementsOut(
      computedAt: (computedAt != null ? computedAt.value : this.computedAt),
      features: (features != null ? features.value : this.features),
      plans: (plans != null ? plans.value : this.plans),
      validUntil: (validUntil != null ? validUntil.value : this.validUntil),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class EntitlementsResponse {
  const EntitlementsResponse({
    required this.entitlements,
    required this.signature,
  });

  factory EntitlementsResponse.fromJson(Map<String, dynamic> json) =>
      _$EntitlementsResponseFromJson(json);

  static const toJsonFactory = _$EntitlementsResponseToJson;
  Map<String, dynamic> toJson() => _$EntitlementsResponseToJson(this);

  @JsonKey(name: 'entitlements', includeIfNull: false)
  final EntitlementsOut entitlements;
  @JsonKey(name: 'signature', includeIfNull: false)
  final String? signature;
  static const fromJsonFactory = _$EntitlementsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EntitlementsResponse &&
            (identical(other.entitlements, entitlements) ||
                const DeepCollectionEquality().equals(
                  other.entitlements,
                  entitlements,
                )) &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(entitlements) ^
      const DeepCollectionEquality().hash(signature) ^
      runtimeType.hashCode;
}

extension $EntitlementsResponseExtension on EntitlementsResponse {
  EntitlementsResponse copyWith({
    EntitlementsOut? entitlements,
    String? signature,
  }) {
    return EntitlementsResponse(
      entitlements: entitlements ?? this.entitlements,
      signature: signature ?? this.signature,
    );
  }

  EntitlementsResponse copyWithWrapped({
    Wrapped<EntitlementsOut>? entitlements,
    Wrapped<String?>? signature,
  }) {
    return EntitlementsResponse(
      entitlements: (entitlements != null
          ? entitlements.value
          : this.entitlements),
      signature: (signature != null ? signature.value : this.signature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ErrorBody {
  const ErrorBody({
    required this.code,
    required this.message,
    required this.requestId,
  });

  factory ErrorBody.fromJson(Map<String, dynamic> json) =>
      _$ErrorBodyFromJson(json);

  static const toJsonFactory = _$ErrorBodyToJson;
  Map<String, dynamic> toJson() => _$ErrorBodyToJson(this);

  @JsonKey(name: 'code', includeIfNull: false)
  final String code;
  @JsonKey(name: 'message', includeIfNull: false)
  final String message;
  @JsonKey(name: 'request_id', includeIfNull: false)
  final String requestId;
  static const fromJsonFactory = _$ErrorBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ErrorBody &&
            (identical(other.code, code) ||
                const DeepCollectionEquality().equals(other.code, code)) &&
            (identical(other.message, message) ||
                const DeepCollectionEquality().equals(
                  other.message,
                  message,
                )) &&
            (identical(other.requestId, requestId) ||
                const DeepCollectionEquality().equals(
                  other.requestId,
                  requestId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(code) ^
      const DeepCollectionEquality().hash(message) ^
      const DeepCollectionEquality().hash(requestId) ^
      runtimeType.hashCode;
}

extension $ErrorBodyExtension on ErrorBody {
  ErrorBody copyWith({String? code, String? message, String? requestId}) {
    return ErrorBody(
      code: code ?? this.code,
      message: message ?? this.message,
      requestId: requestId ?? this.requestId,
    );
  }

  ErrorBody copyWithWrapped({
    Wrapped<String>? code,
    Wrapped<String>? message,
    Wrapped<String>? requestId,
  }) {
    return ErrorBody(
      code: (code != null ? code.value : this.code),
      message: (message != null ? message.value : this.message),
      requestId: (requestId != null ? requestId.value : this.requestId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ErrorResponse {
  const ErrorResponse({required this.error});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  static const toJsonFactory = _$ErrorResponseToJson;
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @JsonKey(name: 'error', includeIfNull: false)
  final ErrorBody error;
  static const fromJsonFactory = _$ErrorResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ErrorResponse &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(error) ^ runtimeType.hashCode;
}

extension $ErrorResponseExtension on ErrorResponse {
  ErrorResponse copyWith({ErrorBody? error}) {
    return ErrorResponse(error: error ?? this.error);
  }

  ErrorResponse copyWithWrapped({Wrapped<ErrorBody>? error}) {
    return ErrorResponse(error: (error != null ? error.value : this.error));
  }
}

@JsonSerializable(explicitToJson: true)
class EventOut {
  const EventOut({
    required this.createdAt,
    required this.eventType,
    required this.id,
    required this.provider,
    required this.subscriptionId,
  });

  factory EventOut.fromJson(Map<String, dynamic> json) =>
      _$EventOutFromJson(json);

  static const toJsonFactory = _$EventOutToJson;
  Map<String, dynamic> toJson() => _$EventOutToJson(this);

  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'event_type', includeIfNull: false)
  final String eventType;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'provider', includeIfNull: false)
  final String provider;
  @JsonKey(name: 'subscription_id', includeIfNull: false)
  final String? subscriptionId;
  static const fromJsonFactory = _$EventOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EventOut &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.eventType, eventType) ||
                const DeepCollectionEquality().equals(
                  other.eventType,
                  eventType,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.provider, provider) ||
                const DeepCollectionEquality().equals(
                  other.provider,
                  provider,
                )) &&
            (identical(other.subscriptionId, subscriptionId) ||
                const DeepCollectionEquality().equals(
                  other.subscriptionId,
                  subscriptionId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(eventType) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(provider) ^
      const DeepCollectionEquality().hash(subscriptionId) ^
      runtimeType.hashCode;
}

extension $EventOutExtension on EventOut {
  EventOut copyWith({
    DateTime? createdAt,
    String? eventType,
    String? id,
    String? provider,
    String? subscriptionId,
  }) {
    return EventOut(
      createdAt: createdAt ?? this.createdAt,
      eventType: eventType ?? this.eventType,
      id: id ?? this.id,
      provider: provider ?? this.provider,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }

  EventOut copyWithWrapped({
    Wrapped<DateTime>? createdAt,
    Wrapped<String>? eventType,
    Wrapped<String>? id,
    Wrapped<String>? provider,
    Wrapped<String?>? subscriptionId,
  }) {
    return EventOut(
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      eventType: (eventType != null ? eventType.value : this.eventType),
      id: (id != null ? id.value : this.id),
      provider: (provider != null ? provider.value : this.provider),
      subscriptionId: (subscriptionId != null
          ? subscriptionId.value
          : this.subscriptionId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class EventsResponse {
  const EventsResponse({required this.events});

  factory EventsResponse.fromJson(Map<String, dynamic> json) =>
      _$EventsResponseFromJson(json);

  static const toJsonFactory = _$EventsResponseToJson;
  Map<String, dynamic> toJson() => _$EventsResponseToJson(this);

  @JsonKey(name: 'events', includeIfNull: false, defaultValue: <EventOut>[])
  final List<EventOut> events;
  static const fromJsonFactory = _$EventsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EventsResponse &&
            (identical(other.events, events) ||
                const DeepCollectionEquality().equals(other.events, events)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(events) ^ runtimeType.hashCode;
}

extension $EventsResponseExtension on EventsResponse {
  EventsResponse copyWith({List<EventOut>? events}) {
    return EventsResponse(events: events ?? this.events);
  }

  EventsResponse copyWithWrapped({Wrapped<List<EventOut>>? events}) {
    return EventsResponse(
      events: (events != null ? events.value : this.events),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FarmerProfile {
  const FarmerProfile({
    required this.consentDataProcessing,
    required this.consentWhatsapp,
    required this.displayName,
    required this.district,
    required this.id,
    required this.language,
    required this.phone,
    required this.taluka,
    required this.village,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) =>
      _$FarmerProfileFromJson(json);

  static const toJsonFactory = _$FarmerProfileToJson;
  Map<String, dynamic> toJson() => _$FarmerProfileToJson(this);

  @JsonKey(name: 'consent_data_processing', includeIfNull: false)
  final bool consentDataProcessing;
  @JsonKey(name: 'consent_whatsapp', includeIfNull: false)
  final bool consentWhatsapp;
  @JsonKey(name: 'display_name', includeIfNull: false)
  final String? displayName;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'language', includeIfNull: false)
  final String language;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String? phone;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'village', includeIfNull: false)
  final String? village;
  static const fromJsonFactory = _$FarmerProfileFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FarmerProfile &&
            (identical(other.consentDataProcessing, consentDataProcessing) ||
                const DeepCollectionEquality().equals(
                  other.consentDataProcessing,
                  consentDataProcessing,
                )) &&
            (identical(other.consentWhatsapp, consentWhatsapp) ||
                const DeepCollectionEquality().equals(
                  other.consentWhatsapp,
                  consentWhatsapp,
                )) &&
            (identical(other.displayName, displayName) ||
                const DeepCollectionEquality().equals(
                  other.displayName,
                  displayName,
                )) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.language, language) ||
                const DeepCollectionEquality().equals(
                  other.language,
                  language,
                )) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(consentDataProcessing) ^
      const DeepCollectionEquality().hash(consentWhatsapp) ^
      const DeepCollectionEquality().hash(displayName) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(language) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $FarmerProfileExtension on FarmerProfile {
  FarmerProfile copyWith({
    bool? consentDataProcessing,
    bool? consentWhatsapp,
    String? displayName,
    String? district,
    String? id,
    String? language,
    String? phone,
    String? taluka,
    String? village,
  }) {
    return FarmerProfile(
      consentDataProcessing:
          consentDataProcessing ?? this.consentDataProcessing,
      consentWhatsapp: consentWhatsapp ?? this.consentWhatsapp,
      displayName: displayName ?? this.displayName,
      district: district ?? this.district,
      id: id ?? this.id,
      language: language ?? this.language,
      phone: phone ?? this.phone,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
    );
  }

  FarmerProfile copyWithWrapped({
    Wrapped<bool>? consentDataProcessing,
    Wrapped<bool>? consentWhatsapp,
    Wrapped<String?>? displayName,
    Wrapped<String?>? district,
    Wrapped<String>? id,
    Wrapped<String>? language,
    Wrapped<String?>? phone,
    Wrapped<String?>? taluka,
    Wrapped<String?>? village,
  }) {
    return FarmerProfile(
      consentDataProcessing: (consentDataProcessing != null
          ? consentDataProcessing.value
          : this.consentDataProcessing),
      consentWhatsapp: (consentWhatsapp != null
          ? consentWhatsapp.value
          : this.consentWhatsapp),
      displayName: (displayName != null ? displayName.value : this.displayName),
      district: (district != null ? district.value : this.district),
      id: (id != null ? id.value : this.id),
      language: (language != null ? language.value : this.language),
      phone: (phone != null ? phone.value : this.phone),
      taluka: (taluka != null ? taluka.value : this.taluka),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeatureConfig {
  const FeatureConfig({required this.feature, required this.limit});

  factory FeatureConfig.fromJson(Map<String, dynamic> json) =>
      _$FeatureConfigFromJson(json);

  static const toJsonFactory = _$FeatureConfigToJson;
  Map<String, dynamic> toJson() => _$FeatureConfigToJson(this);

  @JsonKey(name: 'feature', includeIfNull: false)
  final String feature;
  @JsonKey(name: 'limit', includeIfNull: false)
  final int? limit;
  static const fromJsonFactory = _$FeatureConfigFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeatureConfig &&
            (identical(other.feature, feature) ||
                const DeepCollectionEquality().equals(
                  other.feature,
                  feature,
                )) &&
            (identical(other.limit, limit) ||
                const DeepCollectionEquality().equals(other.limit, limit)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(feature) ^
      const DeepCollectionEquality().hash(limit) ^
      runtimeType.hashCode;
}

extension $FeatureConfigExtension on FeatureConfig {
  FeatureConfig copyWith({String? feature, int? limit}) {
    return FeatureConfig(
      feature: feature ?? this.feature,
      limit: limit ?? this.limit,
    );
  }

  FeatureConfig copyWithWrapped({
    Wrapped<String>? feature,
    Wrapped<int?>? limit,
  }) {
    return FeatureConfig(
      feature: (feature != null ? feature.value : this.feature),
      limit: (limit != null ? limit.value : this.limit),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeatureOut {
  const FeatureOut({required this.enabled, required this.limit});

  factory FeatureOut.fromJson(Map<String, dynamic> json) =>
      _$FeatureOutFromJson(json);

  static const toJsonFactory = _$FeatureOutToJson;
  Map<String, dynamic> toJson() => _$FeatureOutToJson(this);

  @JsonKey(name: 'enabled', includeIfNull: false)
  final bool enabled;
  @JsonKey(name: 'limit', includeIfNull: false)
  final int? limit;
  static const fromJsonFactory = _$FeatureOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeatureOut &&
            (identical(other.enabled, enabled) ||
                const DeepCollectionEquality().equals(
                  other.enabled,
                  enabled,
                )) &&
            (identical(other.limit, limit) ||
                const DeepCollectionEquality().equals(other.limit, limit)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(enabled) ^
      const DeepCollectionEquality().hash(limit) ^
      runtimeType.hashCode;
}

extension $FeatureOutExtension on FeatureOut {
  FeatureOut copyWith({bool? enabled, int? limit}) {
    return FeatureOut(
      enabled: enabled ?? this.enabled,
      limit: limit ?? this.limit,
    );
  }

  FeatureOut copyWithWrapped({Wrapped<bool>? enabled, Wrapped<int?>? limit}) {
    return FeatureOut(
      enabled: (enabled != null ? enabled.value : this.enabled),
      limit: (limit != null ? limit.value : this.limit),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminApproveIn {
  const FeedAdminApproveIn({this.acceptCheckIssues, this.comment});

  factory FeedAdminApproveIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminApproveInFromJson(json);

  static const toJsonFactory = _$FeedAdminApproveInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminApproveInToJson(this);

  @JsonKey(
    name: 'accept_check_issues',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? acceptCheckIssues;
  @JsonKey(name: 'comment', includeIfNull: false)
  final String? comment;
  static const fromJsonFactory = _$FeedAdminApproveInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminApproveIn &&
            (identical(other.acceptCheckIssues, acceptCheckIssues) ||
                const DeepCollectionEquality().equals(
                  other.acceptCheckIssues,
                  acceptCheckIssues,
                )) &&
            (identical(other.comment, comment) ||
                const DeepCollectionEquality().equals(other.comment, comment)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(acceptCheckIssues) ^
      const DeepCollectionEquality().hash(comment) ^
      runtimeType.hashCode;
}

extension $FeedAdminApproveInExtension on FeedAdminApproveIn {
  FeedAdminApproveIn copyWith({bool? acceptCheckIssues, String? comment}) {
    return FeedAdminApproveIn(
      acceptCheckIssues: acceptCheckIssues ?? this.acceptCheckIssues,
      comment: comment ?? this.comment,
    );
  }

  FeedAdminApproveIn copyWithWrapped({
    Wrapped<bool?>? acceptCheckIssues,
    Wrapped<String?>? comment,
  }) {
    return FeedAdminApproveIn(
      acceptCheckIssues: (acceptCheckIssues != null
          ? acceptCheckIssues.value
          : this.acceptCheckIssues),
      comment: (comment != null ? comment.value : this.comment),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminCardFieldIn {
  const FeedAdminCardFieldIn({this.page, required this.value});

  factory FeedAdminCardFieldIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminCardFieldInFromJson(json);

  static const toJsonFactory = _$FeedAdminCardFieldInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminCardFieldInToJson(this);

  @JsonKey(name: 'page', includeIfNull: false)
  final String? page;
  @JsonKey(name: 'value', includeIfNull: false)
  final String value;
  static const fromJsonFactory = _$FeedAdminCardFieldInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminCardFieldIn &&
            (identical(other.page, page) ||
                const DeepCollectionEquality().equals(other.page, page)) &&
            (identical(other.value, value) ||
                const DeepCollectionEquality().equals(other.value, value)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(page) ^
      const DeepCollectionEquality().hash(value) ^
      runtimeType.hashCode;
}

extension $FeedAdminCardFieldInExtension on FeedAdminCardFieldIn {
  FeedAdminCardFieldIn copyWith({String? page, String? value}) {
    return FeedAdminCardFieldIn(
      page: page ?? this.page,
      value: value ?? this.value,
    );
  }

  FeedAdminCardFieldIn copyWithWrapped({
    Wrapped<String?>? page,
    Wrapped<String>? value,
  }) {
    return FeedAdminCardFieldIn(
      page: (page != null ? page.value : this.page),
      value: (value != null ? value.value : this.value),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminCardIn {
  const FeedAdminCardIn({required this.fields});

  factory FeedAdminCardIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminCardInFromJson(json);

  static const toJsonFactory = _$FeedAdminCardInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminCardInToJson(this);

  @JsonKey(name: 'fields', includeIfNull: false)
  final Map<String, dynamic> fields;
  static const fromJsonFactory = _$FeedAdminCardInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminCardIn &&
            (identical(other.fields, fields) ||
                const DeepCollectionEquality().equals(other.fields, fields)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(fields) ^ runtimeType.hashCode;
}

extension $FeedAdminCardInExtension on FeedAdminCardIn {
  FeedAdminCardIn copyWith({Map<String, dynamic>? fields}) {
    return FeedAdminCardIn(fields: fields ?? this.fields);
  }

  FeedAdminCardIn copyWithWrapped({Wrapped<Map<String, dynamic>>? fields}) {
    return FeedAdminCardIn(
      fields: (fields != null ? fields.value : this.fields),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminCardOut {
  const FeedAdminCardOut({required this.fields, required this.version});

  factory FeedAdminCardOut.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminCardOutFromJson(json);

  static const toJsonFactory = _$FeedAdminCardOutToJson;
  Map<String, dynamic> toJson() => _$FeedAdminCardOutToJson(this);

  @JsonKey(name: 'fields', includeIfNull: false)
  final Map<String, dynamic> fields;
  @JsonKey(name: 'version', includeIfNull: false)
  final int version;
  static const fromJsonFactory = _$FeedAdminCardOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminCardOut &&
            (identical(other.fields, fields) ||
                const DeepCollectionEquality().equals(other.fields, fields)) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(fields) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $FeedAdminCardOutExtension on FeedAdminCardOut {
  FeedAdminCardOut copyWith({Map<String, dynamic>? fields, int? version}) {
    return FeedAdminCardOut(
      fields: fields ?? this.fields,
      version: version ?? this.version,
    );
  }

  FeedAdminCardOut copyWithWrapped({
    Wrapped<Map<String, dynamic>>? fields,
    Wrapped<int>? version,
  }) {
    return FeedAdminCardOut(
      fields: (fields != null ? fields.value : this.fields),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminCheckIssue {
  const FeedAdminCheckIssue({
    required this.kind,
    required this.text,
    required this.where,
  });

  factory FeedAdminCheckIssue.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminCheckIssueFromJson(json);

  static const toJsonFactory = _$FeedAdminCheckIssueToJson;
  Map<String, dynamic> toJson() => _$FeedAdminCheckIssueToJson(this);

  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  @JsonKey(name: 'text', includeIfNull: false)
  final String text;
  @JsonKey(name: 'where', includeIfNull: false)
  final String where;
  static const fromJsonFactory = _$FeedAdminCheckIssueFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminCheckIssue &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.text, text) ||
                const DeepCollectionEquality().equals(other.text, text)) &&
            (identical(other.where, where) ||
                const DeepCollectionEquality().equals(other.where, where)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(text) ^
      const DeepCollectionEquality().hash(where) ^
      runtimeType.hashCode;
}

extension $FeedAdminCheckIssueExtension on FeedAdminCheckIssue {
  FeedAdminCheckIssue copyWith({String? kind, String? text, String? where}) {
    return FeedAdminCheckIssue(
      kind: kind ?? this.kind,
      text: text ?? this.text,
      where: where ?? this.where,
    );
  }

  FeedAdminCheckIssue copyWithWrapped({
    Wrapped<String>? kind,
    Wrapped<String>? text,
    Wrapped<String>? where,
  }) {
    return FeedAdminCheckIssue(
      kind: (kind != null ? kind.value : this.kind),
      text: (text != null ? text.value : this.text),
      where: (where != null ? where.value : this.where),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminDatesIn {
  const FeedAdminDatesIn({
    this.deadline,
    this.paymentDate,
    this.validFrom,
    this.validTo,
  });

  factory FeedAdminDatesIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminDatesInFromJson(json);

  static const toJsonFactory = _$FeedAdminDatesInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminDatesInToJson(this);

  @JsonKey(name: 'deadline', includeIfNull: false, toJson: _dateToJson)
  final DateTime? deadline;
  @JsonKey(name: 'payment_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime? paymentDate;
  @JsonKey(name: 'valid_from', includeIfNull: false, toJson: _dateToJson)
  final DateTime? validFrom;
  @JsonKey(name: 'valid_to', includeIfNull: false, toJson: _dateToJson)
  final DateTime? validTo;
  static const fromJsonFactory = _$FeedAdminDatesInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminDatesIn &&
            (identical(other.deadline, deadline) ||
                const DeepCollectionEquality().equals(
                  other.deadline,
                  deadline,
                )) &&
            (identical(other.paymentDate, paymentDate) ||
                const DeepCollectionEquality().equals(
                  other.paymentDate,
                  paymentDate,
                )) &&
            (identical(other.validFrom, validFrom) ||
                const DeepCollectionEquality().equals(
                  other.validFrom,
                  validFrom,
                )) &&
            (identical(other.validTo, validTo) ||
                const DeepCollectionEquality().equals(other.validTo, validTo)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(deadline) ^
      const DeepCollectionEquality().hash(paymentDate) ^
      const DeepCollectionEquality().hash(validFrom) ^
      const DeepCollectionEquality().hash(validTo) ^
      runtimeType.hashCode;
}

extension $FeedAdminDatesInExtension on FeedAdminDatesIn {
  FeedAdminDatesIn copyWith({
    DateTime? deadline,
    DateTime? paymentDate,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    return FeedAdminDatesIn(
      deadline: deadline ?? this.deadline,
      paymentDate: paymentDate ?? this.paymentDate,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
    );
  }

  FeedAdminDatesIn copyWithWrapped({
    Wrapped<DateTime?>? deadline,
    Wrapped<DateTime?>? paymentDate,
    Wrapped<DateTime?>? validFrom,
    Wrapped<DateTime?>? validTo,
  }) {
    return FeedAdminDatesIn(
      deadline: (deadline != null ? deadline.value : this.deadline),
      paymentDate: (paymentDate != null ? paymentDate.value : this.paymentDate),
      validFrom: (validFrom != null ? validFrom.value : this.validFrom),
      validTo: (validTo != null ? validTo.value : this.validTo),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminEventOut {
  const FeedAdminEventOut({
    required this.actorId,
    required this.createdAt,
    required this.detail,
    required this.kind,
  });

  factory FeedAdminEventOut.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminEventOutFromJson(json);

  static const toJsonFactory = _$FeedAdminEventOutToJson;
  Map<String, dynamic> toJson() => _$FeedAdminEventOutToJson(this);

  @JsonKey(name: 'actor_id', includeIfNull: false)
  final String? actorId;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'detail', includeIfNull: false)
  final Map<String, dynamic> detail;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  static const fromJsonFactory = _$FeedAdminEventOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminEventOut &&
            (identical(other.actorId, actorId) ||
                const DeepCollectionEquality().equals(
                  other.actorId,
                  actorId,
                )) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.detail, detail) ||
                const DeepCollectionEquality().equals(other.detail, detail)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(actorId) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(detail) ^
      const DeepCollectionEquality().hash(kind) ^
      runtimeType.hashCode;
}

extension $FeedAdminEventOutExtension on FeedAdminEventOut {
  FeedAdminEventOut copyWith({
    String? actorId,
    DateTime? createdAt,
    Map<String, dynamic>? detail,
    String? kind,
  }) {
    return FeedAdminEventOut(
      actorId: actorId ?? this.actorId,
      createdAt: createdAt ?? this.createdAt,
      detail: detail ?? this.detail,
      kind: kind ?? this.kind,
    );
  }

  FeedAdminEventOut copyWithWrapped({
    Wrapped<String?>? actorId,
    Wrapped<DateTime>? createdAt,
    Wrapped<Map<String, dynamic>>? detail,
    Wrapped<String>? kind,
  }) {
    return FeedAdminEventOut(
      actorId: (actorId != null ? actorId.value : this.actorId),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      detail: (detail != null ? detail.value : this.detail),
      kind: (kind != null ? kind.value : this.kind),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminItemIn {
  const FeedAdminItemIn({
    this.card,
    this.deadline,
    this.department,
    this.documentBase64,
    this.documentType,
    this.externalId,
    this.extractedText,
    this.grNumber,
    this.paymentDate,
    required this.publishedAt,
    required this.sourceKey,
    this.targets,
    this.texts,
    required this.type,
    required this.url,
    this.validFrom,
    this.validTo,
  });

  factory FeedAdminItemIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminItemInFromJson(json);

  static const toJsonFactory = _$FeedAdminItemInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminItemInToJson(this);

  @JsonKey(name: 'card', includeIfNull: false)
  final Object? card;
  @JsonKey(name: 'deadline', includeIfNull: false, toJson: _dateToJson)
  final DateTime? deadline;
  @JsonKey(name: 'department', includeIfNull: false)
  final String? department;
  @JsonKey(name: 'document_base64', includeIfNull: false)
  final String? documentBase64;
  @JsonKey(name: 'document_type', includeIfNull: false)
  final String? documentType;
  @JsonKey(name: 'external_id', includeIfNull: false)
  final String? externalId;
  @JsonKey(name: 'extracted_text', includeIfNull: false)
  final String? extractedText;
  @JsonKey(name: 'gr_number', includeIfNull: false)
  final String? grNumber;
  @JsonKey(name: 'payment_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime? paymentDate;
  @JsonKey(name: 'published_at', includeIfNull: false)
  final DateTime publishedAt;
  @JsonKey(name: 'source_key', includeIfNull: false)
  final String sourceKey;
  @JsonKey(
    name: 'targets',
    includeIfNull: false,
    defaultValue: <FeedAdminTargetIn>[],
  )
  final List<FeedAdminTargetIn>? targets;
  @JsonKey(name: 'texts', includeIfNull: false)
  final Map<String, dynamic>? texts;
  @JsonKey(
    name: 'type',
    includeIfNull: false,
    toJson: feedAdminItemInTypeToJson,
    fromJson: feedAdminItemInTypeFromJson,
  )
  final enums.FeedAdminItemInType type;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  @JsonKey(name: 'valid_from', includeIfNull: false, toJson: _dateToJson)
  final DateTime? validFrom;
  @JsonKey(name: 'valid_to', includeIfNull: false, toJson: _dateToJson)
  final DateTime? validTo;
  static const fromJsonFactory = _$FeedAdminItemInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminItemIn &&
            (identical(other.card, card) ||
                const DeepCollectionEquality().equals(other.card, card)) &&
            (identical(other.deadline, deadline) ||
                const DeepCollectionEquality().equals(
                  other.deadline,
                  deadline,
                )) &&
            (identical(other.department, department) ||
                const DeepCollectionEquality().equals(
                  other.department,
                  department,
                )) &&
            (identical(other.documentBase64, documentBase64) ||
                const DeepCollectionEquality().equals(
                  other.documentBase64,
                  documentBase64,
                )) &&
            (identical(other.documentType, documentType) ||
                const DeepCollectionEquality().equals(
                  other.documentType,
                  documentType,
                )) &&
            (identical(other.externalId, externalId) ||
                const DeepCollectionEquality().equals(
                  other.externalId,
                  externalId,
                )) &&
            (identical(other.extractedText, extractedText) ||
                const DeepCollectionEquality().equals(
                  other.extractedText,
                  extractedText,
                )) &&
            (identical(other.grNumber, grNumber) ||
                const DeepCollectionEquality().equals(
                  other.grNumber,
                  grNumber,
                )) &&
            (identical(other.paymentDate, paymentDate) ||
                const DeepCollectionEquality().equals(
                  other.paymentDate,
                  paymentDate,
                )) &&
            (identical(other.publishedAt, publishedAt) ||
                const DeepCollectionEquality().equals(
                  other.publishedAt,
                  publishedAt,
                )) &&
            (identical(other.sourceKey, sourceKey) ||
                const DeepCollectionEquality().equals(
                  other.sourceKey,
                  sourceKey,
                )) &&
            (identical(other.targets, targets) ||
                const DeepCollectionEquality().equals(
                  other.targets,
                  targets,
                )) &&
            (identical(other.texts, texts) ||
                const DeepCollectionEquality().equals(other.texts, texts)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
            (identical(other.validFrom, validFrom) ||
                const DeepCollectionEquality().equals(
                  other.validFrom,
                  validFrom,
                )) &&
            (identical(other.validTo, validTo) ||
                const DeepCollectionEquality().equals(other.validTo, validTo)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(card) ^
      const DeepCollectionEquality().hash(deadline) ^
      const DeepCollectionEquality().hash(department) ^
      const DeepCollectionEquality().hash(documentBase64) ^
      const DeepCollectionEquality().hash(documentType) ^
      const DeepCollectionEquality().hash(externalId) ^
      const DeepCollectionEquality().hash(extractedText) ^
      const DeepCollectionEquality().hash(grNumber) ^
      const DeepCollectionEquality().hash(paymentDate) ^
      const DeepCollectionEquality().hash(publishedAt) ^
      const DeepCollectionEquality().hash(sourceKey) ^
      const DeepCollectionEquality().hash(targets) ^
      const DeepCollectionEquality().hash(texts) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(validFrom) ^
      const DeepCollectionEquality().hash(validTo) ^
      runtimeType.hashCode;
}

extension $FeedAdminItemInExtension on FeedAdminItemIn {
  FeedAdminItemIn copyWith({
    Object? card,
    DateTime? deadline,
    String? department,
    String? documentBase64,
    String? documentType,
    String? externalId,
    String? extractedText,
    String? grNumber,
    DateTime? paymentDate,
    DateTime? publishedAt,
    String? sourceKey,
    List<FeedAdminTargetIn>? targets,
    Map<String, dynamic>? texts,
    enums.FeedAdminItemInType? type,
    String? url,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    return FeedAdminItemIn(
      card: card ?? this.card,
      deadline: deadline ?? this.deadline,
      department: department ?? this.department,
      documentBase64: documentBase64 ?? this.documentBase64,
      documentType: documentType ?? this.documentType,
      externalId: externalId ?? this.externalId,
      extractedText: extractedText ?? this.extractedText,
      grNumber: grNumber ?? this.grNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      publishedAt: publishedAt ?? this.publishedAt,
      sourceKey: sourceKey ?? this.sourceKey,
      targets: targets ?? this.targets,
      texts: texts ?? this.texts,
      type: type ?? this.type,
      url: url ?? this.url,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
    );
  }

  FeedAdminItemIn copyWithWrapped({
    Wrapped<Object?>? card,
    Wrapped<DateTime?>? deadline,
    Wrapped<String?>? department,
    Wrapped<String?>? documentBase64,
    Wrapped<String?>? documentType,
    Wrapped<String?>? externalId,
    Wrapped<String?>? extractedText,
    Wrapped<String?>? grNumber,
    Wrapped<DateTime?>? paymentDate,
    Wrapped<DateTime>? publishedAt,
    Wrapped<String>? sourceKey,
    Wrapped<List<FeedAdminTargetIn>?>? targets,
    Wrapped<Map<String, dynamic>?>? texts,
    Wrapped<enums.FeedAdminItemInType>? type,
    Wrapped<String>? url,
    Wrapped<DateTime?>? validFrom,
    Wrapped<DateTime?>? validTo,
  }) {
    return FeedAdminItemIn(
      card: (card != null ? card.value : this.card),
      deadline: (deadline != null ? deadline.value : this.deadline),
      department: (department != null ? department.value : this.department),
      documentBase64: (documentBase64 != null
          ? documentBase64.value
          : this.documentBase64),
      documentType: (documentType != null
          ? documentType.value
          : this.documentType),
      externalId: (externalId != null ? externalId.value : this.externalId),
      extractedText: (extractedText != null
          ? extractedText.value
          : this.extractedText),
      grNumber: (grNumber != null ? grNumber.value : this.grNumber),
      paymentDate: (paymentDate != null ? paymentDate.value : this.paymentDate),
      publishedAt: (publishedAt != null ? publishedAt.value : this.publishedAt),
      sourceKey: (sourceKey != null ? sourceKey.value : this.sourceKey),
      targets: (targets != null ? targets.value : this.targets),
      texts: (texts != null ? texts.value : this.texts),
      type: (type != null ? type.value : this.type),
      url: (url != null ? url.value : this.url),
      validFrom: (validFrom != null ? validFrom.value : this.validFrom),
      validTo: (validTo != null ? validTo.value : this.validTo),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminItemOut {
  const FeedAdminItemOut({
    required this.approved,
    required this.card,
    required this.checkIssues,
    required this.deadline,
    required this.department,
    required this.events,
    required this.externalId,
    this.extractedText,
    this.extractedTextTruncated,
    required this.grNumber,
    required this.hasText,
    required this.id,
    this.paymentDate,
    required this.publishedAt,
    required this.rawBytes,
    required this.rawHash,
    required this.replacedById,
    required this.sourceKey,
    required this.status,
    required this.targets,
    required this.texts,
    required this.title,
    required this.trust,
    required this.type,
    required this.url,
    required this.validFrom,
    required this.validTo,
  });

  factory FeedAdminItemOut.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminItemOutFromJson(json);

  static const toJsonFactory = _$FeedAdminItemOutToJson;
  Map<String, dynamic> toJson() => _$FeedAdminItemOutToJson(this);

  @JsonKey(name: 'approved', includeIfNull: false)
  final bool approved;
  @JsonKey(name: 'card', includeIfNull: false)
  final FeedAdminCardOut? card;
  @JsonKey(
    name: 'check_issues',
    includeIfNull: false,
    defaultValue: <FeedAdminCheckIssue>[],
  )
  final List<FeedAdminCheckIssue> checkIssues;
  @JsonKey(name: 'deadline', includeIfNull: false, toJson: _dateToJson)
  final DateTime? deadline;
  @JsonKey(name: 'department', includeIfNull: false)
  final String? department;
  @JsonKey(
    name: 'events',
    includeIfNull: false,
    defaultValue: <FeedAdminEventOut>[],
  )
  final List<FeedAdminEventOut> events;
  @JsonKey(name: 'external_id', includeIfNull: false)
  final String? externalId;
  @JsonKey(name: 'extracted_text', includeIfNull: false)
  final String? extractedText;
  @JsonKey(
    name: 'extracted_text_truncated',
    includeIfNull: false,
    defaultValue: false,
  )
  final bool? extractedTextTruncated;
  @JsonKey(name: 'gr_number', includeIfNull: false)
  final String? grNumber;
  @JsonKey(name: 'has_text', includeIfNull: false)
  final bool hasText;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'payment_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime? paymentDate;
  @JsonKey(name: 'published_at', includeIfNull: false)
  final DateTime publishedAt;
  @JsonKey(name: 'raw_bytes', includeIfNull: false)
  final int? rawBytes;
  @JsonKey(name: 'raw_hash', includeIfNull: false)
  final String? rawHash;
  @JsonKey(name: 'replaced_by_id', includeIfNull: false)
  final String? replacedById;
  @JsonKey(name: 'source_key', includeIfNull: false)
  final String sourceKey;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(
    name: 'targets',
    includeIfNull: false,
    defaultValue: <FeedAdminTargetOut>[],
  )
  final List<FeedAdminTargetOut> targets;
  @JsonKey(name: 'texts', includeIfNull: false)
  final Map<String, dynamic> texts;
  @JsonKey(name: 'title', includeIfNull: false)
  final String? title;
  @JsonKey(name: 'trust', includeIfNull: false)
  final String trust;
  @JsonKey(name: 'type', includeIfNull: false)
  final String type;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  @JsonKey(name: 'valid_from', includeIfNull: false, toJson: _dateToJson)
  final DateTime? validFrom;
  @JsonKey(name: 'valid_to', includeIfNull: false, toJson: _dateToJson)
  final DateTime? validTo;
  static const fromJsonFactory = _$FeedAdminItemOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminItemOut &&
            (identical(other.approved, approved) ||
                const DeepCollectionEquality().equals(
                  other.approved,
                  approved,
                )) &&
            (identical(other.card, card) ||
                const DeepCollectionEquality().equals(other.card, card)) &&
            (identical(other.checkIssues, checkIssues) ||
                const DeepCollectionEquality().equals(
                  other.checkIssues,
                  checkIssues,
                )) &&
            (identical(other.deadline, deadline) ||
                const DeepCollectionEquality().equals(
                  other.deadline,
                  deadline,
                )) &&
            (identical(other.department, department) ||
                const DeepCollectionEquality().equals(
                  other.department,
                  department,
                )) &&
            (identical(other.events, events) ||
                const DeepCollectionEquality().equals(other.events, events)) &&
            (identical(other.externalId, externalId) ||
                const DeepCollectionEquality().equals(
                  other.externalId,
                  externalId,
                )) &&
            (identical(other.extractedText, extractedText) ||
                const DeepCollectionEquality().equals(
                  other.extractedText,
                  extractedText,
                )) &&
            (identical(other.extractedTextTruncated, extractedTextTruncated) ||
                const DeepCollectionEquality().equals(
                  other.extractedTextTruncated,
                  extractedTextTruncated,
                )) &&
            (identical(other.grNumber, grNumber) ||
                const DeepCollectionEquality().equals(
                  other.grNumber,
                  grNumber,
                )) &&
            (identical(other.hasText, hasText) ||
                const DeepCollectionEquality().equals(
                  other.hasText,
                  hasText,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.paymentDate, paymentDate) ||
                const DeepCollectionEquality().equals(
                  other.paymentDate,
                  paymentDate,
                )) &&
            (identical(other.publishedAt, publishedAt) ||
                const DeepCollectionEquality().equals(
                  other.publishedAt,
                  publishedAt,
                )) &&
            (identical(other.rawBytes, rawBytes) ||
                const DeepCollectionEquality().equals(
                  other.rawBytes,
                  rawBytes,
                )) &&
            (identical(other.rawHash, rawHash) ||
                const DeepCollectionEquality().equals(
                  other.rawHash,
                  rawHash,
                )) &&
            (identical(other.replacedById, replacedById) ||
                const DeepCollectionEquality().equals(
                  other.replacedById,
                  replacedById,
                )) &&
            (identical(other.sourceKey, sourceKey) ||
                const DeepCollectionEquality().equals(
                  other.sourceKey,
                  sourceKey,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.targets, targets) ||
                const DeepCollectionEquality().equals(
                  other.targets,
                  targets,
                )) &&
            (identical(other.texts, texts) ||
                const DeepCollectionEquality().equals(other.texts, texts)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.trust, trust) ||
                const DeepCollectionEquality().equals(other.trust, trust)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
            (identical(other.validFrom, validFrom) ||
                const DeepCollectionEquality().equals(
                  other.validFrom,
                  validFrom,
                )) &&
            (identical(other.validTo, validTo) ||
                const DeepCollectionEquality().equals(other.validTo, validTo)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(approved) ^
      const DeepCollectionEquality().hash(card) ^
      const DeepCollectionEquality().hash(checkIssues) ^
      const DeepCollectionEquality().hash(deadline) ^
      const DeepCollectionEquality().hash(department) ^
      const DeepCollectionEquality().hash(events) ^
      const DeepCollectionEquality().hash(externalId) ^
      const DeepCollectionEquality().hash(extractedText) ^
      const DeepCollectionEquality().hash(extractedTextTruncated) ^
      const DeepCollectionEquality().hash(grNumber) ^
      const DeepCollectionEquality().hash(hasText) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(paymentDate) ^
      const DeepCollectionEquality().hash(publishedAt) ^
      const DeepCollectionEquality().hash(rawBytes) ^
      const DeepCollectionEquality().hash(rawHash) ^
      const DeepCollectionEquality().hash(replacedById) ^
      const DeepCollectionEquality().hash(sourceKey) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(targets) ^
      const DeepCollectionEquality().hash(texts) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(trust) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(validFrom) ^
      const DeepCollectionEquality().hash(validTo) ^
      runtimeType.hashCode;
}

extension $FeedAdminItemOutExtension on FeedAdminItemOut {
  FeedAdminItemOut copyWith({
    bool? approved,
    FeedAdminCardOut? card,
    List<FeedAdminCheckIssue>? checkIssues,
    DateTime? deadline,
    String? department,
    List<FeedAdminEventOut>? events,
    String? externalId,
    String? extractedText,
    bool? extractedTextTruncated,
    String? grNumber,
    bool? hasText,
    String? id,
    DateTime? paymentDate,
    DateTime? publishedAt,
    int? rawBytes,
    String? rawHash,
    String? replacedById,
    String? sourceKey,
    String? status,
    List<FeedAdminTargetOut>? targets,
    Map<String, dynamic>? texts,
    String? title,
    String? trust,
    String? type,
    String? url,
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    return FeedAdminItemOut(
      approved: approved ?? this.approved,
      card: card ?? this.card,
      checkIssues: checkIssues ?? this.checkIssues,
      deadline: deadline ?? this.deadline,
      department: department ?? this.department,
      events: events ?? this.events,
      externalId: externalId ?? this.externalId,
      extractedText: extractedText ?? this.extractedText,
      extractedTextTruncated:
          extractedTextTruncated ?? this.extractedTextTruncated,
      grNumber: grNumber ?? this.grNumber,
      hasText: hasText ?? this.hasText,
      id: id ?? this.id,
      paymentDate: paymentDate ?? this.paymentDate,
      publishedAt: publishedAt ?? this.publishedAt,
      rawBytes: rawBytes ?? this.rawBytes,
      rawHash: rawHash ?? this.rawHash,
      replacedById: replacedById ?? this.replacedById,
      sourceKey: sourceKey ?? this.sourceKey,
      status: status ?? this.status,
      targets: targets ?? this.targets,
      texts: texts ?? this.texts,
      title: title ?? this.title,
      trust: trust ?? this.trust,
      type: type ?? this.type,
      url: url ?? this.url,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
    );
  }

  FeedAdminItemOut copyWithWrapped({
    Wrapped<bool>? approved,
    Wrapped<FeedAdminCardOut?>? card,
    Wrapped<List<FeedAdminCheckIssue>>? checkIssues,
    Wrapped<DateTime?>? deadline,
    Wrapped<String?>? department,
    Wrapped<List<FeedAdminEventOut>>? events,
    Wrapped<String?>? externalId,
    Wrapped<String?>? extractedText,
    Wrapped<bool?>? extractedTextTruncated,
    Wrapped<String?>? grNumber,
    Wrapped<bool>? hasText,
    Wrapped<String>? id,
    Wrapped<DateTime?>? paymentDate,
    Wrapped<DateTime>? publishedAt,
    Wrapped<int?>? rawBytes,
    Wrapped<String?>? rawHash,
    Wrapped<String?>? replacedById,
    Wrapped<String>? sourceKey,
    Wrapped<String>? status,
    Wrapped<List<FeedAdminTargetOut>>? targets,
    Wrapped<Map<String, dynamic>>? texts,
    Wrapped<String?>? title,
    Wrapped<String>? trust,
    Wrapped<String>? type,
    Wrapped<String>? url,
    Wrapped<DateTime?>? validFrom,
    Wrapped<DateTime?>? validTo,
  }) {
    return FeedAdminItemOut(
      approved: (approved != null ? approved.value : this.approved),
      card: (card != null ? card.value : this.card),
      checkIssues: (checkIssues != null ? checkIssues.value : this.checkIssues),
      deadline: (deadline != null ? deadline.value : this.deadline),
      department: (department != null ? department.value : this.department),
      events: (events != null ? events.value : this.events),
      externalId: (externalId != null ? externalId.value : this.externalId),
      extractedText: (extractedText != null
          ? extractedText.value
          : this.extractedText),
      extractedTextTruncated: (extractedTextTruncated != null
          ? extractedTextTruncated.value
          : this.extractedTextTruncated),
      grNumber: (grNumber != null ? grNumber.value : this.grNumber),
      hasText: (hasText != null ? hasText.value : this.hasText),
      id: (id != null ? id.value : this.id),
      paymentDate: (paymentDate != null ? paymentDate.value : this.paymentDate),
      publishedAt: (publishedAt != null ? publishedAt.value : this.publishedAt),
      rawBytes: (rawBytes != null ? rawBytes.value : this.rawBytes),
      rawHash: (rawHash != null ? rawHash.value : this.rawHash),
      replacedById: (replacedById != null
          ? replacedById.value
          : this.replacedById),
      sourceKey: (sourceKey != null ? sourceKey.value : this.sourceKey),
      status: (status != null ? status.value : this.status),
      targets: (targets != null ? targets.value : this.targets),
      texts: (texts != null ? texts.value : this.texts),
      title: (title != null ? title.value : this.title),
      trust: (trust != null ? trust.value : this.trust),
      type: (type != null ? type.value : this.type),
      url: (url != null ? url.value : this.url),
      validFrom: (validFrom != null ? validFrom.value : this.validFrom),
      validTo: (validTo != null ? validTo.value : this.validTo),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminItemSummaryOut {
  const FeedAdminItemSummaryOut({
    required this.approved,
    required this.checkIssues,
    required this.department,
    required this.grNumber,
    required this.id,
    required this.publishedAt,
    required this.status,
    required this.title,
    required this.trust,
    required this.type,
  });

  factory FeedAdminItemSummaryOut.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminItemSummaryOutFromJson(json);

  static const toJsonFactory = _$FeedAdminItemSummaryOutToJson;
  Map<String, dynamic> toJson() => _$FeedAdminItemSummaryOutToJson(this);

  @JsonKey(name: 'approved', includeIfNull: false)
  final bool approved;
  @JsonKey(
    name: 'check_issues',
    includeIfNull: false,
    defaultValue: <FeedAdminCheckIssue>[],
  )
  final List<FeedAdminCheckIssue> checkIssues;
  @JsonKey(name: 'department', includeIfNull: false)
  final String? department;
  @JsonKey(name: 'gr_number', includeIfNull: false)
  final String? grNumber;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'published_at', includeIfNull: false)
  final DateTime publishedAt;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'title', includeIfNull: false)
  final String? title;
  @JsonKey(name: 'trust', includeIfNull: false)
  final String trust;
  @JsonKey(name: 'type', includeIfNull: false)
  final String type;
  static const fromJsonFactory = _$FeedAdminItemSummaryOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminItemSummaryOut &&
            (identical(other.approved, approved) ||
                const DeepCollectionEquality().equals(
                  other.approved,
                  approved,
                )) &&
            (identical(other.checkIssues, checkIssues) ||
                const DeepCollectionEquality().equals(
                  other.checkIssues,
                  checkIssues,
                )) &&
            (identical(other.department, department) ||
                const DeepCollectionEquality().equals(
                  other.department,
                  department,
                )) &&
            (identical(other.grNumber, grNumber) ||
                const DeepCollectionEquality().equals(
                  other.grNumber,
                  grNumber,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.publishedAt, publishedAt) ||
                const DeepCollectionEquality().equals(
                  other.publishedAt,
                  publishedAt,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.trust, trust) ||
                const DeepCollectionEquality().equals(other.trust, trust)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(approved) ^
      const DeepCollectionEquality().hash(checkIssues) ^
      const DeepCollectionEquality().hash(department) ^
      const DeepCollectionEquality().hash(grNumber) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(publishedAt) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(trust) ^
      const DeepCollectionEquality().hash(type) ^
      runtimeType.hashCode;
}

extension $FeedAdminItemSummaryOutExtension on FeedAdminItemSummaryOut {
  FeedAdminItemSummaryOut copyWith({
    bool? approved,
    List<FeedAdminCheckIssue>? checkIssues,
    String? department,
    String? grNumber,
    String? id,
    DateTime? publishedAt,
    String? status,
    String? title,
    String? trust,
    String? type,
  }) {
    return FeedAdminItemSummaryOut(
      approved: approved ?? this.approved,
      checkIssues: checkIssues ?? this.checkIssues,
      department: department ?? this.department,
      grNumber: grNumber ?? this.grNumber,
      id: id ?? this.id,
      publishedAt: publishedAt ?? this.publishedAt,
      status: status ?? this.status,
      title: title ?? this.title,
      trust: trust ?? this.trust,
      type: type ?? this.type,
    );
  }

  FeedAdminItemSummaryOut copyWithWrapped({
    Wrapped<bool>? approved,
    Wrapped<List<FeedAdminCheckIssue>>? checkIssues,
    Wrapped<String?>? department,
    Wrapped<String?>? grNumber,
    Wrapped<String>? id,
    Wrapped<DateTime>? publishedAt,
    Wrapped<String>? status,
    Wrapped<String?>? title,
    Wrapped<String>? trust,
    Wrapped<String>? type,
  }) {
    return FeedAdminItemSummaryOut(
      approved: (approved != null ? approved.value : this.approved),
      checkIssues: (checkIssues != null ? checkIssues.value : this.checkIssues),
      department: (department != null ? department.value : this.department),
      grNumber: (grNumber != null ? grNumber.value : this.grNumber),
      id: (id != null ? id.value : this.id),
      publishedAt: (publishedAt != null ? publishedAt.value : this.publishedAt),
      status: (status != null ? status.value : this.status),
      title: (title != null ? title.value : this.title),
      trust: (trust != null ? trust.value : this.trust),
      type: (type != null ? type.value : this.type),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminItemTextOut {
  const FeedAdminItemTextOut({required this.summary, required this.title});

  factory FeedAdminItemTextOut.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminItemTextOutFromJson(json);

  static const toJsonFactory = _$FeedAdminItemTextOutToJson;
  Map<String, dynamic> toJson() => _$FeedAdminItemTextOutToJson(this);

  @JsonKey(name: 'summary', includeIfNull: false)
  final String? summary;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  static const fromJsonFactory = _$FeedAdminItemTextOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminItemTextOut &&
            (identical(other.summary, summary) ||
                const DeepCollectionEquality().equals(
                  other.summary,
                  summary,
                )) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(summary) ^
      const DeepCollectionEquality().hash(title) ^
      runtimeType.hashCode;
}

extension $FeedAdminItemTextOutExtension on FeedAdminItemTextOut {
  FeedAdminItemTextOut copyWith({String? summary, String? title}) {
    return FeedAdminItemTextOut(
      summary: summary ?? this.summary,
      title: title ?? this.title,
    );
  }

  FeedAdminItemTextOut copyWithWrapped({
    Wrapped<String?>? summary,
    Wrapped<String>? title,
  }) {
    return FeedAdminItemTextOut(
      summary: (summary != null ? summary.value : this.summary),
      title: (title != null ? title.value : this.title),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminItemsResponse {
  const FeedAdminItemsResponse({required this.items});

  factory FeedAdminItemsResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminItemsResponseFromJson(json);

  static const toJsonFactory = _$FeedAdminItemsResponseToJson;
  Map<String, dynamic> toJson() => _$FeedAdminItemsResponseToJson(this);

  @JsonKey(
    name: 'items',
    includeIfNull: false,
    defaultValue: <FeedAdminItemSummaryOut>[],
  )
  final List<FeedAdminItemSummaryOut> items;
  static const fromJsonFactory = _$FeedAdminItemsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminItemsResponse &&
            (identical(other.items, items) ||
                const DeepCollectionEquality().equals(other.items, items)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(items) ^ runtimeType.hashCode;
}

extension $FeedAdminItemsResponseExtension on FeedAdminItemsResponse {
  FeedAdminItemsResponse copyWith({List<FeedAdminItemSummaryOut>? items}) {
    return FeedAdminItemsResponse(items: items ?? this.items);
  }

  FeedAdminItemsResponse copyWithWrapped({
    Wrapped<List<FeedAdminItemSummaryOut>>? items,
  }) {
    return FeedAdminItemsResponse(
      items: (items != null ? items.value : this.items),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminSourceOut {
  const FeedAdminSourceOut({
    required this.fetchMethod,
    required this.fetchStatus,
    required this.id,
    required this.key,
    required this.lastError,
    required this.lastOkAt,
    required this.name,
    required this.notes,
    required this.termsStatus,
    required this.tier,
    required this.url,
  });

  factory FeedAdminSourceOut.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminSourceOutFromJson(json);

  static const toJsonFactory = _$FeedAdminSourceOutToJson;
  Map<String, dynamic> toJson() => _$FeedAdminSourceOutToJson(this);

  @JsonKey(name: 'fetch_method', includeIfNull: false)
  final String fetchMethod;
  @JsonKey(name: 'fetch_status', includeIfNull: false)
  final String fetchStatus;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'last_error', includeIfNull: false)
  final String? lastError;
  @JsonKey(name: 'last_ok_at', includeIfNull: false)
  final DateTime? lastOkAt;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'notes', includeIfNull: false)
  final String? notes;
  @JsonKey(name: 'terms_status', includeIfNull: false)
  final String termsStatus;
  @JsonKey(name: 'tier', includeIfNull: false)
  final String tier;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  static const fromJsonFactory = _$FeedAdminSourceOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminSourceOut &&
            (identical(other.fetchMethod, fetchMethod) ||
                const DeepCollectionEquality().equals(
                  other.fetchMethod,
                  fetchMethod,
                )) &&
            (identical(other.fetchStatus, fetchStatus) ||
                const DeepCollectionEquality().equals(
                  other.fetchStatus,
                  fetchStatus,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.lastError, lastError) ||
                const DeepCollectionEquality().equals(
                  other.lastError,
                  lastError,
                )) &&
            (identical(other.lastOkAt, lastOkAt) ||
                const DeepCollectionEquality().equals(
                  other.lastOkAt,
                  lastOkAt,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.notes, notes) ||
                const DeepCollectionEquality().equals(other.notes, notes)) &&
            (identical(other.termsStatus, termsStatus) ||
                const DeepCollectionEquality().equals(
                  other.termsStatus,
                  termsStatus,
                )) &&
            (identical(other.tier, tier) ||
                const DeepCollectionEquality().equals(other.tier, tier)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(fetchMethod) ^
      const DeepCollectionEquality().hash(fetchStatus) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(lastError) ^
      const DeepCollectionEquality().hash(lastOkAt) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(notes) ^
      const DeepCollectionEquality().hash(termsStatus) ^
      const DeepCollectionEquality().hash(tier) ^
      const DeepCollectionEquality().hash(url) ^
      runtimeType.hashCode;
}

extension $FeedAdminSourceOutExtension on FeedAdminSourceOut {
  FeedAdminSourceOut copyWith({
    String? fetchMethod,
    String? fetchStatus,
    String? id,
    String? key,
    String? lastError,
    DateTime? lastOkAt,
    String? name,
    String? notes,
    String? termsStatus,
    String? tier,
    String? url,
  }) {
    return FeedAdminSourceOut(
      fetchMethod: fetchMethod ?? this.fetchMethod,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      id: id ?? this.id,
      key: key ?? this.key,
      lastError: lastError ?? this.lastError,
      lastOkAt: lastOkAt ?? this.lastOkAt,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      termsStatus: termsStatus ?? this.termsStatus,
      tier: tier ?? this.tier,
      url: url ?? this.url,
    );
  }

  FeedAdminSourceOut copyWithWrapped({
    Wrapped<String>? fetchMethod,
    Wrapped<String>? fetchStatus,
    Wrapped<String>? id,
    Wrapped<String>? key,
    Wrapped<String?>? lastError,
    Wrapped<DateTime?>? lastOkAt,
    Wrapped<String>? name,
    Wrapped<String?>? notes,
    Wrapped<String>? termsStatus,
    Wrapped<String>? tier,
    Wrapped<String>? url,
  }) {
    return FeedAdminSourceOut(
      fetchMethod: (fetchMethod != null ? fetchMethod.value : this.fetchMethod),
      fetchStatus: (fetchStatus != null ? fetchStatus.value : this.fetchStatus),
      id: (id != null ? id.value : this.id),
      key: (key != null ? key.value : this.key),
      lastError: (lastError != null ? lastError.value : this.lastError),
      lastOkAt: (lastOkAt != null ? lastOkAt.value : this.lastOkAt),
      name: (name != null ? name.value : this.name),
      notes: (notes != null ? notes.value : this.notes),
      termsStatus: (termsStatus != null ? termsStatus.value : this.termsStatus),
      tier: (tier != null ? tier.value : this.tier),
      url: (url != null ? url.value : this.url),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminSourcesResponse {
  const FeedAdminSourcesResponse({required this.sources});

  factory FeedAdminSourcesResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminSourcesResponseFromJson(json);

  static const toJsonFactory = _$FeedAdminSourcesResponseToJson;
  Map<String, dynamic> toJson() => _$FeedAdminSourcesResponseToJson(this);

  @JsonKey(
    name: 'sources',
    includeIfNull: false,
    defaultValue: <FeedAdminSourceOut>[],
  )
  final List<FeedAdminSourceOut> sources;
  static const fromJsonFactory = _$FeedAdminSourcesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminSourcesResponse &&
            (identical(other.sources, sources) ||
                const DeepCollectionEquality().equals(other.sources, sources)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(sources) ^ runtimeType.hashCode;
}

extension $FeedAdminSourcesResponseExtension on FeedAdminSourcesResponse {
  FeedAdminSourcesResponse copyWith({List<FeedAdminSourceOut>? sources}) {
    return FeedAdminSourcesResponse(sources: sources ?? this.sources);
  }

  FeedAdminSourcesResponse copyWithWrapped({
    Wrapped<List<FeedAdminSourceOut>>? sources,
  }) {
    return FeedAdminSourcesResponse(
      sources: (sources != null ? sources.value : this.sources),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminTargetIn {
  const FeedAdminTargetIn({this.crop, this.district, this.maxHa, this.minHa});

  factory FeedAdminTargetIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminTargetInFromJson(json);

  static const toJsonFactory = _$FeedAdminTargetInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminTargetInToJson(this);

  @JsonKey(name: 'crop', includeIfNull: false)
  final String? crop;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'max_ha', includeIfNull: false)
  final double? maxHa;
  @JsonKey(name: 'min_ha', includeIfNull: false)
  final double? minHa;
  static const fromJsonFactory = _$FeedAdminTargetInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminTargetIn &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.maxHa, maxHa) ||
                const DeepCollectionEquality().equals(other.maxHa, maxHa)) &&
            (identical(other.minHa, minHa) ||
                const DeepCollectionEquality().equals(other.minHa, minHa)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(maxHa) ^
      const DeepCollectionEquality().hash(minHa) ^
      runtimeType.hashCode;
}

extension $FeedAdminTargetInExtension on FeedAdminTargetIn {
  FeedAdminTargetIn copyWith({
    String? crop,
    String? district,
    double? maxHa,
    double? minHa,
  }) {
    return FeedAdminTargetIn(
      crop: crop ?? this.crop,
      district: district ?? this.district,
      maxHa: maxHa ?? this.maxHa,
      minHa: minHa ?? this.minHa,
    );
  }

  FeedAdminTargetIn copyWithWrapped({
    Wrapped<String?>? crop,
    Wrapped<String?>? district,
    Wrapped<double?>? maxHa,
    Wrapped<double?>? minHa,
  }) {
    return FeedAdminTargetIn(
      crop: (crop != null ? crop.value : this.crop),
      district: (district != null ? district.value : this.district),
      maxHa: (maxHa != null ? maxHa.value : this.maxHa),
      minHa: (minHa != null ? minHa.value : this.minHa),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminTargetOut {
  const FeedAdminTargetOut({
    required this.crop,
    required this.district,
    required this.maxHa,
    required this.minHa,
  });

  factory FeedAdminTargetOut.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminTargetOutFromJson(json);

  static const toJsonFactory = _$FeedAdminTargetOutToJson;
  Map<String, dynamic> toJson() => _$FeedAdminTargetOutToJson(this);

  @JsonKey(name: 'crop', includeIfNull: false)
  final String? crop;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'max_ha', includeIfNull: false)
  final double? maxHa;
  @JsonKey(name: 'min_ha', includeIfNull: false)
  final double? minHa;
  static const fromJsonFactory = _$FeedAdminTargetOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminTargetOut &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.maxHa, maxHa) ||
                const DeepCollectionEquality().equals(other.maxHa, maxHa)) &&
            (identical(other.minHa, minHa) ||
                const DeepCollectionEquality().equals(other.minHa, minHa)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(maxHa) ^
      const DeepCollectionEquality().hash(minHa) ^
      runtimeType.hashCode;
}

extension $FeedAdminTargetOutExtension on FeedAdminTargetOut {
  FeedAdminTargetOut copyWith({
    String? crop,
    String? district,
    double? maxHa,
    double? minHa,
  }) {
    return FeedAdminTargetOut(
      crop: crop ?? this.crop,
      district: district ?? this.district,
      maxHa: maxHa ?? this.maxHa,
      minHa: minHa ?? this.minHa,
    );
  }

  FeedAdminTargetOut copyWithWrapped({
    Wrapped<String?>? crop,
    Wrapped<String?>? district,
    Wrapped<double?>? maxHa,
    Wrapped<double?>? minHa,
  }) {
    return FeedAdminTargetOut(
      crop: (crop != null ? crop.value : this.crop),
      district: (district != null ? district.value : this.district),
      maxHa: (maxHa != null ? maxHa.value : this.maxHa),
      minHa: (minHa != null ? minHa.value : this.minHa),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminTargetsIn {
  const FeedAdminTargetsIn({required this.targets});

  factory FeedAdminTargetsIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminTargetsInFromJson(json);

  static const toJsonFactory = _$FeedAdminTargetsInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminTargetsInToJson(this);

  @JsonKey(
    name: 'targets',
    includeIfNull: false,
    defaultValue: <FeedAdminTargetIn>[],
  )
  final List<FeedAdminTargetIn> targets;
  static const fromJsonFactory = _$FeedAdminTargetsInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminTargetsIn &&
            (identical(other.targets, targets) ||
                const DeepCollectionEquality().equals(other.targets, targets)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(targets) ^ runtimeType.hashCode;
}

extension $FeedAdminTargetsInExtension on FeedAdminTargetsIn {
  FeedAdminTargetsIn copyWith({List<FeedAdminTargetIn>? targets}) {
    return FeedAdminTargetsIn(targets: targets ?? this.targets);
  }

  FeedAdminTargetsIn copyWithWrapped({
    Wrapped<List<FeedAdminTargetIn>>? targets,
  }) {
    return FeedAdminTargetsIn(
      targets: (targets != null ? targets.value : this.targets),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminTermsIn {
  const FeedAdminTermsIn({this.notes, required this.termsStatus});

  factory FeedAdminTermsIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminTermsInFromJson(json);

  static const toJsonFactory = _$FeedAdminTermsInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminTermsInToJson(this);

  @JsonKey(name: 'notes', includeIfNull: false)
  final String? notes;
  @JsonKey(
    name: 'terms_status',
    includeIfNull: false,
    toJson: feedAdminTermsInTermsStatusToJson,
    fromJson: feedAdminTermsInTermsStatusFromJson,
  )
  final enums.FeedAdminTermsInTermsStatus termsStatus;
  static const fromJsonFactory = _$FeedAdminTermsInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminTermsIn &&
            (identical(other.notes, notes) ||
                const DeepCollectionEquality().equals(other.notes, notes)) &&
            (identical(other.termsStatus, termsStatus) ||
                const DeepCollectionEquality().equals(
                  other.termsStatus,
                  termsStatus,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(notes) ^
      const DeepCollectionEquality().hash(termsStatus) ^
      runtimeType.hashCode;
}

extension $FeedAdminTermsInExtension on FeedAdminTermsIn {
  FeedAdminTermsIn copyWith({
    String? notes,
    enums.FeedAdminTermsInTermsStatus? termsStatus,
  }) {
    return FeedAdminTermsIn(
      notes: notes ?? this.notes,
      termsStatus: termsStatus ?? this.termsStatus,
    );
  }

  FeedAdminTermsIn copyWithWrapped({
    Wrapped<String?>? notes,
    Wrapped<enums.FeedAdminTermsInTermsStatus>? termsStatus,
  }) {
    return FeedAdminTermsIn(
      notes: (notes != null ? notes.value : this.notes),
      termsStatus: (termsStatus != null ? termsStatus.value : this.termsStatus),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminTextIn {
  const FeedAdminTextIn({this.summary, required this.title});

  factory FeedAdminTextIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminTextInFromJson(json);

  static const toJsonFactory = _$FeedAdminTextInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminTextInToJson(this);

  @JsonKey(name: 'summary', includeIfNull: false)
  final String? summary;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  static const fromJsonFactory = _$FeedAdminTextInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminTextIn &&
            (identical(other.summary, summary) ||
                const DeepCollectionEquality().equals(
                  other.summary,
                  summary,
                )) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(summary) ^
      const DeepCollectionEquality().hash(title) ^
      runtimeType.hashCode;
}

extension $FeedAdminTextInExtension on FeedAdminTextIn {
  FeedAdminTextIn copyWith({String? summary, String? title}) {
    return FeedAdminTextIn(
      summary: summary ?? this.summary,
      title: title ?? this.title,
    );
  }

  FeedAdminTextIn copyWithWrapped({
    Wrapped<String?>? summary,
    Wrapped<String>? title,
  }) {
    return FeedAdminTextIn(
      summary: (summary != null ? summary.value : this.summary),
      title: (title != null ? title.value : this.title),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedAdminWithdrawIn {
  const FeedAdminWithdrawIn({required this.reason, this.replacedById});

  factory FeedAdminWithdrawIn.fromJson(Map<String, dynamic> json) =>
      _$FeedAdminWithdrawInFromJson(json);

  static const toJsonFactory = _$FeedAdminWithdrawInToJson;
  Map<String, dynamic> toJson() => _$FeedAdminWithdrawInToJson(this);

  @JsonKey(name: 'reason', includeIfNull: false)
  final String reason;
  @JsonKey(name: 'replaced_by_id', includeIfNull: false)
  final String? replacedById;
  static const fromJsonFactory = _$FeedAdminWithdrawInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedAdminWithdrawIn &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.replacedById, replacedById) ||
                const DeepCollectionEquality().equals(
                  other.replacedById,
                  replacedById,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(replacedById) ^
      runtimeType.hashCode;
}

extension $FeedAdminWithdrawInExtension on FeedAdminWithdrawIn {
  FeedAdminWithdrawIn copyWith({String? reason, String? replacedById}) {
    return FeedAdminWithdrawIn(
      reason: reason ?? this.reason,
      replacedById: replacedById ?? this.replacedById,
    );
  }

  FeedAdminWithdrawIn copyWithWrapped({
    Wrapped<String>? reason,
    Wrapped<String?>? replacedById,
  }) {
    return FeedAdminWithdrawIn(
      reason: (reason != null ? reason.value : this.reason),
      replacedById: (replacedById != null
          ? replacedById.value
          : this.replacedById),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedCheckIn {
  const FeedCheckIn({required this.text});

  factory FeedCheckIn.fromJson(Map<String, dynamic> json) =>
      _$FeedCheckInFromJson(json);

  static const toJsonFactory = _$FeedCheckInToJson;
  Map<String, dynamic> toJson() => _$FeedCheckInToJson(this);

  @JsonKey(name: 'text', includeIfNull: false)
  final String text;
  static const fromJsonFactory = _$FeedCheckInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedCheckIn &&
            (identical(other.text, text) ||
                const DeepCollectionEquality().equals(other.text, text)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(text) ^ runtimeType.hashCode;
}

extension $FeedCheckInExtension on FeedCheckIn {
  FeedCheckIn copyWith({String? text}) {
    return FeedCheckIn(text: text ?? this.text);
  }

  FeedCheckIn copyWithWrapped({Wrapped<String>? text}) {
    return FeedCheckIn(text: (text != null ? text.value : this.text));
  }
}

@JsonSerializable(explicitToJson: true)
class FeedCheckMatch {
  const FeedCheckMatch({
    required this.grNumber,
    required this.id,
    required this.publishedAt,
    required this.score,
    required this.title,
    required this.url,
  });

  factory FeedCheckMatch.fromJson(Map<String, dynamic> json) =>
      _$FeedCheckMatchFromJson(json);

  static const toJsonFactory = _$FeedCheckMatchToJson;
  Map<String, dynamic> toJson() => _$FeedCheckMatchToJson(this);

  @JsonKey(name: 'gr_number', includeIfNull: false)
  final String? grNumber;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'published_at', includeIfNull: false)
  final DateTime publishedAt;
  @JsonKey(name: 'score', includeIfNull: false)
  final double score;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  static const fromJsonFactory = _$FeedCheckMatchFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedCheckMatch &&
            (identical(other.grNumber, grNumber) ||
                const DeepCollectionEquality().equals(
                  other.grNumber,
                  grNumber,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.publishedAt, publishedAt) ||
                const DeepCollectionEquality().equals(
                  other.publishedAt,
                  publishedAt,
                )) &&
            (identical(other.score, score) ||
                const DeepCollectionEquality().equals(other.score, score)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(grNumber) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(publishedAt) ^
      const DeepCollectionEquality().hash(score) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(url) ^
      runtimeType.hashCode;
}

extension $FeedCheckMatchExtension on FeedCheckMatch {
  FeedCheckMatch copyWith({
    String? grNumber,
    String? id,
    DateTime? publishedAt,
    double? score,
    String? title,
    String? url,
  }) {
    return FeedCheckMatch(
      grNumber: grNumber ?? this.grNumber,
      id: id ?? this.id,
      publishedAt: publishedAt ?? this.publishedAt,
      score: score ?? this.score,
      title: title ?? this.title,
      url: url ?? this.url,
    );
  }

  FeedCheckMatch copyWithWrapped({
    Wrapped<String?>? grNumber,
    Wrapped<String>? id,
    Wrapped<DateTime>? publishedAt,
    Wrapped<double>? score,
    Wrapped<String>? title,
    Wrapped<String>? url,
  }) {
    return FeedCheckMatch(
      grNumber: (grNumber != null ? grNumber.value : this.grNumber),
      id: (id != null ? id.value : this.id),
      publishedAt: (publishedAt != null ? publishedAt.value : this.publishedAt),
      score: (score != null ? score.value : this.score),
      title: (title != null ? title.value : this.title),
      url: (url != null ? url.value : this.url),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedCheckResponse {
  const FeedCheckResponse({
    required this.matches,
    required this.note,
    required this.verdict,
  });

  factory FeedCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedCheckResponseFromJson(json);

  static const toJsonFactory = _$FeedCheckResponseToJson;
  Map<String, dynamic> toJson() => _$FeedCheckResponseToJson(this);

  @JsonKey(
    name: 'matches',
    includeIfNull: false,
    defaultValue: <FeedCheckMatch>[],
  )
  final List<FeedCheckMatch> matches;
  @JsonKey(name: 'note', includeIfNull: false)
  final String note;
  @JsonKey(
    name: 'verdict',
    includeIfNull: false,
    toJson: feedCheckResponseVerdictToJson,
    fromJson: feedCheckResponseVerdictFromJson,
  )
  final enums.FeedCheckResponseVerdict verdict;
  static const fromJsonFactory = _$FeedCheckResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedCheckResponse &&
            (identical(other.matches, matches) ||
                const DeepCollectionEquality().equals(
                  other.matches,
                  matches,
                )) &&
            (identical(other.note, note) ||
                const DeepCollectionEquality().equals(other.note, note)) &&
            (identical(other.verdict, verdict) ||
                const DeepCollectionEquality().equals(other.verdict, verdict)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(matches) ^
      const DeepCollectionEquality().hash(note) ^
      const DeepCollectionEquality().hash(verdict) ^
      runtimeType.hashCode;
}

extension $FeedCheckResponseExtension on FeedCheckResponse {
  FeedCheckResponse copyWith({
    List<FeedCheckMatch>? matches,
    String? note,
    enums.FeedCheckResponseVerdict? verdict,
  }) {
    return FeedCheckResponse(
      matches: matches ?? this.matches,
      note: note ?? this.note,
      verdict: verdict ?? this.verdict,
    );
  }

  FeedCheckResponse copyWithWrapped({
    Wrapped<List<FeedCheckMatch>>? matches,
    Wrapped<String>? note,
    Wrapped<enums.FeedCheckResponseVerdict>? verdict,
  }) {
    return FeedCheckResponse(
      matches: (matches != null ? matches.value : this.matches),
      note: (note != null ? note.value : this.note),
      verdict: (verdict != null ? verdict.value : this.verdict),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedItemOut {
  const FeedItemOut({
    required this.deadline,
    required this.department,
    required this.grNumber,
    required this.id,
    required this.mayBeEligibleBecause,
    required this.publishedAt,
    required this.replacedBy,
    this.seen,
    required this.summary,
    required this.title,
    required this.trust,
    required this.type,
    required this.url,
    required this.validTo,
  });

  factory FeedItemOut.fromJson(Map<String, dynamic> json) =>
      _$FeedItemOutFromJson(json);

  static const toJsonFactory = _$FeedItemOutToJson;
  Map<String, dynamic> toJson() => _$FeedItemOutToJson(this);

  @JsonKey(name: 'deadline', includeIfNull: false, toJson: _dateToJson)
  final DateTime? deadline;
  @JsonKey(name: 'department', includeIfNull: false)
  final String? department;
  @JsonKey(name: 'gr_number', includeIfNull: false)
  final String? grNumber;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(
    name: 'may_be_eligible_because',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String> mayBeEligibleBecause;
  @JsonKey(name: 'published_at', includeIfNull: false)
  final DateTime publishedAt;
  @JsonKey(name: 'replaced_by', includeIfNull: false)
  final String? replacedBy;
  @JsonKey(name: 'seen', includeIfNull: false, defaultValue: false)
  final bool? seen;
  @JsonKey(name: 'summary', includeIfNull: false)
  final String? summary;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(
    name: 'trust',
    includeIfNull: false,
    toJson: feedItemOutTrustToJson,
    fromJson: feedItemOutTrustFromJson,
  )
  final enums.FeedItemOutTrust trust;
  @JsonKey(name: 'type', includeIfNull: false)
  final String type;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  @JsonKey(name: 'valid_to', includeIfNull: false, toJson: _dateToJson)
  final DateTime? validTo;
  static const fromJsonFactory = _$FeedItemOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedItemOut &&
            (identical(other.deadline, deadline) ||
                const DeepCollectionEquality().equals(
                  other.deadline,
                  deadline,
                )) &&
            (identical(other.department, department) ||
                const DeepCollectionEquality().equals(
                  other.department,
                  department,
                )) &&
            (identical(other.grNumber, grNumber) ||
                const DeepCollectionEquality().equals(
                  other.grNumber,
                  grNumber,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.mayBeEligibleBecause, mayBeEligibleBecause) ||
                const DeepCollectionEquality().equals(
                  other.mayBeEligibleBecause,
                  mayBeEligibleBecause,
                )) &&
            (identical(other.publishedAt, publishedAt) ||
                const DeepCollectionEquality().equals(
                  other.publishedAt,
                  publishedAt,
                )) &&
            (identical(other.replacedBy, replacedBy) ||
                const DeepCollectionEquality().equals(
                  other.replacedBy,
                  replacedBy,
                )) &&
            (identical(other.seen, seen) ||
                const DeepCollectionEquality().equals(other.seen, seen)) &&
            (identical(other.summary, summary) ||
                const DeepCollectionEquality().equals(
                  other.summary,
                  summary,
                )) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.trust, trust) ||
                const DeepCollectionEquality().equals(other.trust, trust)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
            (identical(other.validTo, validTo) ||
                const DeepCollectionEquality().equals(other.validTo, validTo)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(deadline) ^
      const DeepCollectionEquality().hash(department) ^
      const DeepCollectionEquality().hash(grNumber) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(mayBeEligibleBecause) ^
      const DeepCollectionEquality().hash(publishedAt) ^
      const DeepCollectionEquality().hash(replacedBy) ^
      const DeepCollectionEquality().hash(seen) ^
      const DeepCollectionEquality().hash(summary) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(trust) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(validTo) ^
      runtimeType.hashCode;
}

extension $FeedItemOutExtension on FeedItemOut {
  FeedItemOut copyWith({
    DateTime? deadline,
    String? department,
    String? grNumber,
    String? id,
    List<String>? mayBeEligibleBecause,
    DateTime? publishedAt,
    String? replacedBy,
    bool? seen,
    String? summary,
    String? title,
    enums.FeedItemOutTrust? trust,
    String? type,
    String? url,
    DateTime? validTo,
  }) {
    return FeedItemOut(
      deadline: deadline ?? this.deadline,
      department: department ?? this.department,
      grNumber: grNumber ?? this.grNumber,
      id: id ?? this.id,
      mayBeEligibleBecause: mayBeEligibleBecause ?? this.mayBeEligibleBecause,
      publishedAt: publishedAt ?? this.publishedAt,
      replacedBy: replacedBy ?? this.replacedBy,
      seen: seen ?? this.seen,
      summary: summary ?? this.summary,
      title: title ?? this.title,
      trust: trust ?? this.trust,
      type: type ?? this.type,
      url: url ?? this.url,
      validTo: validTo ?? this.validTo,
    );
  }

  FeedItemOut copyWithWrapped({
    Wrapped<DateTime?>? deadline,
    Wrapped<String?>? department,
    Wrapped<String?>? grNumber,
    Wrapped<String>? id,
    Wrapped<List<String>>? mayBeEligibleBecause,
    Wrapped<DateTime>? publishedAt,
    Wrapped<String?>? replacedBy,
    Wrapped<bool?>? seen,
    Wrapped<String?>? summary,
    Wrapped<String>? title,
    Wrapped<enums.FeedItemOutTrust>? trust,
    Wrapped<String>? type,
    Wrapped<String>? url,
    Wrapped<DateTime?>? validTo,
  }) {
    return FeedItemOut(
      deadline: (deadline != null ? deadline.value : this.deadline),
      department: (department != null ? department.value : this.department),
      grNumber: (grNumber != null ? grNumber.value : this.grNumber),
      id: (id != null ? id.value : this.id),
      mayBeEligibleBecause: (mayBeEligibleBecause != null
          ? mayBeEligibleBecause.value
          : this.mayBeEligibleBecause),
      publishedAt: (publishedAt != null ? publishedAt.value : this.publishedAt),
      replacedBy: (replacedBy != null ? replacedBy.value : this.replacedBy),
      seen: (seen != null ? seen.value : this.seen),
      summary: (summary != null ? summary.value : this.summary),
      title: (title != null ? title.value : this.title),
      trust: (trust != null ? trust.value : this.trust),
      type: (type != null ? type.value : this.type),
      url: (url != null ? url.value : this.url),
      validTo: (validTo != null ? validTo.value : this.validTo),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedPreferencesBody {
  const FeedPreferencesBody({
    required this.digestWeekly,
    this.optedOut,
    required this.quietEnd,
    required this.quietStart,
    required this.weeklyCap,
  });

  factory FeedPreferencesBody.fromJson(Map<String, dynamic> json) =>
      _$FeedPreferencesBodyFromJson(json);

  static const toJsonFactory = _$FeedPreferencesBodyToJson;
  Map<String, dynamic> toJson() => _$FeedPreferencesBodyToJson(this);

  @JsonKey(name: 'digest_weekly', includeIfNull: false)
  final bool digestWeekly;
  @JsonKey(
    name: 'opted_out',
    includeIfNull: false,
    toJson: feedPreferencesBodyOptedOutListToJson,
    fromJson: feedPreferencesBodyOptedOutListFromJson,
  )
  final List<enums.FeedPreferencesBodyOptedOut>? optedOut;
  @JsonKey(name: 'quiet_end', includeIfNull: false)
  final String quietEnd;
  @JsonKey(name: 'quiet_start', includeIfNull: false)
  final String quietStart;
  @JsonKey(name: 'weekly_cap', includeIfNull: false)
  final int weeklyCap;
  static const fromJsonFactory = _$FeedPreferencesBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedPreferencesBody &&
            (identical(other.digestWeekly, digestWeekly) ||
                const DeepCollectionEquality().equals(
                  other.digestWeekly,
                  digestWeekly,
                )) &&
            (identical(other.optedOut, optedOut) ||
                const DeepCollectionEquality().equals(
                  other.optedOut,
                  optedOut,
                )) &&
            (identical(other.quietEnd, quietEnd) ||
                const DeepCollectionEquality().equals(
                  other.quietEnd,
                  quietEnd,
                )) &&
            (identical(other.quietStart, quietStart) ||
                const DeepCollectionEquality().equals(
                  other.quietStart,
                  quietStart,
                )) &&
            (identical(other.weeklyCap, weeklyCap) ||
                const DeepCollectionEquality().equals(
                  other.weeklyCap,
                  weeklyCap,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(digestWeekly) ^
      const DeepCollectionEquality().hash(optedOut) ^
      const DeepCollectionEquality().hash(quietEnd) ^
      const DeepCollectionEquality().hash(quietStart) ^
      const DeepCollectionEquality().hash(weeklyCap) ^
      runtimeType.hashCode;
}

extension $FeedPreferencesBodyExtension on FeedPreferencesBody {
  FeedPreferencesBody copyWith({
    bool? digestWeekly,
    List<enums.FeedPreferencesBodyOptedOut>? optedOut,
    String? quietEnd,
    String? quietStart,
    int? weeklyCap,
  }) {
    return FeedPreferencesBody(
      digestWeekly: digestWeekly ?? this.digestWeekly,
      optedOut: optedOut ?? this.optedOut,
      quietEnd: quietEnd ?? this.quietEnd,
      quietStart: quietStart ?? this.quietStart,
      weeklyCap: weeklyCap ?? this.weeklyCap,
    );
  }

  FeedPreferencesBody copyWithWrapped({
    Wrapped<bool>? digestWeekly,
    Wrapped<List<enums.FeedPreferencesBodyOptedOut>?>? optedOut,
    Wrapped<String>? quietEnd,
    Wrapped<String>? quietStart,
    Wrapped<int>? weeklyCap,
  }) {
    return FeedPreferencesBody(
      digestWeekly: (digestWeekly != null
          ? digestWeekly.value
          : this.digestWeekly),
      optedOut: (optedOut != null ? optedOut.value : this.optedOut),
      quietEnd: (quietEnd != null ? quietEnd.value : this.quietEnd),
      quietStart: (quietStart != null ? quietStart.value : this.quietStart),
      weeklyCap: (weeklyCap != null ? weeklyCap.value : this.weeklyCap),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedReceiptOut {
  const FeedReceiptOut({
    required this.dismissed,
    required this.itemId,
    required this.remind,
    required this.seen,
  });

  factory FeedReceiptOut.fromJson(Map<String, dynamic> json) =>
      _$FeedReceiptOutFromJson(json);

  static const toJsonFactory = _$FeedReceiptOutToJson;
  Map<String, dynamic> toJson() => _$FeedReceiptOutToJson(this);

  @JsonKey(name: 'dismissed', includeIfNull: false)
  final bool dismissed;
  @JsonKey(name: 'item_id', includeIfNull: false)
  final String itemId;
  @JsonKey(name: 'remind', includeIfNull: false)
  final bool remind;
  @JsonKey(name: 'seen', includeIfNull: false)
  final bool seen;
  static const fromJsonFactory = _$FeedReceiptOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedReceiptOut &&
            (identical(other.dismissed, dismissed) ||
                const DeepCollectionEquality().equals(
                  other.dismissed,
                  dismissed,
                )) &&
            (identical(other.itemId, itemId) ||
                const DeepCollectionEquality().equals(other.itemId, itemId)) &&
            (identical(other.remind, remind) ||
                const DeepCollectionEquality().equals(other.remind, remind)) &&
            (identical(other.seen, seen) ||
                const DeepCollectionEquality().equals(other.seen, seen)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(dismissed) ^
      const DeepCollectionEquality().hash(itemId) ^
      const DeepCollectionEquality().hash(remind) ^
      const DeepCollectionEquality().hash(seen) ^
      runtimeType.hashCode;
}

extension $FeedReceiptOutExtension on FeedReceiptOut {
  FeedReceiptOut copyWith({
    bool? dismissed,
    String? itemId,
    bool? remind,
    bool? seen,
  }) {
    return FeedReceiptOut(
      dismissed: dismissed ?? this.dismissed,
      itemId: itemId ?? this.itemId,
      remind: remind ?? this.remind,
      seen: seen ?? this.seen,
    );
  }

  FeedReceiptOut copyWithWrapped({
    Wrapped<bool>? dismissed,
    Wrapped<String>? itemId,
    Wrapped<bool>? remind,
    Wrapped<bool>? seen,
  }) {
    return FeedReceiptOut(
      dismissed: (dismissed != null ? dismissed.value : this.dismissed),
      itemId: (itemId != null ? itemId.value : this.itemId),
      remind: (remind != null ? remind.value : this.remind),
      seen: (seen != null ? seen.value : this.seen),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class FeedResponse {
  const FeedResponse({required this.footer, required this.items});

  factory FeedResponse.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseFromJson(json);

  static const toJsonFactory = _$FeedResponseToJson;
  Map<String, dynamic> toJson() => _$FeedResponseToJson(this);

  @JsonKey(name: 'footer', includeIfNull: false)
  final String footer;
  @JsonKey(name: 'items', includeIfNull: false, defaultValue: <FeedItemOut>[])
  final List<FeedItemOut> items;
  static const fromJsonFactory = _$FeedResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FeedResponse &&
            (identical(other.footer, footer) ||
                const DeepCollectionEquality().equals(other.footer, footer)) &&
            (identical(other.items, items) ||
                const DeepCollectionEquality().equals(other.items, items)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(footer) ^
      const DeepCollectionEquality().hash(items) ^
      runtimeType.hashCode;
}

extension $FeedResponseExtension on FeedResponse {
  FeedResponse copyWith({String? footer, List<FeedItemOut>? items}) {
    return FeedResponse(
      footer: footer ?? this.footer,
      items: items ?? this.items,
    );
  }

  FeedResponse copyWithWrapped({
    Wrapped<String>? footer,
    Wrapped<List<FeedItemOut>>? items,
  }) {
    return FeedResponse(
      footer: (footer != null ? footer.value : this.footer),
      items: (items != null ? items.value : this.items),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class GrantIn {
  const GrantIn({
    required this.periodEnd,
    required this.planKey,
    required this.reason,
    required this.subjectId,
    required this.subjectType,
  });

  factory GrantIn.fromJson(Map<String, dynamic> json) =>
      _$GrantInFromJson(json);

  static const toJsonFactory = _$GrantInToJson;
  Map<String, dynamic> toJson() => _$GrantInToJson(this);

  @JsonKey(name: 'period_end', includeIfNull: false)
  final DateTime periodEnd;
  @JsonKey(name: 'plan_key', includeIfNull: false)
  final String planKey;
  @JsonKey(name: 'reason', includeIfNull: false)
  final String reason;
  @JsonKey(name: 'subject_id', includeIfNull: false)
  final String subjectId;
  @JsonKey(
    name: 'subject_type',
    includeIfNull: false,
    toJson: grantInSubjectTypeToJson,
    fromJson: grantInSubjectTypeFromJson,
  )
  final enums.GrantInSubjectType subjectType;
  static const fromJsonFactory = _$GrantInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GrantIn &&
            (identical(other.periodEnd, periodEnd) ||
                const DeepCollectionEquality().equals(
                  other.periodEnd,
                  periodEnd,
                )) &&
            (identical(other.planKey, planKey) ||
                const DeepCollectionEquality().equals(
                  other.planKey,
                  planKey,
                )) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.subjectId, subjectId) ||
                const DeepCollectionEquality().equals(
                  other.subjectId,
                  subjectId,
                )) &&
            (identical(other.subjectType, subjectType) ||
                const DeepCollectionEquality().equals(
                  other.subjectType,
                  subjectType,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(periodEnd) ^
      const DeepCollectionEquality().hash(planKey) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(subjectId) ^
      const DeepCollectionEquality().hash(subjectType) ^
      runtimeType.hashCode;
}

extension $GrantInExtension on GrantIn {
  GrantIn copyWith({
    DateTime? periodEnd,
    String? planKey,
    String? reason,
    String? subjectId,
    enums.GrantInSubjectType? subjectType,
  }) {
    return GrantIn(
      periodEnd: periodEnd ?? this.periodEnd,
      planKey: planKey ?? this.planKey,
      reason: reason ?? this.reason,
      subjectId: subjectId ?? this.subjectId,
      subjectType: subjectType ?? this.subjectType,
    );
  }

  GrantIn copyWithWrapped({
    Wrapped<DateTime>? periodEnd,
    Wrapped<String>? planKey,
    Wrapped<String>? reason,
    Wrapped<String>? subjectId,
    Wrapped<enums.GrantInSubjectType>? subjectType,
  }) {
    return GrantIn(
      periodEnd: (periodEnd != null ? periodEnd.value : this.periodEnd),
      planKey: (planKey != null ? planKey.value : this.planKey),
      reason: (reason != null ? reason.value : this.reason),
      subjectId: (subjectId != null ? subjectId.value : this.subjectId),
      subjectType: (subjectType != null ? subjectType.value : this.subjectType),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class GrievanceOfficerOut {
  const GrievanceOfficerOut({required this.contact, required this.name});

  factory GrievanceOfficerOut.fromJson(Map<String, dynamic> json) =>
      _$GrievanceOfficerOutFromJson(json);

  static const toJsonFactory = _$GrievanceOfficerOutToJson;
  Map<String, dynamic> toJson() => _$GrievanceOfficerOutToJson(this);

  @JsonKey(name: 'contact', includeIfNull: false)
  final String? contact;
  @JsonKey(name: 'name', includeIfNull: false)
  final String? name;
  static const fromJsonFactory = _$GrievanceOfficerOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GrievanceOfficerOut &&
            (identical(other.contact, contact) ||
                const DeepCollectionEquality().equals(
                  other.contact,
                  contact,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(contact) ^
      const DeepCollectionEquality().hash(name) ^
      runtimeType.hashCode;
}

extension $GrievanceOfficerOutExtension on GrievanceOfficerOut {
  GrievanceOfficerOut copyWith({String? contact, String? name}) {
    return GrievanceOfficerOut(
      contact: contact ?? this.contact,
      name: name ?? this.name,
    );
  }

  GrievanceOfficerOut copyWithWrapped({
    Wrapped<String?>? contact,
    Wrapped<String?>? name,
  }) {
    return GrievanceOfficerOut(
      contact: (contact != null ? contact.value : this.contact),
      name: (name != null ? name.value : this.name),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class GrowerCardOut {
  const GrowerCardOut({
    required this.crop,
    required this.reviewed,
    required this.sources,
    required this.text,
    required this.topic,
    required this.topicKind,
    required this.topicLabels,
  });

  factory GrowerCardOut.fromJson(Map<String, dynamic> json) =>
      _$GrowerCardOutFromJson(json);

  static const toJsonFactory = _$GrowerCardOutToJson;
  Map<String, dynamic> toJson() => _$GrowerCardOutToJson(this);

  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'reviewed', includeIfNull: false)
  final bool reviewed;
  @JsonKey(
    name: 'sources',
    includeIfNull: false,
    defaultValue: <CardSourceOut>[],
  )
  final List<CardSourceOut> sources;
  @JsonKey(name: 'text', includeIfNull: false)
  final Map<String, dynamic> text;
  @JsonKey(name: 'topic', includeIfNull: false)
  final String topic;
  @JsonKey(name: 'topic_kind', includeIfNull: false)
  final String topicKind;
  @JsonKey(name: 'topic_labels', includeIfNull: false)
  final Map<String, dynamic> topicLabels;
  static const fromJsonFactory = _$GrowerCardOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GrowerCardOut &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.reviewed, reviewed) ||
                const DeepCollectionEquality().equals(
                  other.reviewed,
                  reviewed,
                )) &&
            (identical(other.sources, sources) ||
                const DeepCollectionEquality().equals(
                  other.sources,
                  sources,
                )) &&
            (identical(other.text, text) ||
                const DeepCollectionEquality().equals(other.text, text)) &&
            (identical(other.topic, topic) ||
                const DeepCollectionEquality().equals(other.topic, topic)) &&
            (identical(other.topicKind, topicKind) ||
                const DeepCollectionEquality().equals(
                  other.topicKind,
                  topicKind,
                )) &&
            (identical(other.topicLabels, topicLabels) ||
                const DeepCollectionEquality().equals(
                  other.topicLabels,
                  topicLabels,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(reviewed) ^
      const DeepCollectionEquality().hash(sources) ^
      const DeepCollectionEquality().hash(text) ^
      const DeepCollectionEquality().hash(topic) ^
      const DeepCollectionEquality().hash(topicKind) ^
      const DeepCollectionEquality().hash(topicLabels) ^
      runtimeType.hashCode;
}

extension $GrowerCardOutExtension on GrowerCardOut {
  GrowerCardOut copyWith({
    String? crop,
    bool? reviewed,
    List<CardSourceOut>? sources,
    Map<String, dynamic>? text,
    String? topic,
    String? topicKind,
    Map<String, dynamic>? topicLabels,
  }) {
    return GrowerCardOut(
      crop: crop ?? this.crop,
      reviewed: reviewed ?? this.reviewed,
      sources: sources ?? this.sources,
      text: text ?? this.text,
      topic: topic ?? this.topic,
      topicKind: topicKind ?? this.topicKind,
      topicLabels: topicLabels ?? this.topicLabels,
    );
  }

  GrowerCardOut copyWithWrapped({
    Wrapped<String>? crop,
    Wrapped<bool>? reviewed,
    Wrapped<List<CardSourceOut>>? sources,
    Wrapped<Map<String, dynamic>>? text,
    Wrapped<String>? topic,
    Wrapped<String>? topicKind,
    Wrapped<Map<String, dynamic>>? topicLabels,
  }) {
    return GrowerCardOut(
      crop: (crop != null ? crop.value : this.crop),
      reviewed: (reviewed != null ? reviewed.value : this.reviewed),
      sources: (sources != null ? sources.value : this.sources),
      text: (text != null ? text.value : this.text),
      topic: (topic != null ? topic.value : this.topic),
      topicKind: (topicKind != null ? topicKind.value : this.topicKind),
      topicLabels: (topicLabels != null ? topicLabels.value : this.topicLabels),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class GrowerCardsResponse {
  const GrowerCardsResponse({required this.cards, this.kind});

  factory GrowerCardsResponse.fromJson(Map<String, dynamic> json) =>
      _$GrowerCardsResponseFromJson(json);

  static const toJsonFactory = _$GrowerCardsResponseToJson;
  Map<String, dynamic> toJson() => _$GrowerCardsResponseToJson(this);

  @JsonKey(name: 'cards', includeIfNull: false, defaultValue: <GrowerCardOut>[])
  final List<GrowerCardOut> cards;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String? kind;
  static const fromJsonFactory = _$GrowerCardsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GrowerCardsResponse &&
            (identical(other.cards, cards) ||
                const DeepCollectionEquality().equals(other.cards, cards)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(cards) ^
      const DeepCollectionEquality().hash(kind) ^
      runtimeType.hashCode;
}

extension $GrowerCardsResponseExtension on GrowerCardsResponse {
  GrowerCardsResponse copyWith({List<GrowerCardOut>? cards, String? kind}) {
    return GrowerCardsResponse(
      cards: cards ?? this.cards,
      kind: kind ?? this.kind,
    );
  }

  GrowerCardsResponse copyWithWrapped({
    Wrapped<List<GrowerCardOut>>? cards,
    Wrapped<String?>? kind,
  }) {
    return GrowerCardsResponse(
      cards: (cards != null ? cards.value : this.cards),
      kind: (kind != null ? kind.value : this.kind),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class GrowerInterestOut {
  const GrowerInterestOut({
    required this.basis,
    required this.broker,
    required this.createdAt,
    this.dealId,
    required this.harvestDate,
    required this.id,
    required this.lotId,
    required this.quantityT,
    required this.ratePaise,
    required this.status,
    required this.trader,
    required this.viaBroker,
  });

  factory GrowerInterestOut.fromJson(Map<String, dynamic> json) =>
      _$GrowerInterestOutFromJson(json);

  static const toJsonFactory = _$GrowerInterestOutToJson;
  Map<String, dynamic> toJson() => _$GrowerInterestOutToJson(this);

  @JsonKey(name: 'basis', includeIfNull: false)
  final String basis;
  @JsonKey(name: 'broker', includeIfNull: false)
  final PublicProfileOut? broker;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'deal_id', includeIfNull: false)
  final String? dealId;
  @JsonKey(name: 'harvest_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime harvestDate;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'lot_id', includeIfNull: false)
  final String lotId;
  @JsonKey(name: 'quantity_t', includeIfNull: false)
  final double? quantityT;
  @JsonKey(name: 'rate_paise', includeIfNull: false)
  final int ratePaise;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'trader', includeIfNull: false)
  final PublicProfileOut trader;
  @JsonKey(name: 'via_broker', includeIfNull: false)
  final bool viaBroker;
  static const fromJsonFactory = _$GrowerInterestOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GrowerInterestOut &&
            (identical(other.basis, basis) ||
                const DeepCollectionEquality().equals(other.basis, basis)) &&
            (identical(other.broker, broker) ||
                const DeepCollectionEquality().equals(other.broker, broker)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.dealId, dealId) ||
                const DeepCollectionEquality().equals(other.dealId, dealId)) &&
            (identical(other.harvestDate, harvestDate) ||
                const DeepCollectionEquality().equals(
                  other.harvestDate,
                  harvestDate,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.lotId, lotId) ||
                const DeepCollectionEquality().equals(other.lotId, lotId)) &&
            (identical(other.quantityT, quantityT) ||
                const DeepCollectionEquality().equals(
                  other.quantityT,
                  quantityT,
                )) &&
            (identical(other.ratePaise, ratePaise) ||
                const DeepCollectionEquality().equals(
                  other.ratePaise,
                  ratePaise,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.trader, trader) ||
                const DeepCollectionEquality().equals(other.trader, trader)) &&
            (identical(other.viaBroker, viaBroker) ||
                const DeepCollectionEquality().equals(
                  other.viaBroker,
                  viaBroker,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(basis) ^
      const DeepCollectionEquality().hash(broker) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(dealId) ^
      const DeepCollectionEquality().hash(harvestDate) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(lotId) ^
      const DeepCollectionEquality().hash(quantityT) ^
      const DeepCollectionEquality().hash(ratePaise) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(trader) ^
      const DeepCollectionEquality().hash(viaBroker) ^
      runtimeType.hashCode;
}

extension $GrowerInterestOutExtension on GrowerInterestOut {
  GrowerInterestOut copyWith({
    String? basis,
    PublicProfileOut? broker,
    DateTime? createdAt,
    String? dealId,
    DateTime? harvestDate,
    String? id,
    String? lotId,
    double? quantityT,
    int? ratePaise,
    String? status,
    PublicProfileOut? trader,
    bool? viaBroker,
  }) {
    return GrowerInterestOut(
      basis: basis ?? this.basis,
      broker: broker ?? this.broker,
      createdAt: createdAt ?? this.createdAt,
      dealId: dealId ?? this.dealId,
      harvestDate: harvestDate ?? this.harvestDate,
      id: id ?? this.id,
      lotId: lotId ?? this.lotId,
      quantityT: quantityT ?? this.quantityT,
      ratePaise: ratePaise ?? this.ratePaise,
      status: status ?? this.status,
      trader: trader ?? this.trader,
      viaBroker: viaBroker ?? this.viaBroker,
    );
  }

  GrowerInterestOut copyWithWrapped({
    Wrapped<String>? basis,
    Wrapped<PublicProfileOut?>? broker,
    Wrapped<DateTime>? createdAt,
    Wrapped<String?>? dealId,
    Wrapped<DateTime>? harvestDate,
    Wrapped<String>? id,
    Wrapped<String>? lotId,
    Wrapped<double?>? quantityT,
    Wrapped<int>? ratePaise,
    Wrapped<String>? status,
    Wrapped<PublicProfileOut>? trader,
    Wrapped<bool>? viaBroker,
  }) {
    return GrowerInterestOut(
      basis: (basis != null ? basis.value : this.basis),
      broker: (broker != null ? broker.value : this.broker),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      dealId: (dealId != null ? dealId.value : this.dealId),
      harvestDate: (harvestDate != null ? harvestDate.value : this.harvestDate),
      id: (id != null ? id.value : this.id),
      lotId: (lotId != null ? lotId.value : this.lotId),
      quantityT: (quantityT != null ? quantityT.value : this.quantityT),
      ratePaise: (ratePaise != null ? ratePaise.value : this.ratePaise),
      status: (status != null ? status.value : this.status),
      trader: (trader != null ? trader.value : this.trader),
      viaBroker: (viaBroker != null ? viaBroker.value : this.viaBroker),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class GrowerLotOut {
  const GrowerLotOut({
    required this.crop,
    required this.district,
    required this.id,
    required this.orchardCheck,
    required this.publishedAt,
    required this.status,
    required this.taluka,
    required this.variety,
    required this.village,
  });

  factory GrowerLotOut.fromJson(Map<String, dynamic> json) =>
      _$GrowerLotOutFromJson(json);

  static const toJsonFactory = _$GrowerLotOutToJson;
  Map<String, dynamic> toJson() => _$GrowerLotOutToJson(this);

  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'orchard_check', includeIfNull: false)
  final String? orchardCheck;
  @JsonKey(name: 'published_at', includeIfNull: false)
  final DateTime? publishedAt;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'variety', includeIfNull: false)
  final String? variety;
  @JsonKey(name: 'village', includeIfNull: false)
  final String? village;
  static const fromJsonFactory = _$GrowerLotOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GrowerLotOut &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.orchardCheck, orchardCheck) ||
                const DeepCollectionEquality().equals(
                  other.orchardCheck,
                  orchardCheck,
                )) &&
            (identical(other.publishedAt, publishedAt) ||
                const DeepCollectionEquality().equals(
                  other.publishedAt,
                  publishedAt,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.variety, variety) ||
                const DeepCollectionEquality().equals(
                  other.variety,
                  variety,
                )) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(orchardCheck) ^
      const DeepCollectionEquality().hash(publishedAt) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(variety) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $GrowerLotOutExtension on GrowerLotOut {
  GrowerLotOut copyWith({
    String? crop,
    String? district,
    String? id,
    String? orchardCheck,
    DateTime? publishedAt,
    String? status,
    String? taluka,
    String? variety,
    String? village,
  }) {
    return GrowerLotOut(
      crop: crop ?? this.crop,
      district: district ?? this.district,
      id: id ?? this.id,
      orchardCheck: orchardCheck ?? this.orchardCheck,
      publishedAt: publishedAt ?? this.publishedAt,
      status: status ?? this.status,
      taluka: taluka ?? this.taluka,
      variety: variety ?? this.variety,
      village: village ?? this.village,
    );
  }

  GrowerLotOut copyWithWrapped({
    Wrapped<String>? crop,
    Wrapped<String?>? district,
    Wrapped<String>? id,
    Wrapped<String?>? orchardCheck,
    Wrapped<DateTime?>? publishedAt,
    Wrapped<String>? status,
    Wrapped<String?>? taluka,
    Wrapped<String?>? variety,
    Wrapped<String?>? village,
  }) {
    return GrowerLotOut(
      crop: (crop != null ? crop.value : this.crop),
      district: (district != null ? district.value : this.district),
      id: (id != null ? id.value : this.id),
      orchardCheck: (orchardCheck != null
          ? orchardCheck.value
          : this.orchardCheck),
      publishedAt: (publishedAt != null ? publishedAt.value : this.publishedAt),
      status: (status != null ? status.value : this.status),
      taluka: (taluka != null ? taluka.value : this.taluka),
      variety: (variety != null ? variety.value : this.variety),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class HTTPValidationError {
  const HTTPValidationError({this.detail});

  factory HTTPValidationError.fromJson(Map<String, dynamic> json) =>
      _$HTTPValidationErrorFromJson(json);

  static const toJsonFactory = _$HTTPValidationErrorToJson;
  Map<String, dynamic> toJson() => _$HTTPValidationErrorToJson(this);

  @JsonKey(
    name: 'detail',
    includeIfNull: false,
    defaultValue: <ValidationError>[],
  )
  final List<ValidationError>? detail;
  static const fromJsonFactory = _$HTTPValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is HTTPValidationError &&
            (identical(other.detail, detail) ||
                const DeepCollectionEquality().equals(other.detail, detail)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(detail) ^ runtimeType.hashCode;
}

extension $HTTPValidationErrorExtension on HTTPValidationError {
  HTTPValidationError copyWith({List<ValidationError>? detail}) {
    return HTTPValidationError(detail: detail ?? this.detail);
  }

  HTTPValidationError copyWithWrapped({
    Wrapped<List<ValidationError>?>? detail,
  }) {
    return HTTPValidationError(
      detail: (detail != null ? detail.value : this.detail),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ImportIn {
  const ImportIn({required this.csv, required this.sourceKey});

  factory ImportIn.fromJson(Map<String, dynamic> json) =>
      _$ImportInFromJson(json);

  static const toJsonFactory = _$ImportInToJson;
  Map<String, dynamic> toJson() => _$ImportInToJson(this);

  @JsonKey(name: 'csv', includeIfNull: false)
  final String csv;
  @JsonKey(name: 'source_key', includeIfNull: false)
  final String sourceKey;
  static const fromJsonFactory = _$ImportInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ImportIn &&
            (identical(other.csv, csv) ||
                const DeepCollectionEquality().equals(other.csv, csv)) &&
            (identical(other.sourceKey, sourceKey) ||
                const DeepCollectionEquality().equals(
                  other.sourceKey,
                  sourceKey,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(csv) ^
      const DeepCollectionEquality().hash(sourceKey) ^
      runtimeType.hashCode;
}

extension $ImportInExtension on ImportIn {
  ImportIn copyWith({String? csv, String? sourceKey}) {
    return ImportIn(
      csv: csv ?? this.csv,
      sourceKey: sourceKey ?? this.sourceKey,
    );
  }

  ImportIn copyWithWrapped({Wrapped<String>? csv, Wrapped<String>? sourceKey}) {
    return ImportIn(
      csv: (csv != null ? csv.value : this.csv),
      sourceKey: (sourceKey != null ? sourceKey.value : this.sourceKey),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ImportOut {
  const ImportOut({
    required this.added,
    required this.cardsPulled,
    required this.changed,
    required this.removed,
    required this.unchanged,
  });

  factory ImportOut.fromJson(Map<String, dynamic> json) =>
      _$ImportOutFromJson(json);

  static const toJsonFactory = _$ImportOutToJson;
  Map<String, dynamic> toJson() => _$ImportOutToJson(this);

  @JsonKey(name: 'added', includeIfNull: false)
  final int added;
  @JsonKey(name: 'cards_pulled', includeIfNull: false)
  final int cardsPulled;
  @JsonKey(name: 'changed', includeIfNull: false)
  final int changed;
  @JsonKey(name: 'removed', includeIfNull: false)
  final int removed;
  @JsonKey(name: 'unchanged', includeIfNull: false)
  final int unchanged;
  static const fromJsonFactory = _$ImportOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ImportOut &&
            (identical(other.added, added) ||
                const DeepCollectionEquality().equals(other.added, added)) &&
            (identical(other.cardsPulled, cardsPulled) ||
                const DeepCollectionEquality().equals(
                  other.cardsPulled,
                  cardsPulled,
                )) &&
            (identical(other.changed, changed) ||
                const DeepCollectionEquality().equals(
                  other.changed,
                  changed,
                )) &&
            (identical(other.removed, removed) ||
                const DeepCollectionEquality().equals(
                  other.removed,
                  removed,
                )) &&
            (identical(other.unchanged, unchanged) ||
                const DeepCollectionEquality().equals(
                  other.unchanged,
                  unchanged,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(added) ^
      const DeepCollectionEquality().hash(cardsPulled) ^
      const DeepCollectionEquality().hash(changed) ^
      const DeepCollectionEquality().hash(removed) ^
      const DeepCollectionEquality().hash(unchanged) ^
      runtimeType.hashCode;
}

extension $ImportOutExtension on ImportOut {
  ImportOut copyWith({
    int? added,
    int? cardsPulled,
    int? changed,
    int? removed,
    int? unchanged,
  }) {
    return ImportOut(
      added: added ?? this.added,
      cardsPulled: cardsPulled ?? this.cardsPulled,
      changed: changed ?? this.changed,
      removed: removed ?? this.removed,
      unchanged: unchanged ?? this.unchanged,
    );
  }

  ImportOut copyWithWrapped({
    Wrapped<int>? added,
    Wrapped<int>? cardsPulled,
    Wrapped<int>? changed,
    Wrapped<int>? removed,
    Wrapped<int>? unchanged,
  }) {
    return ImportOut(
      added: (added != null ? added.value : this.added),
      cardsPulled: (cardsPulled != null ? cardsPulled.value : this.cardsPulled),
      changed: (changed != null ? changed.value : this.changed),
      removed: (removed != null ? removed.value : this.removed),
      unchanged: (unchanged != null ? unchanged.value : this.unchanged),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class InsuranceDeadlineOut {
  const InsuranceDeadlineOut({
    required this.dueDate,
    required this.itemId,
    required this.season,
    required this.title,
    required this.url,
  });

  factory InsuranceDeadlineOut.fromJson(Map<String, dynamic> json) =>
      _$InsuranceDeadlineOutFromJson(json);

  static const toJsonFactory = _$InsuranceDeadlineOutToJson;
  Map<String, dynamic> toJson() => _$InsuranceDeadlineOutToJson(this);

  @JsonKey(name: 'due_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime dueDate;
  @JsonKey(name: 'item_id', includeIfNull: false)
  final String itemId;
  @JsonKey(name: 'season', includeIfNull: false)
  final String? season;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  static const fromJsonFactory = _$InsuranceDeadlineOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InsuranceDeadlineOut &&
            (identical(other.dueDate, dueDate) ||
                const DeepCollectionEquality().equals(
                  other.dueDate,
                  dueDate,
                )) &&
            (identical(other.itemId, itemId) ||
                const DeepCollectionEquality().equals(other.itemId, itemId)) &&
            (identical(other.season, season) ||
                const DeepCollectionEquality().equals(other.season, season)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(dueDate) ^
      const DeepCollectionEquality().hash(itemId) ^
      const DeepCollectionEquality().hash(season) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(url) ^
      runtimeType.hashCode;
}

extension $InsuranceDeadlineOutExtension on InsuranceDeadlineOut {
  InsuranceDeadlineOut copyWith({
    DateTime? dueDate,
    String? itemId,
    String? season,
    String? title,
    String? url,
  }) {
    return InsuranceDeadlineOut(
      dueDate: dueDate ?? this.dueDate,
      itemId: itemId ?? this.itemId,
      season: season ?? this.season,
      title: title ?? this.title,
      url: url ?? this.url,
    );
  }

  InsuranceDeadlineOut copyWithWrapped({
    Wrapped<DateTime>? dueDate,
    Wrapped<String>? itemId,
    Wrapped<String?>? season,
    Wrapped<String>? title,
    Wrapped<String>? url,
  }) {
    return InsuranceDeadlineOut(
      dueDate: (dueDate != null ? dueDate.value : this.dueDate),
      itemId: (itemId != null ? itemId.value : this.itemId),
      season: (season != null ? season.value : this.season),
      title: (title != null ? title.value : this.title),
      url: (url != null ? url.value : this.url),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class InsuranceDeadlinesResponse {
  const InsuranceDeadlinesResponse({required this.footer, required this.items});

  factory InsuranceDeadlinesResponse.fromJson(Map<String, dynamic> json) =>
      _$InsuranceDeadlinesResponseFromJson(json);

  static const toJsonFactory = _$InsuranceDeadlinesResponseToJson;
  Map<String, dynamic> toJson() => _$InsuranceDeadlinesResponseToJson(this);

  @JsonKey(name: 'footer', includeIfNull: false)
  final String footer;
  @JsonKey(
    name: 'items',
    includeIfNull: false,
    defaultValue: <InsuranceDeadlineOut>[],
  )
  final List<InsuranceDeadlineOut> items;
  static const fromJsonFactory = _$InsuranceDeadlinesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InsuranceDeadlinesResponse &&
            (identical(other.footer, footer) ||
                const DeepCollectionEquality().equals(other.footer, footer)) &&
            (identical(other.items, items) ||
                const DeepCollectionEquality().equals(other.items, items)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(footer) ^
      const DeepCollectionEquality().hash(items) ^
      runtimeType.hashCode;
}

extension $InsuranceDeadlinesResponseExtension on InsuranceDeadlinesResponse {
  InsuranceDeadlinesResponse copyWith({
    String? footer,
    List<InsuranceDeadlineOut>? items,
  }) {
    return InsuranceDeadlinesResponse(
      footer: footer ?? this.footer,
      items: items ?? this.items,
    );
  }

  InsuranceDeadlinesResponse copyWithWrapped({
    Wrapped<String>? footer,
    Wrapped<List<InsuranceDeadlineOut>>? items,
  }) {
    return InsuranceDeadlinesResponse(
      footer: (footer != null ? footer.value : this.footer),
      items: (items != null ? items.value : this.items),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class InterestIn {
  const InterestIn({
    required this.basis,
    this.brokerId,
    required this.harvestDate,
    this.quantityT,
    required this.ratePaise,
    this.traderId,
  });

  factory InterestIn.fromJson(Map<String, dynamic> json) =>
      _$InterestInFromJson(json);

  static const toJsonFactory = _$InterestInToJson;
  Map<String, dynamic> toJson() => _$InterestInToJson(this);

  @JsonKey(
    name: 'basis',
    includeIfNull: false,
    toJson: interestInBasisToJson,
    fromJson: interestInBasisFromJson,
  )
  final enums.InterestInBasis basis;
  @JsonKey(name: 'broker_id', includeIfNull: false)
  final String? brokerId;
  @JsonKey(name: 'harvest_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime harvestDate;
  @JsonKey(name: 'quantity_t', includeIfNull: false)
  final double? quantityT;
  @JsonKey(name: 'rate_paise', includeIfNull: false)
  final int ratePaise;
  @JsonKey(name: 'trader_id', includeIfNull: false)
  final String? traderId;
  static const fromJsonFactory = _$InterestInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InterestIn &&
            (identical(other.basis, basis) ||
                const DeepCollectionEquality().equals(other.basis, basis)) &&
            (identical(other.brokerId, brokerId) ||
                const DeepCollectionEquality().equals(
                  other.brokerId,
                  brokerId,
                )) &&
            (identical(other.harvestDate, harvestDate) ||
                const DeepCollectionEquality().equals(
                  other.harvestDate,
                  harvestDate,
                )) &&
            (identical(other.quantityT, quantityT) ||
                const DeepCollectionEquality().equals(
                  other.quantityT,
                  quantityT,
                )) &&
            (identical(other.ratePaise, ratePaise) ||
                const DeepCollectionEquality().equals(
                  other.ratePaise,
                  ratePaise,
                )) &&
            (identical(other.traderId, traderId) ||
                const DeepCollectionEquality().equals(
                  other.traderId,
                  traderId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(basis) ^
      const DeepCollectionEquality().hash(brokerId) ^
      const DeepCollectionEquality().hash(harvestDate) ^
      const DeepCollectionEquality().hash(quantityT) ^
      const DeepCollectionEquality().hash(ratePaise) ^
      const DeepCollectionEquality().hash(traderId) ^
      runtimeType.hashCode;
}

extension $InterestInExtension on InterestIn {
  InterestIn copyWith({
    enums.InterestInBasis? basis,
    String? brokerId,
    DateTime? harvestDate,
    double? quantityT,
    int? ratePaise,
    String? traderId,
  }) {
    return InterestIn(
      basis: basis ?? this.basis,
      brokerId: brokerId ?? this.brokerId,
      harvestDate: harvestDate ?? this.harvestDate,
      quantityT: quantityT ?? this.quantityT,
      ratePaise: ratePaise ?? this.ratePaise,
      traderId: traderId ?? this.traderId,
    );
  }

  InterestIn copyWithWrapped({
    Wrapped<enums.InterestInBasis>? basis,
    Wrapped<String?>? brokerId,
    Wrapped<DateTime>? harvestDate,
    Wrapped<double?>? quantityT,
    Wrapped<int>? ratePaise,
    Wrapped<String?>? traderId,
  }) {
    return InterestIn(
      basis: (basis != null ? basis.value : this.basis),
      brokerId: (brokerId != null ? brokerId.value : this.brokerId),
      harvestDate: (harvestDate != null ? harvestDate.value : this.harvestDate),
      quantityT: (quantityT != null ? quantityT.value : this.quantityT),
      ratePaise: (ratePaise != null ? ratePaise.value : this.ratePaise),
      traderId: (traderId != null ? traderId.value : this.traderId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class InterestOut {
  const InterestOut({
    required this.basis,
    required this.createdAt,
    this.dealId,
    required this.harvestDate,
    required this.id,
    required this.lotId,
    required this.quantityT,
    required this.ratePaise,
    required this.status,
    required this.viaBroker,
  });

  factory InterestOut.fromJson(Map<String, dynamic> json) =>
      _$InterestOutFromJson(json);

  static const toJsonFactory = _$InterestOutToJson;
  Map<String, dynamic> toJson() => _$InterestOutToJson(this);

  @JsonKey(name: 'basis', includeIfNull: false)
  final String basis;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'deal_id', includeIfNull: false)
  final String? dealId;
  @JsonKey(name: 'harvest_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime harvestDate;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'lot_id', includeIfNull: false)
  final String lotId;
  @JsonKey(name: 'quantity_t', includeIfNull: false)
  final double? quantityT;
  @JsonKey(name: 'rate_paise', includeIfNull: false)
  final int ratePaise;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'via_broker', includeIfNull: false)
  final bool viaBroker;
  static const fromJsonFactory = _$InterestOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InterestOut &&
            (identical(other.basis, basis) ||
                const DeepCollectionEquality().equals(other.basis, basis)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.dealId, dealId) ||
                const DeepCollectionEquality().equals(other.dealId, dealId)) &&
            (identical(other.harvestDate, harvestDate) ||
                const DeepCollectionEquality().equals(
                  other.harvestDate,
                  harvestDate,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.lotId, lotId) ||
                const DeepCollectionEquality().equals(other.lotId, lotId)) &&
            (identical(other.quantityT, quantityT) ||
                const DeepCollectionEquality().equals(
                  other.quantityT,
                  quantityT,
                )) &&
            (identical(other.ratePaise, ratePaise) ||
                const DeepCollectionEquality().equals(
                  other.ratePaise,
                  ratePaise,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.viaBroker, viaBroker) ||
                const DeepCollectionEquality().equals(
                  other.viaBroker,
                  viaBroker,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(basis) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(dealId) ^
      const DeepCollectionEquality().hash(harvestDate) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(lotId) ^
      const DeepCollectionEquality().hash(quantityT) ^
      const DeepCollectionEquality().hash(ratePaise) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(viaBroker) ^
      runtimeType.hashCode;
}

extension $InterestOutExtension on InterestOut {
  InterestOut copyWith({
    String? basis,
    DateTime? createdAt,
    String? dealId,
    DateTime? harvestDate,
    String? id,
    String? lotId,
    double? quantityT,
    int? ratePaise,
    String? status,
    bool? viaBroker,
  }) {
    return InterestOut(
      basis: basis ?? this.basis,
      createdAt: createdAt ?? this.createdAt,
      dealId: dealId ?? this.dealId,
      harvestDate: harvestDate ?? this.harvestDate,
      id: id ?? this.id,
      lotId: lotId ?? this.lotId,
      quantityT: quantityT ?? this.quantityT,
      ratePaise: ratePaise ?? this.ratePaise,
      status: status ?? this.status,
      viaBroker: viaBroker ?? this.viaBroker,
    );
  }

  InterestOut copyWithWrapped({
    Wrapped<String>? basis,
    Wrapped<DateTime>? createdAt,
    Wrapped<String?>? dealId,
    Wrapped<DateTime>? harvestDate,
    Wrapped<String>? id,
    Wrapped<String>? lotId,
    Wrapped<double?>? quantityT,
    Wrapped<int>? ratePaise,
    Wrapped<String>? status,
    Wrapped<bool>? viaBroker,
  }) {
    return InterestOut(
      basis: (basis != null ? basis.value : this.basis),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      dealId: (dealId != null ? dealId.value : this.dealId),
      harvestDate: (harvestDate != null ? harvestDate.value : this.harvestDate),
      id: (id != null ? id.value : this.id),
      lotId: (lotId != null ? lotId.value : this.lotId),
      quantityT: (quantityT != null ? quantityT.value : this.quantityT),
      ratePaise: (ratePaise != null ? ratePaise.value : this.ratePaise),
      status: (status != null ? status.value : this.status),
      viaBroker: (viaBroker != null ? viaBroker.value : this.viaBroker),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LabelClaimOut {
  const LabelClaimOut({
    required this.activeIngredient,
    this.brandNames,
    this.category,
    this.description,
    this.dilution,
    required this.dose,
    required this.formulation,
    required this.intervalDays,
    required this.labelCrop,
    this.makerUrl,
    required this.maxSprays,
    this.pageRef,
    required this.phiDays,
    this.photoUrl,
    required this.sourceKey,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.target,
  });

  factory LabelClaimOut.fromJson(Map<String, dynamic> json) =>
      _$LabelClaimOutFromJson(json);

  static const toJsonFactory = _$LabelClaimOutToJson;
  Map<String, dynamic> toJson() => _$LabelClaimOutToJson(this);

  @JsonKey(name: 'active_ingredient', includeIfNull: false)
  final String activeIngredient;
  @JsonKey(name: 'brand_names', includeIfNull: false, defaultValue: <String>[])
  final List<String>? brandNames;
  @JsonKey(
    name: 'category',
    includeIfNull: false,
    toJson: labelClaimOutCategoryNullableToJson,
    fromJson: labelClaimOutCategoryCategoryNullableFromJson,
  )
  final enums.LabelClaimOutCategory? category;
  static enums.LabelClaimOutCategory?
  labelClaimOutCategoryCategoryNullableFromJson(Object? value) =>
      labelClaimOutCategoryNullableFromJson(
        value,
        enums.LabelClaimOutCategory.chemical,
      );

  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;
  @JsonKey(name: 'dilution', includeIfNull: false)
  final String? dilution;
  @JsonKey(name: 'dose', includeIfNull: false)
  final String dose;
  @JsonKey(name: 'formulation', includeIfNull: false)
  final String formulation;
  @JsonKey(name: 'interval_days', includeIfNull: false)
  final int? intervalDays;
  @JsonKey(name: 'label_crop', includeIfNull: false)
  final String labelCrop;
  @JsonKey(name: 'maker_url', includeIfNull: false)
  final String? makerUrl;
  @JsonKey(name: 'max_sprays', includeIfNull: false)
  final int? maxSprays;
  @JsonKey(name: 'page_ref', includeIfNull: false)
  final String? pageRef;
  @JsonKey(name: 'phi_days', includeIfNull: false)
  final int? phiDays;
  @JsonKey(name: 'photo_url', includeIfNull: false)
  final String? photoUrl;
  @JsonKey(name: 'source_key', includeIfNull: false)
  final String sourceKey;
  @JsonKey(name: 'source_title', includeIfNull: false)
  final String sourceTitle;
  @JsonKey(name: 'source_url', includeIfNull: false)
  final String sourceUrl;
  @JsonKey(name: 'target', includeIfNull: false)
  final String target;
  static const fromJsonFactory = _$LabelClaimOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LabelClaimOut &&
            (identical(other.activeIngredient, activeIngredient) ||
                const DeepCollectionEquality().equals(
                  other.activeIngredient,
                  activeIngredient,
                )) &&
            (identical(other.brandNames, brandNames) ||
                const DeepCollectionEquality().equals(
                  other.brandNames,
                  brandNames,
                )) &&
            (identical(other.category, category) ||
                const DeepCollectionEquality().equals(
                  other.category,
                  category,
                )) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(
                  other.description,
                  description,
                )) &&
            (identical(other.dilution, dilution) ||
                const DeepCollectionEquality().equals(
                  other.dilution,
                  dilution,
                )) &&
            (identical(other.dose, dose) ||
                const DeepCollectionEquality().equals(other.dose, dose)) &&
            (identical(other.formulation, formulation) ||
                const DeepCollectionEquality().equals(
                  other.formulation,
                  formulation,
                )) &&
            (identical(other.intervalDays, intervalDays) ||
                const DeepCollectionEquality().equals(
                  other.intervalDays,
                  intervalDays,
                )) &&
            (identical(other.labelCrop, labelCrop) ||
                const DeepCollectionEquality().equals(
                  other.labelCrop,
                  labelCrop,
                )) &&
            (identical(other.makerUrl, makerUrl) ||
                const DeepCollectionEquality().equals(
                  other.makerUrl,
                  makerUrl,
                )) &&
            (identical(other.maxSprays, maxSprays) ||
                const DeepCollectionEquality().equals(
                  other.maxSprays,
                  maxSprays,
                )) &&
            (identical(other.pageRef, pageRef) ||
                const DeepCollectionEquality().equals(
                  other.pageRef,
                  pageRef,
                )) &&
            (identical(other.phiDays, phiDays) ||
                const DeepCollectionEquality().equals(
                  other.phiDays,
                  phiDays,
                )) &&
            (identical(other.photoUrl, photoUrl) ||
                const DeepCollectionEquality().equals(
                  other.photoUrl,
                  photoUrl,
                )) &&
            (identical(other.sourceKey, sourceKey) ||
                const DeepCollectionEquality().equals(
                  other.sourceKey,
                  sourceKey,
                )) &&
            (identical(other.sourceTitle, sourceTitle) ||
                const DeepCollectionEquality().equals(
                  other.sourceTitle,
                  sourceTitle,
                )) &&
            (identical(other.sourceUrl, sourceUrl) ||
                const DeepCollectionEquality().equals(
                  other.sourceUrl,
                  sourceUrl,
                )) &&
            (identical(other.target, target) ||
                const DeepCollectionEquality().equals(other.target, target)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activeIngredient) ^
      const DeepCollectionEquality().hash(brandNames) ^
      const DeepCollectionEquality().hash(category) ^
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(dilution) ^
      const DeepCollectionEquality().hash(dose) ^
      const DeepCollectionEquality().hash(formulation) ^
      const DeepCollectionEquality().hash(intervalDays) ^
      const DeepCollectionEquality().hash(labelCrop) ^
      const DeepCollectionEquality().hash(makerUrl) ^
      const DeepCollectionEquality().hash(maxSprays) ^
      const DeepCollectionEquality().hash(pageRef) ^
      const DeepCollectionEquality().hash(phiDays) ^
      const DeepCollectionEquality().hash(photoUrl) ^
      const DeepCollectionEquality().hash(sourceKey) ^
      const DeepCollectionEquality().hash(sourceTitle) ^
      const DeepCollectionEquality().hash(sourceUrl) ^
      const DeepCollectionEquality().hash(target) ^
      runtimeType.hashCode;
}

extension $LabelClaimOutExtension on LabelClaimOut {
  LabelClaimOut copyWith({
    String? activeIngredient,
    List<String>? brandNames,
    enums.LabelClaimOutCategory? category,
    String? description,
    String? dilution,
    String? dose,
    String? formulation,
    int? intervalDays,
    String? labelCrop,
    String? makerUrl,
    int? maxSprays,
    String? pageRef,
    int? phiDays,
    String? photoUrl,
    String? sourceKey,
    String? sourceTitle,
    String? sourceUrl,
    String? target,
  }) {
    return LabelClaimOut(
      activeIngredient: activeIngredient ?? this.activeIngredient,
      brandNames: brandNames ?? this.brandNames,
      category: category ?? this.category,
      description: description ?? this.description,
      dilution: dilution ?? this.dilution,
      dose: dose ?? this.dose,
      formulation: formulation ?? this.formulation,
      intervalDays: intervalDays ?? this.intervalDays,
      labelCrop: labelCrop ?? this.labelCrop,
      makerUrl: makerUrl ?? this.makerUrl,
      maxSprays: maxSprays ?? this.maxSprays,
      pageRef: pageRef ?? this.pageRef,
      phiDays: phiDays ?? this.phiDays,
      photoUrl: photoUrl ?? this.photoUrl,
      sourceKey: sourceKey ?? this.sourceKey,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      target: target ?? this.target,
    );
  }

  LabelClaimOut copyWithWrapped({
    Wrapped<String>? activeIngredient,
    Wrapped<List<String>?>? brandNames,
    Wrapped<enums.LabelClaimOutCategory?>? category,
    Wrapped<String?>? description,
    Wrapped<String?>? dilution,
    Wrapped<String>? dose,
    Wrapped<String>? formulation,
    Wrapped<int?>? intervalDays,
    Wrapped<String>? labelCrop,
    Wrapped<String?>? makerUrl,
    Wrapped<int?>? maxSprays,
    Wrapped<String?>? pageRef,
    Wrapped<int?>? phiDays,
    Wrapped<String?>? photoUrl,
    Wrapped<String>? sourceKey,
    Wrapped<String>? sourceTitle,
    Wrapped<String>? sourceUrl,
    Wrapped<String>? target,
  }) {
    return LabelClaimOut(
      activeIngredient: (activeIngredient != null
          ? activeIngredient.value
          : this.activeIngredient),
      brandNames: (brandNames != null ? brandNames.value : this.brandNames),
      category: (category != null ? category.value : this.category),
      description: (description != null ? description.value : this.description),
      dilution: (dilution != null ? dilution.value : this.dilution),
      dose: (dose != null ? dose.value : this.dose),
      formulation: (formulation != null ? formulation.value : this.formulation),
      intervalDays: (intervalDays != null
          ? intervalDays.value
          : this.intervalDays),
      labelCrop: (labelCrop != null ? labelCrop.value : this.labelCrop),
      makerUrl: (makerUrl != null ? makerUrl.value : this.makerUrl),
      maxSprays: (maxSprays != null ? maxSprays.value : this.maxSprays),
      pageRef: (pageRef != null ? pageRef.value : this.pageRef),
      phiDays: (phiDays != null ? phiDays.value : this.phiDays),
      photoUrl: (photoUrl != null ? photoUrl.value : this.photoUrl),
      sourceKey: (sourceKey != null ? sourceKey.value : this.sourceKey),
      sourceTitle: (sourceTitle != null ? sourceTitle.value : this.sourceTitle),
      sourceUrl: (sourceUrl != null ? sourceUrl.value : this.sourceUrl),
      target: (target != null ? target.value : this.target),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LabelClaimsResponse {
  const LabelClaimsResponse({this.blocked, required this.claims, this.kind});

  factory LabelClaimsResponse.fromJson(Map<String, dynamic> json) =>
      _$LabelClaimsResponseFromJson(json);

  static const toJsonFactory = _$LabelClaimsResponseToJson;
  Map<String, dynamic> toJson() => _$LabelClaimsResponseToJson(this);

  @JsonKey(
    name: 'blocked',
    includeIfNull: false,
    defaultValue: <BlockedClaimOut>[],
  )
  final List<BlockedClaimOut>? blocked;
  @JsonKey(
    name: 'claims',
    includeIfNull: false,
    defaultValue: <LabelClaimOut>[],
  )
  final List<LabelClaimOut> claims;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String? kind;
  static const fromJsonFactory = _$LabelClaimsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LabelClaimsResponse &&
            (identical(other.blocked, blocked) ||
                const DeepCollectionEquality().equals(
                  other.blocked,
                  blocked,
                )) &&
            (identical(other.claims, claims) ||
                const DeepCollectionEquality().equals(other.claims, claims)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(blocked) ^
      const DeepCollectionEquality().hash(claims) ^
      const DeepCollectionEquality().hash(kind) ^
      runtimeType.hashCode;
}

extension $LabelClaimsResponseExtension on LabelClaimsResponse {
  LabelClaimsResponse copyWith({
    List<BlockedClaimOut>? blocked,
    List<LabelClaimOut>? claims,
    String? kind,
  }) {
    return LabelClaimsResponse(
      blocked: blocked ?? this.blocked,
      claims: claims ?? this.claims,
      kind: kind ?? this.kind,
    );
  }

  LabelClaimsResponse copyWithWrapped({
    Wrapped<List<BlockedClaimOut>?>? blocked,
    Wrapped<List<LabelClaimOut>>? claims,
    Wrapped<String?>? kind,
  }) {
    return LabelClaimsResponse(
      blocked: (blocked != null ? blocked.value : this.blocked),
      claims: (claims != null ? claims.value : this.claims),
      kind: (kind != null ? kind.value : this.kind),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LiveResponse {
  const LiveResponse({required this.product, required this.status});

  factory LiveResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveResponseFromJson(json);

  static const toJsonFactory = _$LiveResponseToJson;
  Map<String, dynamic> toJson() => _$LiveResponseToJson(this);

  @JsonKey(name: 'product', includeIfNull: false)
  final String product;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  static const fromJsonFactory = _$LiveResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LiveResponse &&
            (identical(other.product, product) ||
                const DeepCollectionEquality().equals(
                  other.product,
                  product,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(product) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $LiveResponseExtension on LiveResponse {
  LiveResponse copyWith({String? product, String? status}) {
    return LiveResponse(
      product: product ?? this.product,
      status: status ?? this.status,
    );
  }

  LiveResponse copyWithWrapped({
    Wrapped<String>? product,
    Wrapped<String>? status,
  }) {
    return LiveResponse(
      product: (product != null ? product.value : this.product),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LotBrief {
  const LotBrief({
    required this.basis,
    required this.crop,
    required this.district,
    required this.id,
    required this.quantityT,
    required this.status,
    required this.taluka,
    required this.variety,
    required this.village,
  });

  factory LotBrief.fromJson(Map<String, dynamic> json) =>
      _$LotBriefFromJson(json);

  static const toJsonFactory = _$LotBriefToJson;
  Map<String, dynamic> toJson() => _$LotBriefToJson(this);

  @JsonKey(name: 'basis', includeIfNull: false)
  final String basis;
  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'quantity_t', includeIfNull: false)
  final double quantityT;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'variety', includeIfNull: false)
  final String? variety;
  @JsonKey(name: 'village', includeIfNull: false)
  final String? village;
  static const fromJsonFactory = _$LotBriefFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LotBrief &&
            (identical(other.basis, basis) ||
                const DeepCollectionEquality().equals(other.basis, basis)) &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.quantityT, quantityT) ||
                const DeepCollectionEquality().equals(
                  other.quantityT,
                  quantityT,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.variety, variety) ||
                const DeepCollectionEquality().equals(
                  other.variety,
                  variety,
                )) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(basis) ^
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(quantityT) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(variety) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $LotBriefExtension on LotBrief {
  LotBrief copyWith({
    String? basis,
    String? crop,
    String? district,
    String? id,
    double? quantityT,
    String? status,
    String? taluka,
    String? variety,
    String? village,
  }) {
    return LotBrief(
      basis: basis ?? this.basis,
      crop: crop ?? this.crop,
      district: district ?? this.district,
      id: id ?? this.id,
      quantityT: quantityT ?? this.quantityT,
      status: status ?? this.status,
      taluka: taluka ?? this.taluka,
      variety: variety ?? this.variety,
      village: village ?? this.village,
    );
  }

  LotBrief copyWithWrapped({
    Wrapped<String>? basis,
    Wrapped<String>? crop,
    Wrapped<String?>? district,
    Wrapped<String>? id,
    Wrapped<double>? quantityT,
    Wrapped<String>? status,
    Wrapped<String?>? taluka,
    Wrapped<String?>? variety,
    Wrapped<String?>? village,
  }) {
    return LotBrief(
      basis: (basis != null ? basis.value : this.basis),
      crop: (crop != null ? crop.value : this.crop),
      district: (district != null ? district.value : this.district),
      id: (id != null ? id.value : this.id),
      quantityT: (quantityT != null ? quantityT.value : this.quantityT),
      status: (status != null ? status.value : this.status),
      taluka: (taluka != null ? taluka.value : this.taluka),
      variety: (variety != null ? variety.value : this.variety),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LotInterestsResponse {
  const LotInterestsResponse({required this.interests});

  factory LotInterestsResponse.fromJson(Map<String, dynamic> json) =>
      _$LotInterestsResponseFromJson(json);

  static const toJsonFactory = _$LotInterestsResponseToJson;
  Map<String, dynamic> toJson() => _$LotInterestsResponseToJson(this);

  @JsonKey(
    name: 'interests',
    includeIfNull: false,
    defaultValue: <GrowerInterestOut>[],
  )
  final List<GrowerInterestOut> interests;
  static const fromJsonFactory = _$LotInterestsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LotInterestsResponse &&
            (identical(other.interests, interests) ||
                const DeepCollectionEquality().equals(
                  other.interests,
                  interests,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(interests) ^ runtimeType.hashCode;
}

extension $LotInterestsResponseExtension on LotInterestsResponse {
  LotInterestsResponse copyWith({List<GrowerInterestOut>? interests}) {
    return LotInterestsResponse(interests: interests ?? this.interests);
  }

  LotInterestsResponse copyWithWrapped({
    Wrapped<List<GrowerInterestOut>>? interests,
  }) {
    return LotInterestsResponse(
      interests: (interests != null ? interests.value : this.interests),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LotPhotoStored {
  const LotPhotoStored({required this.photoKey});

  factory LotPhotoStored.fromJson(Map<String, dynamic> json) =>
      _$LotPhotoStoredFromJson(json);

  static const toJsonFactory = _$LotPhotoStoredToJson;
  Map<String, dynamic> toJson() => _$LotPhotoStoredToJson(this);

  @JsonKey(name: 'photo_key', includeIfNull: false)
  final String photoKey;
  static const fromJsonFactory = _$LotPhotoStoredFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LotPhotoStored &&
            (identical(other.photoKey, photoKey) ||
                const DeepCollectionEquality().equals(
                  other.photoKey,
                  photoKey,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(photoKey) ^ runtimeType.hashCode;
}

extension $LotPhotoStoredExtension on LotPhotoStored {
  LotPhotoStored copyWith({String? photoKey}) {
    return LotPhotoStored(photoKey: photoKey ?? this.photoKey);
  }

  LotPhotoStored copyWithWrapped({Wrapped<String>? photoKey}) {
    return LotPhotoStored(
      photoKey: (photoKey != null ? photoKey.value : this.photoKey),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LotPhotoUrl {
  const LotPhotoUrl({required this.expiresIn, required this.url});

  factory LotPhotoUrl.fromJson(Map<String, dynamic> json) =>
      _$LotPhotoUrlFromJson(json);

  static const toJsonFactory = _$LotPhotoUrlToJson;
  Map<String, dynamic> toJson() => _$LotPhotoUrlToJson(this);

  @JsonKey(name: 'expires_in', includeIfNull: false)
  final int expiresIn;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  static const fromJsonFactory = _$LotPhotoUrlFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LotPhotoUrl &&
            (identical(other.expiresIn, expiresIn) ||
                const DeepCollectionEquality().equals(
                  other.expiresIn,
                  expiresIn,
                )) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(expiresIn) ^
      const DeepCollectionEquality().hash(url) ^
      runtimeType.hashCode;
}

extension $LotPhotoUrlExtension on LotPhotoUrl {
  LotPhotoUrl copyWith({int? expiresIn, String? url}) {
    return LotPhotoUrl(
      expiresIn: expiresIn ?? this.expiresIn,
      url: url ?? this.url,
    );
  }

  LotPhotoUrl copyWithWrapped({Wrapped<int>? expiresIn, Wrapped<String>? url}) {
    return LotPhotoUrl(
      expiresIn: (expiresIn != null ? expiresIn.value : this.expiresIn),
      url: (url != null ? url.value : this.url),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LotPhotoView {
  const LotPhotoView({required this.capturedAt, required this.id});

  factory LotPhotoView.fromJson(Map<String, dynamic> json) =>
      _$LotPhotoViewFromJson(json);

  static const toJsonFactory = _$LotPhotoViewToJson;
  Map<String, dynamic> toJson() => _$LotPhotoViewToJson(this);

  @JsonKey(name: 'captured_at', includeIfNull: false)
  final DateTime capturedAt;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  static const fromJsonFactory = _$LotPhotoViewFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LotPhotoView &&
            (identical(other.capturedAt, capturedAt) ||
                const DeepCollectionEquality().equals(
                  other.capturedAt,
                  capturedAt,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(capturedAt) ^
      const DeepCollectionEquality().hash(id) ^
      runtimeType.hashCode;
}

extension $LotPhotoViewExtension on LotPhotoView {
  LotPhotoView copyWith({DateTime? capturedAt, String? id}) {
    return LotPhotoView(
      capturedAt: capturedAt ?? this.capturedAt,
      id: id ?? this.id,
    );
  }

  LotPhotoView copyWithWrapped({
    Wrapped<DateTime>? capturedAt,
    Wrapped<String>? id,
  }) {
    return LotPhotoView(
      capturedAt: (capturedAt != null ? capturedAt.value : this.capturedAt),
      id: (id != null ? id.value : this.id),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ManualPriceIn {
  const ManualPriceIn({
    required this.commodity,
    required this.day,
    required this.district,
    this.grade,
    required this.market,
    this.maxRsPerQuintal,
    this.minRsPerQuintal,
    required this.modalRsPerQuintal,
    required this.state,
    this.variety,
  });

  factory ManualPriceIn.fromJson(Map<String, dynamic> json) =>
      _$ManualPriceInFromJson(json);

  static const toJsonFactory = _$ManualPriceInToJson;
  Map<String, dynamic> toJson() => _$ManualPriceInToJson(this);

  @JsonKey(name: 'commodity', includeIfNull: false)
  final String commodity;
  @JsonKey(name: 'day', includeIfNull: false, toJson: _dateToJson)
  final DateTime day;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'grade', includeIfNull: false)
  final String? grade;
  @JsonKey(name: 'market', includeIfNull: false)
  final String market;
  @JsonKey(name: 'max_rs_per_quintal', includeIfNull: false)
  final int? maxRsPerQuintal;
  @JsonKey(name: 'min_rs_per_quintal', includeIfNull: false)
  final int? minRsPerQuintal;
  @JsonKey(name: 'modal_rs_per_quintal', includeIfNull: false)
  final int modalRsPerQuintal;
  @JsonKey(name: 'state', includeIfNull: false)
  final String state;
  @JsonKey(name: 'variety', includeIfNull: false)
  final String? variety;
  static const fromJsonFactory = _$ManualPriceInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ManualPriceIn &&
            (identical(other.commodity, commodity) ||
                const DeepCollectionEquality().equals(
                  other.commodity,
                  commodity,
                )) &&
            (identical(other.day, day) ||
                const DeepCollectionEquality().equals(other.day, day)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.grade, grade) ||
                const DeepCollectionEquality().equals(other.grade, grade)) &&
            (identical(other.market, market) ||
                const DeepCollectionEquality().equals(other.market, market)) &&
            (identical(other.maxRsPerQuintal, maxRsPerQuintal) ||
                const DeepCollectionEquality().equals(
                  other.maxRsPerQuintal,
                  maxRsPerQuintal,
                )) &&
            (identical(other.minRsPerQuintal, minRsPerQuintal) ||
                const DeepCollectionEquality().equals(
                  other.minRsPerQuintal,
                  minRsPerQuintal,
                )) &&
            (identical(other.modalRsPerQuintal, modalRsPerQuintal) ||
                const DeepCollectionEquality().equals(
                  other.modalRsPerQuintal,
                  modalRsPerQuintal,
                )) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.variety, variety) ||
                const DeepCollectionEquality().equals(other.variety, variety)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(commodity) ^
      const DeepCollectionEquality().hash(day) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(grade) ^
      const DeepCollectionEquality().hash(market) ^
      const DeepCollectionEquality().hash(maxRsPerQuintal) ^
      const DeepCollectionEquality().hash(minRsPerQuintal) ^
      const DeepCollectionEquality().hash(modalRsPerQuintal) ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(variety) ^
      runtimeType.hashCode;
}

extension $ManualPriceInExtension on ManualPriceIn {
  ManualPriceIn copyWith({
    String? commodity,
    DateTime? day,
    String? district,
    String? grade,
    String? market,
    int? maxRsPerQuintal,
    int? minRsPerQuintal,
    int? modalRsPerQuintal,
    String? state,
    String? variety,
  }) {
    return ManualPriceIn(
      commodity: commodity ?? this.commodity,
      day: day ?? this.day,
      district: district ?? this.district,
      grade: grade ?? this.grade,
      market: market ?? this.market,
      maxRsPerQuintal: maxRsPerQuintal ?? this.maxRsPerQuintal,
      minRsPerQuintal: minRsPerQuintal ?? this.minRsPerQuintal,
      modalRsPerQuintal: modalRsPerQuintal ?? this.modalRsPerQuintal,
      state: state ?? this.state,
      variety: variety ?? this.variety,
    );
  }

  ManualPriceIn copyWithWrapped({
    Wrapped<String>? commodity,
    Wrapped<DateTime>? day,
    Wrapped<String>? district,
    Wrapped<String?>? grade,
    Wrapped<String>? market,
    Wrapped<int?>? maxRsPerQuintal,
    Wrapped<int?>? minRsPerQuintal,
    Wrapped<int>? modalRsPerQuintal,
    Wrapped<String>? state,
    Wrapped<String?>? variety,
  }) {
    return ManualPriceIn(
      commodity: (commodity != null ? commodity.value : this.commodity),
      day: (day != null ? day.value : this.day),
      district: (district != null ? district.value : this.district),
      grade: (grade != null ? grade.value : this.grade),
      market: (market != null ? market.value : this.market),
      maxRsPerQuintal: (maxRsPerQuintal != null
          ? maxRsPerQuintal.value
          : this.maxRsPerQuintal),
      minRsPerQuintal: (minRsPerQuintal != null
          ? minRsPerQuintal.value
          : this.minRsPerQuintal),
      modalRsPerQuintal: (modalRsPerQuintal != null
          ? modalRsPerQuintal.value
          : this.modalRsPerQuintal),
      state: (state != null ? state.value : this.state),
      variety: (variety != null ? variety.value : this.variety),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ManualPricesIn {
  const ManualPricesIn({required this.prices});

  factory ManualPricesIn.fromJson(Map<String, dynamic> json) =>
      _$ManualPricesInFromJson(json);

  static const toJsonFactory = _$ManualPricesInToJson;
  Map<String, dynamic> toJson() => _$ManualPricesInToJson(this);

  @JsonKey(
    name: 'prices',
    includeIfNull: false,
    defaultValue: <ManualPriceIn>[],
  )
  final List<ManualPriceIn> prices;
  static const fromJsonFactory = _$ManualPricesInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ManualPricesIn &&
            (identical(other.prices, prices) ||
                const DeepCollectionEquality().equals(other.prices, prices)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(prices) ^ runtimeType.hashCode;
}

extension $ManualPricesInExtension on ManualPricesIn {
  ManualPricesIn copyWith({List<ManualPriceIn>? prices}) {
    return ManualPricesIn(prices: prices ?? this.prices);
  }

  ManualPricesIn copyWithWrapped({Wrapped<List<ManualPriceIn>>? prices}) {
    return ManualPricesIn(
      prices: (prices != null ? prices.value : this.prices),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ManualPricesOut {
  const ManualPricesOut({required this.stored});

  factory ManualPricesOut.fromJson(Map<String, dynamic> json) =>
      _$ManualPricesOutFromJson(json);

  static const toJsonFactory = _$ManualPricesOutToJson;
  Map<String, dynamic> toJson() => _$ManualPricesOutToJson(this);

  @JsonKey(name: 'stored', includeIfNull: false)
  final int stored;
  static const fromJsonFactory = _$ManualPricesOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ManualPricesOut &&
            (identical(other.stored, stored) ||
                const DeepCollectionEquality().equals(other.stored, stored)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(stored) ^ runtimeType.hashCode;
}

extension $ManualPricesOutExtension on ManualPricesOut {
  ManualPricesOut copyWith({int? stored}) {
    return ManualPricesOut(stored: stored ?? this.stored);
  }

  ManualPricesOut copyWithWrapped({Wrapped<int>? stored}) {
    return ManualPricesOut(
      stored: (stored != null ? stored.value : this.stored),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class MarketPriceOut {
  const MarketPriceOut({
    required this.commodity,
    required this.day,
    required this.district,
    required this.grade,
    required this.isLocal,
    required this.isMajor,
    required this.market,
    required this.maxRsPerQuintal,
    required this.minRsPerQuintal,
    required this.modalRsPerQuintal,
    required this.source,
    required this.state,
    required this.variety,
  });

  factory MarketPriceOut.fromJson(Map<String, dynamic> json) =>
      _$MarketPriceOutFromJson(json);

  static const toJsonFactory = _$MarketPriceOutToJson;
  Map<String, dynamic> toJson() => _$MarketPriceOutToJson(this);

  @JsonKey(name: 'commodity', includeIfNull: false)
  final String commodity;
  @JsonKey(name: 'day', includeIfNull: false, toJson: _dateToJson)
  final DateTime day;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'grade', includeIfNull: false)
  final String? grade;
  @JsonKey(name: 'is_local', includeIfNull: false)
  final bool isLocal;
  @JsonKey(name: 'is_major', includeIfNull: false)
  final bool isMajor;
  @JsonKey(name: 'market', includeIfNull: false)
  final String market;
  @JsonKey(name: 'max_rs_per_quintal', includeIfNull: false)
  final int? maxRsPerQuintal;
  @JsonKey(name: 'min_rs_per_quintal', includeIfNull: false)
  final int? minRsPerQuintal;
  @JsonKey(name: 'modal_rs_per_quintal', includeIfNull: false)
  final int modalRsPerQuintal;
  @JsonKey(name: 'source', includeIfNull: false)
  final String source;
  @JsonKey(name: 'state', includeIfNull: false)
  final String state;
  @JsonKey(name: 'variety', includeIfNull: false)
  final String? variety;
  static const fromJsonFactory = _$MarketPriceOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MarketPriceOut &&
            (identical(other.commodity, commodity) ||
                const DeepCollectionEquality().equals(
                  other.commodity,
                  commodity,
                )) &&
            (identical(other.day, day) ||
                const DeepCollectionEquality().equals(other.day, day)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.grade, grade) ||
                const DeepCollectionEquality().equals(other.grade, grade)) &&
            (identical(other.isLocal, isLocal) ||
                const DeepCollectionEquality().equals(
                  other.isLocal,
                  isLocal,
                )) &&
            (identical(other.isMajor, isMajor) ||
                const DeepCollectionEquality().equals(
                  other.isMajor,
                  isMajor,
                )) &&
            (identical(other.market, market) ||
                const DeepCollectionEquality().equals(other.market, market)) &&
            (identical(other.maxRsPerQuintal, maxRsPerQuintal) ||
                const DeepCollectionEquality().equals(
                  other.maxRsPerQuintal,
                  maxRsPerQuintal,
                )) &&
            (identical(other.minRsPerQuintal, minRsPerQuintal) ||
                const DeepCollectionEquality().equals(
                  other.minRsPerQuintal,
                  minRsPerQuintal,
                )) &&
            (identical(other.modalRsPerQuintal, modalRsPerQuintal) ||
                const DeepCollectionEquality().equals(
                  other.modalRsPerQuintal,
                  modalRsPerQuintal,
                )) &&
            (identical(other.source, source) ||
                const DeepCollectionEquality().equals(other.source, source)) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.variety, variety) ||
                const DeepCollectionEquality().equals(other.variety, variety)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(commodity) ^
      const DeepCollectionEquality().hash(day) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(grade) ^
      const DeepCollectionEquality().hash(isLocal) ^
      const DeepCollectionEquality().hash(isMajor) ^
      const DeepCollectionEquality().hash(market) ^
      const DeepCollectionEquality().hash(maxRsPerQuintal) ^
      const DeepCollectionEquality().hash(minRsPerQuintal) ^
      const DeepCollectionEquality().hash(modalRsPerQuintal) ^
      const DeepCollectionEquality().hash(source) ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(variety) ^
      runtimeType.hashCode;
}

extension $MarketPriceOutExtension on MarketPriceOut {
  MarketPriceOut copyWith({
    String? commodity,
    DateTime? day,
    String? district,
    String? grade,
    bool? isLocal,
    bool? isMajor,
    String? market,
    int? maxRsPerQuintal,
    int? minRsPerQuintal,
    int? modalRsPerQuintal,
    String? source,
    String? state,
    String? variety,
  }) {
    return MarketPriceOut(
      commodity: commodity ?? this.commodity,
      day: day ?? this.day,
      district: district ?? this.district,
      grade: grade ?? this.grade,
      isLocal: isLocal ?? this.isLocal,
      isMajor: isMajor ?? this.isMajor,
      market: market ?? this.market,
      maxRsPerQuintal: maxRsPerQuintal ?? this.maxRsPerQuintal,
      minRsPerQuintal: minRsPerQuintal ?? this.minRsPerQuintal,
      modalRsPerQuintal: modalRsPerQuintal ?? this.modalRsPerQuintal,
      source: source ?? this.source,
      state: state ?? this.state,
      variety: variety ?? this.variety,
    );
  }

  MarketPriceOut copyWithWrapped({
    Wrapped<String>? commodity,
    Wrapped<DateTime>? day,
    Wrapped<String>? district,
    Wrapped<String?>? grade,
    Wrapped<bool>? isLocal,
    Wrapped<bool>? isMajor,
    Wrapped<String>? market,
    Wrapped<int?>? maxRsPerQuintal,
    Wrapped<int?>? minRsPerQuintal,
    Wrapped<int>? modalRsPerQuintal,
    Wrapped<String>? source,
    Wrapped<String>? state,
    Wrapped<String?>? variety,
  }) {
    return MarketPriceOut(
      commodity: (commodity != null ? commodity.value : this.commodity),
      day: (day != null ? day.value : this.day),
      district: (district != null ? district.value : this.district),
      grade: (grade != null ? grade.value : this.grade),
      isLocal: (isLocal != null ? isLocal.value : this.isLocal),
      isMajor: (isMajor != null ? isMajor.value : this.isMajor),
      market: (market != null ? market.value : this.market),
      maxRsPerQuintal: (maxRsPerQuintal != null
          ? maxRsPerQuintal.value
          : this.maxRsPerQuintal),
      minRsPerQuintal: (minRsPerQuintal != null
          ? minRsPerQuintal.value
          : this.minRsPerQuintal),
      modalRsPerQuintal: (modalRsPerQuintal != null
          ? modalRsPerQuintal.value
          : this.modalRsPerQuintal),
      source: (source != null ? source.value : this.source),
      state: (state != null ? state.value : this.state),
      variety: (variety != null ? variety.value : this.variety),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class MarketPrices {
  const MarketPrices({required this.prices, this.reason, required this.stale});

  factory MarketPrices.fromJson(Map<String, dynamic> json) =>
      _$MarketPricesFromJson(json);

  static const toJsonFactory = _$MarketPricesToJson;
  Map<String, dynamic> toJson() => _$MarketPricesToJson(this);

  @JsonKey(
    name: 'prices',
    includeIfNull: false,
    defaultValue: <MarketPriceOut>[],
  )
  final List<MarketPriceOut> prices;
  @JsonKey(name: 'reason', includeIfNull: false)
  final String? reason;
  @JsonKey(name: 'stale', includeIfNull: false)
  final bool stale;
  static const fromJsonFactory = _$MarketPricesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MarketPrices &&
            (identical(other.prices, prices) ||
                const DeepCollectionEquality().equals(other.prices, prices)) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.stale, stale) ||
                const DeepCollectionEquality().equals(other.stale, stale)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(prices) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(stale) ^
      runtimeType.hashCode;
}

extension $MarketPricesExtension on MarketPrices {
  MarketPrices copyWith({
    List<MarketPriceOut>? prices,
    String? reason,
    bool? stale,
  }) {
    return MarketPrices(
      prices: prices ?? this.prices,
      reason: reason ?? this.reason,
      stale: stale ?? this.stale,
    );
  }

  MarketPrices copyWithWrapped({
    Wrapped<List<MarketPriceOut>>? prices,
    Wrapped<String?>? reason,
    Wrapped<bool>? stale,
  }) {
    return MarketPrices(
      prices: (prices != null ? prices.value : this.prices),
      reason: (reason != null ? reason.value : this.reason),
      stale: (stale != null ? stale.value : this.stale),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Mutation {
  const Mutation({
    required this.clientMutationId,
    required this.clientUpdatedAt,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
  });

  factory Mutation.fromJson(Map<String, dynamic> json) =>
      _$MutationFromJson(json);

  static const toJsonFactory = _$MutationToJson;
  Map<String, dynamic> toJson() => _$MutationToJson(this);

  @JsonKey(name: 'client_mutation_id', includeIfNull: false)
  final String clientMutationId;
  @JsonKey(name: 'client_updated_at', includeIfNull: false)
  final DateTime clientUpdatedAt;
  @JsonKey(name: 'entity', includeIfNull: false)
  final String entity;
  @JsonKey(name: 'entity_id', includeIfNull: false)
  final String entityId;
  @JsonKey(
    name: 'op',
    includeIfNull: false,
    toJson: mutationOpToJson,
    fromJson: mutationOpFromJson,
  )
  final enums.MutationOp op;
  @JsonKey(name: 'payload', includeIfNull: false)
  final Map<String, dynamic> payload;
  static const fromJsonFactory = _$MutationFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Mutation &&
            (identical(other.clientMutationId, clientMutationId) ||
                const DeepCollectionEquality().equals(
                  other.clientMutationId,
                  clientMutationId,
                )) &&
            (identical(other.clientUpdatedAt, clientUpdatedAt) ||
                const DeepCollectionEquality().equals(
                  other.clientUpdatedAt,
                  clientUpdatedAt,
                )) &&
            (identical(other.entity, entity) ||
                const DeepCollectionEquality().equals(other.entity, entity)) &&
            (identical(other.entityId, entityId) ||
                const DeepCollectionEquality().equals(
                  other.entityId,
                  entityId,
                )) &&
            (identical(other.op, op) ||
                const DeepCollectionEquality().equals(other.op, op)) &&
            (identical(other.payload, payload) ||
                const DeepCollectionEquality().equals(other.payload, payload)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(clientMutationId) ^
      const DeepCollectionEquality().hash(clientUpdatedAt) ^
      const DeepCollectionEquality().hash(entity) ^
      const DeepCollectionEquality().hash(entityId) ^
      const DeepCollectionEquality().hash(op) ^
      const DeepCollectionEquality().hash(payload) ^
      runtimeType.hashCode;
}

extension $MutationExtension on Mutation {
  Mutation copyWith({
    String? clientMutationId,
    DateTime? clientUpdatedAt,
    String? entity,
    String? entityId,
    enums.MutationOp? op,
    Map<String, dynamic>? payload,
  }) {
    return Mutation(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
    );
  }

  Mutation copyWithWrapped({
    Wrapped<String>? clientMutationId,
    Wrapped<DateTime>? clientUpdatedAt,
    Wrapped<String>? entity,
    Wrapped<String>? entityId,
    Wrapped<enums.MutationOp>? op,
    Wrapped<Map<String, dynamic>>? payload,
  }) {
    return Mutation(
      clientMutationId: (clientMutationId != null
          ? clientMutationId.value
          : this.clientMutationId),
      clientUpdatedAt: (clientUpdatedAt != null
          ? clientUpdatedAt.value
          : this.clientUpdatedAt),
      entity: (entity != null ? entity.value : this.entity),
      entityId: (entityId != null ? entityId.value : this.entityId),
      op: (op != null ? op.value : this.op),
      payload: (payload != null ? payload.value : this.payload),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class MutationResult {
  const MutationResult({
    required this.clientMutationId,
    this.error,
    required this.status,
  });

  factory MutationResult.fromJson(Map<String, dynamic> json) =>
      _$MutationResultFromJson(json);

  static const toJsonFactory = _$MutationResultToJson;
  Map<String, dynamic> toJson() => _$MutationResultToJson(this);

  @JsonKey(name: 'client_mutation_id', includeIfNull: false)
  final String clientMutationId;
  @JsonKey(name: 'error', includeIfNull: false)
  final String? error;
  @JsonKey(
    name: 'status',
    includeIfNull: false,
    toJson: mutationResultStatusToJson,
    fromJson: mutationResultStatusFromJson,
  )
  final enums.MutationResultStatus status;
  static const fromJsonFactory = _$MutationResultFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MutationResult &&
            (identical(other.clientMutationId, clientMutationId) ||
                const DeepCollectionEquality().equals(
                  other.clientMutationId,
                  clientMutationId,
                )) &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(clientMutationId) ^
      const DeepCollectionEquality().hash(error) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $MutationResultExtension on MutationResult {
  MutationResult copyWith({
    String? clientMutationId,
    String? error,
    enums.MutationResultStatus? status,
  }) {
    return MutationResult(
      clientMutationId: clientMutationId ?? this.clientMutationId,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }

  MutationResult copyWithWrapped({
    Wrapped<String>? clientMutationId,
    Wrapped<String?>? error,
    Wrapped<enums.MutationResultStatus>? status,
  }) {
    return MutationResult(
      clientMutationId: (clientMutationId != null
          ? clientMutationId.value
          : this.clientMutationId),
      error: (error != null ? error.value : this.error),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class MyAcceptancesOut {
  const MyAcceptancesOut({required this.acceptances, required this.roles});

  factory MyAcceptancesOut.fromJson(Map<String, dynamic> json) =>
      _$MyAcceptancesOutFromJson(json);

  static const toJsonFactory = _$MyAcceptancesOutToJson;
  Map<String, dynamic> toJson() => _$MyAcceptancesOutToJson(this);

  @JsonKey(
    name: 'acceptances',
    includeIfNull: false,
    defaultValue: <AcceptanceOut>[],
  )
  final List<AcceptanceOut> acceptances;
  @JsonKey(name: 'roles', includeIfNull: false, defaultValue: <String>[])
  final List<String> roles;
  static const fromJsonFactory = _$MyAcceptancesOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MyAcceptancesOut &&
            (identical(other.acceptances, acceptances) ||
                const DeepCollectionEquality().equals(
                  other.acceptances,
                  acceptances,
                )) &&
            (identical(other.roles, roles) ||
                const DeepCollectionEquality().equals(other.roles, roles)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(acceptances) ^
      const DeepCollectionEquality().hash(roles) ^
      runtimeType.hashCode;
}

extension $MyAcceptancesOutExtension on MyAcceptancesOut {
  MyAcceptancesOut copyWith({
    List<AcceptanceOut>? acceptances,
    List<String>? roles,
  }) {
    return MyAcceptancesOut(
      acceptances: acceptances ?? this.acceptances,
      roles: roles ?? this.roles,
    );
  }

  MyAcceptancesOut copyWithWrapped({
    Wrapped<List<AcceptanceOut>>? acceptances,
    Wrapped<List<String>>? roles,
  }) {
    return MyAcceptancesOut(
      acceptances: (acceptances != null ? acceptances.value : this.acceptances),
      roles: (roles != null ? roles.value : this.roles),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class MyProfileOut {
  const MyProfileOut({
    required this.address,
    required this.areas,
    required this.badges,
    required this.crops,
    required this.district,
    required this.documents,
    required this.firm,
    required this.fix,
    required this.flags,
    required this.hasCertificatePhoto,
    required this.id,
    required this.kind,
    required this.markets,
    required this.name,
    required this.numbers,
    required this.phone,
    this.provider,
    required this.reason,
    required this.status,
    required this.subjectType,
    required this.taluka,
    required this.village,
  });

  factory MyProfileOut.fromJson(Map<String, dynamic> json) =>
      _$MyProfileOutFromJson(json);

  static const toJsonFactory = _$MyProfileOutToJson;
  Map<String, dynamic> toJson() => _$MyProfileOutToJson(this);

  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'areas', includeIfNull: false, defaultValue: <String>[])
  final List<String> areas;
  @JsonKey(name: 'badges', includeIfNull: false, defaultValue: <BadgeOut>[])
  final List<BadgeOut> badges;
  @JsonKey(name: 'crops', includeIfNull: false, defaultValue: <String>[])
  final List<String> crops;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'documents', includeIfNull: false)
  final int documents;
  @JsonKey(name: 'firm', includeIfNull: false)
  final String? firm;
  @JsonKey(name: 'fix', includeIfNull: false)
  final AdminFixOut? fix;
  @JsonKey(name: 'flags', includeIfNull: false, defaultValue: <String>[])
  final List<String> flags;
  @JsonKey(name: 'has_certificate_photo', includeIfNull: false)
  final bool hasCertificatePhoto;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  @JsonKey(name: 'markets', includeIfNull: false, defaultValue: <String>[])
  final List<String> markets;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'numbers', includeIfNull: false)
  final NumbersOut? numbers;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String phone;
  @JsonKey(name: 'provider', includeIfNull: false)
  final ProviderDetailsOut? provider;
  @JsonKey(name: 'reason', includeIfNull: false)
  final String? reason;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'subject_type', includeIfNull: false)
  final String subjectType;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'village', includeIfNull: false)
  final String? village;
  static const fromJsonFactory = _$MyProfileOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MyProfileOut &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.areas, areas) ||
                const DeepCollectionEquality().equals(other.areas, areas)) &&
            (identical(other.badges, badges) ||
                const DeepCollectionEquality().equals(other.badges, badges)) &&
            (identical(other.crops, crops) ||
                const DeepCollectionEquality().equals(other.crops, crops)) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.documents, documents) ||
                const DeepCollectionEquality().equals(
                  other.documents,
                  documents,
                )) &&
            (identical(other.firm, firm) ||
                const DeepCollectionEquality().equals(other.firm, firm)) &&
            (identical(other.fix, fix) ||
                const DeepCollectionEquality().equals(other.fix, fix)) &&
            (identical(other.flags, flags) ||
                const DeepCollectionEquality().equals(other.flags, flags)) &&
            (identical(other.hasCertificatePhoto, hasCertificatePhoto) ||
                const DeepCollectionEquality().equals(
                  other.hasCertificatePhoto,
                  hasCertificatePhoto,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.markets, markets) ||
                const DeepCollectionEquality().equals(
                  other.markets,
                  markets,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.numbers, numbers) ||
                const DeepCollectionEquality().equals(
                  other.numbers,
                  numbers,
                )) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.provider, provider) ||
                const DeepCollectionEquality().equals(
                  other.provider,
                  provider,
                )) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.subjectType, subjectType) ||
                const DeepCollectionEquality().equals(
                  other.subjectType,
                  subjectType,
                )) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(areas) ^
      const DeepCollectionEquality().hash(badges) ^
      const DeepCollectionEquality().hash(crops) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(documents) ^
      const DeepCollectionEquality().hash(firm) ^
      const DeepCollectionEquality().hash(fix) ^
      const DeepCollectionEquality().hash(flags) ^
      const DeepCollectionEquality().hash(hasCertificatePhoto) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(markets) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(numbers) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(provider) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(subjectType) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $MyProfileOutExtension on MyProfileOut {
  MyProfileOut copyWith({
    String? address,
    List<String>? areas,
    List<BadgeOut>? badges,
    List<String>? crops,
    String? district,
    int? documents,
    String? firm,
    AdminFixOut? fix,
    List<String>? flags,
    bool? hasCertificatePhoto,
    String? id,
    String? kind,
    List<String>? markets,
    String? name,
    NumbersOut? numbers,
    String? phone,
    ProviderDetailsOut? provider,
    String? reason,
    String? status,
    String? subjectType,
    String? taluka,
    String? village,
  }) {
    return MyProfileOut(
      address: address ?? this.address,
      areas: areas ?? this.areas,
      badges: badges ?? this.badges,
      crops: crops ?? this.crops,
      district: district ?? this.district,
      documents: documents ?? this.documents,
      firm: firm ?? this.firm,
      fix: fix ?? this.fix,
      flags: flags ?? this.flags,
      hasCertificatePhoto: hasCertificatePhoto ?? this.hasCertificatePhoto,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      markets: markets ?? this.markets,
      name: name ?? this.name,
      numbers: numbers ?? this.numbers,
      phone: phone ?? this.phone,
      provider: provider ?? this.provider,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      subjectType: subjectType ?? this.subjectType,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
    );
  }

  MyProfileOut copyWithWrapped({
    Wrapped<String?>? address,
    Wrapped<List<String>>? areas,
    Wrapped<List<BadgeOut>>? badges,
    Wrapped<List<String>>? crops,
    Wrapped<String>? district,
    Wrapped<int>? documents,
    Wrapped<String?>? firm,
    Wrapped<AdminFixOut?>? fix,
    Wrapped<List<String>>? flags,
    Wrapped<bool>? hasCertificatePhoto,
    Wrapped<String>? id,
    Wrapped<String>? kind,
    Wrapped<List<String>>? markets,
    Wrapped<String>? name,
    Wrapped<NumbersOut?>? numbers,
    Wrapped<String>? phone,
    Wrapped<ProviderDetailsOut?>? provider,
    Wrapped<String?>? reason,
    Wrapped<String>? status,
    Wrapped<String>? subjectType,
    Wrapped<String?>? taluka,
    Wrapped<String?>? village,
  }) {
    return MyProfileOut(
      address: (address != null ? address.value : this.address),
      areas: (areas != null ? areas.value : this.areas),
      badges: (badges != null ? badges.value : this.badges),
      crops: (crops != null ? crops.value : this.crops),
      district: (district != null ? district.value : this.district),
      documents: (documents != null ? documents.value : this.documents),
      firm: (firm != null ? firm.value : this.firm),
      fix: (fix != null ? fix.value : this.fix),
      flags: (flags != null ? flags.value : this.flags),
      hasCertificatePhoto: (hasCertificatePhoto != null
          ? hasCertificatePhoto.value
          : this.hasCertificatePhoto),
      id: (id != null ? id.value : this.id),
      kind: (kind != null ? kind.value : this.kind),
      markets: (markets != null ? markets.value : this.markets),
      name: (name != null ? name.value : this.name),
      numbers: (numbers != null ? numbers.value : this.numbers),
      phone: (phone != null ? phone.value : this.phone),
      provider: (provider != null ? provider.value : this.provider),
      reason: (reason != null ? reason.value : this.reason),
      status: (status != null ? status.value : this.status),
      subjectType: (subjectType != null ? subjectType.value : this.subjectType),
      taluka: (taluka != null ? taluka.value : this.taluka),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class MyProfilesResponse {
  const MyProfilesResponse({required this.profiles});

  factory MyProfilesResponse.fromJson(Map<String, dynamic> json) =>
      _$MyProfilesResponseFromJson(json);

  static const toJsonFactory = _$MyProfilesResponseToJson;
  Map<String, dynamic> toJson() => _$MyProfilesResponseToJson(this);

  @JsonKey(
    name: 'profiles',
    includeIfNull: false,
    defaultValue: <MyProfileOut>[],
  )
  final List<MyProfileOut> profiles;
  static const fromJsonFactory = _$MyProfilesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MyProfilesResponse &&
            (identical(other.profiles, profiles) ||
                const DeepCollectionEquality().equals(
                  other.profiles,
                  profiles,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(profiles) ^ runtimeType.hashCode;
}

extension $MyProfilesResponseExtension on MyProfilesResponse {
  MyProfilesResponse copyWith({List<MyProfileOut>? profiles}) {
    return MyProfilesResponse(profiles: profiles ?? this.profiles);
  }

  MyProfilesResponse copyWithWrapped({Wrapped<List<MyProfileOut>>? profiles}) {
    return MyProfilesResponse(
      profiles: (profiles != null ? profiles.value : this.profiles),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class NumbersOut {
  const NumbersOut({
    required this.apedaNo,
    required this.apmcLicenceNo,
    required this.fssaiNo,
    required this.gstNo,
    required this.iecNo,
  });

  factory NumbersOut.fromJson(Map<String, dynamic> json) =>
      _$NumbersOutFromJson(json);

  static const toJsonFactory = _$NumbersOutToJson;
  Map<String, dynamic> toJson() => _$NumbersOutToJson(this);

  @JsonKey(name: 'apeda_no', includeIfNull: false)
  final String? apedaNo;
  @JsonKey(name: 'apmc_licence_no', includeIfNull: false)
  final String? apmcLicenceNo;
  @JsonKey(name: 'fssai_no', includeIfNull: false)
  final String? fssaiNo;
  @JsonKey(name: 'gst_no', includeIfNull: false)
  final String? gstNo;
  @JsonKey(name: 'iec_no', includeIfNull: false)
  final String? iecNo;
  static const fromJsonFactory = _$NumbersOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NumbersOut &&
            (identical(other.apedaNo, apedaNo) ||
                const DeepCollectionEquality().equals(
                  other.apedaNo,
                  apedaNo,
                )) &&
            (identical(other.apmcLicenceNo, apmcLicenceNo) ||
                const DeepCollectionEquality().equals(
                  other.apmcLicenceNo,
                  apmcLicenceNo,
                )) &&
            (identical(other.fssaiNo, fssaiNo) ||
                const DeepCollectionEquality().equals(
                  other.fssaiNo,
                  fssaiNo,
                )) &&
            (identical(other.gstNo, gstNo) ||
                const DeepCollectionEquality().equals(other.gstNo, gstNo)) &&
            (identical(other.iecNo, iecNo) ||
                const DeepCollectionEquality().equals(other.iecNo, iecNo)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(apedaNo) ^
      const DeepCollectionEquality().hash(apmcLicenceNo) ^
      const DeepCollectionEquality().hash(fssaiNo) ^
      const DeepCollectionEquality().hash(gstNo) ^
      const DeepCollectionEquality().hash(iecNo) ^
      runtimeType.hashCode;
}

extension $NumbersOutExtension on NumbersOut {
  NumbersOut copyWith({
    String? apedaNo,
    String? apmcLicenceNo,
    String? fssaiNo,
    String? gstNo,
    String? iecNo,
  }) {
    return NumbersOut(
      apedaNo: apedaNo ?? this.apedaNo,
      apmcLicenceNo: apmcLicenceNo ?? this.apmcLicenceNo,
      fssaiNo: fssaiNo ?? this.fssaiNo,
      gstNo: gstNo ?? this.gstNo,
      iecNo: iecNo ?? this.iecNo,
    );
  }

  NumbersOut copyWithWrapped({
    Wrapped<String?>? apedaNo,
    Wrapped<String?>? apmcLicenceNo,
    Wrapped<String?>? fssaiNo,
    Wrapped<String?>? gstNo,
    Wrapped<String?>? iecNo,
  }) {
    return NumbersOut(
      apedaNo: (apedaNo != null ? apedaNo.value : this.apedaNo),
      apmcLicenceNo: (apmcLicenceNo != null
          ? apmcLicenceNo.value
          : this.apmcLicenceNo),
      fssaiNo: (fssaiNo != null ? fssaiNo.value : this.fssaiNo),
      gstNo: (gstNo != null ? gstNo.value : this.gstNo),
      iecNo: (iecNo != null ? iecNo.value : this.iecNo),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PhotoDownloadUrl {
  const PhotoDownloadUrl({
    required this.expiresIn,
    required this.photoKey,
    required this.url,
  });

  factory PhotoDownloadUrl.fromJson(Map<String, dynamic> json) =>
      _$PhotoDownloadUrlFromJson(json);

  static const toJsonFactory = _$PhotoDownloadUrlToJson;
  Map<String, dynamic> toJson() => _$PhotoDownloadUrlToJson(this);

  @JsonKey(name: 'expires_in', includeIfNull: false)
  final int expiresIn;
  @JsonKey(name: 'photo_key', includeIfNull: false)
  final String photoKey;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  static const fromJsonFactory = _$PhotoDownloadUrlFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PhotoDownloadUrl &&
            (identical(other.expiresIn, expiresIn) ||
                const DeepCollectionEquality().equals(
                  other.expiresIn,
                  expiresIn,
                )) &&
            (identical(other.photoKey, photoKey) ||
                const DeepCollectionEquality().equals(
                  other.photoKey,
                  photoKey,
                )) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(expiresIn) ^
      const DeepCollectionEquality().hash(photoKey) ^
      const DeepCollectionEquality().hash(url) ^
      runtimeType.hashCode;
}

extension $PhotoDownloadUrlExtension on PhotoDownloadUrl {
  PhotoDownloadUrl copyWith({int? expiresIn, String? photoKey, String? url}) {
    return PhotoDownloadUrl(
      expiresIn: expiresIn ?? this.expiresIn,
      photoKey: photoKey ?? this.photoKey,
      url: url ?? this.url,
    );
  }

  PhotoDownloadUrl copyWithWrapped({
    Wrapped<int>? expiresIn,
    Wrapped<String>? photoKey,
    Wrapped<String>? url,
  }) {
    return PhotoDownloadUrl(
      expiresIn: (expiresIn != null ? expiresIn.value : this.expiresIn),
      photoKey: (photoKey != null ? photoKey.value : this.photoKey),
      url: (url != null ? url.value : this.url),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PhotoUploadIn {
  const PhotoUploadIn({this.contentType, required this.sizeBytes});

  factory PhotoUploadIn.fromJson(Map<String, dynamic> json) =>
      _$PhotoUploadInFromJson(json);

  static const toJsonFactory = _$PhotoUploadInToJson;
  Map<String, dynamic> toJson() => _$PhotoUploadInToJson(this);

  @JsonKey(name: 'content_type', includeIfNull: false)
  final String? contentType;
  @JsonKey(name: 'size_bytes', includeIfNull: false)
  final int sizeBytes;
  static const fromJsonFactory = _$PhotoUploadInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PhotoUploadIn &&
            (identical(other.contentType, contentType) ||
                const DeepCollectionEquality().equals(
                  other.contentType,
                  contentType,
                )) &&
            (identical(other.sizeBytes, sizeBytes) ||
                const DeepCollectionEquality().equals(
                  other.sizeBytes,
                  sizeBytes,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(contentType) ^
      const DeepCollectionEquality().hash(sizeBytes) ^
      runtimeType.hashCode;
}

extension $PhotoUploadInExtension on PhotoUploadIn {
  PhotoUploadIn copyWith({String? contentType, int? sizeBytes}) {
    return PhotoUploadIn(
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }

  PhotoUploadIn copyWithWrapped({
    Wrapped<String?>? contentType,
    Wrapped<int>? sizeBytes,
  }) {
    return PhotoUploadIn(
      contentType: (contentType != null ? contentType.value : this.contentType),
      sizeBytes: (sizeBytes != null ? sizeBytes.value : this.sizeBytes),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PhotoUploadUrl {
  const PhotoUploadUrl({
    this.contentType,
    required this.expiresIn,
    required this.maxBytes,
    required this.photoKey,
    required this.uploadUrl,
  });

  factory PhotoUploadUrl.fromJson(Map<String, dynamic> json) =>
      _$PhotoUploadUrlFromJson(json);

  static const toJsonFactory = _$PhotoUploadUrlToJson;
  Map<String, dynamic> toJson() => _$PhotoUploadUrlToJson(this);

  @JsonKey(name: 'content_type', includeIfNull: false)
  final String? contentType;
  @JsonKey(name: 'expires_in', includeIfNull: false)
  final int expiresIn;
  @JsonKey(name: 'max_bytes', includeIfNull: false)
  final int maxBytes;
  @JsonKey(name: 'photo_key', includeIfNull: false)
  final String photoKey;
  @JsonKey(name: 'upload_url', includeIfNull: false)
  final String uploadUrl;
  static const fromJsonFactory = _$PhotoUploadUrlFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PhotoUploadUrl &&
            (identical(other.contentType, contentType) ||
                const DeepCollectionEquality().equals(
                  other.contentType,
                  contentType,
                )) &&
            (identical(other.expiresIn, expiresIn) ||
                const DeepCollectionEquality().equals(
                  other.expiresIn,
                  expiresIn,
                )) &&
            (identical(other.maxBytes, maxBytes) ||
                const DeepCollectionEquality().equals(
                  other.maxBytes,
                  maxBytes,
                )) &&
            (identical(other.photoKey, photoKey) ||
                const DeepCollectionEquality().equals(
                  other.photoKey,
                  photoKey,
                )) &&
            (identical(other.uploadUrl, uploadUrl) ||
                const DeepCollectionEquality().equals(
                  other.uploadUrl,
                  uploadUrl,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(contentType) ^
      const DeepCollectionEquality().hash(expiresIn) ^
      const DeepCollectionEquality().hash(maxBytes) ^
      const DeepCollectionEquality().hash(photoKey) ^
      const DeepCollectionEquality().hash(uploadUrl) ^
      runtimeType.hashCode;
}

extension $PhotoUploadUrlExtension on PhotoUploadUrl {
  PhotoUploadUrl copyWith({
    String? contentType,
    int? expiresIn,
    int? maxBytes,
    String? photoKey,
    String? uploadUrl,
  }) {
    return PhotoUploadUrl(
      contentType: contentType ?? this.contentType,
      expiresIn: expiresIn ?? this.expiresIn,
      maxBytes: maxBytes ?? this.maxBytes,
      photoKey: photoKey ?? this.photoKey,
      uploadUrl: uploadUrl ?? this.uploadUrl,
    );
  }

  PhotoUploadUrl copyWithWrapped({
    Wrapped<String?>? contentType,
    Wrapped<int>? expiresIn,
    Wrapped<int>? maxBytes,
    Wrapped<String>? photoKey,
    Wrapped<String>? uploadUrl,
  }) {
    return PhotoUploadUrl(
      contentType: (contentType != null ? contentType.value : this.contentType),
      expiresIn: (expiresIn != null ? expiresIn.value : this.expiresIn),
      maxBytes: (maxBytes != null ? maxBytes.value : this.maxBytes),
      photoKey: (photoKey != null ? photoKey.value : this.photoKey),
      uploadUrl: (uploadUrl != null ? uploadUrl.value : this.uploadUrl),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PlanIn {
  const PlanIn({
    this.active,
    required this.features,
    required this.kind,
    required this.names,
    this.sortOrder,
  });

  factory PlanIn.fromJson(Map<String, dynamic> json) => _$PlanInFromJson(json);

  static const toJsonFactory = _$PlanInToJson;
  Map<String, dynamic> toJson() => _$PlanInToJson(this);

  @JsonKey(name: 'active', includeIfNull: false, defaultValue: true)
  final bool? active;
  @JsonKey(name: 'features', includeIfNull: false)
  final Object features;
  @JsonKey(
    name: 'kind',
    includeIfNull: false,
    toJson: planInKindToJson,
    fromJson: planInKindFromJson,
  )
  final enums.PlanInKind kind;
  @JsonKey(name: 'names', includeIfNull: false)
  final Map<String, dynamic> names;
  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int? sortOrder;
  static const fromJsonFactory = _$PlanInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlanIn &&
            (identical(other.active, active) ||
                const DeepCollectionEquality().equals(other.active, active)) &&
            (identical(other.features, features) ||
                const DeepCollectionEquality().equals(
                  other.features,
                  features,
                )) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.names, names) ||
                const DeepCollectionEquality().equals(other.names, names)) &&
            (identical(other.sortOrder, sortOrder) ||
                const DeepCollectionEquality().equals(
                  other.sortOrder,
                  sortOrder,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(active) ^
      const DeepCollectionEquality().hash(features) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(names) ^
      const DeepCollectionEquality().hash(sortOrder) ^
      runtimeType.hashCode;
}

extension $PlanInExtension on PlanIn {
  PlanIn copyWith({
    bool? active,
    Object? features,
    enums.PlanInKind? kind,
    Map<String, dynamic>? names,
    int? sortOrder,
  }) {
    return PlanIn(
      active: active ?? this.active,
      features: features ?? this.features,
      kind: kind ?? this.kind,
      names: names ?? this.names,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  PlanIn copyWithWrapped({
    Wrapped<bool?>? active,
    Wrapped<Object>? features,
    Wrapped<enums.PlanInKind>? kind,
    Wrapped<Map<String, dynamic>>? names,
    Wrapped<int?>? sortOrder,
  }) {
    return PlanIn(
      active: (active != null ? active.value : this.active),
      features: (features != null ? features.value : this.features),
      kind: (kind != null ? kind.value : this.kind),
      names: (names != null ? names.value : this.names),
      sortOrder: (sortOrder != null ? sortOrder.value : this.sortOrder),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PlanOut {
  const PlanOut({
    required this.active,
    required this.features,
    required this.key,
    required this.kind,
    required this.names,
    required this.sortOrder,
  });

  factory PlanOut.fromJson(Map<String, dynamic> json) =>
      _$PlanOutFromJson(json);

  static const toJsonFactory = _$PlanOutToJson;
  Map<String, dynamic> toJson() => _$PlanOutToJson(this);

  @JsonKey(name: 'active', includeIfNull: false)
  final bool active;
  @JsonKey(
    name: 'features',
    includeIfNull: false,
    defaultValue: <FeatureConfig>[],
  )
  final List<FeatureConfig> features;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  @JsonKey(name: 'names', includeIfNull: false)
  final Map<String, dynamic> names;
  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int sortOrder;
  static const fromJsonFactory = _$PlanOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlanOut &&
            (identical(other.active, active) ||
                const DeepCollectionEquality().equals(other.active, active)) &&
            (identical(other.features, features) ||
                const DeepCollectionEquality().equals(
                  other.features,
                  features,
                )) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.names, names) ||
                const DeepCollectionEquality().equals(other.names, names)) &&
            (identical(other.sortOrder, sortOrder) ||
                const DeepCollectionEquality().equals(
                  other.sortOrder,
                  sortOrder,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(active) ^
      const DeepCollectionEquality().hash(features) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(names) ^
      const DeepCollectionEquality().hash(sortOrder) ^
      runtimeType.hashCode;
}

extension $PlanOutExtension on PlanOut {
  PlanOut copyWith({
    bool? active,
    List<FeatureConfig>? features,
    String? key,
    String? kind,
    Map<String, dynamic>? names,
    int? sortOrder,
  }) {
    return PlanOut(
      active: active ?? this.active,
      features: features ?? this.features,
      key: key ?? this.key,
      kind: kind ?? this.kind,
      names: names ?? this.names,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  PlanOut copyWithWrapped({
    Wrapped<bool>? active,
    Wrapped<List<FeatureConfig>>? features,
    Wrapped<String>? key,
    Wrapped<String>? kind,
    Wrapped<Map<String, dynamic>>? names,
    Wrapped<int>? sortOrder,
  }) {
    return PlanOut(
      active: (active != null ? active.value : this.active),
      features: (features != null ? features.value : this.features),
      key: (key != null ? key.value : this.key),
      kind: (kind != null ? kind.value : this.kind),
      names: (names != null ? names.value : this.names),
      sortOrder: (sortOrder != null ? sortOrder.value : this.sortOrder),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PlansResponse {
  const PlansResponse({required this.plans});

  factory PlansResponse.fromJson(Map<String, dynamic> json) =>
      _$PlansResponseFromJson(json);

  static const toJsonFactory = _$PlansResponseToJson;
  Map<String, dynamic> toJson() => _$PlansResponseToJson(this);

  @JsonKey(name: 'plans', includeIfNull: false, defaultValue: <PlanOut>[])
  final List<PlanOut> plans;
  static const fromJsonFactory = _$PlansResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlansResponse &&
            (identical(other.plans, plans) ||
                const DeepCollectionEquality().equals(other.plans, plans)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(plans) ^ runtimeType.hashCode;
}

extension $PlansResponseExtension on PlansResponse {
  PlansResponse copyWith({List<PlanOut>? plans}) {
    return PlansResponse(plans: plans ?? this.plans);
  }

  PlansResponse copyWithWrapped({Wrapped<List<PlanOut>>? plans}) {
    return PlansResponse(plans: (plans != null ? plans.value : this.plans));
  }
}

@JsonSerializable(explicitToJson: true)
class PlotWeather {
  const PlotWeather({
    required this.alerts,
    required this.days,
    required this.stale,
  });

  factory PlotWeather.fromJson(Map<String, dynamic> json) =>
      _$PlotWeatherFromJson(json);

  static const toJsonFactory = _$PlotWeatherToJson;
  Map<String, dynamic> toJson() => _$PlotWeatherToJson(this);

  @JsonKey(name: 'alerts', includeIfNull: false, defaultValue: <WeatherAlert>[])
  final List<WeatherAlert> alerts;
  @JsonKey(name: 'days', includeIfNull: false, defaultValue: <WeatherDay>[])
  final List<WeatherDay> days;
  @JsonKey(name: 'stale', includeIfNull: false)
  final bool stale;
  static const fromJsonFactory = _$PlotWeatherFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlotWeather &&
            (identical(other.alerts, alerts) ||
                const DeepCollectionEquality().equals(other.alerts, alerts)) &&
            (identical(other.days, days) ||
                const DeepCollectionEquality().equals(other.days, days)) &&
            (identical(other.stale, stale) ||
                const DeepCollectionEquality().equals(other.stale, stale)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(alerts) ^
      const DeepCollectionEquality().hash(days) ^
      const DeepCollectionEquality().hash(stale) ^
      runtimeType.hashCode;
}

extension $PlotWeatherExtension on PlotWeather {
  PlotWeather copyWith({
    List<WeatherAlert>? alerts,
    List<WeatherDay>? days,
    bool? stale,
  }) {
    return PlotWeather(
      alerts: alerts ?? this.alerts,
      days: days ?? this.days,
      stale: stale ?? this.stale,
    );
  }

  PlotWeather copyWithWrapped({
    Wrapped<List<WeatherAlert>>? alerts,
    Wrapped<List<WeatherDay>>? days,
    Wrapped<bool>? stale,
  }) {
    return PlotWeather(
      alerts: (alerts != null ? alerts.value : this.alerts),
      days: (days != null ? days.value : this.days),
      stale: (stale != null ? stale.value : this.stale),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ProfilesResponse {
  const ProfilesResponse({required this.profiles});

  factory ProfilesResponse.fromJson(Map<String, dynamic> json) =>
      _$ProfilesResponseFromJson(json);

  static const toJsonFactory = _$ProfilesResponseToJson;
  Map<String, dynamic> toJson() => _$ProfilesResponseToJson(this);

  @JsonKey(
    name: 'profiles',
    includeIfNull: false,
    defaultValue: <PublicProfileOut>[],
  )
  final List<PublicProfileOut> profiles;
  static const fromJsonFactory = _$ProfilesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ProfilesResponse &&
            (identical(other.profiles, profiles) ||
                const DeepCollectionEquality().equals(
                  other.profiles,
                  profiles,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(profiles) ^ runtimeType.hashCode;
}

extension $ProfilesResponseExtension on ProfilesResponse {
  ProfilesResponse copyWith({List<PublicProfileOut>? profiles}) {
    return ProfilesResponse(profiles: profiles ?? this.profiles);
  }

  ProfilesResponse copyWithWrapped({
    Wrapped<List<PublicProfileOut>>? profiles,
  }) {
    return ProfilesResponse(
      profiles: (profiles != null ? profiles.value : this.profiles),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ProviderDetailsOut {
  const ProviderDetailsOut({
    required this.capacityT,
    required this.carrierRegNo,
    required this.certValidUntil,
    required this.certificateExpired,
    required this.refrigerated,
    required this.vehicleNumbers,
  });

  factory ProviderDetailsOut.fromJson(Map<String, dynamic> json) =>
      _$ProviderDetailsOutFromJson(json);

  static const toJsonFactory = _$ProviderDetailsOutToJson;
  Map<String, dynamic> toJson() => _$ProviderDetailsOutToJson(this);

  @JsonKey(name: 'capacity_t', includeIfNull: false)
  final double? capacityT;
  @JsonKey(name: 'carrier_reg_no', includeIfNull: false)
  final String? carrierRegNo;
  @JsonKey(name: 'cert_valid_until', includeIfNull: false, toJson: _dateToJson)
  final DateTime? certValidUntil;
  @JsonKey(name: 'certificate_expired', includeIfNull: false)
  final bool certificateExpired;
  @JsonKey(name: 'refrigerated', includeIfNull: false)
  final bool? refrigerated;
  @JsonKey(
    name: 'vehicle_numbers',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String> vehicleNumbers;
  static const fromJsonFactory = _$ProviderDetailsOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ProviderDetailsOut &&
            (identical(other.capacityT, capacityT) ||
                const DeepCollectionEquality().equals(
                  other.capacityT,
                  capacityT,
                )) &&
            (identical(other.carrierRegNo, carrierRegNo) ||
                const DeepCollectionEquality().equals(
                  other.carrierRegNo,
                  carrierRegNo,
                )) &&
            (identical(other.certValidUntil, certValidUntil) ||
                const DeepCollectionEquality().equals(
                  other.certValidUntil,
                  certValidUntil,
                )) &&
            (identical(other.certificateExpired, certificateExpired) ||
                const DeepCollectionEquality().equals(
                  other.certificateExpired,
                  certificateExpired,
                )) &&
            (identical(other.refrigerated, refrigerated) ||
                const DeepCollectionEquality().equals(
                  other.refrigerated,
                  refrigerated,
                )) &&
            (identical(other.vehicleNumbers, vehicleNumbers) ||
                const DeepCollectionEquality().equals(
                  other.vehicleNumbers,
                  vehicleNumbers,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(capacityT) ^
      const DeepCollectionEquality().hash(carrierRegNo) ^
      const DeepCollectionEquality().hash(certValidUntil) ^
      const DeepCollectionEquality().hash(certificateExpired) ^
      const DeepCollectionEquality().hash(refrigerated) ^
      const DeepCollectionEquality().hash(vehicleNumbers) ^
      runtimeType.hashCode;
}

extension $ProviderDetailsOutExtension on ProviderDetailsOut {
  ProviderDetailsOut copyWith({
    double? capacityT,
    String? carrierRegNo,
    DateTime? certValidUntil,
    bool? certificateExpired,
    bool? refrigerated,
    List<String>? vehicleNumbers,
  }) {
    return ProviderDetailsOut(
      capacityT: capacityT ?? this.capacityT,
      carrierRegNo: carrierRegNo ?? this.carrierRegNo,
      certValidUntil: certValidUntil ?? this.certValidUntil,
      certificateExpired: certificateExpired ?? this.certificateExpired,
      refrigerated: refrigerated ?? this.refrigerated,
      vehicleNumbers: vehicleNumbers ?? this.vehicleNumbers,
    );
  }

  ProviderDetailsOut copyWithWrapped({
    Wrapped<double?>? capacityT,
    Wrapped<String?>? carrierRegNo,
    Wrapped<DateTime?>? certValidUntil,
    Wrapped<bool>? certificateExpired,
    Wrapped<bool?>? refrigerated,
    Wrapped<List<String>>? vehicleNumbers,
  }) {
    return ProviderDetailsOut(
      capacityT: (capacityT != null ? capacityT.value : this.capacityT),
      carrierRegNo: (carrierRegNo != null
          ? carrierRegNo.value
          : this.carrierRegNo),
      certValidUntil: (certValidUntil != null
          ? certValidUntil.value
          : this.certValidUntil),
      certificateExpired: (certificateExpired != null
          ? certificateExpired.value
          : this.certificateExpired),
      refrigerated: (refrigerated != null
          ? refrigerated.value
          : this.refrigerated),
      vehicleNumbers: (vehicleNumbers != null
          ? vehicleNumbers.value
          : this.vehicleNumbers),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ProviderIn {
  const ProviderIn({
    this.address,
    this.capacityT,
    this.carrierRegNo,
    this.certValidUntil,
    required this.district,
    required this.fix,
    required this.kind,
    required this.name,
    required this.phone,
    this.refrigerated,
    this.serviceAreas,
    this.taluka,
    this.vehicleNumbers,
    required this.village,
  });

  factory ProviderIn.fromJson(Map<String, dynamic> json) =>
      _$ProviderInFromJson(json);

  static const toJsonFactory = _$ProviderInToJson;
  Map<String, dynamic> toJson() => _$ProviderInToJson(this);

  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'capacity_t', includeIfNull: false)
  final double? capacityT;
  @JsonKey(name: 'carrier_reg_no', includeIfNull: false)
  final String? carrierRegNo;
  @JsonKey(name: 'cert_valid_until', includeIfNull: false, toJson: _dateToJson)
  final DateTime? certValidUntil;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'fix', includeIfNull: false)
  final RegistrationFixIn fix;
  @JsonKey(
    name: 'kind',
    includeIfNull: false,
    toJson: providerInKindToJson,
    fromJson: providerInKindFromJson,
  )
  final enums.ProviderInKind kind;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String phone;
  @JsonKey(name: 'refrigerated', includeIfNull: false)
  final bool? refrigerated;
  @JsonKey(
    name: 'service_areas',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? serviceAreas;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(
    name: 'vehicle_numbers',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String>? vehicleNumbers;
  @JsonKey(name: 'village', includeIfNull: false)
  final String village;
  static const fromJsonFactory = _$ProviderInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ProviderIn &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.capacityT, capacityT) ||
                const DeepCollectionEquality().equals(
                  other.capacityT,
                  capacityT,
                )) &&
            (identical(other.carrierRegNo, carrierRegNo) ||
                const DeepCollectionEquality().equals(
                  other.carrierRegNo,
                  carrierRegNo,
                )) &&
            (identical(other.certValidUntil, certValidUntil) ||
                const DeepCollectionEquality().equals(
                  other.certValidUntil,
                  certValidUntil,
                )) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.fix, fix) ||
                const DeepCollectionEquality().equals(other.fix, fix)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.refrigerated, refrigerated) ||
                const DeepCollectionEquality().equals(
                  other.refrigerated,
                  refrigerated,
                )) &&
            (identical(other.serviceAreas, serviceAreas) ||
                const DeepCollectionEquality().equals(
                  other.serviceAreas,
                  serviceAreas,
                )) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.vehicleNumbers, vehicleNumbers) ||
                const DeepCollectionEquality().equals(
                  other.vehicleNumbers,
                  vehicleNumbers,
                )) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(capacityT) ^
      const DeepCollectionEquality().hash(carrierRegNo) ^
      const DeepCollectionEquality().hash(certValidUntil) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(fix) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(refrigerated) ^
      const DeepCollectionEquality().hash(serviceAreas) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(vehicleNumbers) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $ProviderInExtension on ProviderIn {
  ProviderIn copyWith({
    String? address,
    double? capacityT,
    String? carrierRegNo,
    DateTime? certValidUntil,
    String? district,
    RegistrationFixIn? fix,
    enums.ProviderInKind? kind,
    String? name,
    String? phone,
    bool? refrigerated,
    List<String>? serviceAreas,
    String? taluka,
    List<String>? vehicleNumbers,
    String? village,
  }) {
    return ProviderIn(
      address: address ?? this.address,
      capacityT: capacityT ?? this.capacityT,
      carrierRegNo: carrierRegNo ?? this.carrierRegNo,
      certValidUntil: certValidUntil ?? this.certValidUntil,
      district: district ?? this.district,
      fix: fix ?? this.fix,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      refrigerated: refrigerated ?? this.refrigerated,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      taluka: taluka ?? this.taluka,
      vehicleNumbers: vehicleNumbers ?? this.vehicleNumbers,
      village: village ?? this.village,
    );
  }

  ProviderIn copyWithWrapped({
    Wrapped<String?>? address,
    Wrapped<double?>? capacityT,
    Wrapped<String?>? carrierRegNo,
    Wrapped<DateTime?>? certValidUntil,
    Wrapped<String>? district,
    Wrapped<RegistrationFixIn>? fix,
    Wrapped<enums.ProviderInKind>? kind,
    Wrapped<String>? name,
    Wrapped<String>? phone,
    Wrapped<bool?>? refrigerated,
    Wrapped<List<String>?>? serviceAreas,
    Wrapped<String?>? taluka,
    Wrapped<List<String>?>? vehicleNumbers,
    Wrapped<String>? village,
  }) {
    return ProviderIn(
      address: (address != null ? address.value : this.address),
      capacityT: (capacityT != null ? capacityT.value : this.capacityT),
      carrierRegNo: (carrierRegNo != null
          ? carrierRegNo.value
          : this.carrierRegNo),
      certValidUntil: (certValidUntil != null
          ? certValidUntil.value
          : this.certValidUntil),
      district: (district != null ? district.value : this.district),
      fix: (fix != null ? fix.value : this.fix),
      kind: (kind != null ? kind.value : this.kind),
      name: (name != null ? name.value : this.name),
      phone: (phone != null ? phone.value : this.phone),
      refrigerated: (refrigerated != null
          ? refrigerated.value
          : this.refrigerated),
      serviceAreas: (serviceAreas != null
          ? serviceAreas.value
          : this.serviceAreas),
      taluka: (taluka != null ? taluka.value : this.taluka),
      vehicleNumbers: (vehicleNumbers != null
          ? vehicleNumbers.value
          : this.vehicleNumbers),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PublicProfileOut {
  const PublicProfileOut({
    required this.address,
    required this.areas,
    required this.badges,
    required this.crops,
    required this.dealsCompleted,
    this.distanceKm,
    required this.district,
    required this.firm,
    required this.id,
    required this.kind,
    required this.markets,
    required this.name,
    required this.phone,
    this.provider,
    required this.stars,
    required this.subjectType,
    required this.tags,
    required this.taluka,
    required this.village,
  });

  factory PublicProfileOut.fromJson(Map<String, dynamic> json) =>
      _$PublicProfileOutFromJson(json);

  static const toJsonFactory = _$PublicProfileOutToJson;
  Map<String, dynamic> toJson() => _$PublicProfileOutToJson(this);

  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'areas', includeIfNull: false, defaultValue: <String>[])
  final List<String> areas;
  @JsonKey(name: 'badges', includeIfNull: false, defaultValue: <BadgeOut>[])
  final List<BadgeOut> badges;
  @JsonKey(name: 'crops', includeIfNull: false, defaultValue: <String>[])
  final List<String> crops;
  @JsonKey(name: 'deals_completed', includeIfNull: false)
  final int dealsCompleted;
  @JsonKey(name: 'distance_km', includeIfNull: false)
  final int? distanceKm;
  @JsonKey(name: 'district', includeIfNull: false)
  final String district;
  @JsonKey(name: 'firm', includeIfNull: false)
  final String? firm;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  @JsonKey(name: 'markets', includeIfNull: false, defaultValue: <String>[])
  final List<String> markets;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'phone', includeIfNull: false)
  final String phone;
  @JsonKey(name: 'provider', includeIfNull: false)
  final ProviderDetailsOut? provider;
  @JsonKey(
    name: 'stars',
    includeIfNull: false,
    defaultValue: <QuestionStarsOut>[],
  )
  final List<QuestionStarsOut> stars;
  @JsonKey(name: 'subject_type', includeIfNull: false)
  final String subjectType;
  @JsonKey(name: 'tags', includeIfNull: false, defaultValue: <TagCountOut>[])
  final List<TagCountOut> tags;
  @JsonKey(name: 'taluka', includeIfNull: false)
  final String? taluka;
  @JsonKey(name: 'village', includeIfNull: false)
  final String? village;
  static const fromJsonFactory = _$PublicProfileOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PublicProfileOut &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.areas, areas) ||
                const DeepCollectionEquality().equals(other.areas, areas)) &&
            (identical(other.badges, badges) ||
                const DeepCollectionEquality().equals(other.badges, badges)) &&
            (identical(other.crops, crops) ||
                const DeepCollectionEquality().equals(other.crops, crops)) &&
            (identical(other.dealsCompleted, dealsCompleted) ||
                const DeepCollectionEquality().equals(
                  other.dealsCompleted,
                  dealsCompleted,
                )) &&
            (identical(other.distanceKm, distanceKm) ||
                const DeepCollectionEquality().equals(
                  other.distanceKm,
                  distanceKm,
                )) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.firm, firm) ||
                const DeepCollectionEquality().equals(other.firm, firm)) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.markets, markets) ||
                const DeepCollectionEquality().equals(
                  other.markets,
                  markets,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.phone, phone) ||
                const DeepCollectionEquality().equals(other.phone, phone)) &&
            (identical(other.provider, provider) ||
                const DeepCollectionEquality().equals(
                  other.provider,
                  provider,
                )) &&
            (identical(other.stars, stars) ||
                const DeepCollectionEquality().equals(other.stars, stars)) &&
            (identical(other.subjectType, subjectType) ||
                const DeepCollectionEquality().equals(
                  other.subjectType,
                  subjectType,
                )) &&
            (identical(other.tags, tags) ||
                const DeepCollectionEquality().equals(other.tags, tags)) &&
            (identical(other.taluka, taluka) ||
                const DeepCollectionEquality().equals(other.taluka, taluka)) &&
            (identical(other.village, village) ||
                const DeepCollectionEquality().equals(other.village, village)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(areas) ^
      const DeepCollectionEquality().hash(badges) ^
      const DeepCollectionEquality().hash(crops) ^
      const DeepCollectionEquality().hash(dealsCompleted) ^
      const DeepCollectionEquality().hash(distanceKm) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(firm) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(markets) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(phone) ^
      const DeepCollectionEquality().hash(provider) ^
      const DeepCollectionEquality().hash(stars) ^
      const DeepCollectionEquality().hash(subjectType) ^
      const DeepCollectionEquality().hash(tags) ^
      const DeepCollectionEquality().hash(taluka) ^
      const DeepCollectionEquality().hash(village) ^
      runtimeType.hashCode;
}

extension $PublicProfileOutExtension on PublicProfileOut {
  PublicProfileOut copyWith({
    String? address,
    List<String>? areas,
    List<BadgeOut>? badges,
    List<String>? crops,
    int? dealsCompleted,
    int? distanceKm,
    String? district,
    String? firm,
    String? id,
    String? kind,
    List<String>? markets,
    String? name,
    String? phone,
    ProviderDetailsOut? provider,
    List<QuestionStarsOut>? stars,
    String? subjectType,
    List<TagCountOut>? tags,
    String? taluka,
    String? village,
  }) {
    return PublicProfileOut(
      address: address ?? this.address,
      areas: areas ?? this.areas,
      badges: badges ?? this.badges,
      crops: crops ?? this.crops,
      dealsCompleted: dealsCompleted ?? this.dealsCompleted,
      distanceKm: distanceKm ?? this.distanceKm,
      district: district ?? this.district,
      firm: firm ?? this.firm,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      markets: markets ?? this.markets,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      provider: provider ?? this.provider,
      stars: stars ?? this.stars,
      subjectType: subjectType ?? this.subjectType,
      tags: tags ?? this.tags,
      taluka: taluka ?? this.taluka,
      village: village ?? this.village,
    );
  }

  PublicProfileOut copyWithWrapped({
    Wrapped<String?>? address,
    Wrapped<List<String>>? areas,
    Wrapped<List<BadgeOut>>? badges,
    Wrapped<List<String>>? crops,
    Wrapped<int>? dealsCompleted,
    Wrapped<int?>? distanceKm,
    Wrapped<String>? district,
    Wrapped<String?>? firm,
    Wrapped<String>? id,
    Wrapped<String>? kind,
    Wrapped<List<String>>? markets,
    Wrapped<String>? name,
    Wrapped<String>? phone,
    Wrapped<ProviderDetailsOut?>? provider,
    Wrapped<List<QuestionStarsOut>>? stars,
    Wrapped<String>? subjectType,
    Wrapped<List<TagCountOut>>? tags,
    Wrapped<String?>? taluka,
    Wrapped<String?>? village,
  }) {
    return PublicProfileOut(
      address: (address != null ? address.value : this.address),
      areas: (areas != null ? areas.value : this.areas),
      badges: (badges != null ? badges.value : this.badges),
      crops: (crops != null ? crops.value : this.crops),
      dealsCompleted: (dealsCompleted != null
          ? dealsCompleted.value
          : this.dealsCompleted),
      distanceKm: (distanceKm != null ? distanceKm.value : this.distanceKm),
      district: (district != null ? district.value : this.district),
      firm: (firm != null ? firm.value : this.firm),
      id: (id != null ? id.value : this.id),
      kind: (kind != null ? kind.value : this.kind),
      markets: (markets != null ? markets.value : this.markets),
      name: (name != null ? name.value : this.name),
      phone: (phone != null ? phone.value : this.phone),
      provider: (provider != null ? provider.value : this.provider),
      stars: (stars != null ? stars.value : this.stars),
      subjectType: (subjectType != null ? subjectType.value : this.subjectType),
      tags: (tags != null ? tags.value : this.tags),
      taluka: (taluka != null ? taluka.value : this.taluka),
      village: (village != null ? village.value : this.village),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PullResponse {
  const PullResponse({required this.changes, required this.cursor});

  factory PullResponse.fromJson(Map<String, dynamic> json) =>
      _$PullResponseFromJson(json);

  static const toJsonFactory = _$PullResponseToJson;
  Map<String, dynamic> toJson() => _$PullResponseToJson(this);

  @JsonKey(name: 'changes', includeIfNull: false, defaultValue: <Change>[])
  final List<Change> changes;
  @JsonKey(name: 'cursor', includeIfNull: false)
  final int cursor;
  static const fromJsonFactory = _$PullResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PullResponse &&
            (identical(other.changes, changes) ||
                const DeepCollectionEquality().equals(
                  other.changes,
                  changes,
                )) &&
            (identical(other.cursor, cursor) ||
                const DeepCollectionEquality().equals(other.cursor, cursor)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(changes) ^
      const DeepCollectionEquality().hash(cursor) ^
      runtimeType.hashCode;
}

extension $PullResponseExtension on PullResponse {
  PullResponse copyWith({List<Change>? changes, int? cursor}) {
    return PullResponse(
      changes: changes ?? this.changes,
      cursor: cursor ?? this.cursor,
    );
  }

  PullResponse copyWithWrapped({
    Wrapped<List<Change>>? changes,
    Wrapped<int>? cursor,
  }) {
    return PullResponse(
      changes: (changes != null ? changes.value : this.changes),
      cursor: (cursor != null ? cursor.value : this.cursor),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PushRequest {
  const PushRequest({required this.mutations});

  factory PushRequest.fromJson(Map<String, dynamic> json) =>
      _$PushRequestFromJson(json);

  static const toJsonFactory = _$PushRequestToJson;
  Map<String, dynamic> toJson() => _$PushRequestToJson(this);

  @JsonKey(name: 'mutations', includeIfNull: false, defaultValue: <Mutation>[])
  final List<Mutation> mutations;
  static const fromJsonFactory = _$PushRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PushRequest &&
            (identical(other.mutations, mutations) ||
                const DeepCollectionEquality().equals(
                  other.mutations,
                  mutations,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(mutations) ^ runtimeType.hashCode;
}

extension $PushRequestExtension on PushRequest {
  PushRequest copyWith({List<Mutation>? mutations}) {
    return PushRequest(mutations: mutations ?? this.mutations);
  }

  PushRequest copyWithWrapped({Wrapped<List<Mutation>>? mutations}) {
    return PushRequest(
      mutations: (mutations != null ? mutations.value : this.mutations),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PushResponse {
  const PushResponse({required this.results});

  factory PushResponse.fromJson(Map<String, dynamic> json) =>
      _$PushResponseFromJson(json);

  static const toJsonFactory = _$PushResponseToJson;
  Map<String, dynamic> toJson() => _$PushResponseToJson(this);

  @JsonKey(
    name: 'results',
    includeIfNull: false,
    defaultValue: <MutationResult>[],
  )
  final List<MutationResult> results;
  static const fromJsonFactory = _$PushResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PushResponse &&
            (identical(other.results, results) ||
                const DeepCollectionEquality().equals(other.results, results)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(results) ^ runtimeType.hashCode;
}

extension $PushResponseExtension on PushResponse {
  PushResponse copyWith({List<MutationResult>? results}) {
    return PushResponse(results: results ?? this.results);
  }

  PushResponse copyWithWrapped({Wrapped<List<MutationResult>>? results}) {
    return PushResponse(
      results: (results != null ? results.value : this.results),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class QuestionStarsOut {
  const QuestionStarsOut({
    required this.average,
    required this.count,
    required this.questionKey,
  });

  factory QuestionStarsOut.fromJson(Map<String, dynamic> json) =>
      _$QuestionStarsOutFromJson(json);

  static const toJsonFactory = _$QuestionStarsOutToJson;
  Map<String, dynamic> toJson() => _$QuestionStarsOutToJson(this);

  @JsonKey(name: 'average', includeIfNull: false)
  final double average;
  @JsonKey(name: 'count', includeIfNull: false)
  final int count;
  @JsonKey(name: 'question_key', includeIfNull: false)
  final String questionKey;
  static const fromJsonFactory = _$QuestionStarsOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is QuestionStarsOut &&
            (identical(other.average, average) ||
                const DeepCollectionEquality().equals(
                  other.average,
                  average,
                )) &&
            (identical(other.count, count) ||
                const DeepCollectionEquality().equals(other.count, count)) &&
            (identical(other.questionKey, questionKey) ||
                const DeepCollectionEquality().equals(
                  other.questionKey,
                  questionKey,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(average) ^
      const DeepCollectionEquality().hash(count) ^
      const DeepCollectionEquality().hash(questionKey) ^
      runtimeType.hashCode;
}

extension $QuestionStarsOutExtension on QuestionStarsOut {
  QuestionStarsOut copyWith({
    double? average,
    int? count,
    String? questionKey,
  }) {
    return QuestionStarsOut(
      average: average ?? this.average,
      count: count ?? this.count,
      questionKey: questionKey ?? this.questionKey,
    );
  }

  QuestionStarsOut copyWithWrapped({
    Wrapped<double>? average,
    Wrapped<int>? count,
    Wrapped<String>? questionKey,
  }) {
    return QuestionStarsOut(
      average: (average != null ? average.value : this.average),
      count: (count != null ? count.value : this.count),
      questionKey: (questionKey != null ? questionKey.value : this.questionKey),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class QueueResponse {
  const QueueResponse({required this.subjects});

  factory QueueResponse.fromJson(Map<String, dynamic> json) =>
      _$QueueResponseFromJson(json);

  static const toJsonFactory = _$QueueResponseToJson;
  Map<String, dynamic> toJson() => _$QueueResponseToJson(this);

  @JsonKey(name: 'subjects', includeIfNull: false, defaultValue: <SubjectOut>[])
  final List<SubjectOut> subjects;
  static const fromJsonFactory = _$QueueResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is QueueResponse &&
            (identical(other.subjects, subjects) ||
                const DeepCollectionEquality().equals(
                  other.subjects,
                  subjects,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(subjects) ^ runtimeType.hashCode;
}

extension $QueueResponseExtension on QueueResponse {
  QueueResponse copyWith({List<SubjectOut>? subjects}) {
    return QueueResponse(subjects: subjects ?? this.subjects);
  }

  QueueResponse copyWithWrapped({Wrapped<List<SubjectOut>>? subjects}) {
    return QueueResponse(
      subjects: (subjects != null ? subjects.value : this.subjects),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RatingTagAdminOut {
  const RatingTagAdminOut({
    required this.id,
    required this.key,
    required this.labelEn,
    required this.labelHi,
    required this.labelMr,
    required this.polarity,
    required this.questionKey,
    required this.sortOrder,
    required this.status,
  });

  factory RatingTagAdminOut.fromJson(Map<String, dynamic> json) =>
      _$RatingTagAdminOutFromJson(json);

  static const toJsonFactory = _$RatingTagAdminOutToJson;
  Map<String, dynamic> toJson() => _$RatingTagAdminOutToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'label_en', includeIfNull: false)
  final String labelEn;
  @JsonKey(name: 'label_hi', includeIfNull: false)
  final String labelHi;
  @JsonKey(name: 'label_mr', includeIfNull: false)
  final String labelMr;
  @JsonKey(name: 'polarity', includeIfNull: false)
  final String polarity;
  @JsonKey(name: 'question_key', includeIfNull: false)
  final String questionKey;
  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int sortOrder;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  static const fromJsonFactory = _$RatingTagAdminOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RatingTagAdminOut &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.labelEn, labelEn) ||
                const DeepCollectionEquality().equals(
                  other.labelEn,
                  labelEn,
                )) &&
            (identical(other.labelHi, labelHi) ||
                const DeepCollectionEquality().equals(
                  other.labelHi,
                  labelHi,
                )) &&
            (identical(other.labelMr, labelMr) ||
                const DeepCollectionEquality().equals(
                  other.labelMr,
                  labelMr,
                )) &&
            (identical(other.polarity, polarity) ||
                const DeepCollectionEquality().equals(
                  other.polarity,
                  polarity,
                )) &&
            (identical(other.questionKey, questionKey) ||
                const DeepCollectionEquality().equals(
                  other.questionKey,
                  questionKey,
                )) &&
            (identical(other.sortOrder, sortOrder) ||
                const DeepCollectionEquality().equals(
                  other.sortOrder,
                  sortOrder,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(labelEn) ^
      const DeepCollectionEquality().hash(labelHi) ^
      const DeepCollectionEquality().hash(labelMr) ^
      const DeepCollectionEquality().hash(polarity) ^
      const DeepCollectionEquality().hash(questionKey) ^
      const DeepCollectionEquality().hash(sortOrder) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $RatingTagAdminOutExtension on RatingTagAdminOut {
  RatingTagAdminOut copyWith({
    String? id,
    String? key,
    String? labelEn,
    String? labelHi,
    String? labelMr,
    String? polarity,
    String? questionKey,
    int? sortOrder,
    String? status,
  }) {
    return RatingTagAdminOut(
      id: id ?? this.id,
      key: key ?? this.key,
      labelEn: labelEn ?? this.labelEn,
      labelHi: labelHi ?? this.labelHi,
      labelMr: labelMr ?? this.labelMr,
      polarity: polarity ?? this.polarity,
      questionKey: questionKey ?? this.questionKey,
      sortOrder: sortOrder ?? this.sortOrder,
      status: status ?? this.status,
    );
  }

  RatingTagAdminOut copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? key,
    Wrapped<String>? labelEn,
    Wrapped<String>? labelHi,
    Wrapped<String>? labelMr,
    Wrapped<String>? polarity,
    Wrapped<String>? questionKey,
    Wrapped<int>? sortOrder,
    Wrapped<String>? status,
  }) {
    return RatingTagAdminOut(
      id: (id != null ? id.value : this.id),
      key: (key != null ? key.value : this.key),
      labelEn: (labelEn != null ? labelEn.value : this.labelEn),
      labelHi: (labelHi != null ? labelHi.value : this.labelHi),
      labelMr: (labelMr != null ? labelMr.value : this.labelMr),
      polarity: (polarity != null ? polarity.value : this.polarity),
      questionKey: (questionKey != null ? questionKey.value : this.questionKey),
      sortOrder: (sortOrder != null ? sortOrder.value : this.sortOrder),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RatingTagIn {
  const RatingTagIn({
    required this.labelEn,
    required this.labelHi,
    required this.labelMr,
    required this.status,
  });

  factory RatingTagIn.fromJson(Map<String, dynamic> json) =>
      _$RatingTagInFromJson(json);

  static const toJsonFactory = _$RatingTagInToJson;
  Map<String, dynamic> toJson() => _$RatingTagInToJson(this);

  @JsonKey(name: 'label_en', includeIfNull: false)
  final String labelEn;
  @JsonKey(name: 'label_hi', includeIfNull: false)
  final String labelHi;
  @JsonKey(name: 'label_mr', includeIfNull: false)
  final String labelMr;
  @JsonKey(
    name: 'status',
    includeIfNull: false,
    toJson: ratingTagInStatusToJson,
    fromJson: ratingTagInStatusFromJson,
  )
  final enums.RatingTagInStatus status;
  static const fromJsonFactory = _$RatingTagInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RatingTagIn &&
            (identical(other.labelEn, labelEn) ||
                const DeepCollectionEquality().equals(
                  other.labelEn,
                  labelEn,
                )) &&
            (identical(other.labelHi, labelHi) ||
                const DeepCollectionEquality().equals(
                  other.labelHi,
                  labelHi,
                )) &&
            (identical(other.labelMr, labelMr) ||
                const DeepCollectionEquality().equals(
                  other.labelMr,
                  labelMr,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(labelEn) ^
      const DeepCollectionEquality().hash(labelHi) ^
      const DeepCollectionEquality().hash(labelMr) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $RatingTagInExtension on RatingTagIn {
  RatingTagIn copyWith({
    String? labelEn,
    String? labelHi,
    String? labelMr,
    enums.RatingTagInStatus? status,
  }) {
    return RatingTagIn(
      labelEn: labelEn ?? this.labelEn,
      labelHi: labelHi ?? this.labelHi,
      labelMr: labelMr ?? this.labelMr,
      status: status ?? this.status,
    );
  }

  RatingTagIn copyWithWrapped({
    Wrapped<String>? labelEn,
    Wrapped<String>? labelHi,
    Wrapped<String>? labelMr,
    Wrapped<enums.RatingTagInStatus>? status,
  }) {
    return RatingTagIn(
      labelEn: (labelEn != null ? labelEn.value : this.labelEn),
      labelHi: (labelHi != null ? labelHi.value : this.labelHi),
      labelMr: (labelMr != null ? labelMr.value : this.labelMr),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RatingTagOut {
  const RatingTagOut({
    required this.id,
    required this.key,
    required this.labelEn,
    required this.labelHi,
    required this.labelMr,
    required this.polarity,
    required this.questionKey,
    required this.sortOrder,
  });

  factory RatingTagOut.fromJson(Map<String, dynamic> json) =>
      _$RatingTagOutFromJson(json);

  static const toJsonFactory = _$RatingTagOutToJson;
  Map<String, dynamic> toJson() => _$RatingTagOutToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'label_en', includeIfNull: false)
  final String labelEn;
  @JsonKey(name: 'label_hi', includeIfNull: false)
  final String labelHi;
  @JsonKey(name: 'label_mr', includeIfNull: false)
  final String labelMr;
  @JsonKey(name: 'polarity', includeIfNull: false)
  final String polarity;
  @JsonKey(name: 'question_key', includeIfNull: false)
  final String questionKey;
  @JsonKey(name: 'sort_order', includeIfNull: false)
  final int sortOrder;
  static const fromJsonFactory = _$RatingTagOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RatingTagOut &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.labelEn, labelEn) ||
                const DeepCollectionEquality().equals(
                  other.labelEn,
                  labelEn,
                )) &&
            (identical(other.labelHi, labelHi) ||
                const DeepCollectionEquality().equals(
                  other.labelHi,
                  labelHi,
                )) &&
            (identical(other.labelMr, labelMr) ||
                const DeepCollectionEquality().equals(
                  other.labelMr,
                  labelMr,
                )) &&
            (identical(other.polarity, polarity) ||
                const DeepCollectionEquality().equals(
                  other.polarity,
                  polarity,
                )) &&
            (identical(other.questionKey, questionKey) ||
                const DeepCollectionEquality().equals(
                  other.questionKey,
                  questionKey,
                )) &&
            (identical(other.sortOrder, sortOrder) ||
                const DeepCollectionEquality().equals(
                  other.sortOrder,
                  sortOrder,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(labelEn) ^
      const DeepCollectionEquality().hash(labelHi) ^
      const DeepCollectionEquality().hash(labelMr) ^
      const DeepCollectionEquality().hash(polarity) ^
      const DeepCollectionEquality().hash(questionKey) ^
      const DeepCollectionEquality().hash(sortOrder) ^
      runtimeType.hashCode;
}

extension $RatingTagOutExtension on RatingTagOut {
  RatingTagOut copyWith({
    String? id,
    String? key,
    String? labelEn,
    String? labelHi,
    String? labelMr,
    String? polarity,
    String? questionKey,
    int? sortOrder,
  }) {
    return RatingTagOut(
      id: id ?? this.id,
      key: key ?? this.key,
      labelEn: labelEn ?? this.labelEn,
      labelHi: labelHi ?? this.labelHi,
      labelMr: labelMr ?? this.labelMr,
      polarity: polarity ?? this.polarity,
      questionKey: questionKey ?? this.questionKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  RatingTagOut copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? key,
    Wrapped<String>? labelEn,
    Wrapped<String>? labelHi,
    Wrapped<String>? labelMr,
    Wrapped<String>? polarity,
    Wrapped<String>? questionKey,
    Wrapped<int>? sortOrder,
  }) {
    return RatingTagOut(
      id: (id != null ? id.value : this.id),
      key: (key != null ? key.value : this.key),
      labelEn: (labelEn != null ? labelEn.value : this.labelEn),
      labelHi: (labelHi != null ? labelHi.value : this.labelHi),
      labelMr: (labelMr != null ? labelMr.value : this.labelMr),
      polarity: (polarity != null ? polarity.value : this.polarity),
      questionKey: (questionKey != null ? questionKey.value : this.questionKey),
      sortOrder: (sortOrder != null ? sortOrder.value : this.sortOrder),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RatingTagsAdminResponse {
  const RatingTagsAdminResponse({required this.tags});

  factory RatingTagsAdminResponse.fromJson(Map<String, dynamic> json) =>
      _$RatingTagsAdminResponseFromJson(json);

  static const toJsonFactory = _$RatingTagsAdminResponseToJson;
  Map<String, dynamic> toJson() => _$RatingTagsAdminResponseToJson(this);

  @JsonKey(
    name: 'tags',
    includeIfNull: false,
    defaultValue: <RatingTagAdminOut>[],
  )
  final List<RatingTagAdminOut> tags;
  static const fromJsonFactory = _$RatingTagsAdminResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RatingTagsAdminResponse &&
            (identical(other.tags, tags) ||
                const DeepCollectionEquality().equals(other.tags, tags)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tags) ^ runtimeType.hashCode;
}

extension $RatingTagsAdminResponseExtension on RatingTagsAdminResponse {
  RatingTagsAdminResponse copyWith({List<RatingTagAdminOut>? tags}) {
    return RatingTagsAdminResponse(tags: tags ?? this.tags);
  }

  RatingTagsAdminResponse copyWithWrapped({
    Wrapped<List<RatingTagAdminOut>>? tags,
  }) {
    return RatingTagsAdminResponse(
      tags: (tags != null ? tags.value : this.tags),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RatingTagsResponse {
  const RatingTagsResponse({required this.tags});

  factory RatingTagsResponse.fromJson(Map<String, dynamic> json) =>
      _$RatingTagsResponseFromJson(json);

  static const toJsonFactory = _$RatingTagsResponseToJson;
  Map<String, dynamic> toJson() => _$RatingTagsResponseToJson(this);

  @JsonKey(name: 'tags', includeIfNull: false, defaultValue: <RatingTagOut>[])
  final List<RatingTagOut> tags;
  static const fromJsonFactory = _$RatingTagsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RatingTagsResponse &&
            (identical(other.tags, tags) ||
                const DeepCollectionEquality().equals(other.tags, tags)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tags) ^ runtimeType.hashCode;
}

extension $RatingTagsResponseExtension on RatingTagsResponse {
  RatingTagsResponse copyWith({List<RatingTagOut>? tags}) {
    return RatingTagsResponse(tags: tags ?? this.tags);
  }

  RatingTagsResponse copyWithWrapped({Wrapped<List<RatingTagOut>>? tags}) {
    return RatingTagsResponse(tags: (tags != null ? tags.value : this.tags));
  }
}

@JsonSerializable(explicitToJson: true)
class ReadyResponse {
  const ReadyResponse({required this.database, required this.status});

  factory ReadyResponse.fromJson(Map<String, dynamic> json) =>
      _$ReadyResponseFromJson(json);

  static const toJsonFactory = _$ReadyResponseToJson;
  Map<String, dynamic> toJson() => _$ReadyResponseToJson(this);

  @JsonKey(name: 'database', includeIfNull: false)
  final String database;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  static const fromJsonFactory = _$ReadyResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReadyResponse &&
            (identical(other.database, database) ||
                const DeepCollectionEquality().equals(
                  other.database,
                  database,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(database) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $ReadyResponseExtension on ReadyResponse {
  ReadyResponse copyWith({String? database, String? status}) {
    return ReadyResponse(
      database: database ?? this.database,
      status: status ?? this.status,
    );
  }

  ReadyResponse copyWithWrapped({
    Wrapped<String>? database,
    Wrapped<String>? status,
  }) {
    return ReadyResponse(
      database: (database != null ? database.value : this.database),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RegistrationFixIn {
  const RegistrationFixIn({
    required this.accuracyM,
    required this.capturedAt,
    this.district,
    this.isMocked,
    required this.lat,
    required this.lon,
    this.pin,
    this.place,
    this.state,
  });

  factory RegistrationFixIn.fromJson(Map<String, dynamic> json) =>
      _$RegistrationFixInFromJson(json);

  static const toJsonFactory = _$RegistrationFixInToJson;
  Map<String, dynamic> toJson() => _$RegistrationFixInToJson(this);

  @JsonKey(name: 'accuracy_m', includeIfNull: false)
  final double accuracyM;
  @JsonKey(name: 'captured_at', includeIfNull: false)
  final DateTime capturedAt;
  @JsonKey(name: 'district', includeIfNull: false)
  final String? district;
  @JsonKey(name: 'is_mocked', includeIfNull: false, defaultValue: false)
  final bool? isMocked;
  @JsonKey(name: 'lat', includeIfNull: false)
  final double lat;
  @JsonKey(name: 'lon', includeIfNull: false)
  final double lon;
  @JsonKey(name: 'pin', includeIfNull: false)
  final String? pin;
  @JsonKey(name: 'place', includeIfNull: false)
  final String? place;
  @JsonKey(name: 'state', includeIfNull: false)
  final String? state;
  static const fromJsonFactory = _$RegistrationFixInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RegistrationFixIn &&
            (identical(other.accuracyM, accuracyM) ||
                const DeepCollectionEquality().equals(
                  other.accuracyM,
                  accuracyM,
                )) &&
            (identical(other.capturedAt, capturedAt) ||
                const DeepCollectionEquality().equals(
                  other.capturedAt,
                  capturedAt,
                )) &&
            (identical(other.district, district) ||
                const DeepCollectionEquality().equals(
                  other.district,
                  district,
                )) &&
            (identical(other.isMocked, isMocked) ||
                const DeepCollectionEquality().equals(
                  other.isMocked,
                  isMocked,
                )) &&
            (identical(other.lat, lat) ||
                const DeepCollectionEquality().equals(other.lat, lat)) &&
            (identical(other.lon, lon) ||
                const DeepCollectionEquality().equals(other.lon, lon)) &&
            (identical(other.pin, pin) ||
                const DeepCollectionEquality().equals(other.pin, pin)) &&
            (identical(other.place, place) ||
                const DeepCollectionEquality().equals(other.place, place)) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(accuracyM) ^
      const DeepCollectionEquality().hash(capturedAt) ^
      const DeepCollectionEquality().hash(district) ^
      const DeepCollectionEquality().hash(isMocked) ^
      const DeepCollectionEquality().hash(lat) ^
      const DeepCollectionEquality().hash(lon) ^
      const DeepCollectionEquality().hash(pin) ^
      const DeepCollectionEquality().hash(place) ^
      const DeepCollectionEquality().hash(state) ^
      runtimeType.hashCode;
}

extension $RegistrationFixInExtension on RegistrationFixIn {
  RegistrationFixIn copyWith({
    double? accuracyM,
    DateTime? capturedAt,
    String? district,
    bool? isMocked,
    double? lat,
    double? lon,
    String? pin,
    String? place,
    String? state,
  }) {
    return RegistrationFixIn(
      accuracyM: accuracyM ?? this.accuracyM,
      capturedAt: capturedAt ?? this.capturedAt,
      district: district ?? this.district,
      isMocked: isMocked ?? this.isMocked,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      pin: pin ?? this.pin,
      place: place ?? this.place,
      state: state ?? this.state,
    );
  }

  RegistrationFixIn copyWithWrapped({
    Wrapped<double>? accuracyM,
    Wrapped<DateTime>? capturedAt,
    Wrapped<String?>? district,
    Wrapped<bool?>? isMocked,
    Wrapped<double>? lat,
    Wrapped<double>? lon,
    Wrapped<String?>? pin,
    Wrapped<String?>? place,
    Wrapped<String?>? state,
  }) {
    return RegistrationFixIn(
      accuracyM: (accuracyM != null ? accuracyM.value : this.accuracyM),
      capturedAt: (capturedAt != null ? capturedAt.value : this.capturedAt),
      district: (district != null ? district.value : this.district),
      isMocked: (isMocked != null ? isMocked.value : this.isMocked),
      lat: (lat != null ? lat.value : this.lat),
      lon: (lon != null ? lon.value : this.lon),
      pin: (pin != null ? pin.value : this.pin),
      place: (place != null ? place.value : this.place),
      state: (state != null ? state.value : this.state),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RestrictionOut {
  const RestrictionOut({
    required this.activeIngredient,
    required this.cropGroups,
    required this.crops,
    required this.effectiveFrom,
    required this.kind,
    required this.notification,
  });

  factory RestrictionOut.fromJson(Map<String, dynamic> json) =>
      _$RestrictionOutFromJson(json);

  static const toJsonFactory = _$RestrictionOutToJson;
  Map<String, dynamic> toJson() => _$RestrictionOutToJson(this);

  @JsonKey(name: 'active_ingredient', includeIfNull: false)
  final String activeIngredient;
  @JsonKey(name: 'crop_groups', includeIfNull: false, defaultValue: <String>[])
  final List<String> cropGroups;
  @JsonKey(name: 'crops', includeIfNull: false, defaultValue: <String>[])
  final List<String> crops;
  @JsonKey(name: 'effective_from', includeIfNull: false)
  final DateTime effectiveFrom;
  @JsonKey(name: 'kind', includeIfNull: false)
  final String kind;
  @JsonKey(name: 'notification', includeIfNull: false)
  final String notification;
  static const fromJsonFactory = _$RestrictionOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestrictionOut &&
            (identical(other.activeIngredient, activeIngredient) ||
                const DeepCollectionEquality().equals(
                  other.activeIngredient,
                  activeIngredient,
                )) &&
            (identical(other.cropGroups, cropGroups) ||
                const DeepCollectionEquality().equals(
                  other.cropGroups,
                  cropGroups,
                )) &&
            (identical(other.crops, crops) ||
                const DeepCollectionEquality().equals(other.crops, crops)) &&
            (identical(other.effectiveFrom, effectiveFrom) ||
                const DeepCollectionEquality().equals(
                  other.effectiveFrom,
                  effectiveFrom,
                )) &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.notification, notification) ||
                const DeepCollectionEquality().equals(
                  other.notification,
                  notification,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activeIngredient) ^
      const DeepCollectionEquality().hash(cropGroups) ^
      const DeepCollectionEquality().hash(crops) ^
      const DeepCollectionEquality().hash(effectiveFrom) ^
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(notification) ^
      runtimeType.hashCode;
}

extension $RestrictionOutExtension on RestrictionOut {
  RestrictionOut copyWith({
    String? activeIngredient,
    List<String>? cropGroups,
    List<String>? crops,
    DateTime? effectiveFrom,
    String? kind,
    String? notification,
  }) {
    return RestrictionOut(
      activeIngredient: activeIngredient ?? this.activeIngredient,
      cropGroups: cropGroups ?? this.cropGroups,
      crops: crops ?? this.crops,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      kind: kind ?? this.kind,
      notification: notification ?? this.notification,
    );
  }

  RestrictionOut copyWithWrapped({
    Wrapped<String>? activeIngredient,
    Wrapped<List<String>>? cropGroups,
    Wrapped<List<String>>? crops,
    Wrapped<DateTime>? effectiveFrom,
    Wrapped<String>? kind,
    Wrapped<String>? notification,
  }) {
    return RestrictionOut(
      activeIngredient: (activeIngredient != null
          ? activeIngredient.value
          : this.activeIngredient),
      cropGroups: (cropGroups != null ? cropGroups.value : this.cropGroups),
      crops: (crops != null ? crops.value : this.crops),
      effectiveFrom: (effectiveFrom != null
          ? effectiveFrom.value
          : this.effectiveFrom),
      kind: (kind != null ? kind.value : this.kind),
      notification: (notification != null
          ? notification.value
          : this.notification),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RestrictionsResponse {
  const RestrictionsResponse({
    required this.restrictions,
    required this.synonyms,
  });

  factory RestrictionsResponse.fromJson(Map<String, dynamic> json) =>
      _$RestrictionsResponseFromJson(json);

  static const toJsonFactory = _$RestrictionsResponseToJson;
  Map<String, dynamic> toJson() => _$RestrictionsResponseToJson(this);

  @JsonKey(
    name: 'restrictions',
    includeIfNull: false,
    defaultValue: <RestrictionOut>[],
  )
  final List<RestrictionOut> restrictions;
  @JsonKey(name: 'synonyms', includeIfNull: false, defaultValue: <SynonymOut>[])
  final List<SynonymOut> synonyms;
  static const fromJsonFactory = _$RestrictionsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestrictionsResponse &&
            (identical(other.restrictions, restrictions) ||
                const DeepCollectionEquality().equals(
                  other.restrictions,
                  restrictions,
                )) &&
            (identical(other.synonyms, synonyms) ||
                const DeepCollectionEquality().equals(
                  other.synonyms,
                  synonyms,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(restrictions) ^
      const DeepCollectionEquality().hash(synonyms) ^
      runtimeType.hashCode;
}

extension $RestrictionsResponseExtension on RestrictionsResponse {
  RestrictionsResponse copyWith({
    List<RestrictionOut>? restrictions,
    List<SynonymOut>? synonyms,
  }) {
    return RestrictionsResponse(
      restrictions: restrictions ?? this.restrictions,
      synonyms: synonyms ?? this.synonyms,
    );
  }

  RestrictionsResponse copyWithWrapped({
    Wrapped<List<RestrictionOut>>? restrictions,
    Wrapped<List<SynonymOut>>? synonyms,
  }) {
    return RestrictionsResponse(
      restrictions: (restrictions != null
          ? restrictions.value
          : this.restrictions),
      synonyms: (synonyms != null ? synonyms.value : this.synonyms),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReviewIn {
  const ReviewIn({this.comments, required this.decision});

  factory ReviewIn.fromJson(Map<String, dynamic> json) =>
      _$ReviewInFromJson(json);

  static const toJsonFactory = _$ReviewInToJson;
  Map<String, dynamic> toJson() => _$ReviewInToJson(this);

  @JsonKey(name: 'comments', includeIfNull: false)
  final String? comments;
  @JsonKey(
    name: 'decision',
    includeIfNull: false,
    toJson: reviewInDecisionToJson,
    fromJson: reviewInDecisionFromJson,
  )
  final enums.ReviewInDecision decision;
  static const fromJsonFactory = _$ReviewInFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReviewIn &&
            (identical(other.comments, comments) ||
                const DeepCollectionEquality().equals(
                  other.comments,
                  comments,
                )) &&
            (identical(other.decision, decision) ||
                const DeepCollectionEquality().equals(
                  other.decision,
                  decision,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(comments) ^
      const DeepCollectionEquality().hash(decision) ^
      runtimeType.hashCode;
}

extension $ReviewInExtension on ReviewIn {
  ReviewIn copyWith({String? comments, enums.ReviewInDecision? decision}) {
    return ReviewIn(
      comments: comments ?? this.comments,
      decision: decision ?? this.decision,
    );
  }

  ReviewIn copyWithWrapped({
    Wrapped<String?>? comments,
    Wrapped<enums.ReviewInDecision>? decision,
  }) {
    return ReviewIn(
      comments: (comments != null ? comments.value : this.comments),
      decision: (decision != null ? decision.value : this.decision),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SentInterestOut {
  const SentInterestOut({
    required this.basis,
    required this.createdAt,
    this.dealId,
    required this.harvestDate,
    required this.id,
    required this.lot,
    required this.lotId,
    required this.quantityT,
    required this.ratePaise,
    required this.status,
    required this.viaBroker,
  });

  factory SentInterestOut.fromJson(Map<String, dynamic> json) =>
      _$SentInterestOutFromJson(json);

  static const toJsonFactory = _$SentInterestOutToJson;
  Map<String, dynamic> toJson() => _$SentInterestOutToJson(this);

  @JsonKey(name: 'basis', includeIfNull: false)
  final String basis;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(name: 'deal_id', includeIfNull: false)
  final String? dealId;
  @JsonKey(name: 'harvest_date', includeIfNull: false, toJson: _dateToJson)
  final DateTime harvestDate;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'lot', includeIfNull: false)
  final LotBrief lot;
  @JsonKey(name: 'lot_id', includeIfNull: false)
  final String lotId;
  @JsonKey(name: 'quantity_t', includeIfNull: false)
  final double? quantityT;
  @JsonKey(name: 'rate_paise', includeIfNull: false)
  final int ratePaise;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'via_broker', includeIfNull: false)
  final bool viaBroker;
  static const fromJsonFactory = _$SentInterestOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SentInterestOut &&
            (identical(other.basis, basis) ||
                const DeepCollectionEquality().equals(other.basis, basis)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.dealId, dealId) ||
                const DeepCollectionEquality().equals(other.dealId, dealId)) &&
            (identical(other.harvestDate, harvestDate) ||
                const DeepCollectionEquality().equals(
                  other.harvestDate,
                  harvestDate,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.lot, lot) ||
                const DeepCollectionEquality().equals(other.lot, lot)) &&
            (identical(other.lotId, lotId) ||
                const DeepCollectionEquality().equals(other.lotId, lotId)) &&
            (identical(other.quantityT, quantityT) ||
                const DeepCollectionEquality().equals(
                  other.quantityT,
                  quantityT,
                )) &&
            (identical(other.ratePaise, ratePaise) ||
                const DeepCollectionEquality().equals(
                  other.ratePaise,
                  ratePaise,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.viaBroker, viaBroker) ||
                const DeepCollectionEquality().equals(
                  other.viaBroker,
                  viaBroker,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(basis) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(dealId) ^
      const DeepCollectionEquality().hash(harvestDate) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(lot) ^
      const DeepCollectionEquality().hash(lotId) ^
      const DeepCollectionEquality().hash(quantityT) ^
      const DeepCollectionEquality().hash(ratePaise) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(viaBroker) ^
      runtimeType.hashCode;
}

extension $SentInterestOutExtension on SentInterestOut {
  SentInterestOut copyWith({
    String? basis,
    DateTime? createdAt,
    String? dealId,
    DateTime? harvestDate,
    String? id,
    LotBrief? lot,
    String? lotId,
    double? quantityT,
    int? ratePaise,
    String? status,
    bool? viaBroker,
  }) {
    return SentInterestOut(
      basis: basis ?? this.basis,
      createdAt: createdAt ?? this.createdAt,
      dealId: dealId ?? this.dealId,
      harvestDate: harvestDate ?? this.harvestDate,
      id: id ?? this.id,
      lot: lot ?? this.lot,
      lotId: lotId ?? this.lotId,
      quantityT: quantityT ?? this.quantityT,
      ratePaise: ratePaise ?? this.ratePaise,
      status: status ?? this.status,
      viaBroker: viaBroker ?? this.viaBroker,
    );
  }

  SentInterestOut copyWithWrapped({
    Wrapped<String>? basis,
    Wrapped<DateTime>? createdAt,
    Wrapped<String?>? dealId,
    Wrapped<DateTime>? harvestDate,
    Wrapped<String>? id,
    Wrapped<LotBrief>? lot,
    Wrapped<String>? lotId,
    Wrapped<double?>? quantityT,
    Wrapped<int>? ratePaise,
    Wrapped<String>? status,
    Wrapped<bool>? viaBroker,
  }) {
    return SentInterestOut(
      basis: (basis != null ? basis.value : this.basis),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      dealId: (dealId != null ? dealId.value : this.dealId),
      harvestDate: (harvestDate != null ? harvestDate.value : this.harvestDate),
      id: (id != null ? id.value : this.id),
      lot: (lot != null ? lot.value : this.lot),
      lotId: (lotId != null ? lotId.value : this.lotId),
      quantityT: (quantityT != null ? quantityT.value : this.quantityT),
      ratePaise: (ratePaise != null ? ratePaise.value : this.ratePaise),
      status: (status != null ? status.value : this.status),
      viaBroker: (viaBroker != null ? viaBroker.value : this.viaBroker),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SentInterestsResponse {
  const SentInterestsResponse({required this.interests});

  factory SentInterestsResponse.fromJson(Map<String, dynamic> json) =>
      _$SentInterestsResponseFromJson(json);

  static const toJsonFactory = _$SentInterestsResponseToJson;
  Map<String, dynamic> toJson() => _$SentInterestsResponseToJson(this);

  @JsonKey(
    name: 'interests',
    includeIfNull: false,
    defaultValue: <SentInterestOut>[],
  )
  final List<SentInterestOut> interests;
  static const fromJsonFactory = _$SentInterestsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SentInterestsResponse &&
            (identical(other.interests, interests) ||
                const DeepCollectionEquality().equals(
                  other.interests,
                  interests,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(interests) ^ runtimeType.hashCode;
}

extension $SentInterestsResponseExtension on SentInterestsResponse {
  SentInterestsResponse copyWith({List<SentInterestOut>? interests}) {
    return SentInterestsResponse(interests: interests ?? this.interests);
  }

  SentInterestsResponse copyWithWrapped({
    Wrapped<List<SentInterestOut>>? interests,
  }) {
    return SentInterestsResponse(
      interests: (interests != null ? interests.value : this.interests),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SourceOut {
  const SourceOut({
    required this.allowedUse,
    required this.contentHash,
    required this.fetchError,
    required this.fetchStatus,
    required this.fetchedAt,
    required this.id,
    required this.key,
    required this.publisher,
    required this.tier,
    required this.title,
    required this.url,
    required this.verification,
  });

  factory SourceOut.fromJson(Map<String, dynamic> json) =>
      _$SourceOutFromJson(json);

  static const toJsonFactory = _$SourceOutToJson;
  Map<String, dynamic> toJson() => _$SourceOutToJson(this);

  @JsonKey(name: 'allowed_use', includeIfNull: false)
  final String allowedUse;
  @JsonKey(name: 'content_hash', includeIfNull: false)
  final String? contentHash;
  @JsonKey(name: 'fetch_error', includeIfNull: false)
  final String? fetchError;
  @JsonKey(name: 'fetch_status', includeIfNull: false)
  final String fetchStatus;
  @JsonKey(name: 'fetched_at', includeIfNull: false)
  final DateTime? fetchedAt;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'publisher', includeIfNull: false)
  final String publisher;
  @JsonKey(name: 'tier', includeIfNull: false)
  final String tier;
  @JsonKey(name: 'title', includeIfNull: false)
  final String title;
  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  @JsonKey(name: 'verification', includeIfNull: false)
  final String verification;
  static const fromJsonFactory = _$SourceOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SourceOut &&
            (identical(other.allowedUse, allowedUse) ||
                const DeepCollectionEquality().equals(
                  other.allowedUse,
                  allowedUse,
                )) &&
            (identical(other.contentHash, contentHash) ||
                const DeepCollectionEquality().equals(
                  other.contentHash,
                  contentHash,
                )) &&
            (identical(other.fetchError, fetchError) ||
                const DeepCollectionEquality().equals(
                  other.fetchError,
                  fetchError,
                )) &&
            (identical(other.fetchStatus, fetchStatus) ||
                const DeepCollectionEquality().equals(
                  other.fetchStatus,
                  fetchStatus,
                )) &&
            (identical(other.fetchedAt, fetchedAt) ||
                const DeepCollectionEquality().equals(
                  other.fetchedAt,
                  fetchedAt,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.publisher, publisher) ||
                const DeepCollectionEquality().equals(
                  other.publisher,
                  publisher,
                )) &&
            (identical(other.tier, tier) ||
                const DeepCollectionEquality().equals(other.tier, tier)) &&
            (identical(other.title, title) ||
                const DeepCollectionEquality().equals(other.title, title)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
            (identical(other.verification, verification) ||
                const DeepCollectionEquality().equals(
                  other.verification,
                  verification,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(allowedUse) ^
      const DeepCollectionEquality().hash(contentHash) ^
      const DeepCollectionEquality().hash(fetchError) ^
      const DeepCollectionEquality().hash(fetchStatus) ^
      const DeepCollectionEquality().hash(fetchedAt) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(publisher) ^
      const DeepCollectionEquality().hash(tier) ^
      const DeepCollectionEquality().hash(title) ^
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(verification) ^
      runtimeType.hashCode;
}

extension $SourceOutExtension on SourceOut {
  SourceOut copyWith({
    String? allowedUse,
    String? contentHash,
    String? fetchError,
    String? fetchStatus,
    DateTime? fetchedAt,
    String? id,
    String? key,
    String? publisher,
    String? tier,
    String? title,
    String? url,
    String? verification,
  }) {
    return SourceOut(
      allowedUse: allowedUse ?? this.allowedUse,
      contentHash: contentHash ?? this.contentHash,
      fetchError: fetchError ?? this.fetchError,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      id: id ?? this.id,
      key: key ?? this.key,
      publisher: publisher ?? this.publisher,
      tier: tier ?? this.tier,
      title: title ?? this.title,
      url: url ?? this.url,
      verification: verification ?? this.verification,
    );
  }

  SourceOut copyWithWrapped({
    Wrapped<String>? allowedUse,
    Wrapped<String?>? contentHash,
    Wrapped<String?>? fetchError,
    Wrapped<String>? fetchStatus,
    Wrapped<DateTime?>? fetchedAt,
    Wrapped<String>? id,
    Wrapped<String>? key,
    Wrapped<String>? publisher,
    Wrapped<String>? tier,
    Wrapped<String>? title,
    Wrapped<String>? url,
    Wrapped<String>? verification,
  }) {
    return SourceOut(
      allowedUse: (allowedUse != null ? allowedUse.value : this.allowedUse),
      contentHash: (contentHash != null ? contentHash.value : this.contentHash),
      fetchError: (fetchError != null ? fetchError.value : this.fetchError),
      fetchStatus: (fetchStatus != null ? fetchStatus.value : this.fetchStatus),
      fetchedAt: (fetchedAt != null ? fetchedAt.value : this.fetchedAt),
      id: (id != null ? id.value : this.id),
      key: (key != null ? key.value : this.key),
      publisher: (publisher != null ? publisher.value : this.publisher),
      tier: (tier != null ? tier.value : this.tier),
      title: (title != null ? title.value : this.title),
      url: (url != null ? url.value : this.url),
      verification: (verification != null
          ? verification.value
          : this.verification),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SourcesResponse {
  const SourcesResponse({required this.sources});

  factory SourcesResponse.fromJson(Map<String, dynamic> json) =>
      _$SourcesResponseFromJson(json);

  static const toJsonFactory = _$SourcesResponseToJson;
  Map<String, dynamic> toJson() => _$SourcesResponseToJson(this);

  @JsonKey(name: 'sources', includeIfNull: false, defaultValue: <SourceOut>[])
  final List<SourceOut> sources;
  static const fromJsonFactory = _$SourcesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SourcesResponse &&
            (identical(other.sources, sources) ||
                const DeepCollectionEquality().equals(other.sources, sources)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(sources) ^ runtimeType.hashCode;
}

extension $SourcesResponseExtension on SourcesResponse {
  SourcesResponse copyWith({List<SourceOut>? sources}) {
    return SourcesResponse(sources: sources ?? this.sources);
  }

  SourcesResponse copyWithWrapped({Wrapped<List<SourceOut>>? sources}) {
    return SourcesResponse(
      sources: (sources != null ? sources.value : this.sources),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class StageTemplate {
  const StageTemplate({
    required this.bahar,
    required this.crop,
    required this.id,
    required this.labels,
    required this.sources,
    required this.stages,
    required this.updatedAt,
    required this.version,
  });

  factory StageTemplate.fromJson(Map<String, dynamic> json) =>
      _$StageTemplateFromJson(json);

  static const toJsonFactory = _$StageTemplateToJson;
  Map<String, dynamic> toJson() => _$StageTemplateToJson(this);

  @JsonKey(name: 'bahar', includeIfNull: false)
  final String bahar;
  @JsonKey(name: 'crop', includeIfNull: false)
  final String crop;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'labels', includeIfNull: false)
  final Map<String, dynamic> labels;
  @JsonKey(name: 'sources', includeIfNull: false)
  final Map<String, dynamic> sources;
  @JsonKey(
    name: 'stages',
    includeIfNull: false,
    defaultValue: <TemplateStage>[],
  )
  final List<TemplateStage> stages;
  @JsonKey(name: 'updated_at', includeIfNull: false)
  final DateTime updatedAt;
  @JsonKey(name: 'version', includeIfNull: false)
  final int version;
  static const fromJsonFactory = _$StageTemplateFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StageTemplate &&
            (identical(other.bahar, bahar) ||
                const DeepCollectionEquality().equals(other.bahar, bahar)) &&
            (identical(other.crop, crop) ||
                const DeepCollectionEquality().equals(other.crop, crop)) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)) &&
            (identical(other.sources, sources) ||
                const DeepCollectionEquality().equals(
                  other.sources,
                  sources,
                )) &&
            (identical(other.stages, stages) ||
                const DeepCollectionEquality().equals(other.stages, stages)) &&
            (identical(other.updatedAt, updatedAt) ||
                const DeepCollectionEquality().equals(
                  other.updatedAt,
                  updatedAt,
                )) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bahar) ^
      const DeepCollectionEquality().hash(crop) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(labels) ^
      const DeepCollectionEquality().hash(sources) ^
      const DeepCollectionEquality().hash(stages) ^
      const DeepCollectionEquality().hash(updatedAt) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $StageTemplateExtension on StageTemplate {
  StageTemplate copyWith({
    String? bahar,
    String? crop,
    String? id,
    Map<String, dynamic>? labels,
    Map<String, dynamic>? sources,
    List<TemplateStage>? stages,
    DateTime? updatedAt,
    int? version,
  }) {
    return StageTemplate(
      bahar: bahar ?? this.bahar,
      crop: crop ?? this.crop,
      id: id ?? this.id,
      labels: labels ?? this.labels,
      sources: sources ?? this.sources,
      stages: stages ?? this.stages,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  StageTemplate copyWithWrapped({
    Wrapped<String>? bahar,
    Wrapped<String>? crop,
    Wrapped<String>? id,
    Wrapped<Map<String, dynamic>>? labels,
    Wrapped<Map<String, dynamic>>? sources,
    Wrapped<List<TemplateStage>>? stages,
    Wrapped<DateTime>? updatedAt,
    Wrapped<int>? version,
  }) {
    return StageTemplate(
      bahar: (bahar != null ? bahar.value : this.bahar),
      crop: (crop != null ? crop.value : this.crop),
      id: (id != null ? id.value : this.id),
      labels: (labels != null ? labels.value : this.labels),
      sources: (sources != null ? sources.value : this.sources),
      stages: (stages != null ? stages.value : this.stages),
      updatedAt: (updatedAt != null ? updatedAt.value : this.updatedAt),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class StageTemplatesResponse {
  const StageTemplatesResponse({required this.templates});

  factory StageTemplatesResponse.fromJson(Map<String, dynamic> json) =>
      _$StageTemplatesResponseFromJson(json);

  static const toJsonFactory = _$StageTemplatesResponseToJson;
  Map<String, dynamic> toJson() => _$StageTemplatesResponseToJson(this);

  @JsonKey(
    name: 'templates',
    includeIfNull: false,
    defaultValue: <StageTemplate>[],
  )
  final List<StageTemplate> templates;
  static const fromJsonFactory = _$StageTemplatesResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StageTemplatesResponse &&
            (identical(other.templates, templates) ||
                const DeepCollectionEquality().equals(
                  other.templates,
                  templates,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(templates) ^ runtimeType.hashCode;
}

extension $StageTemplatesResponseExtension on StageTemplatesResponse {
  StageTemplatesResponse copyWith({List<StageTemplate>? templates}) {
    return StageTemplatesResponse(templates: templates ?? this.templates);
  }

  StageTemplatesResponse copyWithWrapped({
    Wrapped<List<StageTemplate>>? templates,
  }) {
    return StageTemplatesResponse(
      templates: (templates != null ? templates.value : this.templates),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SubjectDetailOut {
  const SubjectDetailOut({required this.history, required this.subject});

  factory SubjectDetailOut.fromJson(Map<String, dynamic> json) =>
      _$SubjectDetailOutFromJson(json);

  static const toJsonFactory = _$SubjectDetailOutToJson;
  Map<String, dynamic> toJson() => _$SubjectDetailOutToJson(this);

  @JsonKey(
    name: 'history',
    includeIfNull: false,
    defaultValue: <VerificationOut>[],
  )
  final List<VerificationOut> history;
  @JsonKey(name: 'subject', includeIfNull: false)
  final SubjectOut subject;
  static const fromJsonFactory = _$SubjectDetailOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubjectDetailOut &&
            (identical(other.history, history) ||
                const DeepCollectionEquality().equals(
                  other.history,
                  history,
                )) &&
            (identical(other.subject, subject) ||
                const DeepCollectionEquality().equals(other.subject, subject)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(history) ^
      const DeepCollectionEquality().hash(subject) ^
      runtimeType.hashCode;
}

extension $SubjectDetailOutExtension on SubjectDetailOut {
  SubjectDetailOut copyWith({
    List<VerificationOut>? history,
    SubjectOut? subject,
  }) {
    return SubjectDetailOut(
      history: history ?? this.history,
      subject: subject ?? this.subject,
    );
  }

  SubjectDetailOut copyWithWrapped({
    Wrapped<List<VerificationOut>>? history,
    Wrapped<SubjectOut>? subject,
  }) {
    return SubjectDetailOut(
      history: (history != null ? history.value : this.history),
      subject: (subject != null ? subject.value : this.subject),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SubjectOut {
  const SubjectOut({
    required this.documentKeys,
    required this.fields,
    this.flags,
    required this.name,
    this.registrationFix,
    required this.status,
    required this.subjectId,
    required this.subjectType,
    required this.waitingSince,
  });

  factory SubjectOut.fromJson(Map<String, dynamic> json) =>
      _$SubjectOutFromJson(json);

  static const toJsonFactory = _$SubjectOutToJson;
  Map<String, dynamic> toJson() => _$SubjectOutToJson(this);

  @JsonKey(
    name: 'document_keys',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String> documentKeys;
  @JsonKey(name: 'fields', includeIfNull: false)
  final Map<String, dynamic> fields;
  @JsonKey(name: 'flags', includeIfNull: false, defaultValue: <String>[])
  final List<String>? flags;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  @JsonKey(name: 'registration_fix', includeIfNull: false)
  final AdminFixOut? registrationFix;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'subject_id', includeIfNull: false)
  final String subjectId;
  @JsonKey(name: 'subject_type', includeIfNull: false)
  final String subjectType;
  @JsonKey(name: 'waiting_since', includeIfNull: false)
  final DateTime waitingSince;
  static const fromJsonFactory = _$SubjectOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubjectOut &&
            (identical(other.documentKeys, documentKeys) ||
                const DeepCollectionEquality().equals(
                  other.documentKeys,
                  documentKeys,
                )) &&
            (identical(other.fields, fields) ||
                const DeepCollectionEquality().equals(other.fields, fields)) &&
            (identical(other.flags, flags) ||
                const DeepCollectionEquality().equals(other.flags, flags)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)) &&
            (identical(other.registrationFix, registrationFix) ||
                const DeepCollectionEquality().equals(
                  other.registrationFix,
                  registrationFix,
                )) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.subjectId, subjectId) ||
                const DeepCollectionEquality().equals(
                  other.subjectId,
                  subjectId,
                )) &&
            (identical(other.subjectType, subjectType) ||
                const DeepCollectionEquality().equals(
                  other.subjectType,
                  subjectType,
                )) &&
            (identical(other.waitingSince, waitingSince) ||
                const DeepCollectionEquality().equals(
                  other.waitingSince,
                  waitingSince,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(documentKeys) ^
      const DeepCollectionEquality().hash(fields) ^
      const DeepCollectionEquality().hash(flags) ^
      const DeepCollectionEquality().hash(name) ^
      const DeepCollectionEquality().hash(registrationFix) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(subjectId) ^
      const DeepCollectionEquality().hash(subjectType) ^
      const DeepCollectionEquality().hash(waitingSince) ^
      runtimeType.hashCode;
}

extension $SubjectOutExtension on SubjectOut {
  SubjectOut copyWith({
    List<String>? documentKeys,
    Map<String, dynamic>? fields,
    List<String>? flags,
    String? name,
    AdminFixOut? registrationFix,
    String? status,
    String? subjectId,
    String? subjectType,
    DateTime? waitingSince,
  }) {
    return SubjectOut(
      documentKeys: documentKeys ?? this.documentKeys,
      fields: fields ?? this.fields,
      flags: flags ?? this.flags,
      name: name ?? this.name,
      registrationFix: registrationFix ?? this.registrationFix,
      status: status ?? this.status,
      subjectId: subjectId ?? this.subjectId,
      subjectType: subjectType ?? this.subjectType,
      waitingSince: waitingSince ?? this.waitingSince,
    );
  }

  SubjectOut copyWithWrapped({
    Wrapped<List<String>>? documentKeys,
    Wrapped<Map<String, dynamic>>? fields,
    Wrapped<List<String>?>? flags,
    Wrapped<String>? name,
    Wrapped<AdminFixOut?>? registrationFix,
    Wrapped<String>? status,
    Wrapped<String>? subjectId,
    Wrapped<String>? subjectType,
    Wrapped<DateTime>? waitingSince,
  }) {
    return SubjectOut(
      documentKeys: (documentKeys != null
          ? documentKeys.value
          : this.documentKeys),
      fields: (fields != null ? fields.value : this.fields),
      flags: (flags != null ? flags.value : this.flags),
      name: (name != null ? name.value : this.name),
      registrationFix: (registrationFix != null
          ? registrationFix.value
          : this.registrationFix),
      status: (status != null ? status.value : this.status),
      subjectId: (subjectId != null ? subjectId.value : this.subjectId),
      subjectType: (subjectType != null ? subjectType.value : this.subjectType),
      waitingSince: (waitingSince != null
          ? waitingSince.value
          : this.waitingSince),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SubscriptionOut {
  const SubscriptionOut({
    required this.id,
    required this.periodEnd,
    required this.periodStart,
    required this.planKey,
    required this.provider,
    required this.reason,
    required this.state,
    required this.subjectId,
    required this.subjectType,
  });

  factory SubscriptionOut.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionOutFromJson(json);

  static const toJsonFactory = _$SubscriptionOutToJson;
  Map<String, dynamic> toJson() => _$SubscriptionOutToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'period_end', includeIfNull: false)
  final DateTime periodEnd;
  @JsonKey(name: 'period_start', includeIfNull: false)
  final DateTime periodStart;
  @JsonKey(name: 'plan_key', includeIfNull: false)
  final String planKey;
  @JsonKey(name: 'provider', includeIfNull: false)
  final String provider;
  @JsonKey(name: 'reason', includeIfNull: false)
  final String? reason;
  @JsonKey(name: 'state', includeIfNull: false)
  final String state;
  @JsonKey(name: 'subject_id', includeIfNull: false)
  final String subjectId;
  @JsonKey(name: 'subject_type', includeIfNull: false)
  final String subjectType;
  static const fromJsonFactory = _$SubscriptionOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubscriptionOut &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.periodEnd, periodEnd) ||
                const DeepCollectionEquality().equals(
                  other.periodEnd,
                  periodEnd,
                )) &&
            (identical(other.periodStart, periodStart) ||
                const DeepCollectionEquality().equals(
                  other.periodStart,
                  periodStart,
                )) &&
            (identical(other.planKey, planKey) ||
                const DeepCollectionEquality().equals(
                  other.planKey,
                  planKey,
                )) &&
            (identical(other.provider, provider) ||
                const DeepCollectionEquality().equals(
                  other.provider,
                  provider,
                )) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.state, state) ||
                const DeepCollectionEquality().equals(other.state, state)) &&
            (identical(other.subjectId, subjectId) ||
                const DeepCollectionEquality().equals(
                  other.subjectId,
                  subjectId,
                )) &&
            (identical(other.subjectType, subjectType) ||
                const DeepCollectionEquality().equals(
                  other.subjectType,
                  subjectType,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(periodEnd) ^
      const DeepCollectionEquality().hash(periodStart) ^
      const DeepCollectionEquality().hash(planKey) ^
      const DeepCollectionEquality().hash(provider) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(state) ^
      const DeepCollectionEquality().hash(subjectId) ^
      const DeepCollectionEquality().hash(subjectType) ^
      runtimeType.hashCode;
}

extension $SubscriptionOutExtension on SubscriptionOut {
  SubscriptionOut copyWith({
    String? id,
    DateTime? periodEnd,
    DateTime? periodStart,
    String? planKey,
    String? provider,
    String? reason,
    String? state,
    String? subjectId,
    String? subjectType,
  }) {
    return SubscriptionOut(
      id: id ?? this.id,
      periodEnd: periodEnd ?? this.periodEnd,
      periodStart: periodStart ?? this.periodStart,
      planKey: planKey ?? this.planKey,
      provider: provider ?? this.provider,
      reason: reason ?? this.reason,
      state: state ?? this.state,
      subjectId: subjectId ?? this.subjectId,
      subjectType: subjectType ?? this.subjectType,
    );
  }

  SubscriptionOut copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<DateTime>? periodEnd,
    Wrapped<DateTime>? periodStart,
    Wrapped<String>? planKey,
    Wrapped<String>? provider,
    Wrapped<String?>? reason,
    Wrapped<String>? state,
    Wrapped<String>? subjectId,
    Wrapped<String>? subjectType,
  }) {
    return SubscriptionOut(
      id: (id != null ? id.value : this.id),
      periodEnd: (periodEnd != null ? periodEnd.value : this.periodEnd),
      periodStart: (periodStart != null ? periodStart.value : this.periodStart),
      planKey: (planKey != null ? planKey.value : this.planKey),
      provider: (provider != null ? provider.value : this.provider),
      reason: (reason != null ? reason.value : this.reason),
      state: (state != null ? state.value : this.state),
      subjectId: (subjectId != null ? subjectId.value : this.subjectId),
      subjectType: (subjectType != null ? subjectType.value : this.subjectType),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SubscriptionsResponse {
  const SubscriptionsResponse({required this.subscriptions});

  factory SubscriptionsResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionsResponseFromJson(json);

  static const toJsonFactory = _$SubscriptionsResponseToJson;
  Map<String, dynamic> toJson() => _$SubscriptionsResponseToJson(this);

  @JsonKey(
    name: 'subscriptions',
    includeIfNull: false,
    defaultValue: <SubscriptionOut>[],
  )
  final List<SubscriptionOut> subscriptions;
  static const fromJsonFactory = _$SubscriptionsResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubscriptionsResponse &&
            (identical(other.subscriptions, subscriptions) ||
                const DeepCollectionEquality().equals(
                  other.subscriptions,
                  subscriptions,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(subscriptions) ^ runtimeType.hashCode;
}

extension $SubscriptionsResponseExtension on SubscriptionsResponse {
  SubscriptionsResponse copyWith({List<SubscriptionOut>? subscriptions}) {
    return SubscriptionsResponse(
      subscriptions: subscriptions ?? this.subscriptions,
    );
  }

  SubscriptionsResponse copyWithWrapped({
    Wrapped<List<SubscriptionOut>>? subscriptions,
  }) {
    return SubscriptionsResponse(
      subscriptions: (subscriptions != null
          ? subscriptions.value
          : this.subscriptions),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SynonymOut {
  const SynonymOut({required this.activeIngredient, required this.name});

  factory SynonymOut.fromJson(Map<String, dynamic> json) =>
      _$SynonymOutFromJson(json);

  static const toJsonFactory = _$SynonymOutToJson;
  Map<String, dynamic> toJson() => _$SynonymOutToJson(this);

  @JsonKey(name: 'active_ingredient', includeIfNull: false)
  final String activeIngredient;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  static const fromJsonFactory = _$SynonymOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SynonymOut &&
            (identical(other.activeIngredient, activeIngredient) ||
                const DeepCollectionEquality().equals(
                  other.activeIngredient,
                  activeIngredient,
                )) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(activeIngredient) ^
      const DeepCollectionEquality().hash(name) ^
      runtimeType.hashCode;
}

extension $SynonymOutExtension on SynonymOut {
  SynonymOut copyWith({String? activeIngredient, String? name}) {
    return SynonymOut(
      activeIngredient: activeIngredient ?? this.activeIngredient,
      name: name ?? this.name,
    );
  }

  SynonymOut copyWithWrapped({
    Wrapped<String>? activeIngredient,
    Wrapped<String>? name,
  }) {
    return SynonymOut(
      activeIngredient: (activeIngredient != null
          ? activeIngredient.value
          : this.activeIngredient),
      name: (name != null ? name.value : this.name),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class TagCountOut {
  const TagCountOut({
    required this.count,
    required this.key,
    required this.labelEn,
    required this.labelHi,
    required this.labelMr,
    required this.polarity,
    required this.questionKey,
    required this.tagId,
  });

  factory TagCountOut.fromJson(Map<String, dynamic> json) =>
      _$TagCountOutFromJson(json);

  static const toJsonFactory = _$TagCountOutToJson;
  Map<String, dynamic> toJson() => _$TagCountOutToJson(this);

  @JsonKey(name: 'count', includeIfNull: false)
  final int count;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'label_en', includeIfNull: false)
  final String labelEn;
  @JsonKey(name: 'label_hi', includeIfNull: false)
  final String labelHi;
  @JsonKey(name: 'label_mr', includeIfNull: false)
  final String labelMr;
  @JsonKey(name: 'polarity', includeIfNull: false)
  final String polarity;
  @JsonKey(name: 'question_key', includeIfNull: false)
  final String questionKey;
  @JsonKey(name: 'tag_id', includeIfNull: false)
  final String tagId;
  static const fromJsonFactory = _$TagCountOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TagCountOut &&
            (identical(other.count, count) ||
                const DeepCollectionEquality().equals(other.count, count)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.labelEn, labelEn) ||
                const DeepCollectionEquality().equals(
                  other.labelEn,
                  labelEn,
                )) &&
            (identical(other.labelHi, labelHi) ||
                const DeepCollectionEquality().equals(
                  other.labelHi,
                  labelHi,
                )) &&
            (identical(other.labelMr, labelMr) ||
                const DeepCollectionEquality().equals(
                  other.labelMr,
                  labelMr,
                )) &&
            (identical(other.polarity, polarity) ||
                const DeepCollectionEquality().equals(
                  other.polarity,
                  polarity,
                )) &&
            (identical(other.questionKey, questionKey) ||
                const DeepCollectionEquality().equals(
                  other.questionKey,
                  questionKey,
                )) &&
            (identical(other.tagId, tagId) ||
                const DeepCollectionEquality().equals(other.tagId, tagId)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(count) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(labelEn) ^
      const DeepCollectionEquality().hash(labelHi) ^
      const DeepCollectionEquality().hash(labelMr) ^
      const DeepCollectionEquality().hash(polarity) ^
      const DeepCollectionEquality().hash(questionKey) ^
      const DeepCollectionEquality().hash(tagId) ^
      runtimeType.hashCode;
}

extension $TagCountOutExtension on TagCountOut {
  TagCountOut copyWith({
    int? count,
    String? key,
    String? labelEn,
    String? labelHi,
    String? labelMr,
    String? polarity,
    String? questionKey,
    String? tagId,
  }) {
    return TagCountOut(
      count: count ?? this.count,
      key: key ?? this.key,
      labelEn: labelEn ?? this.labelEn,
      labelHi: labelHi ?? this.labelHi,
      labelMr: labelMr ?? this.labelMr,
      polarity: polarity ?? this.polarity,
      questionKey: questionKey ?? this.questionKey,
      tagId: tagId ?? this.tagId,
    );
  }

  TagCountOut copyWithWrapped({
    Wrapped<int>? count,
    Wrapped<String>? key,
    Wrapped<String>? labelEn,
    Wrapped<String>? labelHi,
    Wrapped<String>? labelMr,
    Wrapped<String>? polarity,
    Wrapped<String>? questionKey,
    Wrapped<String>? tagId,
  }) {
    return TagCountOut(
      count: (count != null ? count.value : this.count),
      key: (key != null ? key.value : this.key),
      labelEn: (labelEn != null ? labelEn.value : this.labelEn),
      labelHi: (labelHi != null ? labelHi.value : this.labelHi),
      labelMr: (labelMr != null ? labelMr.value : this.labelMr),
      polarity: (polarity != null ? polarity.value : this.polarity),
      questionKey: (questionKey != null ? questionKey.value : this.questionKey),
      tagId: (tagId != null ? tagId.value : this.tagId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class TemplateStage {
  const TemplateStage({
    required this.anchor,
    required this.key,
    required this.labels,
    required this.offsetDaysMax,
    required this.offsetDaysMin,
    required this.sourceIds,
  });

  factory TemplateStage.fromJson(Map<String, dynamic> json) =>
      _$TemplateStageFromJson(json);

  static const toJsonFactory = _$TemplateStageToJson;
  Map<String, dynamic> toJson() => _$TemplateStageToJson(this);

  @JsonKey(name: 'anchor', includeIfNull: false)
  final String anchor;
  @JsonKey(name: 'key', includeIfNull: false)
  final String key;
  @JsonKey(name: 'labels', includeIfNull: false)
  final Map<String, dynamic> labels;
  @JsonKey(name: 'offset_days_max', includeIfNull: false)
  final int offsetDaysMax;
  @JsonKey(name: 'offset_days_min', includeIfNull: false)
  final int offsetDaysMin;
  @JsonKey(name: 'source_ids', includeIfNull: false, defaultValue: <String>[])
  final List<String> sourceIds;
  static const fromJsonFactory = _$TemplateStageFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TemplateStage &&
            (identical(other.anchor, anchor) ||
                const DeepCollectionEquality().equals(other.anchor, anchor)) &&
            (identical(other.key, key) ||
                const DeepCollectionEquality().equals(other.key, key)) &&
            (identical(other.labels, labels) ||
                const DeepCollectionEquality().equals(other.labels, labels)) &&
            (identical(other.offsetDaysMax, offsetDaysMax) ||
                const DeepCollectionEquality().equals(
                  other.offsetDaysMax,
                  offsetDaysMax,
                )) &&
            (identical(other.offsetDaysMin, offsetDaysMin) ||
                const DeepCollectionEquality().equals(
                  other.offsetDaysMin,
                  offsetDaysMin,
                )) &&
            (identical(other.sourceIds, sourceIds) ||
                const DeepCollectionEquality().equals(
                  other.sourceIds,
                  sourceIds,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(anchor) ^
      const DeepCollectionEquality().hash(key) ^
      const DeepCollectionEquality().hash(labels) ^
      const DeepCollectionEquality().hash(offsetDaysMax) ^
      const DeepCollectionEquality().hash(offsetDaysMin) ^
      const DeepCollectionEquality().hash(sourceIds) ^
      runtimeType.hashCode;
}

extension $TemplateStageExtension on TemplateStage {
  TemplateStage copyWith({
    String? anchor,
    String? key,
    Map<String, dynamic>? labels,
    int? offsetDaysMax,
    int? offsetDaysMin,
    List<String>? sourceIds,
  }) {
    return TemplateStage(
      anchor: anchor ?? this.anchor,
      key: key ?? this.key,
      labels: labels ?? this.labels,
      offsetDaysMax: offsetDaysMax ?? this.offsetDaysMax,
      offsetDaysMin: offsetDaysMin ?? this.offsetDaysMin,
      sourceIds: sourceIds ?? this.sourceIds,
    );
  }

  TemplateStage copyWithWrapped({
    Wrapped<String>? anchor,
    Wrapped<String>? key,
    Wrapped<Map<String, dynamic>>? labels,
    Wrapped<int>? offsetDaysMax,
    Wrapped<int>? offsetDaysMin,
    Wrapped<List<String>>? sourceIds,
  }) {
    return TemplateStage(
      anchor: (anchor != null ? anchor.value : this.anchor),
      key: (key != null ? key.value : this.key),
      labels: (labels != null ? labels.value : this.labels),
      offsetDaysMax: (offsetDaysMax != null
          ? offsetDaysMax.value
          : this.offsetDaysMax),
      offsetDaysMin: (offsetDaysMin != null
          ? offsetDaysMin.value
          : this.offsetDaysMin),
      sourceIds: (sourceIds != null ? sourceIds.value : this.sourceIds),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class TermsDocOut {
  const TermsDocOut({
    required this.kind,
    required this.url,
    required this.version,
  });

  factory TermsDocOut.fromJson(Map<String, dynamic> json) =>
      _$TermsDocOutFromJson(json);

  static const toJsonFactory = _$TermsDocOutToJson;
  Map<String, dynamic> toJson() => _$TermsDocOutToJson(this);

  @JsonKey(
    name: 'kind',
    includeIfNull: false,
    toJson: termsDocOutKindToJson,
    fromJson: termsDocOutKindFromJson,
  )
  final enums.TermsDocOutKind kind;
  @JsonKey(name: 'url', includeIfNull: false)
  final String? url;
  @JsonKey(name: 'version', includeIfNull: false)
  final String version;
  static const fromJsonFactory = _$TermsDocOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TermsDocOut &&
            (identical(other.kind, kind) ||
                const DeepCollectionEquality().equals(other.kind, kind)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(kind) ^
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $TermsDocOutExtension on TermsDocOut {
  TermsDocOut copyWith({
    enums.TermsDocOutKind? kind,
    String? url,
    String? version,
  }) {
    return TermsDocOut(
      kind: kind ?? this.kind,
      url: url ?? this.url,
      version: version ?? this.version,
    );
  }

  TermsDocOut copyWithWrapped({
    Wrapped<enums.TermsDocOutKind>? kind,
    Wrapped<String?>? url,
    Wrapped<String>? version,
  }) {
    return TermsDocOut(
      kind: (kind != null ? kind.value : this.kind),
      url: (url != null ? url.value : this.url),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class TermsOut {
  const TermsOut({required this.documents, required this.grievanceOfficer});

  factory TermsOut.fromJson(Map<String, dynamic> json) =>
      _$TermsOutFromJson(json);

  static const toJsonFactory = _$TermsOutToJson;
  Map<String, dynamic> toJson() => _$TermsOutToJson(this);

  @JsonKey(
    name: 'documents',
    includeIfNull: false,
    defaultValue: <TermsDocOut>[],
  )
  final List<TermsDocOut> documents;
  @JsonKey(name: 'grievance_officer', includeIfNull: false)
  final GrievanceOfficerOut grievanceOfficer;
  static const fromJsonFactory = _$TermsOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TermsOut &&
            (identical(other.documents, documents) ||
                const DeepCollectionEquality().equals(
                  other.documents,
                  documents,
                )) &&
            (identical(other.grievanceOfficer, grievanceOfficer) ||
                const DeepCollectionEquality().equals(
                  other.grievanceOfficer,
                  grievanceOfficer,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(documents) ^
      const DeepCollectionEquality().hash(grievanceOfficer) ^
      runtimeType.hashCode;
}

extension $TermsOutExtension on TermsOut {
  TermsOut copyWith({
    List<TermsDocOut>? documents,
    GrievanceOfficerOut? grievanceOfficer,
  }) {
    return TermsOut(
      documents: documents ?? this.documents,
      grievanceOfficer: grievanceOfficer ?? this.grievanceOfficer,
    );
  }

  TermsOut copyWithWrapped({
    Wrapped<List<TermsDocOut>>? documents,
    Wrapped<GrievanceOfficerOut>? grievanceOfficer,
  }) {
    return TermsOut(
      documents: (documents != null ? documents.value : this.documents),
      grievanceOfficer: (grievanceOfficer != null
          ? grievanceOfficer.value
          : this.grievanceOfficer),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ValidationError {
  const ValidationError({
    required this.loc,
    required this.msg,
    required this.type,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) =>
      _$ValidationErrorFromJson(json);

  static const toJsonFactory = _$ValidationErrorToJson;
  Map<String, dynamic> toJson() => _$ValidationErrorToJson(this);

  @JsonKey(name: 'loc', includeIfNull: false, defaultValue: <Object>[])
  final List<Object> loc;
  @JsonKey(name: 'msg', includeIfNull: false)
  final String msg;
  @JsonKey(name: 'type', includeIfNull: false)
  final String type;
  static const fromJsonFactory = _$ValidationErrorFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ValidationError &&
            (identical(other.loc, loc) ||
                const DeepCollectionEquality().equals(other.loc, loc)) &&
            (identical(other.msg, msg) ||
                const DeepCollectionEquality().equals(other.msg, msg)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(loc) ^
      const DeepCollectionEquality().hash(msg) ^
      const DeepCollectionEquality().hash(type) ^
      runtimeType.hashCode;
}

extension $ValidationErrorExtension on ValidationError {
  ValidationError copyWith({List<Object>? loc, String? msg, String? type}) {
    return ValidationError(
      loc: loc ?? this.loc,
      msg: msg ?? this.msg,
      type: type ?? this.type,
    );
  }

  ValidationError copyWithWrapped({
    Wrapped<List<Object>>? loc,
    Wrapped<String>? msg,
    Wrapped<String>? type,
  }) {
    return ValidationError(
      loc: (loc != null ? loc.value : this.loc),
      msg: (msg != null ? msg.value : this.msg),
      type: (type != null ? type.value : this.type),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class VerificationOut {
  const VerificationOut({
    required this.checkedAt,
    required this.checkedBy,
    required this.createdAt,
    required this.documentKeys,
    required this.id,
    required this.reason,
    required this.status,
  });

  factory VerificationOut.fromJson(Map<String, dynamic> json) =>
      _$VerificationOutFromJson(json);

  static const toJsonFactory = _$VerificationOutToJson;
  Map<String, dynamic> toJson() => _$VerificationOutToJson(this);

  @JsonKey(name: 'checked_at', includeIfNull: false)
  final DateTime? checkedAt;
  @JsonKey(name: 'checked_by', includeIfNull: false)
  final String? checkedBy;
  @JsonKey(name: 'created_at', includeIfNull: false)
  final DateTime createdAt;
  @JsonKey(
    name: 'document_keys',
    includeIfNull: false,
    defaultValue: <String>[],
  )
  final List<String> documentKeys;
  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'reason', includeIfNull: false)
  final String? reason;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  static const fromJsonFactory = _$VerificationOutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is VerificationOut &&
            (identical(other.checkedAt, checkedAt) ||
                const DeepCollectionEquality().equals(
                  other.checkedAt,
                  checkedAt,
                )) &&
            (identical(other.checkedBy, checkedBy) ||
                const DeepCollectionEquality().equals(
                  other.checkedBy,
                  checkedBy,
                )) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.documentKeys, documentKeys) ||
                const DeepCollectionEquality().equals(
                  other.documentKeys,
                  documentKeys,
                )) &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.reason, reason) ||
                const DeepCollectionEquality().equals(other.reason, reason)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(checkedAt) ^
      const DeepCollectionEquality().hash(checkedBy) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(documentKeys) ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(reason) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $VerificationOutExtension on VerificationOut {
  VerificationOut copyWith({
    DateTime? checkedAt,
    String? checkedBy,
    DateTime? createdAt,
    List<String>? documentKeys,
    String? id,
    String? reason,
    String? status,
  }) {
    return VerificationOut(
      checkedAt: checkedAt ?? this.checkedAt,
      checkedBy: checkedBy ?? this.checkedBy,
      createdAt: createdAt ?? this.createdAt,
      documentKeys: documentKeys ?? this.documentKeys,
      id: id ?? this.id,
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  VerificationOut copyWithWrapped({
    Wrapped<DateTime?>? checkedAt,
    Wrapped<String?>? checkedBy,
    Wrapped<DateTime>? createdAt,
    Wrapped<List<String>>? documentKeys,
    Wrapped<String>? id,
    Wrapped<String?>? reason,
    Wrapped<String>? status,
  }) {
    return VerificationOut(
      checkedAt: (checkedAt != null ? checkedAt.value : this.checkedAt),
      checkedBy: (checkedBy != null ? checkedBy.value : this.checkedBy),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      documentKeys: (documentKeys != null
          ? documentKeys.value
          : this.documentKeys),
      id: (id != null ? id.value : this.id),
      reason: (reason != null ? reason.value : this.reason),
      status: (status != null ? status.value : this.status),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class WeatherAlert {
  const WeatherAlert({
    this.action,
    required this.firstDay,
    required this.ruleKey,
    required this.source,
    required this.status,
    required this.text,
    required this.units,
    required this.value,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) =>
      _$WeatherAlertFromJson(json);

  static const toJsonFactory = _$WeatherAlertToJson;
  Map<String, dynamic> toJson() => _$WeatherAlertToJson(this);

  @JsonKey(name: 'action', includeIfNull: false)
  final String? action;
  @JsonKey(name: 'first_day', includeIfNull: false, toJson: _dateToJson)
  final DateTime firstDay;
  @JsonKey(name: 'rule_key', includeIfNull: false)
  final String ruleKey;
  @JsonKey(name: 'source', includeIfNull: false)
  final String source;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'text', includeIfNull: false)
  final String text;
  @JsonKey(name: 'units', includeIfNull: false)
  final double? units;
  @JsonKey(name: 'value', includeIfNull: false)
  final double value;
  static const fromJsonFactory = _$WeatherAlertFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WeatherAlert &&
            (identical(other.action, action) ||
                const DeepCollectionEquality().equals(other.action, action)) &&
            (identical(other.firstDay, firstDay) ||
                const DeepCollectionEquality().equals(
                  other.firstDay,
                  firstDay,
                )) &&
            (identical(other.ruleKey, ruleKey) ||
                const DeepCollectionEquality().equals(
                  other.ruleKey,
                  ruleKey,
                )) &&
            (identical(other.source, source) ||
                const DeepCollectionEquality().equals(other.source, source)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.text, text) ||
                const DeepCollectionEquality().equals(other.text, text)) &&
            (identical(other.units, units) ||
                const DeepCollectionEquality().equals(other.units, units)) &&
            (identical(other.value, value) ||
                const DeepCollectionEquality().equals(other.value, value)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(action) ^
      const DeepCollectionEquality().hash(firstDay) ^
      const DeepCollectionEquality().hash(ruleKey) ^
      const DeepCollectionEquality().hash(source) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(text) ^
      const DeepCollectionEquality().hash(units) ^
      const DeepCollectionEquality().hash(value) ^
      runtimeType.hashCode;
}

extension $WeatherAlertExtension on WeatherAlert {
  WeatherAlert copyWith({
    String? action,
    DateTime? firstDay,
    String? ruleKey,
    String? source,
    String? status,
    String? text,
    double? units,
    double? value,
  }) {
    return WeatherAlert(
      action: action ?? this.action,
      firstDay: firstDay ?? this.firstDay,
      ruleKey: ruleKey ?? this.ruleKey,
      source: source ?? this.source,
      status: status ?? this.status,
      text: text ?? this.text,
      units: units ?? this.units,
      value: value ?? this.value,
    );
  }

  WeatherAlert copyWithWrapped({
    Wrapped<String?>? action,
    Wrapped<DateTime>? firstDay,
    Wrapped<String>? ruleKey,
    Wrapped<String>? source,
    Wrapped<String>? status,
    Wrapped<String>? text,
    Wrapped<double?>? units,
    Wrapped<double>? value,
  }) {
    return WeatherAlert(
      action: (action != null ? action.value : this.action),
      firstDay: (firstDay != null ? firstDay.value : this.firstDay),
      ruleKey: (ruleKey != null ? ruleKey.value : this.ruleKey),
      source: (source != null ? source.value : this.source),
      status: (status != null ? status.value : this.status),
      text: (text != null ? text.value : this.text),
      units: (units != null ? units.value : this.units),
      value: (value != null ? value.value : this.value),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class WeatherDay {
  const WeatherDay({
    required this.day,
    required this.precipMm,
    required this.rhMeanPct,
    required this.tMaxC,
    required this.tMinC,
    this.weatherCode,
    required this.windGustKmh,
  });

  factory WeatherDay.fromJson(Map<String, dynamic> json) =>
      _$WeatherDayFromJson(json);

  static const toJsonFactory = _$WeatherDayToJson;
  Map<String, dynamic> toJson() => _$WeatherDayToJson(this);

  @JsonKey(name: 'day', includeIfNull: false, toJson: _dateToJson)
  final DateTime day;
  @JsonKey(name: 'precip_mm', includeIfNull: false)
  final double? precipMm;
  @JsonKey(name: 'rh_mean_pct', includeIfNull: false)
  final double? rhMeanPct;
  @JsonKey(name: 't_max_c', includeIfNull: false)
  final double? tMaxC;
  @JsonKey(name: 't_min_c', includeIfNull: false)
  final double? tMinC;
  @JsonKey(name: 'weather_code', includeIfNull: false)
  final double? weatherCode;
  @JsonKey(name: 'wind_gust_kmh', includeIfNull: false)
  final double? windGustKmh;
  static const fromJsonFactory = _$WeatherDayFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WeatherDay &&
            (identical(other.day, day) ||
                const DeepCollectionEquality().equals(other.day, day)) &&
            (identical(other.precipMm, precipMm) ||
                const DeepCollectionEquality().equals(
                  other.precipMm,
                  precipMm,
                )) &&
            (identical(other.rhMeanPct, rhMeanPct) ||
                const DeepCollectionEquality().equals(
                  other.rhMeanPct,
                  rhMeanPct,
                )) &&
            (identical(other.tMaxC, tMaxC) ||
                const DeepCollectionEquality().equals(other.tMaxC, tMaxC)) &&
            (identical(other.tMinC, tMinC) ||
                const DeepCollectionEquality().equals(other.tMinC, tMinC)) &&
            (identical(other.weatherCode, weatherCode) ||
                const DeepCollectionEquality().equals(
                  other.weatherCode,
                  weatherCode,
                )) &&
            (identical(other.windGustKmh, windGustKmh) ||
                const DeepCollectionEquality().equals(
                  other.windGustKmh,
                  windGustKmh,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(day) ^
      const DeepCollectionEquality().hash(precipMm) ^
      const DeepCollectionEquality().hash(rhMeanPct) ^
      const DeepCollectionEquality().hash(tMaxC) ^
      const DeepCollectionEquality().hash(tMinC) ^
      const DeepCollectionEquality().hash(weatherCode) ^
      const DeepCollectionEquality().hash(windGustKmh) ^
      runtimeType.hashCode;
}

extension $WeatherDayExtension on WeatherDay {
  WeatherDay copyWith({
    DateTime? day,
    double? precipMm,
    double? rhMeanPct,
    double? tMaxC,
    double? tMinC,
    double? weatherCode,
    double? windGustKmh,
  }) {
    return WeatherDay(
      day: day ?? this.day,
      precipMm: precipMm ?? this.precipMm,
      rhMeanPct: rhMeanPct ?? this.rhMeanPct,
      tMaxC: tMaxC ?? this.tMaxC,
      tMinC: tMinC ?? this.tMinC,
      weatherCode: weatherCode ?? this.weatherCode,
      windGustKmh: windGustKmh ?? this.windGustKmh,
    );
  }

  WeatherDay copyWithWrapped({
    Wrapped<DateTime>? day,
    Wrapped<double?>? precipMm,
    Wrapped<double?>? rhMeanPct,
    Wrapped<double?>? tMaxC,
    Wrapped<double?>? tMinC,
    Wrapped<double?>? weatherCode,
    Wrapped<double?>? windGustKmh,
  }) {
    return WeatherDay(
      day: (day != null ? day.value : this.day),
      precipMm: (precipMm != null ? precipMm.value : this.precipMm),
      rhMeanPct: (rhMeanPct != null ? rhMeanPct.value : this.rhMeanPct),
      tMaxC: (tMaxC != null ? tMaxC.value : this.tMaxC),
      tMinC: (tMinC != null ? tMinC.value : this.tMinC),
      weatherCode: (weatherCode != null ? weatherCode.value : this.weatherCode),
      windGustKmh: (windGustKmh != null ? windGustKmh.value : this.windGustKmh),
    );
  }
}

String? acceptInRoleNullableToJson(enums.AcceptInRole? acceptInRole) {
  return acceptInRole?.value;
}

String? acceptInRoleToJson(enums.AcceptInRole acceptInRole) {
  return acceptInRole.value;
}

enums.AcceptInRole acceptInRoleFromJson(
  Object? acceptInRole, [
  enums.AcceptInRole? defaultValue,
]) {
  return enums.AcceptInRole.values.firstWhereOrNull(
        (e) => e.value == acceptInRole,
      ) ??
      defaultValue ??
      enums.AcceptInRole.swaggerGeneratedUnknown;
}

enums.AcceptInRole? acceptInRoleNullableFromJson(
  Object? acceptInRole, [
  enums.AcceptInRole? defaultValue,
]) {
  if (acceptInRole == null) {
    return null;
  }
  return enums.AcceptInRole.values.firstWhereOrNull(
        (e) => e.value == acceptInRole,
      ) ??
      defaultValue;
}

String acceptInRoleExplodedListToJson(List<enums.AcceptInRole>? acceptInRole) {
  return acceptInRole?.map((e) => e.value!).join(',') ?? '';
}

List<String> acceptInRoleListToJson(List<enums.AcceptInRole>? acceptInRole) {
  if (acceptInRole == null) {
    return [];
  }

  return acceptInRole.map((e) => e.value!).toList();
}

List<enums.AcceptInRole> acceptInRoleListFromJson(
  List? acceptInRole, [
  List<enums.AcceptInRole>? defaultValue,
]) {
  if (acceptInRole == null) {
    return defaultValue ?? [];
  }

  return acceptInRole.map((e) => acceptInRoleFromJson(e.toString())).toList();
}

List<enums.AcceptInRole>? acceptInRoleNullableListFromJson(
  List? acceptInRole, [
  List<enums.AcceptInRole>? defaultValue,
]) {
  if (acceptInRole == null) {
    return defaultValue;
  }

  return acceptInRole.map((e) => acceptInRoleFromJson(e.toString())).toList();
}

String? adminProviderInKindNullableToJson(
  enums.AdminProviderInKind? adminProviderInKind,
) {
  return adminProviderInKind?.value;
}

String? adminProviderInKindToJson(
  enums.AdminProviderInKind adminProviderInKind,
) {
  return adminProviderInKind.value;
}

enums.AdminProviderInKind adminProviderInKindFromJson(
  Object? adminProviderInKind, [
  enums.AdminProviderInKind? defaultValue,
]) {
  return enums.AdminProviderInKind.values.firstWhereOrNull(
        (e) => e.value == adminProviderInKind,
      ) ??
      defaultValue ??
      enums.AdminProviderInKind.swaggerGeneratedUnknown;
}

enums.AdminProviderInKind? adminProviderInKindNullableFromJson(
  Object? adminProviderInKind, [
  enums.AdminProviderInKind? defaultValue,
]) {
  if (adminProviderInKind == null) {
    return null;
  }
  return enums.AdminProviderInKind.values.firstWhereOrNull(
        (e) => e.value == adminProviderInKind,
      ) ??
      defaultValue;
}

String adminProviderInKindExplodedListToJson(
  List<enums.AdminProviderInKind>? adminProviderInKind,
) {
  return adminProviderInKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> adminProviderInKindListToJson(
  List<enums.AdminProviderInKind>? adminProviderInKind,
) {
  if (adminProviderInKind == null) {
    return [];
  }

  return adminProviderInKind.map((e) => e.value!).toList();
}

List<enums.AdminProviderInKind> adminProviderInKindListFromJson(
  List? adminProviderInKind, [
  List<enums.AdminProviderInKind>? defaultValue,
]) {
  if (adminProviderInKind == null) {
    return defaultValue ?? [];
  }

  return adminProviderInKind
      .map((e) => adminProviderInKindFromJson(e.toString()))
      .toList();
}

List<enums.AdminProviderInKind>? adminProviderInKindNullableListFromJson(
  List? adminProviderInKind, [
  List<enums.AdminProviderInKind>? defaultValue,
]) {
  if (adminProviderInKind == null) {
    return defaultValue;
  }

  return adminProviderInKind
      .map((e) => adminProviderInKindFromJson(e.toString()))
      .toList();
}

String? badgeOutKindNullableToJson(enums.BadgeOutKind? badgeOutKind) {
  return badgeOutKind?.value;
}

String? badgeOutKindToJson(enums.BadgeOutKind badgeOutKind) {
  return badgeOutKind.value;
}

enums.BadgeOutKind badgeOutKindFromJson(
  Object? badgeOutKind, [
  enums.BadgeOutKind? defaultValue,
]) {
  return enums.BadgeOutKind.values.firstWhereOrNull(
        (e) => e.value == badgeOutKind,
      ) ??
      defaultValue ??
      enums.BadgeOutKind.swaggerGeneratedUnknown;
}

enums.BadgeOutKind? badgeOutKindNullableFromJson(
  Object? badgeOutKind, [
  enums.BadgeOutKind? defaultValue,
]) {
  if (badgeOutKind == null) {
    return null;
  }
  return enums.BadgeOutKind.values.firstWhereOrNull(
        (e) => e.value == badgeOutKind,
      ) ??
      defaultValue;
}

String badgeOutKindExplodedListToJson(List<enums.BadgeOutKind>? badgeOutKind) {
  return badgeOutKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> badgeOutKindListToJson(List<enums.BadgeOutKind>? badgeOutKind) {
  if (badgeOutKind == null) {
    return [];
  }

  return badgeOutKind.map((e) => e.value!).toList();
}

List<enums.BadgeOutKind> badgeOutKindListFromJson(
  List? badgeOutKind, [
  List<enums.BadgeOutKind>? defaultValue,
]) {
  if (badgeOutKind == null) {
    return defaultValue ?? [];
  }

  return badgeOutKind.map((e) => badgeOutKindFromJson(e.toString())).toList();
}

List<enums.BadgeOutKind>? badgeOutKindNullableListFromJson(
  List? badgeOutKind, [
  List<enums.BadgeOutKind>? defaultValue,
]) {
  if (badgeOutKind == null) {
    return defaultValue;
  }

  return badgeOutKind.map((e) => badgeOutKindFromJson(e.toString())).toList();
}

String? blockedClaimOutReasonNullableToJson(
  enums.BlockedClaimOutReason? blockedClaimOutReason,
) {
  return blockedClaimOutReason?.value;
}

String? blockedClaimOutReasonToJson(
  enums.BlockedClaimOutReason blockedClaimOutReason,
) {
  return blockedClaimOutReason.value;
}

enums.BlockedClaimOutReason blockedClaimOutReasonFromJson(
  Object? blockedClaimOutReason, [
  enums.BlockedClaimOutReason? defaultValue,
]) {
  return enums.BlockedClaimOutReason.values.firstWhereOrNull(
        (e) => e.value == blockedClaimOutReason,
      ) ??
      defaultValue ??
      enums.BlockedClaimOutReason.swaggerGeneratedUnknown;
}

enums.BlockedClaimOutReason? blockedClaimOutReasonNullableFromJson(
  Object? blockedClaimOutReason, [
  enums.BlockedClaimOutReason? defaultValue,
]) {
  if (blockedClaimOutReason == null) {
    return null;
  }
  return enums.BlockedClaimOutReason.values.firstWhereOrNull(
        (e) => e.value == blockedClaimOutReason,
      ) ??
      defaultValue;
}

String blockedClaimOutReasonExplodedListToJson(
  List<enums.BlockedClaimOutReason>? blockedClaimOutReason,
) {
  return blockedClaimOutReason?.map((e) => e.value!).join(',') ?? '';
}

List<String> blockedClaimOutReasonListToJson(
  List<enums.BlockedClaimOutReason>? blockedClaimOutReason,
) {
  if (blockedClaimOutReason == null) {
    return [];
  }

  return blockedClaimOutReason.map((e) => e.value!).toList();
}

List<enums.BlockedClaimOutReason> blockedClaimOutReasonListFromJson(
  List? blockedClaimOutReason, [
  List<enums.BlockedClaimOutReason>? defaultValue,
]) {
  if (blockedClaimOutReason == null) {
    return defaultValue ?? [];
  }

  return blockedClaimOutReason
      .map((e) => blockedClaimOutReasonFromJson(e.toString()))
      .toList();
}

List<enums.BlockedClaimOutReason>? blockedClaimOutReasonNullableListFromJson(
  List? blockedClaimOutReason, [
  List<enums.BlockedClaimOutReason>? defaultValue,
]) {
  if (blockedClaimOutReason == null) {
    return defaultValue;
  }

  return blockedClaimOutReason
      .map((e) => blockedClaimOutReasonFromJson(e.toString()))
      .toList();
}

String? changeOpNullableToJson(enums.ChangeOp? changeOp) {
  return changeOp?.value;
}

String? changeOpToJson(enums.ChangeOp changeOp) {
  return changeOp.value;
}

enums.ChangeOp changeOpFromJson(
  Object? changeOp, [
  enums.ChangeOp? defaultValue,
]) {
  return enums.ChangeOp.values.firstWhereOrNull((e) => e.value == changeOp) ??
      defaultValue ??
      enums.ChangeOp.swaggerGeneratedUnknown;
}

enums.ChangeOp? changeOpNullableFromJson(
  Object? changeOp, [
  enums.ChangeOp? defaultValue,
]) {
  if (changeOp == null) {
    return null;
  }
  return enums.ChangeOp.values.firstWhereOrNull((e) => e.value == changeOp) ??
      defaultValue;
}

String changeOpExplodedListToJson(List<enums.ChangeOp>? changeOp) {
  return changeOp?.map((e) => e.value!).join(',') ?? '';
}

List<String> changeOpListToJson(List<enums.ChangeOp>? changeOp) {
  if (changeOp == null) {
    return [];
  }

  return changeOp.map((e) => e.value!).toList();
}

List<enums.ChangeOp> changeOpListFromJson(
  List? changeOp, [
  List<enums.ChangeOp>? defaultValue,
]) {
  if (changeOp == null) {
    return defaultValue ?? [];
  }

  return changeOp.map((e) => changeOpFromJson(e.toString())).toList();
}

List<enums.ChangeOp>? changeOpNullableListFromJson(
  List? changeOp, [
  List<enums.ChangeOp>? defaultValue,
]) {
  if (changeOp == null) {
    return defaultValue;
  }

  return changeOp.map((e) => changeOpFromJson(e.toString())).toList();
}

String? decisionInStatusNullableToJson(
  enums.DecisionInStatus? decisionInStatus,
) {
  return decisionInStatus?.value;
}

String? decisionInStatusToJson(enums.DecisionInStatus decisionInStatus) {
  return decisionInStatus.value;
}

enums.DecisionInStatus decisionInStatusFromJson(
  Object? decisionInStatus, [
  enums.DecisionInStatus? defaultValue,
]) {
  return enums.DecisionInStatus.values.firstWhereOrNull(
        (e) => e.value == decisionInStatus,
      ) ??
      defaultValue ??
      enums.DecisionInStatus.swaggerGeneratedUnknown;
}

enums.DecisionInStatus? decisionInStatusNullableFromJson(
  Object? decisionInStatus, [
  enums.DecisionInStatus? defaultValue,
]) {
  if (decisionInStatus == null) {
    return null;
  }
  return enums.DecisionInStatus.values.firstWhereOrNull(
        (e) => e.value == decisionInStatus,
      ) ??
      defaultValue;
}

String decisionInStatusExplodedListToJson(
  List<enums.DecisionInStatus>? decisionInStatus,
) {
  return decisionInStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> decisionInStatusListToJson(
  List<enums.DecisionInStatus>? decisionInStatus,
) {
  if (decisionInStatus == null) {
    return [];
  }

  return decisionInStatus.map((e) => e.value!).toList();
}

List<enums.DecisionInStatus> decisionInStatusListFromJson(
  List? decisionInStatus, [
  List<enums.DecisionInStatus>? defaultValue,
]) {
  if (decisionInStatus == null) {
    return defaultValue ?? [];
  }

  return decisionInStatus
      .map((e) => decisionInStatusFromJson(e.toString()))
      .toList();
}

List<enums.DecisionInStatus>? decisionInStatusNullableListFromJson(
  List? decisionInStatus, [
  List<enums.DecisionInStatus>? defaultValue,
]) {
  if (decisionInStatus == null) {
    return defaultValue;
  }

  return decisionInStatus
      .map((e) => decisionInStatusFromJson(e.toString()))
      .toList();
}

String? deviceInPlatformNullableToJson(
  enums.DeviceInPlatform? deviceInPlatform,
) {
  return deviceInPlatform?.value;
}

String? deviceInPlatformToJson(enums.DeviceInPlatform deviceInPlatform) {
  return deviceInPlatform.value;
}

enums.DeviceInPlatform deviceInPlatformFromJson(
  Object? deviceInPlatform, [
  enums.DeviceInPlatform? defaultValue,
]) {
  return enums.DeviceInPlatform.values.firstWhereOrNull(
        (e) => e.value == deviceInPlatform,
      ) ??
      defaultValue ??
      enums.DeviceInPlatform.swaggerGeneratedUnknown;
}

enums.DeviceInPlatform? deviceInPlatformNullableFromJson(
  Object? deviceInPlatform, [
  enums.DeviceInPlatform? defaultValue,
]) {
  if (deviceInPlatform == null) {
    return null;
  }
  return enums.DeviceInPlatform.values.firstWhereOrNull(
        (e) => e.value == deviceInPlatform,
      ) ??
      defaultValue;
}

String deviceInPlatformExplodedListToJson(
  List<enums.DeviceInPlatform>? deviceInPlatform,
) {
  return deviceInPlatform?.map((e) => e.value!).join(',') ?? '';
}

List<String> deviceInPlatformListToJson(
  List<enums.DeviceInPlatform>? deviceInPlatform,
) {
  if (deviceInPlatform == null) {
    return [];
  }

  return deviceInPlatform.map((e) => e.value!).toList();
}

List<enums.DeviceInPlatform> deviceInPlatformListFromJson(
  List? deviceInPlatform, [
  List<enums.DeviceInPlatform>? defaultValue,
]) {
  if (deviceInPlatform == null) {
    return defaultValue ?? [];
  }

  return deviceInPlatform
      .map((e) => deviceInPlatformFromJson(e.toString()))
      .toList();
}

List<enums.DeviceInPlatform>? deviceInPlatformNullableListFromJson(
  List? deviceInPlatform, [
  List<enums.DeviceInPlatform>? defaultValue,
]) {
  if (deviceInPlatform == null) {
    return defaultValue;
  }

  return deviceInPlatform
      .map((e) => deviceInPlatformFromJson(e.toString()))
      .toList();
}

String? feedAdminItemInTypeNullableToJson(
  enums.FeedAdminItemInType? feedAdminItemInType,
) {
  return feedAdminItemInType?.value;
}

String? feedAdminItemInTypeToJson(
  enums.FeedAdminItemInType feedAdminItemInType,
) {
  return feedAdminItemInType.value;
}

enums.FeedAdminItemInType feedAdminItemInTypeFromJson(
  Object? feedAdminItemInType, [
  enums.FeedAdminItemInType? defaultValue,
]) {
  return enums.FeedAdminItemInType.values.firstWhereOrNull(
        (e) => e.value == feedAdminItemInType,
      ) ??
      defaultValue ??
      enums.FeedAdminItemInType.swaggerGeneratedUnknown;
}

enums.FeedAdminItemInType? feedAdminItemInTypeNullableFromJson(
  Object? feedAdminItemInType, [
  enums.FeedAdminItemInType? defaultValue,
]) {
  if (feedAdminItemInType == null) {
    return null;
  }
  return enums.FeedAdminItemInType.values.firstWhereOrNull(
        (e) => e.value == feedAdminItemInType,
      ) ??
      defaultValue;
}

String feedAdminItemInTypeExplodedListToJson(
  List<enums.FeedAdminItemInType>? feedAdminItemInType,
) {
  return feedAdminItemInType?.map((e) => e.value!).join(',') ?? '';
}

List<String> feedAdminItemInTypeListToJson(
  List<enums.FeedAdminItemInType>? feedAdminItemInType,
) {
  if (feedAdminItemInType == null) {
    return [];
  }

  return feedAdminItemInType.map((e) => e.value!).toList();
}

List<enums.FeedAdminItemInType> feedAdminItemInTypeListFromJson(
  List? feedAdminItemInType, [
  List<enums.FeedAdminItemInType>? defaultValue,
]) {
  if (feedAdminItemInType == null) {
    return defaultValue ?? [];
  }

  return feedAdminItemInType
      .map((e) => feedAdminItemInTypeFromJson(e.toString()))
      .toList();
}

List<enums.FeedAdminItemInType>? feedAdminItemInTypeNullableListFromJson(
  List? feedAdminItemInType, [
  List<enums.FeedAdminItemInType>? defaultValue,
]) {
  if (feedAdminItemInType == null) {
    return defaultValue;
  }

  return feedAdminItemInType
      .map((e) => feedAdminItemInTypeFromJson(e.toString()))
      .toList();
}

String? feedAdminTermsInTermsStatusNullableToJson(
  enums.FeedAdminTermsInTermsStatus? feedAdminTermsInTermsStatus,
) {
  return feedAdminTermsInTermsStatus?.value;
}

String? feedAdminTermsInTermsStatusToJson(
  enums.FeedAdminTermsInTermsStatus feedAdminTermsInTermsStatus,
) {
  return feedAdminTermsInTermsStatus.value;
}

enums.FeedAdminTermsInTermsStatus feedAdminTermsInTermsStatusFromJson(
  Object? feedAdminTermsInTermsStatus, [
  enums.FeedAdminTermsInTermsStatus? defaultValue,
]) {
  return enums.FeedAdminTermsInTermsStatus.values.firstWhereOrNull(
        (e) => e.value == feedAdminTermsInTermsStatus,
      ) ??
      defaultValue ??
      enums.FeedAdminTermsInTermsStatus.swaggerGeneratedUnknown;
}

enums.FeedAdminTermsInTermsStatus? feedAdminTermsInTermsStatusNullableFromJson(
  Object? feedAdminTermsInTermsStatus, [
  enums.FeedAdminTermsInTermsStatus? defaultValue,
]) {
  if (feedAdminTermsInTermsStatus == null) {
    return null;
  }
  return enums.FeedAdminTermsInTermsStatus.values.firstWhereOrNull(
        (e) => e.value == feedAdminTermsInTermsStatus,
      ) ??
      defaultValue;
}

String feedAdminTermsInTermsStatusExplodedListToJson(
  List<enums.FeedAdminTermsInTermsStatus>? feedAdminTermsInTermsStatus,
) {
  return feedAdminTermsInTermsStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> feedAdminTermsInTermsStatusListToJson(
  List<enums.FeedAdminTermsInTermsStatus>? feedAdminTermsInTermsStatus,
) {
  if (feedAdminTermsInTermsStatus == null) {
    return [];
  }

  return feedAdminTermsInTermsStatus.map((e) => e.value!).toList();
}

List<enums.FeedAdminTermsInTermsStatus> feedAdminTermsInTermsStatusListFromJson(
  List? feedAdminTermsInTermsStatus, [
  List<enums.FeedAdminTermsInTermsStatus>? defaultValue,
]) {
  if (feedAdminTermsInTermsStatus == null) {
    return defaultValue ?? [];
  }

  return feedAdminTermsInTermsStatus
      .map((e) => feedAdminTermsInTermsStatusFromJson(e.toString()))
      .toList();
}

List<enums.FeedAdminTermsInTermsStatus>?
feedAdminTermsInTermsStatusNullableListFromJson(
  List? feedAdminTermsInTermsStatus, [
  List<enums.FeedAdminTermsInTermsStatus>? defaultValue,
]) {
  if (feedAdminTermsInTermsStatus == null) {
    return defaultValue;
  }

  return feedAdminTermsInTermsStatus
      .map((e) => feedAdminTermsInTermsStatusFromJson(e.toString()))
      .toList();
}

String? feedCheckResponseVerdictNullableToJson(
  enums.FeedCheckResponseVerdict? feedCheckResponseVerdict,
) {
  return feedCheckResponseVerdict?.value;
}

String? feedCheckResponseVerdictToJson(
  enums.FeedCheckResponseVerdict feedCheckResponseVerdict,
) {
  return feedCheckResponseVerdict.value;
}

enums.FeedCheckResponseVerdict feedCheckResponseVerdictFromJson(
  Object? feedCheckResponseVerdict, [
  enums.FeedCheckResponseVerdict? defaultValue,
]) {
  return enums.FeedCheckResponseVerdict.values.firstWhereOrNull(
        (e) => e.value == feedCheckResponseVerdict,
      ) ??
      defaultValue ??
      enums.FeedCheckResponseVerdict.swaggerGeneratedUnknown;
}

enums.FeedCheckResponseVerdict? feedCheckResponseVerdictNullableFromJson(
  Object? feedCheckResponseVerdict, [
  enums.FeedCheckResponseVerdict? defaultValue,
]) {
  if (feedCheckResponseVerdict == null) {
    return null;
  }
  return enums.FeedCheckResponseVerdict.values.firstWhereOrNull(
        (e) => e.value == feedCheckResponseVerdict,
      ) ??
      defaultValue;
}

String feedCheckResponseVerdictExplodedListToJson(
  List<enums.FeedCheckResponseVerdict>? feedCheckResponseVerdict,
) {
  return feedCheckResponseVerdict?.map((e) => e.value!).join(',') ?? '';
}

List<String> feedCheckResponseVerdictListToJson(
  List<enums.FeedCheckResponseVerdict>? feedCheckResponseVerdict,
) {
  if (feedCheckResponseVerdict == null) {
    return [];
  }

  return feedCheckResponseVerdict.map((e) => e.value!).toList();
}

List<enums.FeedCheckResponseVerdict> feedCheckResponseVerdictListFromJson(
  List? feedCheckResponseVerdict, [
  List<enums.FeedCheckResponseVerdict>? defaultValue,
]) {
  if (feedCheckResponseVerdict == null) {
    return defaultValue ?? [];
  }

  return feedCheckResponseVerdict
      .map((e) => feedCheckResponseVerdictFromJson(e.toString()))
      .toList();
}

List<enums.FeedCheckResponseVerdict>?
feedCheckResponseVerdictNullableListFromJson(
  List? feedCheckResponseVerdict, [
  List<enums.FeedCheckResponseVerdict>? defaultValue,
]) {
  if (feedCheckResponseVerdict == null) {
    return defaultValue;
  }

  return feedCheckResponseVerdict
      .map((e) => feedCheckResponseVerdictFromJson(e.toString()))
      .toList();
}

String? feedItemOutTrustNullableToJson(
  enums.FeedItemOutTrust? feedItemOutTrust,
) {
  return feedItemOutTrust?.value;
}

String? feedItemOutTrustToJson(enums.FeedItemOutTrust feedItemOutTrust) {
  return feedItemOutTrust.value;
}

enums.FeedItemOutTrust feedItemOutTrustFromJson(
  Object? feedItemOutTrust, [
  enums.FeedItemOutTrust? defaultValue,
]) {
  return enums.FeedItemOutTrust.values.firstWhereOrNull(
        (e) => e.value == feedItemOutTrust,
      ) ??
      defaultValue ??
      enums.FeedItemOutTrust.swaggerGeneratedUnknown;
}

enums.FeedItemOutTrust? feedItemOutTrustNullableFromJson(
  Object? feedItemOutTrust, [
  enums.FeedItemOutTrust? defaultValue,
]) {
  if (feedItemOutTrust == null) {
    return null;
  }
  return enums.FeedItemOutTrust.values.firstWhereOrNull(
        (e) => e.value == feedItemOutTrust,
      ) ??
      defaultValue;
}

String feedItemOutTrustExplodedListToJson(
  List<enums.FeedItemOutTrust>? feedItemOutTrust,
) {
  return feedItemOutTrust?.map((e) => e.value!).join(',') ?? '';
}

List<String> feedItemOutTrustListToJson(
  List<enums.FeedItemOutTrust>? feedItemOutTrust,
) {
  if (feedItemOutTrust == null) {
    return [];
  }

  return feedItemOutTrust.map((e) => e.value!).toList();
}

List<enums.FeedItemOutTrust> feedItemOutTrustListFromJson(
  List? feedItemOutTrust, [
  List<enums.FeedItemOutTrust>? defaultValue,
]) {
  if (feedItemOutTrust == null) {
    return defaultValue ?? [];
  }

  return feedItemOutTrust
      .map((e) => feedItemOutTrustFromJson(e.toString()))
      .toList();
}

List<enums.FeedItemOutTrust>? feedItemOutTrustNullableListFromJson(
  List? feedItemOutTrust, [
  List<enums.FeedItemOutTrust>? defaultValue,
]) {
  if (feedItemOutTrust == null) {
    return defaultValue;
  }

  return feedItemOutTrust
      .map((e) => feedItemOutTrustFromJson(e.toString()))
      .toList();
}

String? feedPreferencesBodyOptedOutNullableToJson(
  enums.FeedPreferencesBodyOptedOut? feedPreferencesBodyOptedOut,
) {
  return feedPreferencesBodyOptedOut?.value;
}

String? feedPreferencesBodyOptedOutToJson(
  enums.FeedPreferencesBodyOptedOut feedPreferencesBodyOptedOut,
) {
  return feedPreferencesBodyOptedOut.value;
}

enums.FeedPreferencesBodyOptedOut feedPreferencesBodyOptedOutFromJson(
  Object? feedPreferencesBodyOptedOut, [
  enums.FeedPreferencesBodyOptedOut? defaultValue,
]) {
  return enums.FeedPreferencesBodyOptedOut.values.firstWhereOrNull(
        (e) => e.value == feedPreferencesBodyOptedOut,
      ) ??
      defaultValue ??
      enums.FeedPreferencesBodyOptedOut.swaggerGeneratedUnknown;
}

enums.FeedPreferencesBodyOptedOut? feedPreferencesBodyOptedOutNullableFromJson(
  Object? feedPreferencesBodyOptedOut, [
  enums.FeedPreferencesBodyOptedOut? defaultValue,
]) {
  if (feedPreferencesBodyOptedOut == null) {
    return null;
  }
  return enums.FeedPreferencesBodyOptedOut.values.firstWhereOrNull(
        (e) => e.value == feedPreferencesBodyOptedOut,
      ) ??
      defaultValue;
}

String feedPreferencesBodyOptedOutExplodedListToJson(
  List<enums.FeedPreferencesBodyOptedOut>? feedPreferencesBodyOptedOut,
) {
  return feedPreferencesBodyOptedOut?.map((e) => e.value!).join(',') ?? '';
}

List<String> feedPreferencesBodyOptedOutListToJson(
  List<enums.FeedPreferencesBodyOptedOut>? feedPreferencesBodyOptedOut,
) {
  if (feedPreferencesBodyOptedOut == null) {
    return [];
  }

  return feedPreferencesBodyOptedOut.map((e) => e.value!).toList();
}

List<enums.FeedPreferencesBodyOptedOut> feedPreferencesBodyOptedOutListFromJson(
  List? feedPreferencesBodyOptedOut, [
  List<enums.FeedPreferencesBodyOptedOut>? defaultValue,
]) {
  if (feedPreferencesBodyOptedOut == null) {
    return defaultValue ?? [];
  }

  return feedPreferencesBodyOptedOut
      .map((e) => feedPreferencesBodyOptedOutFromJson(e.toString()))
      .toList();
}

List<enums.FeedPreferencesBodyOptedOut>?
feedPreferencesBodyOptedOutNullableListFromJson(
  List? feedPreferencesBodyOptedOut, [
  List<enums.FeedPreferencesBodyOptedOut>? defaultValue,
]) {
  if (feedPreferencesBodyOptedOut == null) {
    return defaultValue;
  }

  return feedPreferencesBodyOptedOut
      .map((e) => feedPreferencesBodyOptedOutFromJson(e.toString()))
      .toList();
}

String? grantInSubjectTypeNullableToJson(
  enums.GrantInSubjectType? grantInSubjectType,
) {
  return grantInSubjectType?.value;
}

String? grantInSubjectTypeToJson(enums.GrantInSubjectType grantInSubjectType) {
  return grantInSubjectType.value;
}

enums.GrantInSubjectType grantInSubjectTypeFromJson(
  Object? grantInSubjectType, [
  enums.GrantInSubjectType? defaultValue,
]) {
  return enums.GrantInSubjectType.values.firstWhereOrNull(
        (e) => e.value == grantInSubjectType,
      ) ??
      defaultValue ??
      enums.GrantInSubjectType.swaggerGeneratedUnknown;
}

enums.GrantInSubjectType? grantInSubjectTypeNullableFromJson(
  Object? grantInSubjectType, [
  enums.GrantInSubjectType? defaultValue,
]) {
  if (grantInSubjectType == null) {
    return null;
  }
  return enums.GrantInSubjectType.values.firstWhereOrNull(
        (e) => e.value == grantInSubjectType,
      ) ??
      defaultValue;
}

String grantInSubjectTypeExplodedListToJson(
  List<enums.GrantInSubjectType>? grantInSubjectType,
) {
  return grantInSubjectType?.map((e) => e.value!).join(',') ?? '';
}

List<String> grantInSubjectTypeListToJson(
  List<enums.GrantInSubjectType>? grantInSubjectType,
) {
  if (grantInSubjectType == null) {
    return [];
  }

  return grantInSubjectType.map((e) => e.value!).toList();
}

List<enums.GrantInSubjectType> grantInSubjectTypeListFromJson(
  List? grantInSubjectType, [
  List<enums.GrantInSubjectType>? defaultValue,
]) {
  if (grantInSubjectType == null) {
    return defaultValue ?? [];
  }

  return grantInSubjectType
      .map((e) => grantInSubjectTypeFromJson(e.toString()))
      .toList();
}

List<enums.GrantInSubjectType>? grantInSubjectTypeNullableListFromJson(
  List? grantInSubjectType, [
  List<enums.GrantInSubjectType>? defaultValue,
]) {
  if (grantInSubjectType == null) {
    return defaultValue;
  }

  return grantInSubjectType
      .map((e) => grantInSubjectTypeFromJson(e.toString()))
      .toList();
}

String? interestInBasisNullableToJson(enums.InterestInBasis? interestInBasis) {
  return interestInBasis?.value;
}

String? interestInBasisToJson(enums.InterestInBasis interestInBasis) {
  return interestInBasis.value;
}

enums.InterestInBasis interestInBasisFromJson(
  Object? interestInBasis, [
  enums.InterestInBasis? defaultValue,
]) {
  return enums.InterestInBasis.values.firstWhereOrNull(
        (e) => e.value == interestInBasis,
      ) ??
      defaultValue ??
      enums.InterestInBasis.swaggerGeneratedUnknown;
}

enums.InterestInBasis? interestInBasisNullableFromJson(
  Object? interestInBasis, [
  enums.InterestInBasis? defaultValue,
]) {
  if (interestInBasis == null) {
    return null;
  }
  return enums.InterestInBasis.values.firstWhereOrNull(
        (e) => e.value == interestInBasis,
      ) ??
      defaultValue;
}

String interestInBasisExplodedListToJson(
  List<enums.InterestInBasis>? interestInBasis,
) {
  return interestInBasis?.map((e) => e.value!).join(',') ?? '';
}

List<String> interestInBasisListToJson(
  List<enums.InterestInBasis>? interestInBasis,
) {
  if (interestInBasis == null) {
    return [];
  }

  return interestInBasis.map((e) => e.value!).toList();
}

List<enums.InterestInBasis> interestInBasisListFromJson(
  List? interestInBasis, [
  List<enums.InterestInBasis>? defaultValue,
]) {
  if (interestInBasis == null) {
    return defaultValue ?? [];
  }

  return interestInBasis
      .map((e) => interestInBasisFromJson(e.toString()))
      .toList();
}

List<enums.InterestInBasis>? interestInBasisNullableListFromJson(
  List? interestInBasis, [
  List<enums.InterestInBasis>? defaultValue,
]) {
  if (interestInBasis == null) {
    return defaultValue;
  }

  return interestInBasis
      .map((e) => interestInBasisFromJson(e.toString()))
      .toList();
}

String? labelClaimOutCategoryNullableToJson(
  enums.LabelClaimOutCategory? labelClaimOutCategory,
) {
  return labelClaimOutCategory?.value;
}

String? labelClaimOutCategoryToJson(
  enums.LabelClaimOutCategory labelClaimOutCategory,
) {
  return labelClaimOutCategory.value;
}

enums.LabelClaimOutCategory labelClaimOutCategoryFromJson(
  Object? labelClaimOutCategory, [
  enums.LabelClaimOutCategory? defaultValue,
]) {
  return enums.LabelClaimOutCategory.values.firstWhereOrNull(
        (e) => e.value == labelClaimOutCategory,
      ) ??
      defaultValue ??
      enums.LabelClaimOutCategory.swaggerGeneratedUnknown;
}

enums.LabelClaimOutCategory? labelClaimOutCategoryNullableFromJson(
  Object? labelClaimOutCategory, [
  enums.LabelClaimOutCategory? defaultValue,
]) {
  if (labelClaimOutCategory == null) {
    return null;
  }
  return enums.LabelClaimOutCategory.values.firstWhereOrNull(
        (e) => e.value == labelClaimOutCategory,
      ) ??
      defaultValue;
}

String labelClaimOutCategoryExplodedListToJson(
  List<enums.LabelClaimOutCategory>? labelClaimOutCategory,
) {
  return labelClaimOutCategory?.map((e) => e.value!).join(',') ?? '';
}

List<String> labelClaimOutCategoryListToJson(
  List<enums.LabelClaimOutCategory>? labelClaimOutCategory,
) {
  if (labelClaimOutCategory == null) {
    return [];
  }

  return labelClaimOutCategory.map((e) => e.value!).toList();
}

List<enums.LabelClaimOutCategory> labelClaimOutCategoryListFromJson(
  List? labelClaimOutCategory, [
  List<enums.LabelClaimOutCategory>? defaultValue,
]) {
  if (labelClaimOutCategory == null) {
    return defaultValue ?? [];
  }

  return labelClaimOutCategory
      .map((e) => labelClaimOutCategoryFromJson(e.toString()))
      .toList();
}

List<enums.LabelClaimOutCategory>? labelClaimOutCategoryNullableListFromJson(
  List? labelClaimOutCategory, [
  List<enums.LabelClaimOutCategory>? defaultValue,
]) {
  if (labelClaimOutCategory == null) {
    return defaultValue;
  }

  return labelClaimOutCategory
      .map((e) => labelClaimOutCategoryFromJson(e.toString()))
      .toList();
}

String? mutationOpNullableToJson(enums.MutationOp? mutationOp) {
  return mutationOp?.value;
}

String? mutationOpToJson(enums.MutationOp mutationOp) {
  return mutationOp.value;
}

enums.MutationOp mutationOpFromJson(
  Object? mutationOp, [
  enums.MutationOp? defaultValue,
]) {
  return enums.MutationOp.values.firstWhereOrNull(
        (e) => e.value == mutationOp,
      ) ??
      defaultValue ??
      enums.MutationOp.swaggerGeneratedUnknown;
}

enums.MutationOp? mutationOpNullableFromJson(
  Object? mutationOp, [
  enums.MutationOp? defaultValue,
]) {
  if (mutationOp == null) {
    return null;
  }
  return enums.MutationOp.values.firstWhereOrNull(
        (e) => e.value == mutationOp,
      ) ??
      defaultValue;
}

String mutationOpExplodedListToJson(List<enums.MutationOp>? mutationOp) {
  return mutationOp?.map((e) => e.value!).join(',') ?? '';
}

List<String> mutationOpListToJson(List<enums.MutationOp>? mutationOp) {
  if (mutationOp == null) {
    return [];
  }

  return mutationOp.map((e) => e.value!).toList();
}

List<enums.MutationOp> mutationOpListFromJson(
  List? mutationOp, [
  List<enums.MutationOp>? defaultValue,
]) {
  if (mutationOp == null) {
    return defaultValue ?? [];
  }

  return mutationOp.map((e) => mutationOpFromJson(e.toString())).toList();
}

List<enums.MutationOp>? mutationOpNullableListFromJson(
  List? mutationOp, [
  List<enums.MutationOp>? defaultValue,
]) {
  if (mutationOp == null) {
    return defaultValue;
  }

  return mutationOp.map((e) => mutationOpFromJson(e.toString())).toList();
}

String? mutationResultStatusNullableToJson(
  enums.MutationResultStatus? mutationResultStatus,
) {
  return mutationResultStatus?.value;
}

String? mutationResultStatusToJson(
  enums.MutationResultStatus mutationResultStatus,
) {
  return mutationResultStatus.value;
}

enums.MutationResultStatus mutationResultStatusFromJson(
  Object? mutationResultStatus, [
  enums.MutationResultStatus? defaultValue,
]) {
  return enums.MutationResultStatus.values.firstWhereOrNull(
        (e) => e.value == mutationResultStatus,
      ) ??
      defaultValue ??
      enums.MutationResultStatus.swaggerGeneratedUnknown;
}

enums.MutationResultStatus? mutationResultStatusNullableFromJson(
  Object? mutationResultStatus, [
  enums.MutationResultStatus? defaultValue,
]) {
  if (mutationResultStatus == null) {
    return null;
  }
  return enums.MutationResultStatus.values.firstWhereOrNull(
        (e) => e.value == mutationResultStatus,
      ) ??
      defaultValue;
}

String mutationResultStatusExplodedListToJson(
  List<enums.MutationResultStatus>? mutationResultStatus,
) {
  return mutationResultStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> mutationResultStatusListToJson(
  List<enums.MutationResultStatus>? mutationResultStatus,
) {
  if (mutationResultStatus == null) {
    return [];
  }

  return mutationResultStatus.map((e) => e.value!).toList();
}

List<enums.MutationResultStatus> mutationResultStatusListFromJson(
  List? mutationResultStatus, [
  List<enums.MutationResultStatus>? defaultValue,
]) {
  if (mutationResultStatus == null) {
    return defaultValue ?? [];
  }

  return mutationResultStatus
      .map((e) => mutationResultStatusFromJson(e.toString()))
      .toList();
}

List<enums.MutationResultStatus>? mutationResultStatusNullableListFromJson(
  List? mutationResultStatus, [
  List<enums.MutationResultStatus>? defaultValue,
]) {
  if (mutationResultStatus == null) {
    return defaultValue;
  }

  return mutationResultStatus
      .map((e) => mutationResultStatusFromJson(e.toString()))
      .toList();
}

String? planInKindNullableToJson(enums.PlanInKind? planInKind) {
  return planInKind?.value;
}

String? planInKindToJson(enums.PlanInKind planInKind) {
  return planInKind.value;
}

enums.PlanInKind planInKindFromJson(
  Object? planInKind, [
  enums.PlanInKind? defaultValue,
]) {
  return enums.PlanInKind.values.firstWhereOrNull(
        (e) => e.value == planInKind,
      ) ??
      defaultValue ??
      enums.PlanInKind.swaggerGeneratedUnknown;
}

enums.PlanInKind? planInKindNullableFromJson(
  Object? planInKind, [
  enums.PlanInKind? defaultValue,
]) {
  if (planInKind == null) {
    return null;
  }
  return enums.PlanInKind.values.firstWhereOrNull(
        (e) => e.value == planInKind,
      ) ??
      defaultValue;
}

String planInKindExplodedListToJson(List<enums.PlanInKind>? planInKind) {
  return planInKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> planInKindListToJson(List<enums.PlanInKind>? planInKind) {
  if (planInKind == null) {
    return [];
  }

  return planInKind.map((e) => e.value!).toList();
}

List<enums.PlanInKind> planInKindListFromJson(
  List? planInKind, [
  List<enums.PlanInKind>? defaultValue,
]) {
  if (planInKind == null) {
    return defaultValue ?? [];
  }

  return planInKind.map((e) => planInKindFromJson(e.toString())).toList();
}

List<enums.PlanInKind>? planInKindNullableListFromJson(
  List? planInKind, [
  List<enums.PlanInKind>? defaultValue,
]) {
  if (planInKind == null) {
    return defaultValue;
  }

  return planInKind.map((e) => planInKindFromJson(e.toString())).toList();
}

String? providerInKindNullableToJson(enums.ProviderInKind? providerInKind) {
  return providerInKind?.value;
}

String? providerInKindToJson(enums.ProviderInKind providerInKind) {
  return providerInKind.value;
}

enums.ProviderInKind providerInKindFromJson(
  Object? providerInKind, [
  enums.ProviderInKind? defaultValue,
]) {
  return enums.ProviderInKind.values.firstWhereOrNull(
        (e) => e.value == providerInKind,
      ) ??
      defaultValue ??
      enums.ProviderInKind.swaggerGeneratedUnknown;
}

enums.ProviderInKind? providerInKindNullableFromJson(
  Object? providerInKind, [
  enums.ProviderInKind? defaultValue,
]) {
  if (providerInKind == null) {
    return null;
  }
  return enums.ProviderInKind.values.firstWhereOrNull(
        (e) => e.value == providerInKind,
      ) ??
      defaultValue;
}

String providerInKindExplodedListToJson(
  List<enums.ProviderInKind>? providerInKind,
) {
  return providerInKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> providerInKindListToJson(
  List<enums.ProviderInKind>? providerInKind,
) {
  if (providerInKind == null) {
    return [];
  }

  return providerInKind.map((e) => e.value!).toList();
}

List<enums.ProviderInKind> providerInKindListFromJson(
  List? providerInKind, [
  List<enums.ProviderInKind>? defaultValue,
]) {
  if (providerInKind == null) {
    return defaultValue ?? [];
  }

  return providerInKind
      .map((e) => providerInKindFromJson(e.toString()))
      .toList();
}

List<enums.ProviderInKind>? providerInKindNullableListFromJson(
  List? providerInKind, [
  List<enums.ProviderInKind>? defaultValue,
]) {
  if (providerInKind == null) {
    return defaultValue;
  }

  return providerInKind
      .map((e) => providerInKindFromJson(e.toString()))
      .toList();
}

String? ratingTagInStatusNullableToJson(
  enums.RatingTagInStatus? ratingTagInStatus,
) {
  return ratingTagInStatus?.value;
}

String? ratingTagInStatusToJson(enums.RatingTagInStatus ratingTagInStatus) {
  return ratingTagInStatus.value;
}

enums.RatingTagInStatus ratingTagInStatusFromJson(
  Object? ratingTagInStatus, [
  enums.RatingTagInStatus? defaultValue,
]) {
  return enums.RatingTagInStatus.values.firstWhereOrNull(
        (e) => e.value == ratingTagInStatus,
      ) ??
      defaultValue ??
      enums.RatingTagInStatus.swaggerGeneratedUnknown;
}

enums.RatingTagInStatus? ratingTagInStatusNullableFromJson(
  Object? ratingTagInStatus, [
  enums.RatingTagInStatus? defaultValue,
]) {
  if (ratingTagInStatus == null) {
    return null;
  }
  return enums.RatingTagInStatus.values.firstWhereOrNull(
        (e) => e.value == ratingTagInStatus,
      ) ??
      defaultValue;
}

String ratingTagInStatusExplodedListToJson(
  List<enums.RatingTagInStatus>? ratingTagInStatus,
) {
  return ratingTagInStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> ratingTagInStatusListToJson(
  List<enums.RatingTagInStatus>? ratingTagInStatus,
) {
  if (ratingTagInStatus == null) {
    return [];
  }

  return ratingTagInStatus.map((e) => e.value!).toList();
}

List<enums.RatingTagInStatus> ratingTagInStatusListFromJson(
  List? ratingTagInStatus, [
  List<enums.RatingTagInStatus>? defaultValue,
]) {
  if (ratingTagInStatus == null) {
    return defaultValue ?? [];
  }

  return ratingTagInStatus
      .map((e) => ratingTagInStatusFromJson(e.toString()))
      .toList();
}

List<enums.RatingTagInStatus>? ratingTagInStatusNullableListFromJson(
  List? ratingTagInStatus, [
  List<enums.RatingTagInStatus>? defaultValue,
]) {
  if (ratingTagInStatus == null) {
    return defaultValue;
  }

  return ratingTagInStatus
      .map((e) => ratingTagInStatusFromJson(e.toString()))
      .toList();
}

String? reviewInDecisionNullableToJson(
  enums.ReviewInDecision? reviewInDecision,
) {
  return reviewInDecision?.value;
}

String? reviewInDecisionToJson(enums.ReviewInDecision reviewInDecision) {
  return reviewInDecision.value;
}

enums.ReviewInDecision reviewInDecisionFromJson(
  Object? reviewInDecision, [
  enums.ReviewInDecision? defaultValue,
]) {
  return enums.ReviewInDecision.values.firstWhereOrNull(
        (e) => e.value == reviewInDecision,
      ) ??
      defaultValue ??
      enums.ReviewInDecision.swaggerGeneratedUnknown;
}

enums.ReviewInDecision? reviewInDecisionNullableFromJson(
  Object? reviewInDecision, [
  enums.ReviewInDecision? defaultValue,
]) {
  if (reviewInDecision == null) {
    return null;
  }
  return enums.ReviewInDecision.values.firstWhereOrNull(
        (e) => e.value == reviewInDecision,
      ) ??
      defaultValue;
}

String reviewInDecisionExplodedListToJson(
  List<enums.ReviewInDecision>? reviewInDecision,
) {
  return reviewInDecision?.map((e) => e.value!).join(',') ?? '';
}

List<String> reviewInDecisionListToJson(
  List<enums.ReviewInDecision>? reviewInDecision,
) {
  if (reviewInDecision == null) {
    return [];
  }

  return reviewInDecision.map((e) => e.value!).toList();
}

List<enums.ReviewInDecision> reviewInDecisionListFromJson(
  List? reviewInDecision, [
  List<enums.ReviewInDecision>? defaultValue,
]) {
  if (reviewInDecision == null) {
    return defaultValue ?? [];
  }

  return reviewInDecision
      .map((e) => reviewInDecisionFromJson(e.toString()))
      .toList();
}

List<enums.ReviewInDecision>? reviewInDecisionNullableListFromJson(
  List? reviewInDecision, [
  List<enums.ReviewInDecision>? defaultValue,
]) {
  if (reviewInDecision == null) {
    return defaultValue;
  }

  return reviewInDecision
      .map((e) => reviewInDecisionFromJson(e.toString()))
      .toList();
}

String? termsDocOutKindNullableToJson(enums.TermsDocOutKind? termsDocOutKind) {
  return termsDocOutKind?.value;
}

String? termsDocOutKindToJson(enums.TermsDocOutKind termsDocOutKind) {
  return termsDocOutKind.value;
}

enums.TermsDocOutKind termsDocOutKindFromJson(
  Object? termsDocOutKind, [
  enums.TermsDocOutKind? defaultValue,
]) {
  return enums.TermsDocOutKind.values.firstWhereOrNull(
        (e) => e.value == termsDocOutKind,
      ) ??
      defaultValue ??
      enums.TermsDocOutKind.swaggerGeneratedUnknown;
}

enums.TermsDocOutKind? termsDocOutKindNullableFromJson(
  Object? termsDocOutKind, [
  enums.TermsDocOutKind? defaultValue,
]) {
  if (termsDocOutKind == null) {
    return null;
  }
  return enums.TermsDocOutKind.values.firstWhereOrNull(
        (e) => e.value == termsDocOutKind,
      ) ??
      defaultValue;
}

String termsDocOutKindExplodedListToJson(
  List<enums.TermsDocOutKind>? termsDocOutKind,
) {
  return termsDocOutKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> termsDocOutKindListToJson(
  List<enums.TermsDocOutKind>? termsDocOutKind,
) {
  if (termsDocOutKind == null) {
    return [];
  }

  return termsDocOutKind.map((e) => e.value!).toList();
}

List<enums.TermsDocOutKind> termsDocOutKindListFromJson(
  List? termsDocOutKind, [
  List<enums.TermsDocOutKind>? defaultValue,
]) {
  if (termsDocOutKind == null) {
    return defaultValue ?? [];
  }

  return termsDocOutKind
      .map((e) => termsDocOutKindFromJson(e.toString()))
      .toList();
}

List<enums.TermsDocOutKind>? termsDocOutKindNullableListFromJson(
  List? termsDocOutKind, [
  List<enums.TermsDocOutKind>? defaultValue,
]) {
  if (termsDocOutKind == null) {
    return defaultValue;
  }

  return termsDocOutKind
      .map((e) => termsDocOutKindFromJson(e.toString()))
      .toList();
}

String? v1AdminFeedItemsGetStatusNullableToJson(
  enums.V1AdminFeedItemsGetStatus? v1AdminFeedItemsGetStatus,
) {
  return v1AdminFeedItemsGetStatus?.value;
}

String? v1AdminFeedItemsGetStatusToJson(
  enums.V1AdminFeedItemsGetStatus v1AdminFeedItemsGetStatus,
) {
  return v1AdminFeedItemsGetStatus.value;
}

enums.V1AdminFeedItemsGetStatus v1AdminFeedItemsGetStatusFromJson(
  Object? v1AdminFeedItemsGetStatus, [
  enums.V1AdminFeedItemsGetStatus? defaultValue,
]) {
  return enums.V1AdminFeedItemsGetStatus.values.firstWhereOrNull(
        (e) => e.value == v1AdminFeedItemsGetStatus,
      ) ??
      defaultValue ??
      enums.V1AdminFeedItemsGetStatus.swaggerGeneratedUnknown;
}

enums.V1AdminFeedItemsGetStatus? v1AdminFeedItemsGetStatusNullableFromJson(
  Object? v1AdminFeedItemsGetStatus, [
  enums.V1AdminFeedItemsGetStatus? defaultValue,
]) {
  if (v1AdminFeedItemsGetStatus == null) {
    return null;
  }
  return enums.V1AdminFeedItemsGetStatus.values.firstWhereOrNull(
        (e) => e.value == v1AdminFeedItemsGetStatus,
      ) ??
      defaultValue;
}

String v1AdminFeedItemsGetStatusExplodedListToJson(
  List<enums.V1AdminFeedItemsGetStatus>? v1AdminFeedItemsGetStatus,
) {
  return v1AdminFeedItemsGetStatus?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1AdminFeedItemsGetStatusListToJson(
  List<enums.V1AdminFeedItemsGetStatus>? v1AdminFeedItemsGetStatus,
) {
  if (v1AdminFeedItemsGetStatus == null) {
    return [];
  }

  return v1AdminFeedItemsGetStatus.map((e) => e.value!).toList();
}

List<enums.V1AdminFeedItemsGetStatus> v1AdminFeedItemsGetStatusListFromJson(
  List? v1AdminFeedItemsGetStatus, [
  List<enums.V1AdminFeedItemsGetStatus>? defaultValue,
]) {
  if (v1AdminFeedItemsGetStatus == null) {
    return defaultValue ?? [];
  }

  return v1AdminFeedItemsGetStatus
      .map((e) => v1AdminFeedItemsGetStatusFromJson(e.toString()))
      .toList();
}

List<enums.V1AdminFeedItemsGetStatus>?
v1AdminFeedItemsGetStatusNullableListFromJson(
  List? v1AdminFeedItemsGetStatus, [
  List<enums.V1AdminFeedItemsGetStatus>? defaultValue,
]) {
  if (v1AdminFeedItemsGetStatus == null) {
    return defaultValue;
  }

  return v1AdminFeedItemsGetStatus
      .map((e) => v1AdminFeedItemsGetStatusFromJson(e.toString()))
      .toList();
}

String? v1AdminFeedItemsItemIdTextsLangPutLangNullableToJson(
  enums.V1AdminFeedItemsItemIdTextsLangPutLang?
  v1AdminFeedItemsItemIdTextsLangPutLang,
) {
  return v1AdminFeedItemsItemIdTextsLangPutLang?.value;
}

String? v1AdminFeedItemsItemIdTextsLangPutLangToJson(
  enums.V1AdminFeedItemsItemIdTextsLangPutLang
  v1AdminFeedItemsItemIdTextsLangPutLang,
) {
  return v1AdminFeedItemsItemIdTextsLangPutLang.value;
}

enums.V1AdminFeedItemsItemIdTextsLangPutLang
v1AdminFeedItemsItemIdTextsLangPutLangFromJson(
  Object? v1AdminFeedItemsItemIdTextsLangPutLang, [
  enums.V1AdminFeedItemsItemIdTextsLangPutLang? defaultValue,
]) {
  return enums.V1AdminFeedItemsItemIdTextsLangPutLang.values.firstWhereOrNull(
        (e) => e.value == v1AdminFeedItemsItemIdTextsLangPutLang,
      ) ??
      defaultValue ??
      enums.V1AdminFeedItemsItemIdTextsLangPutLang.swaggerGeneratedUnknown;
}

enums.V1AdminFeedItemsItemIdTextsLangPutLang?
v1AdminFeedItemsItemIdTextsLangPutLangNullableFromJson(
  Object? v1AdminFeedItemsItemIdTextsLangPutLang, [
  enums.V1AdminFeedItemsItemIdTextsLangPutLang? defaultValue,
]) {
  if (v1AdminFeedItemsItemIdTextsLangPutLang == null) {
    return null;
  }
  return enums.V1AdminFeedItemsItemIdTextsLangPutLang.values.firstWhereOrNull(
        (e) => e.value == v1AdminFeedItemsItemIdTextsLangPutLang,
      ) ??
      defaultValue;
}

String v1AdminFeedItemsItemIdTextsLangPutLangExplodedListToJson(
  List<enums.V1AdminFeedItemsItemIdTextsLangPutLang>?
  v1AdminFeedItemsItemIdTextsLangPutLang,
) {
  return v1AdminFeedItemsItemIdTextsLangPutLang
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String> v1AdminFeedItemsItemIdTextsLangPutLangListToJson(
  List<enums.V1AdminFeedItemsItemIdTextsLangPutLang>?
  v1AdminFeedItemsItemIdTextsLangPutLang,
) {
  if (v1AdminFeedItemsItemIdTextsLangPutLang == null) {
    return [];
  }

  return v1AdminFeedItemsItemIdTextsLangPutLang.map((e) => e.value!).toList();
}

List<enums.V1AdminFeedItemsItemIdTextsLangPutLang>
v1AdminFeedItemsItemIdTextsLangPutLangListFromJson(
  List? v1AdminFeedItemsItemIdTextsLangPutLang, [
  List<enums.V1AdminFeedItemsItemIdTextsLangPutLang>? defaultValue,
]) {
  if (v1AdminFeedItemsItemIdTextsLangPutLang == null) {
    return defaultValue ?? [];
  }

  return v1AdminFeedItemsItemIdTextsLangPutLang
      .map((e) => v1AdminFeedItemsItemIdTextsLangPutLangFromJson(e.toString()))
      .toList();
}

List<enums.V1AdminFeedItemsItemIdTextsLangPutLang>?
v1AdminFeedItemsItemIdTextsLangPutLangNullableListFromJson(
  List? v1AdminFeedItemsItemIdTextsLangPutLang, [
  List<enums.V1AdminFeedItemsItemIdTextsLangPutLang>? defaultValue,
]) {
  if (v1AdminFeedItemsItemIdTextsLangPutLang == null) {
    return defaultValue;
  }

  return v1AdminFeedItemsItemIdTextsLangPutLang
      .map((e) => v1AdminFeedItemsItemIdTextsLangPutLangFromJson(e.toString()))
      .toList();
}

String? v1AdminKbImportsKindPostKindNullableToJson(
  enums.V1AdminKbImportsKindPostKind? v1AdminKbImportsKindPostKind,
) {
  return v1AdminKbImportsKindPostKind?.value;
}

String? v1AdminKbImportsKindPostKindToJson(
  enums.V1AdminKbImportsKindPostKind v1AdminKbImportsKindPostKind,
) {
  return v1AdminKbImportsKindPostKind.value;
}

enums.V1AdminKbImportsKindPostKind v1AdminKbImportsKindPostKindFromJson(
  Object? v1AdminKbImportsKindPostKind, [
  enums.V1AdminKbImportsKindPostKind? defaultValue,
]) {
  return enums.V1AdminKbImportsKindPostKind.values.firstWhereOrNull(
        (e) => e.value == v1AdminKbImportsKindPostKind,
      ) ??
      defaultValue ??
      enums.V1AdminKbImportsKindPostKind.swaggerGeneratedUnknown;
}

enums.V1AdminKbImportsKindPostKind?
v1AdminKbImportsKindPostKindNullableFromJson(
  Object? v1AdminKbImportsKindPostKind, [
  enums.V1AdminKbImportsKindPostKind? defaultValue,
]) {
  if (v1AdminKbImportsKindPostKind == null) {
    return null;
  }
  return enums.V1AdminKbImportsKindPostKind.values.firstWhereOrNull(
        (e) => e.value == v1AdminKbImportsKindPostKind,
      ) ??
      defaultValue;
}

String v1AdminKbImportsKindPostKindExplodedListToJson(
  List<enums.V1AdminKbImportsKindPostKind>? v1AdminKbImportsKindPostKind,
) {
  return v1AdminKbImportsKindPostKind?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1AdminKbImportsKindPostKindListToJson(
  List<enums.V1AdminKbImportsKindPostKind>? v1AdminKbImportsKindPostKind,
) {
  if (v1AdminKbImportsKindPostKind == null) {
    return [];
  }

  return v1AdminKbImportsKindPostKind.map((e) => e.value!).toList();
}

List<enums.V1AdminKbImportsKindPostKind>
v1AdminKbImportsKindPostKindListFromJson(
  List? v1AdminKbImportsKindPostKind, [
  List<enums.V1AdminKbImportsKindPostKind>? defaultValue,
]) {
  if (v1AdminKbImportsKindPostKind == null) {
    return defaultValue ?? [];
  }

  return v1AdminKbImportsKindPostKind
      .map((e) => v1AdminKbImportsKindPostKindFromJson(e.toString()))
      .toList();
}

List<enums.V1AdminKbImportsKindPostKind>?
v1AdminKbImportsKindPostKindNullableListFromJson(
  List? v1AdminKbImportsKindPostKind, [
  List<enums.V1AdminKbImportsKindPostKind>? defaultValue,
]) {
  if (v1AdminKbImportsKindPostKind == null) {
    return defaultValue;
  }

  return v1AdminKbImportsKindPostKind
      .map((e) => v1AdminKbImportsKindPostKindFromJson(e.toString()))
      .toList();
}

String?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeNullableToJson(
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
      ?.value;
}

String? v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeToJson(
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType.value;
}

enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeFromJson(
  Object? v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType, [
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType?
  defaultValue,
]) {
  return enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType,
          ) ??
      defaultValue ??
      enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
          .swaggerGeneratedUnknown;
}

enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeNullableFromJson(
  Object? v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType, [
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType ==
      null) {
    return null;
  }
  return enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType,
          ) ??
      defaultValue;
}

String
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeExplodedListToJson(
  List<enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType>?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String>
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeListToJson(
  List<enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType>?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType,
) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType ==
      null) {
    return [];
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
      .map((e) => e.value!)
      .toList();
}

List<enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType>
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeListFromJson(
  List? v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType, [
  List<enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType>?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType ==
      null) {
    return defaultValue ?? [];
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
      .map(
        (e) =>
            v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

List<enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType>?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeNullableListFromJson(
  List? v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType, [
  List<enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType>?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType ==
      null) {
    return defaultValue;
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectType
      .map(
        (e) =>
            v1AdminMarketLinkVerificationsSubjectTypeSubjectIdGetSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

String?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeNullableToJson(
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
      ?.value;
}

String?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeToJson(
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
      .value;
}

enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeFromJson(
  Object?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType, [
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType?
  defaultValue,
]) {
  return enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType,
          ) ??
      defaultValue ??
      enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
          .swaggerGeneratedUnknown;
}

enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeNullableFromJson(
  Object?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType, [
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType ==
      null) {
    return null;
  }
  return enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType,
          ) ??
      defaultValue;
}

String
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeExplodedListToJson(
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
  >?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String>
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeListToJson(
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
  >?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType,
) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType ==
      null) {
    return [];
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
      .map((e) => e.value!)
      .toList();
}

List<
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
>
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeListFromJson(
  List?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType, [
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
  >?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType ==
      null) {
    return defaultValue ?? [];
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
      .map(
        (e) =>
            v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

List<
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
>?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeNullableListFromJson(
  List?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType, [
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
  >?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType ==
      null) {
    return defaultValue;
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectType
      .map(
        (e) =>
            v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDecisionPostSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

String?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeNullableToJson(
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
      ?.value;
}

String?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeToJson(
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
      .value;
}

enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeFromJson(
  Object?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType, [
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType?
  defaultValue,
]) {
  return enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType,
          ) ??
      defaultValue ??
      enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
          .swaggerGeneratedUnknown;
}

enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeNullableFromJson(
  Object?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType, [
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType ==
      null) {
    return null;
  }
  return enums
          .V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType,
          ) ??
      defaultValue;
}

String
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeExplodedListToJson(
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
  >?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType,
) {
  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String>
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeListToJson(
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
  >?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType,
) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType ==
      null) {
    return [];
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
      .map((e) => e.value!)
      .toList();
}

List<
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
>
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeListFromJson(
  List?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType, [
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
  >?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType ==
      null) {
    return defaultValue ?? [];
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
      .map(
        (e) =>
            v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

List<
  enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
>?
v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeNullableListFromJson(
  List?
  v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType, [
  List<
    enums.V1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
  >?
  defaultValue,
]) {
  if (v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType ==
      null) {
    return defaultValue;
  }

  return v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectType
      .map(
        (e) =>
            v1AdminMarketLinkVerificationsSubjectTypeSubjectIdDocumentsIndexUrlGetSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

String? v1FeedGetLangNullableToJson(enums.V1FeedGetLang? v1FeedGetLang) {
  return v1FeedGetLang?.value;
}

String? v1FeedGetLangToJson(enums.V1FeedGetLang v1FeedGetLang) {
  return v1FeedGetLang.value;
}

enums.V1FeedGetLang v1FeedGetLangFromJson(
  Object? v1FeedGetLang, [
  enums.V1FeedGetLang? defaultValue,
]) {
  return enums.V1FeedGetLang.values.firstWhereOrNull(
        (e) => e.value == v1FeedGetLang,
      ) ??
      defaultValue ??
      enums.V1FeedGetLang.swaggerGeneratedUnknown;
}

enums.V1FeedGetLang? v1FeedGetLangNullableFromJson(
  Object? v1FeedGetLang, [
  enums.V1FeedGetLang? defaultValue,
]) {
  if (v1FeedGetLang == null) {
    return null;
  }
  return enums.V1FeedGetLang.values.firstWhereOrNull(
        (e) => e.value == v1FeedGetLang,
      ) ??
      defaultValue;
}

String v1FeedGetLangExplodedListToJson(
  List<enums.V1FeedGetLang>? v1FeedGetLang,
) {
  return v1FeedGetLang?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1FeedGetLangListToJson(List<enums.V1FeedGetLang>? v1FeedGetLang) {
  if (v1FeedGetLang == null) {
    return [];
  }

  return v1FeedGetLang.map((e) => e.value!).toList();
}

List<enums.V1FeedGetLang> v1FeedGetLangListFromJson(
  List? v1FeedGetLang, [
  List<enums.V1FeedGetLang>? defaultValue,
]) {
  if (v1FeedGetLang == null) {
    return defaultValue ?? [];
  }

  return v1FeedGetLang.map((e) => v1FeedGetLangFromJson(e.toString())).toList();
}

List<enums.V1FeedGetLang>? v1FeedGetLangNullableListFromJson(
  List? v1FeedGetLang, [
  List<enums.V1FeedGetLang>? defaultValue,
]) {
  if (v1FeedGetLang == null) {
    return defaultValue;
  }

  return v1FeedGetLang.map((e) => v1FeedGetLangFromJson(e.toString())).toList();
}

String? v1FeedCheckPostLangNullableToJson(
  enums.V1FeedCheckPostLang? v1FeedCheckPostLang,
) {
  return v1FeedCheckPostLang?.value;
}

String? v1FeedCheckPostLangToJson(
  enums.V1FeedCheckPostLang v1FeedCheckPostLang,
) {
  return v1FeedCheckPostLang.value;
}

enums.V1FeedCheckPostLang v1FeedCheckPostLangFromJson(
  Object? v1FeedCheckPostLang, [
  enums.V1FeedCheckPostLang? defaultValue,
]) {
  return enums.V1FeedCheckPostLang.values.firstWhereOrNull(
        (e) => e.value == v1FeedCheckPostLang,
      ) ??
      defaultValue ??
      enums.V1FeedCheckPostLang.swaggerGeneratedUnknown;
}

enums.V1FeedCheckPostLang? v1FeedCheckPostLangNullableFromJson(
  Object? v1FeedCheckPostLang, [
  enums.V1FeedCheckPostLang? defaultValue,
]) {
  if (v1FeedCheckPostLang == null) {
    return null;
  }
  return enums.V1FeedCheckPostLang.values.firstWhereOrNull(
        (e) => e.value == v1FeedCheckPostLang,
      ) ??
      defaultValue;
}

String v1FeedCheckPostLangExplodedListToJson(
  List<enums.V1FeedCheckPostLang>? v1FeedCheckPostLang,
) {
  return v1FeedCheckPostLang?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1FeedCheckPostLangListToJson(
  List<enums.V1FeedCheckPostLang>? v1FeedCheckPostLang,
) {
  if (v1FeedCheckPostLang == null) {
    return [];
  }

  return v1FeedCheckPostLang.map((e) => e.value!).toList();
}

List<enums.V1FeedCheckPostLang> v1FeedCheckPostLangListFromJson(
  List? v1FeedCheckPostLang, [
  List<enums.V1FeedCheckPostLang>? defaultValue,
]) {
  if (v1FeedCheckPostLang == null) {
    return defaultValue ?? [];
  }

  return v1FeedCheckPostLang
      .map((e) => v1FeedCheckPostLangFromJson(e.toString()))
      .toList();
}

List<enums.V1FeedCheckPostLang>? v1FeedCheckPostLangNullableListFromJson(
  List? v1FeedCheckPostLang, [
  List<enums.V1FeedCheckPostLang>? defaultValue,
]) {
  if (v1FeedCheckPostLang == null) {
    return defaultValue;
  }

  return v1FeedCheckPostLang
      .map((e) => v1FeedCheckPostLangFromJson(e.toString()))
      .toList();
}

String? v1InsuranceDeadlinesGetLangNullableToJson(
  enums.V1InsuranceDeadlinesGetLang? v1InsuranceDeadlinesGetLang,
) {
  return v1InsuranceDeadlinesGetLang?.value;
}

String? v1InsuranceDeadlinesGetLangToJson(
  enums.V1InsuranceDeadlinesGetLang v1InsuranceDeadlinesGetLang,
) {
  return v1InsuranceDeadlinesGetLang.value;
}

enums.V1InsuranceDeadlinesGetLang v1InsuranceDeadlinesGetLangFromJson(
  Object? v1InsuranceDeadlinesGetLang, [
  enums.V1InsuranceDeadlinesGetLang? defaultValue,
]) {
  return enums.V1InsuranceDeadlinesGetLang.values.firstWhereOrNull(
        (e) => e.value == v1InsuranceDeadlinesGetLang,
      ) ??
      defaultValue ??
      enums.V1InsuranceDeadlinesGetLang.swaggerGeneratedUnknown;
}

enums.V1InsuranceDeadlinesGetLang? v1InsuranceDeadlinesGetLangNullableFromJson(
  Object? v1InsuranceDeadlinesGetLang, [
  enums.V1InsuranceDeadlinesGetLang? defaultValue,
]) {
  if (v1InsuranceDeadlinesGetLang == null) {
    return null;
  }
  return enums.V1InsuranceDeadlinesGetLang.values.firstWhereOrNull(
        (e) => e.value == v1InsuranceDeadlinesGetLang,
      ) ??
      defaultValue;
}

String v1InsuranceDeadlinesGetLangExplodedListToJson(
  List<enums.V1InsuranceDeadlinesGetLang>? v1InsuranceDeadlinesGetLang,
) {
  return v1InsuranceDeadlinesGetLang?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1InsuranceDeadlinesGetLangListToJson(
  List<enums.V1InsuranceDeadlinesGetLang>? v1InsuranceDeadlinesGetLang,
) {
  if (v1InsuranceDeadlinesGetLang == null) {
    return [];
  }

  return v1InsuranceDeadlinesGetLang.map((e) => e.value!).toList();
}

List<enums.V1InsuranceDeadlinesGetLang> v1InsuranceDeadlinesGetLangListFromJson(
  List? v1InsuranceDeadlinesGetLang, [
  List<enums.V1InsuranceDeadlinesGetLang>? defaultValue,
]) {
  if (v1InsuranceDeadlinesGetLang == null) {
    return defaultValue ?? [];
  }

  return v1InsuranceDeadlinesGetLang
      .map((e) => v1InsuranceDeadlinesGetLangFromJson(e.toString()))
      .toList();
}

List<enums.V1InsuranceDeadlinesGetLang>?
v1InsuranceDeadlinesGetLangNullableListFromJson(
  List? v1InsuranceDeadlinesGetLang, [
  List<enums.V1InsuranceDeadlinesGetLang>? defaultValue,
]) {
  if (v1InsuranceDeadlinesGetLang == null) {
    return defaultValue;
  }

  return v1InsuranceDeadlinesGetLang
      .map((e) => v1InsuranceDeadlinesGetLangFromJson(e.toString()))
      .toList();
}

String? v1MarketLinkProfilesGetRoleNullableToJson(
  enums.V1MarketLinkProfilesGetRole? v1MarketLinkProfilesGetRole,
) {
  return v1MarketLinkProfilesGetRole?.value;
}

String? v1MarketLinkProfilesGetRoleToJson(
  enums.V1MarketLinkProfilesGetRole v1MarketLinkProfilesGetRole,
) {
  return v1MarketLinkProfilesGetRole.value;
}

enums.V1MarketLinkProfilesGetRole v1MarketLinkProfilesGetRoleFromJson(
  Object? v1MarketLinkProfilesGetRole, [
  enums.V1MarketLinkProfilesGetRole? defaultValue,
]) {
  return enums.V1MarketLinkProfilesGetRole.values.firstWhereOrNull(
        (e) => e.value == v1MarketLinkProfilesGetRole,
      ) ??
      defaultValue ??
      enums.V1MarketLinkProfilesGetRole.swaggerGeneratedUnknown;
}

enums.V1MarketLinkProfilesGetRole? v1MarketLinkProfilesGetRoleNullableFromJson(
  Object? v1MarketLinkProfilesGetRole, [
  enums.V1MarketLinkProfilesGetRole? defaultValue,
]) {
  if (v1MarketLinkProfilesGetRole == null) {
    return null;
  }
  return enums.V1MarketLinkProfilesGetRole.values.firstWhereOrNull(
        (e) => e.value == v1MarketLinkProfilesGetRole,
      ) ??
      defaultValue;
}

String v1MarketLinkProfilesGetRoleExplodedListToJson(
  List<enums.V1MarketLinkProfilesGetRole>? v1MarketLinkProfilesGetRole,
) {
  return v1MarketLinkProfilesGetRole?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1MarketLinkProfilesGetRoleListToJson(
  List<enums.V1MarketLinkProfilesGetRole>? v1MarketLinkProfilesGetRole,
) {
  if (v1MarketLinkProfilesGetRole == null) {
    return [];
  }

  return v1MarketLinkProfilesGetRole.map((e) => e.value!).toList();
}

List<enums.V1MarketLinkProfilesGetRole> v1MarketLinkProfilesGetRoleListFromJson(
  List? v1MarketLinkProfilesGetRole, [
  List<enums.V1MarketLinkProfilesGetRole>? defaultValue,
]) {
  if (v1MarketLinkProfilesGetRole == null) {
    return defaultValue ?? [];
  }

  return v1MarketLinkProfilesGetRole
      .map((e) => v1MarketLinkProfilesGetRoleFromJson(e.toString()))
      .toList();
}

List<enums.V1MarketLinkProfilesGetRole>?
v1MarketLinkProfilesGetRoleNullableListFromJson(
  List? v1MarketLinkProfilesGetRole, [
  List<enums.V1MarketLinkProfilesGetRole>? defaultValue,
]) {
  if (v1MarketLinkProfilesGetRole == null) {
    return defaultValue;
  }

  return v1MarketLinkProfilesGetRole
      .map((e) => v1MarketLinkProfilesGetRoleFromJson(e.toString()))
      .toList();
}

String? v1MarketLinkProfilesGetSortNullableToJson(
  enums.V1MarketLinkProfilesGetSort? v1MarketLinkProfilesGetSort,
) {
  return v1MarketLinkProfilesGetSort?.value;
}

String? v1MarketLinkProfilesGetSortToJson(
  enums.V1MarketLinkProfilesGetSort v1MarketLinkProfilesGetSort,
) {
  return v1MarketLinkProfilesGetSort.value;
}

enums.V1MarketLinkProfilesGetSort v1MarketLinkProfilesGetSortFromJson(
  Object? v1MarketLinkProfilesGetSort, [
  enums.V1MarketLinkProfilesGetSort? defaultValue,
]) {
  return enums.V1MarketLinkProfilesGetSort.values.firstWhereOrNull(
        (e) => e.value == v1MarketLinkProfilesGetSort,
      ) ??
      defaultValue ??
      enums.V1MarketLinkProfilesGetSort.swaggerGeneratedUnknown;
}

enums.V1MarketLinkProfilesGetSort? v1MarketLinkProfilesGetSortNullableFromJson(
  Object? v1MarketLinkProfilesGetSort, [
  enums.V1MarketLinkProfilesGetSort? defaultValue,
]) {
  if (v1MarketLinkProfilesGetSort == null) {
    return null;
  }
  return enums.V1MarketLinkProfilesGetSort.values.firstWhereOrNull(
        (e) => e.value == v1MarketLinkProfilesGetSort,
      ) ??
      defaultValue;
}

String v1MarketLinkProfilesGetSortExplodedListToJson(
  List<enums.V1MarketLinkProfilesGetSort>? v1MarketLinkProfilesGetSort,
) {
  return v1MarketLinkProfilesGetSort?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1MarketLinkProfilesGetSortListToJson(
  List<enums.V1MarketLinkProfilesGetSort>? v1MarketLinkProfilesGetSort,
) {
  if (v1MarketLinkProfilesGetSort == null) {
    return [];
  }

  return v1MarketLinkProfilesGetSort.map((e) => e.value!).toList();
}

List<enums.V1MarketLinkProfilesGetSort> v1MarketLinkProfilesGetSortListFromJson(
  List? v1MarketLinkProfilesGetSort, [
  List<enums.V1MarketLinkProfilesGetSort>? defaultValue,
]) {
  if (v1MarketLinkProfilesGetSort == null) {
    return defaultValue ?? [];
  }

  return v1MarketLinkProfilesGetSort
      .map((e) => v1MarketLinkProfilesGetSortFromJson(e.toString()))
      .toList();
}

List<enums.V1MarketLinkProfilesGetSort>?
v1MarketLinkProfilesGetSortNullableListFromJson(
  List? v1MarketLinkProfilesGetSort, [
  List<enums.V1MarketLinkProfilesGetSort>? defaultValue,
]) {
  if (v1MarketLinkProfilesGetSort == null) {
    return defaultValue;
  }

  return v1MarketLinkProfilesGetSort
      .map((e) => v1MarketLinkProfilesGetSortFromJson(e.toString()))
      .toList();
}

String? v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeNullableToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType?
  v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType?.value;
}

String? v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType
  v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType.value;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType
v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType? defaultValue,
]) {
  return enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType.values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType,
          ) ??
      defaultValue ??
      enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType
          .swaggerGeneratedUnknown;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType?
v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeNullableFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType? defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType == null) {
    return null;
  }
  return enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType.values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType,
          ) ??
      defaultValue;
}

String v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeExplodedListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String> v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType,
) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType == null) {
    return [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType
      .map((e) => e.value!)
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType>
v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType == null) {
    return defaultValue ?? [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType
      .map(
        (e) => v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeFromJson(
          e.toString(),
        ),
      )
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType>?
v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeNullableListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType == null) {
    return defaultValue;
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectType
      .map(
        (e) => v1MarketLinkProfilesSubjectTypeSubjectIdGetSubjectTypeFromJson(
          e.toString(),
        ),
      )
      .toList();
}

String?
v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeNullableToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType?
  v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType?.value;
}

String? v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
  v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType.value;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType?
  defaultValue,
]) {
  return enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType,
          ) ??
      defaultValue ??
      enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
          .swaggerGeneratedUnknown;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType?
v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeNullableFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType == null) {
    return null;
  }
  return enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType,
          ) ??
      defaultValue;
}

String
v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeExplodedListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String>
v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType,
) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType == null) {
    return [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
      .map((e) => e.value!)
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType>
v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType == null) {
    return defaultValue ?? [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
      .map(
        (e) =>
            v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType>?
v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeNullableListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType == null) {
    return defaultValue;
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectType
      .map(
        (e) =>
            v1MarketLinkProfilesSubjectTypeSubjectIdAddressPutSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

String?
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeNullableToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType?
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
      ?.value;
}

String? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType.value;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType?
  defaultValue,
]) {
  return enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType,
          ) ??
      defaultValue ??
      enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
          .swaggerGeneratedUnknown;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType?
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeNullableFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType ==
      null) {
    return null;
  }
  return enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType,
          ) ??
      defaultValue;
}

String
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeExplodedListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String>
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType,
) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType ==
      null) {
    return [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
      .map((e) => e.value!)
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType>
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType ==
      null) {
    return defaultValue ?? [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
      .map(
        (e) =>
            v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType>?
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeNullableListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType ==
      null) {
    return defaultValue;
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectType
      .map(
        (e) =>
            v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

String? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocNullableToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc?
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc?.value;
}

String? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc.value;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc? defaultValue,
]) {
  return enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc.values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc,
          ) ??
      defaultValue ??
      enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc
          .swaggerGeneratedUnknown;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc?
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocNullableFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc? defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc == null) {
    return null;
  }
  return enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc.values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc,
          ) ??
      defaultValue;
}

String
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocExplodedListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc>?
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String> v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc>?
  v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc,
) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc == null) {
    return [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc
      .map((e) => e.value!)
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc>
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc == null) {
    return defaultValue ?? [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc
      .map(
        (e) => v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocFromJson(
          e.toString(),
        ),
      )
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc>?
v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocNullableListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc == null) {
    return defaultValue;
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDoc
      .map(
        (e) => v1MarketLinkProfilesSubjectTypeSubjectIdDocumentsPostDocFromJson(
          e.toString(),
        ),
      )
      .toList();
}

String?
v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeNullableToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType?
  v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
      ?.value;
}

String? v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeToJson(
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
  v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
      .value;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType?
  defaultValue,
]) {
  return enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType,
          ) ??
      defaultValue ??
      enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
          .swaggerGeneratedUnknown;
}

enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType?
v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeNullableFromJson(
  Object? v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType, [
  enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType ==
      null) {
    return null;
  }
  return enums
          .V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
          .values
          .firstWhereOrNull(
            (e) =>
                e.value ==
                v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType,
          ) ??
      defaultValue;
}

String
v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeExplodedListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType,
) {
  return v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
          ?.map((e) => e.value!)
          .join(',') ??
      '';
}

List<String>
v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeListToJson(
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType>?
  v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType,
) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType ==
      null) {
    return [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
      .map((e) => e.value!)
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType>
v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType ==
      null) {
    return defaultValue ?? [];
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
      .map(
        (e) =>
            v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType>?
v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeNullableListFromJson(
  List? v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType, [
  List<enums.V1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType>?
  defaultValue,
]) {
  if (v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType ==
      null) {
    return defaultValue;
  }

  return v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectType
      .map(
        (e) =>
            v1MarketLinkProfilesSubjectTypeSubjectIdPlacePhotoPostSubjectTypeFromJson(
              e.toString(),
            ),
      )
      .toList();
}

String? v1MarketPricesGetScopeNullableToJson(
  enums.V1MarketPricesGetScope? v1MarketPricesGetScope,
) {
  return v1MarketPricesGetScope?.value;
}

String? v1MarketPricesGetScopeToJson(
  enums.V1MarketPricesGetScope v1MarketPricesGetScope,
) {
  return v1MarketPricesGetScope.value;
}

enums.V1MarketPricesGetScope v1MarketPricesGetScopeFromJson(
  Object? v1MarketPricesGetScope, [
  enums.V1MarketPricesGetScope? defaultValue,
]) {
  return enums.V1MarketPricesGetScope.values.firstWhereOrNull(
        (e) => e.value == v1MarketPricesGetScope,
      ) ??
      defaultValue ??
      enums.V1MarketPricesGetScope.swaggerGeneratedUnknown;
}

enums.V1MarketPricesGetScope? v1MarketPricesGetScopeNullableFromJson(
  Object? v1MarketPricesGetScope, [
  enums.V1MarketPricesGetScope? defaultValue,
]) {
  if (v1MarketPricesGetScope == null) {
    return null;
  }
  return enums.V1MarketPricesGetScope.values.firstWhereOrNull(
        (e) => e.value == v1MarketPricesGetScope,
      ) ??
      defaultValue;
}

String v1MarketPricesGetScopeExplodedListToJson(
  List<enums.V1MarketPricesGetScope>? v1MarketPricesGetScope,
) {
  return v1MarketPricesGetScope?.map((e) => e.value!).join(',') ?? '';
}

List<String> v1MarketPricesGetScopeListToJson(
  List<enums.V1MarketPricesGetScope>? v1MarketPricesGetScope,
) {
  if (v1MarketPricesGetScope == null) {
    return [];
  }

  return v1MarketPricesGetScope.map((e) => e.value!).toList();
}

List<enums.V1MarketPricesGetScope> v1MarketPricesGetScopeListFromJson(
  List? v1MarketPricesGetScope, [
  List<enums.V1MarketPricesGetScope>? defaultValue,
]) {
  if (v1MarketPricesGetScope == null) {
    return defaultValue ?? [];
  }

  return v1MarketPricesGetScope
      .map((e) => v1MarketPricesGetScopeFromJson(e.toString()))
      .toList();
}

List<enums.V1MarketPricesGetScope>? v1MarketPricesGetScopeNullableListFromJson(
  List? v1MarketPricesGetScope, [
  List<enums.V1MarketPricesGetScope>? defaultValue,
]) {
  if (v1MarketPricesGetScope == null) {
    return defaultValue;
  }

  return v1MarketPricesGetScope
      .map((e) => v1MarketPricesGetScopeFromJson(e.toString()))
      .toList();
}

// ignore: unused_element
String? _dateToJson(DateTime? date) {
  if (date == null) {
    return null;
  }

  final year = date.year.toString();
  final month = date.month < 10 ? '0${date.month}' : date.month.toString();
  final day = date.day < 10 ? '0${date.day}' : date.day.toString();

  return '$year-$month-$day';
}

class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}
