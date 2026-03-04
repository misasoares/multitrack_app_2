// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist_item_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SetlistItemModelSchema = Schema(
  name: r'SetlistItemModel',
  id: -1248574815608723760,
  properties: {
    r'exportedItemDirectory': PropertySchema(
      id: 0,
      name: r'exportedItemDirectory',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 1,
      name: r'id',
      type: IsarType.string,
    ),
    r'masterEqBands': PropertySchema(
      id: 2,
      name: r'masterEqBands',
      type: IsarType.objectList,
      target: r'EqBandModel',
    ),
    r'normalizationGain': PropertySchema(
      id: 3,
      name: r'normalizationGain',
      type: IsarType.double,
    ),
    r'originalMusicArtist': PropertySchema(
      id: 4,
      name: r'originalMusicArtist',
      type: IsarType.string,
    ),
    r'originalMusicBpm': PropertySchema(
      id: 5,
      name: r'originalMusicBpm',
      type: IsarType.long,
    ),
    r'originalMusicCreatedAt': PropertySchema(
      id: 6,
      name: r'originalMusicCreatedAt',
      type: IsarType.dateTime,
    ),
    r'originalMusicId': PropertySchema(
      id: 7,
      name: r'originalMusicId',
      type: IsarType.string,
    ),
    r'originalMusicKey': PropertySchema(
      id: 8,
      name: r'originalMusicKey',
      type: IsarType.string,
    ),
    r'originalMusicMarkers': PropertySchema(
      id: 9,
      name: r'originalMusicMarkers',
      type: IsarType.objectList,
      target: r'MarkerModel',
    ),
    r'originalMusicTimeSignatureDenominator': PropertySchema(
      id: 10,
      name: r'originalMusicTimeSignatureDenominator',
      type: IsarType.long,
    ),
    r'originalMusicTimeSignatureNumerator': PropertySchema(
      id: 11,
      name: r'originalMusicTimeSignatureNumerator',
      type: IsarType.long,
    ),
    r'originalMusicTitle': PropertySchema(
      id: 12,
      name: r'originalMusicTitle',
      type: IsarType.string,
    ),
    r'originalMusicTracks': PropertySchema(
      id: 13,
      name: r'originalMusicTracks',
      type: IsarType.objectList,
      target: r'TrackModel',
    ),
    r'originalMusicUpdatedAt': PropertySchema(
      id: 14,
      name: r'originalMusicUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'tempoFactor': PropertySchema(
      id: 15,
      name: r'tempoFactor',
      type: IsarType.double,
    ),
    r'transposableTrackIds': PropertySchema(
      id: 16,
      name: r'transposableTrackIds',
      type: IsarType.stringList,
    ),
    r'transposeSemitones': PropertySchema(
      id: 17,
      name: r'transposeSemitones',
      type: IsarType.long,
    ),
    r'volume': PropertySchema(
      id: 18,
      name: r'volume',
      type: IsarType.double,
    )
  },
  estimateSize: _setlistItemModelEstimateSize,
  serialize: _setlistItemModelSerialize,
  deserialize: _setlistItemModelDeserialize,
  deserializeProp: _setlistItemModelDeserializeProp,
);

int _setlistItemModelEstimateSize(
  SetlistItemModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.exportedItemDirectory;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.id;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.masterEqBands;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[EqBandModel]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              EqBandModelSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.originalMusicArtist;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.originalMusicId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.originalMusicKey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.originalMusicMarkers;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[MarkerModel]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              MarkerModelSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final value = object.originalMusicTitle;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.originalMusicTracks;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[TrackModel]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              TrackModelSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final list = object.transposableTrackIds;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  return bytesCount;
}

