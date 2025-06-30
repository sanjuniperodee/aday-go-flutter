import 'package:aktau_go/interactors/main_navigation_interactor.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:aktau_go/interactors/session_interactor.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:aktau_go/utils/network_utils.dart';
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

  Future<void> login();
  
  Future<void> logout();
  
  void goToHistoryScreen();
  
  void goToEditProfile();
  
  Future<void> goToSupportScreen();

  StateNotifier<String> get role;

  Future<void> navigateDriverRegistration();

  void logOut();

  Future<void> toggleRole();
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
  Future<void> login() async {
    await NetworkUtils.executeWithErrorHandling<void>(
      () => model.login(),
      customErrorMessage: 'Не удалось войти в систему',
    );
    
    // After login attempt, refresh the profile data
    await _fetchProfile();
  }
  
  @override
  Future<void> logout() async {
    await NetworkUtils.executeWithErrorHandling<void>(
      () => model.logout(),
      customErrorMessage: 'Не удалось выйти из системы',
    );
    
    // Clear user data after logout
    me.accept(null);
    role.accept(null);
  }
  
  @override
  void goToHistoryScreen() {
    Routes.router.navigate(
      Routes.historyScreen,
    );
  }
  
  @override
  void goToEditProfile() {
    Routes.router.navigate(
      Routes.editProfileScreen,
    );
  }
  
  @override
  Future<void> goToSupportScreen() async {
    // Показываем модальное окно поддержки
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      builder: (context) => buildSupportBottomSheet(context),
    );
  }
  
  // Вспомогательный метод для построения нижнего листа поддержки
  Widget buildSupportBottomSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка для закрытия
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Поддержка',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () async {
              // Вызов WhatsApp
              await model.launchWhatsApp();
              Navigator.of(context).pop(); // Close the bottom sheet
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Написать в WhatsApp',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void initWidgetModel() {
    super.initWidgetModel();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _fetchProfile();
    });
  }

  Future<void> _fetchProfile() async {
    final result = await NetworkUtils.executeWithErrorHandling<UserDomain?>(
      () => model.getUserProfile(),
      showErrorMessages: false, // Не показываем ошибки для автоматических запросов профиля
    );
    
    if (result != null) {
      print('Fetching user profile data...');
      
      // Check if the response contains a valid user
      final bool hasValidUser = result.id.isNotEmpty;
      print('User profile loaded: ${hasValidUser ? 'Valid user found' : 'No valid user'}');
      
      if (hasValidUser) {
        me.accept(result);
        
        // Try to get role from session interactor
        final currentRole = model.role.value;
        if (currentRole != null && currentRole.isNotEmpty) {
          role.accept(currentRole);
          print('Set role: $currentRole');
        }
      } else {
        print('No valid user profile data received');
        me.accept(null);
      }
    } else {
      print('Error fetching profile or no internet connection');
      me.accept(null);
    }
  }

  @override
  final StateNotifier<String> role = StateNotifier();

  @override
  final StateNotifier<UserDomain> me = StateNotifier();

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
    // Toggle the role immediately in UI
    final newRole = role.value == 'LANDLORD' ? 'ROLE_TENANT' : 'LANDLORD';
    role.accept(newRole);
    
    // Then update the backend
    model.toggleRole();
    
    // Show loading screen during transition
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => LoadingScreen()));
    
    // Change tab to first tab
    model.changeTab(0);
    
    // Refresh profile to get latest data
    await _fetchProfile();
  }
}
