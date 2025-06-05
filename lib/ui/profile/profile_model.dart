import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  ) : super() {
    _sessionInteractor.role.addListener(() {
      _role.value = _sessionInteractor.role.value;
    });
    _role.value = _sessionInteractor.role.value;
  }

  final _role = ValueNotifier<String?>(null);

  ValueListenable<String?> get role => _role;

  Future<UserDomain?> getUserProfile() async {
    try {
      if (_sessionInteractor.role.value == 'LANDLORD' || _sessionInteractor.role.value == 'TENANT') {
        return await _profileInteractor.fetchUserProfile();
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }

  void toggleRole() {
    final isLandlord = role.value == 'LANDLORD';
    _sessionInteractor.role.accept(isLandlord ? 'TENANT' : 'LANDLORD');
    _sessionInteractor.saveRole();
  }

  void changeTab(
    int newTab, [
    int? newSubTab,
  ]) =>
      _mainNavigationInteractor.changeTab(
        newTab,
        newSubTab,
      );

  Future<void> launchWhatsApp() async {
    const whatsappNumber = '77088431748';
    final whatsappUrl = 'https://wa.me/$whatsappNumber';
    
    try {
      if (await canLaunchUrlString(whatsappUrl)) {
        await launchUrlString(whatsappUrl);
      }
    } catch (e) {
      print('Ошибка при запуске WhatsApp: $e');
    }
  }

  Future<void> login() async {
    try {
      // Navigate to login screen
      await _mainNavigationInteractor.navigateToLogin();
      
      // Wait a moment for the navigation to complete
      await Future.delayed(Duration(milliseconds: 500));
    } catch (e) {
      print('Error during login navigation: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Log out the user
      _sessionInteractor.logout();
      
      // Clear role
      _role.value = null;
      
      // Navigate to home screen
      _mainNavigationInteractor.changeTab(0);
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