void _setlistItemModelSerialize(
  SetlistItemModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.exportedItemDirectory);
  writer.writeString(offsets[1], object.id);
  writer.writeObjectList<EqBandModel>(
    offsets[2],
    allOffsets,
    EqBandModelSchema.serialize,
    object.masterEqBands,
  );
  writer.writeDouble(offsets[3], object.normalizationGain);
  writer.writeString(offsets[4], object.originalMusicArtist);
  writer.writeLong(offsets[5], object.originalMusicBpm);
  writer.writeDateTime(offsets[6], object.originalMusicCreatedAt);
  writer.writeString(offsets[7], object.originalMusicId);
  writer.writeString(offsets[8], object.originalMusicKey);
  writer.writeObjectList<MarkerModel>(
    offsets[9],
    allOffsets,
    MarkerModelSchema.serialize,
    object.originalMusicMarkers,
  );
  writer.writeLong(offsets[10], object.originalMusicTimeSignatureDenominator);
  writer.writeLong(offsets[11], object.originalMusicTimeSignatureNumerator);
  writer.writeString(offsets[12], object.originalMusicTitle);
  writer.writeObjectList<TrackModel>(
    offsets[13],
    allOffsets,
    TrackModelSchema.serialize,
    object.originalMusicTracks,
  );
  writer.writeDateTime(offsets[14], object.originalMusicUpdatedAt);
  writer.writeDouble(offsets[15], object.tempoFactor);
  writer.writeStringList(offsets[16], object.transposableTrackIds);
  writer.writeLong(offsets[17], object.transposeSemitones);
  writer.writeDouble(offsets[18], object.volume);
}

SetlistItemModel _setlistItemModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SetlistItemModel(
    exportedItemDirectory: reader.readStringOrNull(offsets[0]),
    id: reader.readStringOrNull(offsets[1]),
    masterEqBands: reader.readObjectList<EqBandModel>(
      offsets[2],
      EqBandModelSchema.deserialize,
      allOffsets,
      EqBandModel(),
    ),
    normalizationGain: reader.readDoubleOrNull(offsets[3]),
    originalMusicArtist: reader.readStringOrNull(offsets[4]),
    originalMusicBpm: reader.readLongOrNull(offsets[5]),
    originalMusicCreatedAt: reader.readDateTimeOrNull(offsets[6]),
    originalMusicId: reader.readStringOrNull(offsets[7]),
    originalMusicKey: reader.readStringOrNull(offsets[8]),
    originalMusicMarkers: reader.readObjectList<MarkerModel>(
      offsets[9],
      MarkerModelSchema.deserialize,
      allOffsets,
      MarkerModel(),
    ),
    originalMusicTimeSignatureDenominator: reader.readLongOrNull(offsets[10]),
    originalMusicTimeSignatureNumerator: reader.readLongOrNull(offsets[11]),
    originalMusicTitle: reader.readStringOrNull(offsets[12]),
    originalMusicTracks: reader.readObjectList<TrackModel>(
      offsets[13],
      TrackModelSchema.deserialize,
      allOffsets,
      TrackModel(),
    ),
    originalMusicUpdatedAt: reader.readDateTimeOrNull(offsets[14]),
    tempoFactor: reader.readDoubleOrNull(offsets[15]),
    transposableTrackIds: reader.readStringList(offsets[16]),
    transposeSemitones: reader.readLongOrNull(offsets[17]),
    volume: reader.readDoubleOrNull(offsets[18]),
  );
  return object;
}

