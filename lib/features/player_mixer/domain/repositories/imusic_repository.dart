import '../entities/music.dart';

abstract class IMusicRepository {
  Future<void> saveMusic(Music music);
  Future<List<Music>> getAllMusic();
}
