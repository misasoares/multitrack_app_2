// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TrackModelSchema = Schema(
  name: r'TrackModel',
  id: -624065756729765013,
  properties: {
    r'applyTranspose': PropertySchema(
      id: 0,
      name: r'applyTranspose',
      type: IsarType.bool,
    ),
    r'durationInMilliseconds': PropertySchema(
      id: 1,
      name: r'durationInMilliseconds',
      type: IsarType.long,
    ),
    r'eqBands': PropertySchema(
      id: 2,
      name: r'eqBands',
      type: IsarType.objectList,
      target: r'EqBandModel',
    ),
    r'filePath': PropertySchema(
      id: 3,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 4,
      name: r'id',
      type: IsarType.string,
    ),
    r'isClick': PropertySchema(
      id: 5,
      name: r'isClick',
      type: IsarType.bool,
    ),
    r'isMuted': PropertySchema(
      id: 6,
      name: r'isMuted',
      type: IsarType.bool,
    ),
    r'isSolo': PropertySchema(
      id: 7,
      name: r'isSolo',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 8,
      name: r'name',
      type: IsarType.string,
    ),
    r'octaveShift': PropertySchema(
      id: 9,
      name: r'octaveShift',
      type: IsarType.long,
    ),
    r'order': PropertySchema(
      id: 10,
      name: r'order',
      type: IsarType.long,
    ),
    r'pan': PropertySchema(
      id: 11,
      name: r'pan',
      type: IsarType.double,
    ),
    r'volume': PropertySchema(
      id: 12,
      name: r'volume',
      type: IsarType.double,
    ),
    r'waveformPeaks': PropertySchema(
      id: 13,
      name: r'waveformPeaks',
      type: IsarType.doubleList,
    )
  },
  estimateSize: _trackModelEstimateSize,
  serialize: _trackModelSerialize,
  deserialize: _trackModelDeserialize,
  deserializeProp: _trackModelDeserializeProp,
);

int _trackModelEstimateSize(
  TrackModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.eqBands;
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
    final value = object.filePath;
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
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.waveformPeaks;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  return bytesCount;
}

void _trackModelSerialize(
  TrackModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.applyTranspose);
  writer.writeLong(offsets[1], object.durationInMilliseconds);
  writer.writeObjectList<EqBandModel>(
    offsets[2],
    allOffsets,
    EqBandModelSchema.serialize,
    object.eqBands,
  );
  writer.writeString(offsets[3], object.filePath);
  writer.writeString(offsets[4], object.id);
  writer.writeBool(offsets[5], object.isClick);
  writer.writeBool(offsets[6], object.isMuted);
  writer.writeBool(offsets[7], object.isSolo);
  writer.writeString(offsets[8], object.name);
  writer.writeLong(offsets[9], object.octaveShift);
  writer.writeLong(offsets[10], object.order);
  writer.writeDouble(offsets[11], object.pan);
  writer.writeDouble(offsets[12], object.volume);
  writer.writeDoubleList(offsets[13], object.waveformPeaks);
}

TrackModel _trackModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TrackModel(
    applyTranspose: reader.readBoolOrNull(offsets[0]),
    durationInMilliseconds: reader.readLongOrNull(offsets[1]),
    eqBands: reader.readObjectList<EqBandModel>(
      offsets[2],
      EqBandModelSchema.deserialize,
      allOffsets,
      EqBandModel(),
    ),
    filePath: reader.readStringOrNull(offsets[3]),
    id: reader.readStringOrNull(offsets[4]),
    isClick: reader.readBoolOrNull(offsets[5]),
    isMuted: reader.readBoolOrNull(offsets[6]),
    isSolo: reader.readBoolOrNull(offsets[7]),
    name: reader.readStringOrNull(offsets[8]),
    octaveShift: reader.readLongOrNull(offsets[9]),
    order: reader.readLongOrNull(offsets[10]),
    pan: reader.readDoubleOrNull(offsets[11]),
    volume: reader.readDoubleOrNull(offsets[12]),
    waveformPeaks: reader.readDoubleList(offsets[13]),
  );
  return object;
}

P _trackModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readObjectList<EqBandModel>(
        offset,
        EqBandModelSchema.deserialize,
        allOffsets,
        EqBandModel(),
      )) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset)) as P;
    case 6:
      return (reader.readBoolOrNull(offset)) as P;
    case 7:
      return (reader.readBoolOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readLongOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleList(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TrackModelQueryFilter
    on QueryBuilder<TrackModel, TrackModel, QFilterCondition> {
  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      applyTransposeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'applyTranspose',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      applyTransposeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'applyTranspose',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      applyTransposeEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'applyTranspose',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      durationInMillisecondsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'durationInMilliseconds',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      durationInMillisecondsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'durationInMilliseconds',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      durationInMillisecondsEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'durationInMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      durationInMillisecondsGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'durationInMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      durationInMillisecondsLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'durationInMilliseconds',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      durationInMillisecondsBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'durationInMilliseconds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> eqBandsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eqBands',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      eqBandsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eqBands',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      eqBandsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eqBands',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> eqBandsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eqBands',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      eqBandsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eqBands',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      eqBandsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eqBands',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      eqBandsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eqBands',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      eqBandsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eqBands',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> filePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      filePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> filePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      filePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> filePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> filePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> filePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> filePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idEqualTo(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idStartsWith(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idEndsWith(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> isClickIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isClick',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      isClickIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isClick',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> isClickEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isClick',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> isMutedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isMuted',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      isMutedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isMuted',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> isMutedEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMuted',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> isSoloIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isSolo',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      isSoloIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isSolo',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> isSoloEqualTo(
      bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSolo',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      octaveShiftIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'octaveShift',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      octaveShiftIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'octaveShift',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      octaveShiftEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'octaveShift',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      octaveShiftGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'octaveShift',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      octaveShiftLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'octaveShift',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      octaveShiftBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'octaveShift',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> orderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'order',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> orderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'order',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> orderEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> orderGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> orderLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'order',
        value: value,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> orderBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'order',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> panIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pan',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> panIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pan',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> panEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pan',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> panGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pan',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> panLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pan',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> panBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pan',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> volumeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'volume',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      volumeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'volume',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> volumeEqualTo(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> volumeGreaterThan(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> volumeLessThan(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> volumeBetween(
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

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'waveformPeaks',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'waveformPeaks',
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksElementEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'waveformPeaks',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksElementGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'waveformPeaks',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksElementLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'waveformPeaks',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksElementBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'waveformPeaks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'waveformPeaks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'waveformPeaks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'waveformPeaks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'waveformPeaks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'waveformPeaks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition>
      waveformPeaksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'waveformPeaks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension TrackModelQueryObject
    on QueryBuilder<TrackModel, TrackModel, QFilterCondition> {
  QueryBuilder<TrackModel, TrackModel, QAfterFilterCondition> eqBandsElement(
      FilterQuery<EqBandModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'eqBands');
    });
  }
}
