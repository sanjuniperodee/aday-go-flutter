import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:aktau_go/utils/network_utils.dart';
import 'package:aktau_go/utils/text_editing_controller.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';

import '../../domains/user/user_domain.dart';
import './edit_profile_model.dart';
import './edit_profile_screen.dart';

defaultEditProfileWMFactory(BuildContext context) => EditProfileWM(
      EditProfileModel(
        inject<ProfileInteractor>(),
      ),
    );

abstract class IEditProfileWM implements IWidgetModel {
  StateNotifier<UserDomain?> get user;
  StateNotifier<bool> get isLoading;
  
  TextEditingController get firstNameController;
  TextEditingController get lastNameController;
  TextEditingController get middleNameController;
  
  Future<void> saveProfile();
  
  BuildContext get context;
}

class EditProfileWM extends WidgetModel<EditProfileScreen, EditProfileModel>
    implements IEditProfileWM {
  EditProfileWM(
    EditProfileModel model,
  ) : super(model);

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    _loadUserProfile();
  }

  @override
  final StateNotifier<UserDomain?> user = StateNotifier();

  @override
  final StateNotifier<bool> isLoading = StateNotifier(initValue: false);

  @override
  late final TextEditingController firstNameController = createTextEditingController(
    initialText: '',
  );

  @override
  late final TextEditingController lastNameController = createTextEditingController(
    initialText: '',
  );

  @override
  late final TextEditingController middleNameController = createTextEditingController(
    initialText: '',
  );

  Future<void> _loadUserProfile() async {
    try {
      final userData = await model.getUserProfile();
      user.accept(userData);
      
      // Заполняем поля данными пользователя
      firstNameController.text = userData.firstName ?? '';
      lastNameController.text = userData.lastName ?? '';
      middleNameController.text = userData.middleName ?? '';
    } catch (e) {
      print('Ошибка загрузки профиля: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось загрузить данные профиля'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Future<void> saveProfile() async {
    if (isLoading.value == true) return;
    
    isLoading.accept(true);
    
    try {
      await NetworkUtils.executeWithErrorHandling<void>(
        () => model.updateUserProfile(
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          middleName: middleNameController.text.trim().isNotEmpty 
              ? middleNameController.text.trim() 
              : null,
        ),
        customErrorMessage: 'Не удалось обновить профиль',
      );
      
      // Обновляем данные пользователя после успешного сохранения
      await _loadUserProfile();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Профиль успешно обновлен'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Возвращаемся на предыдущий экран
      Navigator.of(context).pop();
    } finally {
      isLoading.accept(false);
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    super.dispose();
  }
} 