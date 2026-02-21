import 'package:isar/isar.dart';
import '../../domain/entities/setlist.dart';
import 'setlist_item_model.dart';
import 'track_model.dart';
import 'marker_model.dart';
import 'eq_band_model.dart';

part 'setlist_model.g.dart';

@collection
class SetlistModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? domainId;

  String? name;
  String? description;
  List<SetlistItemModel>? items;

  @Enumerated(EnumType.name)
  SetlistStatus? status;

  SetlistModel({
    this.domainId,
    this.name,
    this.description,
    this.items,
    this.status,
  });

  factory SetlistModel.fromEntity(Setlist setlist) {
    return SetlistModel(
      domainId: setlist.id,
      name: setlist.name,
      description: setlist.description,
      items: setlist.items.map((i) => SetlistItemModel.fromEntity(i)).toList(),
      status: setlist.status,
    );
  }

  Setlist toEntity() {
    return Setlist(
      id: domainId ?? '',
      name: name ?? '',
      description: description ?? '',
      items: items?.map((i) => i.toEntity()).toList() ?? [],
      status: status ?? SetlistStatus.draft,
    );
  }
}
