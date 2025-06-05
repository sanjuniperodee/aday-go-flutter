import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../widgets/text_locale.dart';

class AboutApplicationScreen extends StatefulWidget {
  const AboutApplicationScreen({Key? key}) : super(key: key);

  @override
  State<AboutApplicationScreen> createState() => _AboutApplicationScreenState();
}

class _AboutApplicationScreenState extends State<AboutApplicationScreen> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'О приложении',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Logo and Version Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App Logo with animated shadow
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
              'assets/icons/logo.svg',
                      height: 100,
                      width: 100,
                    ),
            ),
                  SizedBox(height: 24),
                  // App Name with custom styling
            Text(
              packageInfo?.appName ?? 'Aktau Go',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Version info with pill styling
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Версия ${packageInfo?.version ?? '1.0.6'} (${packageInfo?.buildNumber ?? '22'})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Description Card with shadow and rounded corners
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with accent color
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white),
                        SizedBox(width: 12),
            Text(
                          'О приложении',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Description text with improved typography
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aktau Go - это современное мобильное приложение для жителей и гостей города Актау. Приложение предоставляет удобный доступ к услугам такси, позволяя быстро заказать поездку в любую точку города. Благодаря интуитивному интерфейсу и точной карте города, вы всегда будете знать, где находится ваш автомобиль и когда он прибудет.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
            ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Features section with icons
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Основные возможности',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildFeatureItem(
                      icon: Icons.location_on,
                      title: 'Точное определение маршрута',
                      description: 'Выбирайте маршрут с точностью до адреса',
                    ),
                    _buildFeatureItem(
                      icon: Icons.access_time,
                      title: 'Быстрое оформление заказа',
                      description: 'Создавайте заказ в несколько касаний',
                    ),
                    _buildFeatureItem(
                      icon: Icons.directions_car,
                      title: 'Отслеживание водителя',
                      description: 'Следите за перемещением вашего такси',
                    ),
                    _buildFeatureItem(
                      icon: Icons.attach_money,
                      title: 'Прозрачные цены',
                      description: 'Узнавайте стоимость поездки заранее',
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Contact section with improved styling
            Container(
              margin: EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with accent color
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.contact_support_outlined, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Связаться с нами',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contact details with interactive items
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // Phone number
                        InkWell(
                          onTap: () => _launchUrl('tel:+77088431748'),
                          child: _buildContactItem(
                            icon: Icons.phone,
                            title: 'Телефон',
                            value: '+7 (708) 843-17-48',
                          ),
                        ),
                        
                        // Email
                        InkWell(
                          onTap: () => _launchUrl('mailto:info@aktau-go.kz'),
                          child: _buildContactItem(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: 'info@aktau-go.kz',
                          ),
                        ),
                        
                        // Website
                        InkWell(
                          onTap: () => _launchUrl('https://aktau-go.kz'),
                          child: _buildContactItem(
                            icon: Icons.language,
                            title: 'Веб-сайт',
                            value: 'aktau-go.kz',
                          ),
                        ),
                        
                        // WhatsApp
                        InkWell(
                          onTap: () => _launchUrl('https://wa.me/77088431748'),
                          child: _buildContactItem(
                            icon: Icons.chat,
                            title: 'WhatsApp',
                            value: '+7 (708) 843-17-48',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // App information section
            Container(
              margin: EdgeInsets.only(left: 16, right: 16, bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with accent color
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.library_books_outlined, color: Colors.white),
                        SizedBox(width: 12),
            Text(
                          'Документы',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Legal documents
                  InkWell(
                    onTap: () => _launchUrl('https://aktau-go.kz/privacy'),
                    child: _buildContactItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Политика конфиденциальности',
                      value: '',
                    ),
                  ),
                  
                  InkWell(
                    onTap: () => _launchUrl('https://aktau-go.kz/terms'),
                    child: _buildContactItem(
                      icon: Icons.description_outlined,
                      title: 'Условия использования',
                      value: '',
            ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Copyright footer
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  '© ${DateTime.now().year} Aktau Go. Все права защищены.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build feature item
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build consistent contact items
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
          if (value.isNotEmpty)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
        ],
      ),
    );
  }
  
  // Helper method to launch URLs
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrlString(url);
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }
}
