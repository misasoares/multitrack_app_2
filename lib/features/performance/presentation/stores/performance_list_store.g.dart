// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_list_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PerformanceListStore on PerformanceListStoreBase, Store {
  late final _$setlistsAtom =
      Atom(name: 'PerformanceListStoreBase.setlists', context: context);

  @override
  ObservableList<Setlist> get setlists {
    _$setlistsAtom.reportRead();
    return super.setlists;
  }

  @override
  set setlists(ObservableList<Setlist> value) {
    _$setlistsAtom.reportWrite(value, super.setlists, () {
      super.setlists = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: 'PerformanceListStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: 'PerformanceListStoreBase.errorMessage', context: context);

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$loadSetlistsAsyncAction =
      AsyncAction('PerformanceListStoreBase.loadSetlists', context: context);

  @override
  Future<void> loadSetlists() {
    return _$loadSetlistsAsyncAction.run(() => super.loadSetlists());
  }

  @override
  String toString() {
    return '''
setlists: ${setlists},
isLoading: ${isLoading},
errorMessage: ${errorMessage}
    ''';
  }
}
