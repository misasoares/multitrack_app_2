// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'midi_config_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMidiConfigModelCollection on Isar {
  IsarCollection<MidiConfigModel> get midiConfigModels => this.collection();
}

const MidiConfigModelSchema = CollectionSchema(
  name: r'MidiConfigModel',
  id: 330654156305922297,
  properties: {
    r'deviceId': PropertySchema(
      id: 0,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'midiNotes': PropertySchema(
      id: 1,
      name: r'midiNotes',
      type: IsarType.longList,
    ),
    r'padIds': PropertySchema(
      id: 2,
      name: r'padIds',
      type: IsarType.stringList,
    )
  },
  estimateSize: _midiConfigModelEstimateSize,
  serialize: _midiConfigModelSerialize,
  deserialize: _midiConfigModelDeserialize,
  deserializeProp: _midiConfigModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'deviceId': IndexSchema(
      id: 4442814072367132509,
      name: r'deviceId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'deviceId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _midiConfigModelGetId,
  getLinks: _midiConfigModelGetLinks,
  attach: _midiConfigModelAttach,
  version: '3.1.0+1',
);

int _midiConfigModelEstimateSize(
  MidiConfigModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.midiNotes.length * 8;
  bytesCount += 3 + object.padIds.length * 3;
  {
    for (var i = 0; i < object.padIds.length; i++) {
      final value = object.padIds[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _midiConfigModelSerialize(
  MidiConfigModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.deviceId);
  writer.writeLongList(offsets[1], object.midiNotes);
  writer.writeStringList(offsets[2], object.padIds);
}

MidiConfigModel _midiConfigModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MidiConfigModel();
  object.deviceId = reader.readString(offsets[0]);
  object.id = id;
  object.midiNotes = reader.readLongList(offsets[1]) ?? [];
  object.padIds = reader.readStringList(offsets[2]) ?? [];
  return object;
}

P _midiConfigModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLongList(offset) ?? []) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _midiConfigModelGetId(MidiConfigModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _midiConfigModelGetLinks(MidiConfigModel object) {
  return [];
}

void _midiConfigModelAttach(
    IsarCollection<dynamic> col, Id id, MidiConfigModel object) {
  object.id = id;
}

extension MidiConfigModelByIndex on IsarCollection<MidiConfigModel> {
  Future<MidiConfigModel?> getByDeviceId(String deviceId) {
    return getByIndex(r'deviceId', [deviceId]);
  }

  MidiConfigModel? getByDeviceIdSync(String deviceId) {
    return getByIndexSync(r'deviceId', [deviceId]);
  }

  Future<bool> deleteByDeviceId(String deviceId) {
    return deleteByIndex(r'deviceId', [deviceId]);
  }

  bool deleteByDeviceIdSync(String deviceId) {
    return deleteByIndexSync(r'deviceId', [deviceId]);
  }

  Future<List<MidiConfigModel?>> getAllByDeviceId(List<String> deviceIdValues) {
    final values = deviceIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'deviceId', values);
  }

  List<MidiConfigModel?> getAllByDeviceIdSync(List<String> deviceIdValues) {
    final values = deviceIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'deviceId', values);
  }

  Future<int> deleteAllByDeviceId(List<String> deviceIdValues) {
    final values = deviceIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'deviceId', values);
  }

  int deleteAllByDeviceIdSync(List<String> deviceIdValues) {
    final values = deviceIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'deviceId', values);
  }

  Future<Id> putByDeviceId(MidiConfigModel object) {
    return putByIndex(r'deviceId', object);
  }

  Id putByDeviceIdSync(MidiConfigModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'deviceId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDeviceId(List<MidiConfigModel> objects) {
    return putAllByIndex(r'deviceId', objects);
  }

  List<Id> putAllByDeviceIdSync(List<MidiConfigModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'deviceId', objects, saveLinks: saveLinks);
  }
}

extension MidiConfigModelQueryWhereSort
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QWhere> {
  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MidiConfigModelQueryWhere
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QWhereClause> {
  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhereClause>
      deviceIdEqualTo(String deviceId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'deviceId',
        value: [deviceId],
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterWhereClause>
      deviceIdNotEqualTo(String deviceId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deviceId',
              lower: [],
              upper: [deviceId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deviceId',
              lower: [deviceId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deviceId',
              lower: [deviceId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'deviceId',
              lower: [],
              upper: [deviceId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension MidiConfigModelQueryFilter
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QFilterCondition> {
  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deviceId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'deviceId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'deviceId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'deviceId',
        value: '',
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'midiNotes',
        value: value,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'midiNotes',
        value: value,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'midiNotes',
        value: value,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'midiNotes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'midiNotes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'midiNotes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'midiNotes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'midiNotes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'midiNotes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      midiNotesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'midiNotes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'padIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'padIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'padIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'padIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'padIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'padIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'padIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'padIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'padIds',
        value: '',
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'padIds',
        value: '',
      ));
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'padIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'padIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'padIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'padIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'padIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterFilterCondition>
      padIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'padIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension MidiConfigModelQueryObject
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QFilterCondition> {}

extension MidiConfigModelQueryLinks
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QFilterCondition> {}

extension MidiConfigModelQuerySortBy
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QSortBy> {
  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterSortBy>
      sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterSortBy>
      sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }
}

extension MidiConfigModelQuerySortThenBy
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QSortThenBy> {
  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterSortBy>
      thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterSortBy>
      thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension MidiConfigModelQueryWhereDistinct
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QDistinct> {
  QueryBuilder<MidiConfigModel, MidiConfigModel, QDistinct> distinctByDeviceId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QDistinct>
      distinctByMidiNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'midiNotes');
    });
  }

  QueryBuilder<MidiConfigModel, MidiConfigModel, QDistinct> distinctByPadIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'padIds');
    });
  }
}

extension MidiConfigModelQueryProperty
    on QueryBuilder<MidiConfigModel, MidiConfigModel, QQueryProperty> {
  QueryBuilder<MidiConfigModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<MidiConfigModel, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<MidiConfigModel, List<int>, QQueryOperations>
      midiNotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'midiNotes');
    });
  }

  QueryBuilder<MidiConfigModel, List<String>, QQueryOperations>
      padIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'padIds');
    });
  }
}
