import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';

import '../../core/images.dart';
import '../../core/text_styles.dart';
import './onboarding_wm.dart';

class OnboardingScreen extends ElementaryWidget<IOnboardingWM> {
  OnboardingScreen({
    Key? key,
  }) : super(
          (context) => defaultOnboardingWMFactory(context),
        );

  @override
  Widget build(IOnboardingWM wm) {
    return Scaffold(
      body: StateNotifierBuilder(
          listenableState: wm.step,
          builder: (context, int? step) {
            if (step == 0) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.asset(imgNotification),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Получайте уведомления!',
                          textAlign: TextAlign.center,
                          style: text500Size20Greyscale90,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Будьте в курсе своего путешествия, когда появляются лучшие предложения или персонализированные рекомендации.',
                          textAlign: TextAlign.center,
                          style: text400Size16Greyscale90,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return SizedBox(
                            height: 200,
                            width: 200,
                            child: Image.asset(imgNotificationBg),
                          );
                        }),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: wm.skipNotificationPermission,
                              child: Text(
                                'Пропустить',
                                style: text400Size16Greyscale90,
                              ),
                            ),
                          ),
                          Expanded(
                            child: PrimaryButton.primary(
                              onPressed: wm.requestNotificationPermission,
                              child: Text(
                                'Я с вами',
                                style: text400Size16White,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            } else {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.asset(imgLocationBg),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Почему это важно?',
                          textAlign: TextAlign.center,
                          style: text500Size20Greyscale90,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Мы используем ваше местоположение, чтобы показывать вам ближайшие достопримечательности, рестораны и мероприятия.',
                          textAlign: TextAlign.center,
                          style: text400Size16Greyscale90,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(builder: (context, constraints) {
                          return SizedBox(
                            height: 200,
                            width: 200,
                            child: Image.asset(imgLocationBg),
                          );
                        }),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: wm.skipLocationPermission,
                              child: Text(
                                'Пропустить',
                                style: text400Size16Greyscale90,
                              ),
                            ),
                          ),
                          Expanded(
                            child: PrimaryButton.primary(
                              onPressed: wm.requestLocationPermission,
                              child: Text(
                                'Хорошо, разрешить',
                                style: text400Size16White,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }
          }),
    );
  }
}
