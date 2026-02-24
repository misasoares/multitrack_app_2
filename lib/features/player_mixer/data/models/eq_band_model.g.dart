// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eq_band_model.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const EqBandModelSchema = Schema(
  name: r'EqBandModel',
  id: -258803398084176840,
  properties: {
    r'bandIndex': PropertySchema(
      id: 0,
      name: r'bandIndex',
      type: IsarType.long,
    ),
    r'frequency': PropertySchema(
      id: 1,
      name: r'frequency',
      type: IsarType.double,
    ),
    r'gainDb': PropertySchema(
      id: 2,
      name: r'gainDb',
      type: IsarType.double,
    ),
    r'q': PropertySchema(
      id: 3,
      name: r'q',
      type: IsarType.double,
    ),
    r'type': PropertySchema(
      id: 4,
      name: r'type',
      type: IsarType.byte,
      enumMap: _EqBandModeltypeEnumValueMap,
    )
  },
  estimateSize: _eqBandModelEstimateSize,
  serialize: _eqBandModelSerialize,
  deserialize: _eqBandModelDeserialize,
  deserializeProp: _eqBandModelDeserializeProp,
);

int _eqBandModelEstimateSize(
  EqBandModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _eqBandModelSerialize(
  EqBandModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.bandIndex);
  writer.writeDouble(offsets[1], object.frequency);
  writer.writeDouble(offsets[2], object.gainDb);
  writer.writeDouble(offsets[3], object.q);
  writer.writeByte(offsets[4], object.type.index);
}

EqBandModel _eqBandModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EqBandModel(
    bandIndex: reader.readLongOrNull(offsets[0]),
    frequency: reader.readDoubleOrNull(offsets[1]),
    gainDb: reader.readDoubleOrNull(offsets[2]),
    q: reader.readDoubleOrNull(offsets[3]),
    type: _EqBandModeltypeValueEnumMap[reader.readByteOrNull(offsets[4])] ??
        EqFilterType.peaking,
  );
  return object;
}

P _eqBandModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (_EqBandModeltypeValueEnumMap[reader.readByteOrNull(offset)] ??
          EqFilterType.peaking) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _EqBandModeltypeEnumValueMap = {
  'highPass': 0,
  'peaking': 1,
  'lowPass': 2,
};
const _EqBandModeltypeValueEnumMap = {
  0: EqFilterType.highPass,
  1: EqFilterType.peaking,
  2: EqFilterType.lowPass,
};

extension EqBandModelQueryFilter
    on QueryBuilder<EqBandModel, EqBandModel, QFilterCondition> {
  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      bandIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bandIndex',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      bandIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bandIndex',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      bandIndexEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bandIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      bandIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bandIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      bandIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bandIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      bandIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bandIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      frequencyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'frequency',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      frequencyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'frequency',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      frequencyEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      frequencyGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      frequencyLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequency',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      frequencyBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> gainDbIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gainDb',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      gainDbIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gainDb',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> gainDbEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gainDb',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition>
      gainDbGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gainDb',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> gainDbLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gainDb',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> gainDbBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gainDb',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> qIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'q',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> qIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'q',
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> qEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'q',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> qGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'q',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> qLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'q',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> qBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'q',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> typeEqualTo(
      EqFilterType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> typeGreaterThan(
    EqFilterType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> typeLessThan(
    EqFilterType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<EqBandModel, EqBandModel, QAfterFilterCondition> typeBetween(
    EqFilterType lower,
    EqFilterType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension EqBandModelQueryObject
    on QueryBuilder<EqBandModel, EqBandModel, QFilterCondition> {}
