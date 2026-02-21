import 'package:isar/isar.dart';
import '../../domain/entities/music.dart';
import '../../domain/repositories/imusic_repository.dart';
import '../models/music_model.dart';
import '../models/setlist_model.dart';
import '../../domain/entities/setlist.dart';

class IsarMusicRepository implements IMusicRepository {
  final Isar isar;

  IsarMusicRepository(this.isar);

  @override
  Future<void> saveMusic(Music music) async {
    final musicModel = MusicModel.fromEntity(music);

    await isar.writeTxn(() async {
      await isar.musicModels.put(musicModel);
    });
  }

  @override
  Future<List<Music>> getAllMusic() async {
    final models = await isar.musicModels.where().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> deleteMusic(String id) async {
    await isar.writeTxn(() async {
      await isar.musicModels.filter().domainIdEqualTo(id).deleteAll();
    });
  }

  @override
  Future<List<Music>> getMusicByIds(List<String> ids) async {
    final models = await isar.musicModels
        .filter()
        .anyOf(ids, (q, String id) => q.domainIdEqualTo(id))
        .findAll();

    // Maintain order based on ids list
    final musicMap = {for (var m in models) m.domainId: m.toEntity()};
    return ids.map((id) => musicMap[id]).whereType<Music>().toList();
  }

  // ─── Setlist Methods ────────────────────────────────────────────────

  @override
  Future<void> saveSetlist(Setlist setlist) async {
    final model = SetlistModel.fromEntity(setlist);
    await isar.writeTxn(() async {
      await isar.setlistModels.put(model);
    });
  }

  @override
  Future<List<Setlist>> getAllSetlists() async {
    final models = await isar.setlistModels.where().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> deleteSetlist(String id) async {
    await isar.writeTxn(() async {
      await isar.setlistModels.filter().domainIdEqualTo(id).deleteAll();
    });
  }
}
