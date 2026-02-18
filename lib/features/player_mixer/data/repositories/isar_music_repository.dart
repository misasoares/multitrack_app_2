import 'package:isar/isar.dart';
import '../../domain/entities/music.dart';
import '../../domain/repositories/imusic_repository.dart';
import '../models/music_model.dart';

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
}
