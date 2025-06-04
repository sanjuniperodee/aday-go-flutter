import 'package:aktau_go/interactors/main_navigation_interactor.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:aktau_go/interactors/session_interactor.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:seafarer/seafarer.dart';

import '../../domains/user/user_domain.dart';
import '../loading/loading_screen.dart';
import './profile_model.dart';
import './profile_screen.dart';

defaultProfileWMFactory(BuildContext context) => ProfileWM(
      ProfileModel(
        inject<SessionInteractor>(),
        inject<ProfileInteractor>(),
        inject<MainNavigationInteractor>(),
      ),
    );

abstract class IProfileWM implements IWidgetModel {
  StateNotifier<UserDomain> get me;

  void navigateToLogin();

  StateNotifier<String> get role;

  Future<void> navigateDriverRegistration();

  void logOut();

  void toggleRole();
}

class ProfileWM extends WidgetModel<ProfileScreen, ProfileModel>
    implements IProfileWM {
  ProfileWM(
    ProfileModel model,
  ) : super(model);

  @override
  void navigateToLogin() {
    Routes.router.navigate(
      Routes.loginScreen,
    );
  }

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    model.role.addListener(() {
      role.accept(model.role.value);
      fetchUserProfile();
    });
  }

  @override
  final StateNotifier<String> role = StateNotifier();

  @override
  final StateNotifier<UserDomain> me = StateNotifier();

  void fetchUserProfile() async {
    final response = await model.fetchUserProfile();

    me.accept(response);
  }

  @override
  Future<void> navigateDriverRegistration() async {
    Routes.router.navigate(Routes.driverRegistrationScreen);
  }

  @override
  void logOut() {
    inject<SessionInteractor>().logout();
    Routes.router.navigate(
      Routes.loginScreen,
      navigationType: NavigationType.pushAndRemoveUntil,
      removeUntilPredicate: (predicate) => false,
    );
  }

  @override
  Future<void> toggleRole() async {
    model.toggleRole();
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => LoadingScreen()));
    model.changeTab(0);
  }
}
