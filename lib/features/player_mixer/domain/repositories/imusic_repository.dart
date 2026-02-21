import '../entities/music.dart';
import '../entities/setlist.dart';

abstract class IMusicRepository {
  Future<void> saveMusic(Music music);
  Future<List<Music>> getAllMusic();
  Future<void> deleteMusic(String id);
  Future<List<Music>> getMusicByIds(List<String> ids);

  // Setlist methods
  Future<void> saveSetlist(Setlist setlist);
  Future<List<Setlist>> getAllSetlists();
  Future<void> deleteSetlist(String id);
}
