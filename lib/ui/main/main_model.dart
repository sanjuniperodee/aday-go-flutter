import 'package:aktau_go/interactors/location_interactor.dart';
import 'package:aktau_go/interactors/main_navigation_interactor.dart';
import 'package:aktau_go/interactors/session_interactor.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';

class MainModel extends ElementaryModel {
  final SessionInteractor _sessionInteractor;
  final MainNavigationInteractor _mainNavigationInteractor;
  final LocationInteractor _locationInteractor;

  MainModel(
    this._sessionInteractor,
    this._mainNavigationInteractor,
    this._locationInteractor,
  ) : super();

  StateNotifier<String> get role => _sessionInteractor.role;

  StateNotifier<int> get currentTab => _mainNavigationInteractor.currentTab;

  Future<void> requestLocation() => _locationInteractor.requestLocation();
}
