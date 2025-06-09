import 'package:aktau_go/forms/profile_registration_form.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/ui/widgets/rounded_text_field.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:seafarer/seafarer.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import './registration_wm.dart';

class RegistrationScreen extends ElementaryWidget<IRegistrationWM> {
  final String phoneNumber;

  RegistrationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(
          (context) => defaultRegistrationWMFactory(context),
        );

  @override
  Widget build(IRegistrationWM wm) {
    return StateNotifierBuilder(
        listenableState: wm.profileRegistrationForm,
        builder: (
          context,
          ProfileRegistrationForm? profileRegistrationForm,
        ) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: Text(
                'Регистрация',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    
                    // Заголовок и подзаголовок
                    Text(
                      'Расскажите о себе',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Заполните информацию для создания профиля',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 40),
                    
                    // Поля ввода
                    _buildInputField(
                      label: 'Имя',
                      controller: wm.firstNameTextEditingController,
                      icon: Icons.person_outline,
                      hint: 'Введите ваше имя',
                    ),
                    SizedBox(height: 20),
                    
                    _buildInputField(
                      label: 'Фамилия',
                      controller: wm.lastNameTextEditingController,
                      icon: Icons.person_outline,
                      hint: 'Введите вашу фамилию',
                    ),
                    SizedBox(height: 20),
                    
                    _buildInputField(
                      label: 'Номер телефона',
                      controller: wm.phoneTextEditingController,
                      icon: Icons.phone_outlined,
                      enabled: false,
                      hint: phoneNumber,
                    ),
                    SizedBox(height: 40),
                    
                    // Информационный блок
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ваши данные будут использованы только для идентификации в приложении',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    
                    // Кнопка продолжить
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: profileRegistrationForm!.isValid
                            ? wm.submitProfileRegistration
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(
                          'Продолжить',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ] : null,
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: enabled ? Colors.black87 : Colors.grey.shade600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              prefixIcon: Container(
                padding: EdgeInsets.all(16),
                child: Icon(
                  icon,
                  color: enabled ? primaryColor : Colors.grey.shade400,
                  size: 24,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RegistrationScreenArgs extends BaseArguments {
  final String phoneNumber;

  RegistrationScreenArgs({
    required this.phoneNumber,
  });
}
