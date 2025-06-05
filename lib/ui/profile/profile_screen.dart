import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/ui/earning_analytics/earning_analytics_bottom_sheet.dart';
import 'package:aktau_go/ui/widgets/notification_badge.dart';
import 'package:aktau_go/ui/widgets/primary_bottom_sheet.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../core/button_styles.dart';
import '../../core/colors.dart';
import '../../core/images.dart';
import '../../core/text_styles.dart';
import '../about_application/about_application_screen.dart';
import '../widgets/primary_button.dart';
import '../widgets/primary_outlined_button.dart';
import '../widgets/text_locale.dart';
import './profile_wm.dart';

class ProfileScreen extends ElementaryWidget<IProfileWM> {
  ProfileScreen({
    Key? key,
  }) : super(
          (context) => defaultProfileWMFactory(context),
        );

  @override
  Widget build(IProfileWM wm) {
    return DoubleSourceBuilder(
      firstSource: wm.role,
      secondSource: wm.me,
      builder: (
        context,
        String? role,
        UserDomain? me,
      ) {
        final bool isLoggedIn = me != null && me.id.isNotEmpty;
        
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
                    'Профиль',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                    ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      color: greyscale10,
                    ),
                  ),
          ),
          body: isLoggedIn 
              ? _buildLoggedInProfile(context, me, wm)
              : _buildLoginScreen(context, wm),
        );
      },
    );
  }
  
  Widget _buildLoggedInProfile(BuildContext context, UserDomain? me, IProfileWM wm) {
    // Force update the role from the widget model to ensure it's current
    final String? currentRole = wm.role.value;
    final bool isDriverMode = currentRole == 'LANDLORD';
    
    print("Current user role: $currentRole, isDriverMode: $isDriverMode");
    
    return ListView(
      padding: EdgeInsets.zero,
                  children: [
        // Профиль пользователя
                    Container(
                        color: Colors.white,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar and user info
              Row(
                        children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: null,
                    child: Icon(Icons.person, size: 40, color: Colors.grey),
                          ),
                  SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                        Text(
                          me?.fullName ?? 'Пользователь',
                                      style: TextStyle(
                                        fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          me?.phone ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                                    ),
                                  ),
                        SizedBox(height: 8),
                        Row(
                                      children: [
                            RatingBar.builder(
                              initialRating: me?.rating.toDouble() ?? 0,
                              minRating: 0,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 5,
                              itemSize: 16,
                              ignoreGestures: true,
                                            itemBuilder: (context, _) => Icon(
                                              Icons.star,
                                color: Colors.amber,
                                            ),
                              onRatingUpdate: (_) {},
                                          ),
                            SizedBox(width: 8),
                                        Text(
                              '(${me?.ratedOrders.length ?? 0})',
                                          style: TextStyle(
                                            fontSize: 12,
                                color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                  ),
                                ],
                            ),
                          ),
                        ],
                      ),
              
                    SizedBox(height: 16),
              
              // Analytics section for driver - show only in driver mode
              if (isDriverMode)
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => EarningAnalyticsBottomSheet(me: me),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.monetization_on,
                              color: primaryColor,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Аналитика заработка',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Просмотр статистики доходов',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade600,
                          ),
                          ],
                        ),
                        ),
                      ),
                    
                    // Vehicle category registration button
                    InkWell(
                      onTap: () => Navigator.of(context).pushNamed(Routes.driverRegistrationScreen),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_car,
                              color: Colors.green,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                          child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                  Text(
                                    'Управление автомобилями',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Регистрация и редактирование категорий',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                ),
                              ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              
              // Кнопка редактирования профиля
                              SizedBox(
                                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => wm.goToEditProfile(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                                child: Text(
                    'Редактировать профиль',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                                ),
                              ),
                ),
              ),
              
              SizedBox(height: 12),
              
              // Кнопка переключения в режим водителя
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.local_taxi),
                  label: Text(
                    wm.role.value == 'LANDLORD' 
                        ? 'Переключиться в режим клиента' 
                        : 'Переключиться в режим водителя'
                  ),
                  onPressed: () => wm.toggleRole(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
            ],
          ),
        ),
        
        SizedBox(height: 8),
        
        // Разделы профиля
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildProfileSection(
                icon: Icons.history,
                title: 'История поездок',
                onTap: () => wm.goToHistoryScreen(),
                                ),
              _buildDivider(),
              _buildProfileSection(
                icon: Icons.notifications,
                title: 'Уведомления',
                onTap: () => Navigator.of(context).pushNamed(Routes.notificationsScreen),
                trailing: NotificationBadge(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  color: Colors.red,
                  size: 20,
                                ),
                              ),
              _buildDivider(),
              _buildProfileSection(
                icon: Icons.credit_card,
                title: 'Способы оплаты',
                onTap: () {},
              ),
              _buildDivider(),
              _buildProfileSection(
                icon: Icons.support_agent,
                title: 'Поддержка',
                onTap: () => wm.goToSupportScreen(),
              ),
                            ],
                          ),
                        ),
        
        SizedBox(height: 8),
        
        // Дополнительные настройки
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildProfileSection(
                icon: Icons.info_outline,
                title: 'О приложении',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AboutApplicationScreen(),
                        ),
                      ),
              ),
              _buildDivider(),
              _buildProfileSection(
                icon: Icons.settings,
                title: 'Настройки',
                onTap: () {},
                      ),
            ],
          ),
                    ),
        
        SizedBox(height: 24),
        
        // Кнопка выхода
                      Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () => wm.logout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text('Выйти из аккаунта'),
                      ),
                    ),
        
        SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildLoginScreen(BuildContext context, IProfileWM wm) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(
              Icons.account_circle,
              size: 80,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 24),
            Text(
              'Войдите в аккаунт',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                    ),
            ),
            SizedBox(height: 16),
            Text(
              'Чтобы получить доступ ко всем функциям приложения, пожалуйста, войдите в свой аккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
                                  ),
            SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
              child: ElevatedButton(
                onPressed: () => wm.login(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                                child: Text(
                  'Войти',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                                ),
                              ),
            ),
                            ],
                          ),
                        ),
    );
  }
  
  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
                        ),
                      ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
                      ),
            trailing ?? Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
                    ),
                  ],
        ),
                ),
        );
  }
  
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 0,
      color: Colors.grey.shade100,
    );
  }
}
