import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';

import '../../domains/user/user_domain.dart';
import '../../interactors/main_navigation_interactor.dart';
import '../../interactors/session_interactor.dart';

class ProfileModel extends ElementaryModel {
  final SessionInteractor _sessionInteractor;
  final ProfileInteractor _profileInteractor;
  final MainNavigationInteractor _mainNavigationInteractor;

  ProfileModel(
    this._sessionInteractor,
    this._profileInteractor,
    this._mainNavigationInteractor,
  ) : super();

  StateNotifier<String> get role => _sessionInteractor.role;

  void toggleRole([
    String? newRole,
  ]) =>
      _sessionInteractor.toggleRole(
        newRole,
      );

  Future<UserDomain> fetchUserProfile() =>
      _profileInteractor.fetchUserProfile();

  void changeTab(
    int newTab, [
    int? newSubTab,
  ]) =>
      _mainNavigationInteractor.changeTab(
        newTab,
        newSubTab,
      );
}
