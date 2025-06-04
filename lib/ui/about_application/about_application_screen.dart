import 'package:aktau_go/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      appBar: AppBar(
        title: TextLocale('about_application'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 24),
            SvgPicture.asset(
              'assets/icons/logo.svg',
              height: 80,
              width: 80,
            ),
            SizedBox(height: 16),
            Text(
              packageInfo?.appName ?? 'Aktau Go',
              style: text500Size24Black,
            ),
            SizedBox(height: 8),
            Text(
              'Version ${packageInfo?.version ?? '1.0.6'} (${packageInfo?.buildNumber ?? '22'})',
              style: text400Size16Greyscale60,
            ),
            SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextLocale('about_app_description'),
                    SizedBox(height: 16),
                    Text(
                      'Aktau Go - это современное мобильное приложение для жителей и гостей города Актау. Приложение предоставляет удобный доступ к городским услугам, картам, транспорту и многому другому.',
                      style: text400Size16Greyscale90,
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            Text(
              '© 2024 Aktau Go Team',
              style: text400Size12Greyscale60,
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
