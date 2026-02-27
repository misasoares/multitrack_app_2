import 'package:equatable/equatable.dart';
import 'setlist_item.dart';

enum SetlistStatus { draft, configured, rendering, ready }

class Setlist extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<SetlistItem> items;
  final SetlistStatus status;
  /// Path to the exported show directory (e.g. ApplicationDocumentsDirectory/shows/{id}).
  final String? exportedShowDirectory;

  const Setlist({
    required this.id,
    required this.name,
    this.description = '',
    this.items = const [],
    this.status = SetlistStatus.draft,
    this.exportedShowDirectory,
  });

  Setlist copyWith({
    String? id,
    String? name,
    String? description,
    List<SetlistItem>? items,
    SetlistStatus? status,
    String? exportedShowDirectory,
  }) {
    return Setlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      status: status ?? this.status,
      exportedShowDirectory: exportedShowDirectory ?? this.exportedShowDirectory,
    );
  }

  @override
  List<Object?> get props => [id, name, description, items, status, exportedShowDirectory];
}