P _setlistItemModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readObjectList<EqBandModel>(
        offset,
        EqBandModelSchema.deserialize,
        allOffsets,
        EqBandModel(),
      )) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readObjectList<MarkerModel>(
        offset,
        MarkerModelSchema.deserialize,
        allOffsets,
        MarkerModel(),
      )) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readObjectList<TrackModel>(
        offset,
        TrackModelSchema.deserialize,
        allOffsets,
        TrackModel(),
      )) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readStringList(offset)) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SetlistItemModelQueryFilter
    on QueryBuilder<SetlistItemModel, SetlistItemModel, QFilterCondition> {
  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exportedItemDirectory',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exportedItemDirectory',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exportedItemDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exportedItemDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exportedItemDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exportedItemDirectory',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exportedItemDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exportedItemDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exportedItemDirectory',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exportedItemDirectory',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exportedItemDirectory',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      exportedItemDirectoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exportedItemDirectory',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'masterEqBands',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'masterEqBands',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'masterEqBands',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'masterEqBands',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'masterEqBands',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'masterEqBands',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'masterEqBands',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'masterEqBands',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      normalizationGainIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'normalizationGain',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      normalizationGainIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'normalizationGain',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      normalizationGainEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'normalizationGain',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      normalizationGainGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'normalizationGain',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      normalizationGainLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'normalizationGain',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      normalizationGainBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'normalizationGain',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicArtist',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicArtist',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicArtist',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalMusicArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalMusicArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalMusicArtist',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalMusicArtist',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicArtist',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicArtistIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalMusicArtist',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicBpmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicBpm',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicBpmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicBpm',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicBpmEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicBpmGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicBpmLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicBpm',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicBpmBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicBpm',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicCreatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicCreatedAt',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicCreatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicCreatedAt',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicCreatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicCreatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicCreatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicCreatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicCreatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicCreatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicCreatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicCreatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicId',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicId',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalMusicId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalMusicId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicId',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalMusicId',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicKey',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicKey',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalMusicKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalMusicKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalMusicKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalMusicKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicKey',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalMusicKey',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicMarkers',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicMarkers',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicMarkers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicMarkers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicMarkers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicMarkers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicMarkers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicMarkers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureDenominatorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicTimeSignatureDenominator',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureDenominatorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicTimeSignatureDenominator',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureDenominatorEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicTimeSignatureDenominator',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureDenominatorGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicTimeSignatureDenominator',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureDenominatorLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicTimeSignatureDenominator',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureDenominatorBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicTimeSignatureDenominator',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureNumeratorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicTimeSignatureNumerator',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureNumeratorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicTimeSignatureNumerator',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureNumeratorEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicTimeSignatureNumerator',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureNumeratorGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicTimeSignatureNumerator',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureNumeratorLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicTimeSignatureNumerator',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTimeSignatureNumeratorBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicTimeSignatureNumerator',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicTitle',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicTitle',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'originalMusicTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'originalMusicTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'originalMusicTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'originalMusicTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'originalMusicTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicTracks',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicTracks',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicTracks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicTracks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicTracks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicTracks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicTracks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'originalMusicTracks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalMusicUpdatedAt',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalMusicUpdatedAt',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalMusicUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicUpdatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalMusicUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicUpdatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalMusicUpdatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalMusicUpdatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      tempoFactorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tempoFactor',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      tempoFactorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tempoFactor',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      tempoFactorEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tempoFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      tempoFactorGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tempoFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      tempoFactorLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tempoFactor',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      tempoFactorBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tempoFactor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transposableTrackIds',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transposableTrackIds',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transposableTrackIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transposableTrackIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transposableTrackIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transposableTrackIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'transposableTrackIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'transposableTrackIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'transposableTrackIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'transposableTrackIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transposableTrackIds',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'transposableTrackIds',
        value: '',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transposableTrackIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transposableTrackIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transposableTrackIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transposableTrackIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transposableTrackIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposableTrackIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'transposableTrackIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposeSemitonesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'transposeSemitones',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposeSemitonesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'transposeSemitones',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposeSemitonesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transposeSemitones',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposeSemitonesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transposeSemitones',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposeSemitonesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transposeSemitones',
        value: value,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      transposeSemitonesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transposeSemitones',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      volumeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'volume',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      volumeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'volume',
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      volumeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'volume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      volumeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'volume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      volumeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'volume',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      volumeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'volume',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension SetlistItemModelQueryObject
    on QueryBuilder<SetlistItemModel, SetlistItemModel, QFilterCondition> {
  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      masterEqBandsElement(FilterQuery<EqBandModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'masterEqBands');
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicMarkersElement(FilterQuery<MarkerModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'originalMusicMarkers');
    });
  }

  QueryBuilder<SetlistItemModel, SetlistItemModel, QAfterFilterCondition>
      originalMusicTracksElement(FilterQuery<TrackModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'originalMusicTracks');
    });
  }
}
