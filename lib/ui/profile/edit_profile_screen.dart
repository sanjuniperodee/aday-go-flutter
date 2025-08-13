import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../widgets/rounded_text_field.dart';
import './edit_profile_wm.dart';

class EditProfileScreen extends ElementaryWidget<IEditProfileWM> {
  EditProfileScreen({
    Key? key,
  }) : super(
          (context) => defaultEditProfileWMFactory(context),
        );

  @override
  Widget build(IEditProfileWM wm) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Редактирование профиля',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(wm.context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: greyscale10,
          ),
        ),
      ),
      body: StateNotifierBuilder<UserDomain?>(
        listenableState: wm.user,
        builder: (context, user) {
          if (user == null) {
            return Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Аватар пользователя (заглушка)
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                
                // Имя
                _buildFormLabel('Имя'),
                RoundedTextField(
                  backgroundColor: Colors.white,
                  hintText: 'Введите имя',
                  hintStyle: text400Size16Greyscale30,
                  controller: wm.firstNameController,
                ),
                SizedBox(height: 16),
                
                // Фамилия
                _buildFormLabel('Фамилия'),
                RoundedTextField(
                  backgroundColor: Colors.white,
                  hintText: 'Введите фамилию',
                  hintStyle: text400Size16Greyscale30,
                  controller: wm.lastNameController,
                ),
                SizedBox(height: 16),
                
                // Отчество (необязательно)
                _buildFormLabel('Отчество (необязательно)'),
                RoundedTextField(
                  backgroundColor: Colors.white,
                  hintText: 'Введите отчество',
                  hintStyle: text400Size16Greyscale30,
                  controller: wm.middleNameController,
                ),
                SizedBox(height: 16),
                
                // Телефон (неизменяемый)
                _buildFormLabel('Телефон'),
                RoundedTextField(
                  backgroundColor: Colors.grey[200]!,
                  hintText: user.phone,
                  hintStyle: text400Size16Greyscale30,
                  enabled: false,
                  controller: TextEditingController(text: user.phone),
                ),
                SizedBox(height: 32),
                
                // Кнопка сохранения
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: StateNotifierBuilder<bool>(
                    listenableState: wm.isLoading,
                    builder: (context, isLoading) {
                      return PrimaryButton.primary(
                        onPressed: isLoading == true ? null : wm.saveProfile,
                        text: isLoading == true ? 'Сохранение...' : 'Сохранить изменения',
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Вспомогательный метод для создания заголовков полей
  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
    );
  }
} 