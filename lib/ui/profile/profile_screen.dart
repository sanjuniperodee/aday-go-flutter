import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/ui/earning_analytics/earning_analytics_bottom_sheet.dart';
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
        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Профиль',
                    style: text500Size24Black,
                  ),
                ),
                if (!['TENANT', 'LANDLORD'].contains(role))
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Войдите в аккаунт',
                      style: text400Size16Black,
                    ),
                  ),
              ],
            ),
            centerTitle: false,
            bottom: ['TENANT', 'LANDLORD'].contains(role)
                ? null
                : PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      color: greyscale10,
                    ),
                  ),
          ),
          body: (['TENANT', 'LANDLORD'].contains(role))
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Container(
                      width: double.infinity,
                      height: 96,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Color(0xFFE7E1E1)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                    "https://via.placeholder.com/48x48"),
                                fit: BoxFit.cover,
                              ),
                              shape: OvalBorder(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      me?.fullName ?? '',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF261619),
                                        fontSize: 20,
                                        fontFamily: 'Rubik',
                                        fontWeight: FontWeight.w400,
                                        height: 0.06,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IgnorePointer(
                                          ignoring: true,
                                          child: RatingBar.builder(
                                            initialRating:
                                                me?.rating.toDouble() ?? 0,
                                            minRating: 1,
                                            direction: Axis.horizontal,
                                            allowHalfRating: true,
                                            itemCount: 5,
                                            itemSize: 20,
                                            itemPadding: EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                            ),
                                            itemBuilder: (context, _) => Icon(
                                              Icons.star,
                                              color: primaryColor,
                                            ),
                                            onRatingUpdate: (rating) {
                                              print(rating);
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '(${me?.ratedOrders.length} отзыва)',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF261619),
                                            fontSize: 12,
                                            fontFamily: 'Rubik',
                                            fontWeight: FontWeight.w400,
                                            height: 0.11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.symmetric(
                    //       horizontal: 16, vertical: 12),
                    //   clipBehavior: Clip.antiAlias,
                    //   decoration: BoxDecoration(
                    //     color: Color(0xFFF73C4E),
                    //     borderRadius: BorderRadius.circular(16),
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     mainAxisAlignment: MainAxisAlignment.start,
                    //     crossAxisAlignment: CrossAxisAlignment.center,
                    //     children: [
                    //       Container(
                    //         width: 48,
                    //         height: 48,
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.min,
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             Container(
                    //               width: 48,
                    //               height: 48,
                    //               child: SvgPicture.asset(
                    //                   'assets/icons/subscription.svg'),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //       const SizedBox(width: 8),
                    //       Expanded(
                    //         child: Container(
                    //           child: Column(
                    //             mainAxisSize: MainAxisSize.min,
                    //             mainAxisAlignment: MainAxisAlignment.center,
                    //             crossAxisAlignment: CrossAxisAlignment.start,
                    //             children: [
                    //               Container(
                    //                 width: double.infinity,
                    //                 child: Row(
                    //                   mainAxisSize: MainAxisSize.min,
                    //                   mainAxisAlignment:
                    //                       MainAxisAlignment.spaceBetween,
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.center,
                    //                   children: [
                    //                     Text(
                    //                       'Подписка активна',
                    //                       textAlign: TextAlign.center,
                    //                       style: text600Size16White,
                    //                     ),
                    //                     const SizedBox(width: 10),
                    //                     Container(
                    //                       width: 16,
                    //                       height: 16,
                    //                       child: Row(
                    //                         mainAxisSize: MainAxisSize.min,
                    //                         mainAxisAlignment:
                    //                             MainAxisAlignment.center,
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.center,
                    //                         children: [
                    //                           Container(
                    //                             width: 16,
                    //                             height: 16,
                    //                             child: Row(
                    //                               mainAxisSize:
                    //                                   MainAxisSize.min,
                    //                               mainAxisAlignment:
                    //                                   MainAxisAlignment.center,
                    //                               crossAxisAlignment:
                    //                                   CrossAxisAlignment.center,
                    //                               children: [
                    //                                 Container(
                    //                                     width: 16,
                    //                                     height: 16,
                    //                                     child: Stack()),
                    //                               ],
                    //                             ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //               const SizedBox(height: 4),
                    //               Container(
                    //                 child: Column(
                    //                   mainAxisSize: MainAxisSize.min,
                    //                   mainAxisAlignment:
                    //                       MainAxisAlignment.center,
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.start,
                    //                   children: [
                    //                     Text(
                    //                       'Начало подписки: 02.06.24',
                    //                       textAlign: TextAlign.center,
                    //                       style: text400Size10White,
                    //                     ),
                    //                     Text(
                    //                       'Конец подписки:  02.07.24',
                    //                       textAlign: TextAlign.center,
                    //                       style: text400Size10White,
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const SizedBox(height: 24),
                    if (['LANDLORD'].contains(role))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ListTile(
                          onTap: wm.navigateDriverRegistration,
                          leading: SvgPicture.asset(icRegistration),
                          title: Text(
                            'Регистрация',
                            style: text400Size16Black,
                          ),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                    if (['LANDLORD'].contains(role))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ListTile(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isDismissible: true,
                            isScrollControlled: true,
                            builder: (context) =>
                                EarningAnalyticsBottomSheet(me: me),
                          ),
                          leading: SvgPicture.asset(icAnalytics),
                          title: Text(
                            'Аналитика',
                            style: text400Size16Black,
                          ),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                    ListTile(
                      leading: SvgPicture.asset(icSupport),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isDismissible: true,
                        isScrollControlled: true,
                        builder: (context) => PrimaryBottomSheet(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  width: 38,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: greyscale30,
                                    borderRadius: BorderRadius.circular(1.4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Поддержка',
                                  style: text500Size24Greyscale90,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                onTap: () {
                                  launchUrlString('https://wa.me/77088431748');
                                },
                                contentPadding: EdgeInsets.zero,
                                title: TextLocale(
                                  'Написать Whatsapp',
                                  style: text400Size16Greyscale90,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      title: Text(
                        'Поддержка',
                        style: text400Size16Black,
                      ),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AboutApplicationScreen(),
                        ),
                      ),
                      leading: SvgPicture.asset(icInfo),
                      title: Text(
                        'О приложении',
                        style: text400Size16Black,
                      ),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 24),
                    if (role != "GUEST")
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          height: 70,
                          child: PrimaryOutlinedButton.primary(
                            style: outlinedRounded12Green,
                            onPressed: wm.toggleRole,
                            text: role == 'TENANT'
                                ? 'Режим водителя'
                                : 'Режим пассажира',
                            textStyle: text600Size16White,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ListTile(
                      onTap: wm.logOut,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: TextLocale(
                        'Выйти',
                        style: text400Size16Primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      onTap: wm.logOut,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: TextLocale(
                        'Удалить аккаунт',
                        style: text400Size16Primary,
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 24),
                    PrimaryButton.primary(
                      onPressed: wm.navigateToLogin,
                      text: 'Войти',
                      textStyle: text400Size16White,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: SvgPicture.asset(icSupport),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isDismissible: true,
                        isScrollControlled: true,
                        builder: (context) => PrimaryBottomSheet(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  width: 38,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: greyscale30,
                                    borderRadius: BorderRadius.circular(1.4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Поддержка',
                                  style: text500Size24Greyscale90,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                onTap: () {
                                  launchUrlString('https://wa.me/77088431748');
                                },
                                contentPadding: EdgeInsets.zero,
                                title: TextLocale(
                                  'Написать Whatsapp',
                                  style: text400Size16Greyscale90,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      title: Text(
                        'Поддержка',
                        style: text400Size16Black,
                      ),
                      trailing: Icon(Icons.chevron_right),
                    ),
                    const SizedBox(height: 24),
                    ListTile(
                      leading: SizedBox(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AboutApplicationScreen(),
                        ),
                      ),
                      title: Text(
                        'О приложении',
                        style: text400Size16Black,
                      ),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
