import 'package:aktau_go/interactors/location_interactor.dart';
import 'package:aktau_go/interactors/main_navigation_interactor.dart';
import 'package:aktau_go/interactors/session_interactor.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../core/colors.dart';
import '../../core/images.dart';
import '../client_history/client_history_screen.dart';
import '../history/history_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../tenant_home/tenant_home_screen.dart';
// import '../driver_home/driver_home_screen.dart';
// import '../driver_registration/driver_registration_screen.dart';
import './main_model.dart';
import './main_screen.dart';

defaultMainWMFactory(BuildContext context) => MainWM(MainModel(
      inject<SessionInteractor>(),
      inject<MainNavigationInteractor>(),
      inject<LocationInteractor>(),
    ));

abstract class IMainWM implements IWidgetModel {
  PageController get pageController;

  StateNotifier<int> get currentPage;

  StateNotifier<String> get currentRole;

  void onPageChanged(int newPage);

  List<Widget> getUserScreenByRole();

  List<BottomNavigationBarItem> getUserBottomItemsByRole();
}

class MainWM extends WidgetModel<MainScreen, MainModel> implements IMainWM {
  MainWM(
    MainModel model,
  ) : super(model);

  @override
  final PageController pageController = PageController();

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    pageController.addListener(() {
      currentPage.accept(pageController.page?.toInt() ?? 0);
    });

    model.role.addListener(() {
      currentRole.accept(model.role.value);
    });

    model.currentTab.addListener(() {
      currentPage.accept(model.currentTab.value);
    });

    model.requestLocation();
  }

  @override
  final StateNotifier<int> currentPage = StateNotifier(
    initValue: 0,
  );

  @override
  final StateNotifier<String> currentRole = StateNotifier(
    initValue: 'TENANT',
  );

  @override
  void onPageChanged(int newPage) {
    currentPage.accept(newPage);
    pageController.animateToPage(
      newPage,
      duration: Duration(
        milliseconds: 1,
      ),
      curve: Curves.linear,
    );
  }

  @override
  List<Widget> getUserScreenByRole() {
    switch (currentRole.value) {
      case "LANDLORD":
        return [
          OrdersScreen(),
          HistoryScreen(),
          ProfileScreen(),
        ];
      case "TENANT":
        return [
          TenantHomeScreen(),
          ClientHistoryScreen(),
          ProfileScreen(),
        ];
      default:
        return [
          OrdersScreen(),
          HistoryScreen(),
          ProfileScreen(),
        ];
    }
  }

  @override
  List<BottomNavigationBarItem> getUserBottomItemsByRole() {
    List<Map<String, dynamic>> elements = [];
    switch (currentRole.value) {
      case "LANDLORD":
        elements = [
          {
            'icon': icOrders,
            'label': 'orders',
          },
          {
            'icon': icHistory,
            'label': 'history',
          },
          {
            'icon': icProfile,
            'label': 'profile',
          },
        ];
      case "TENANT":
        elements = [
          {
            'icon': icOrders,
            'label': 'orders',
          },
          {
            'icon': icHistory,
            'label': 'history',
          },
          {
            'icon': icProfile,
            'label': 'profile',
          },
        ];
      default:
        elements = [
          {
            'icon': icOrders,
            'label': 'orders',
          },
          {
            'icon': icHistory,
            'label': 'history',
          },
          {
            'icon': icProfile,
            'label': 'profile',
          },
        ];
    }

    return elements
        .asMap()
        .entries
        .map(
          (e) => BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(
                height: 24,
                width: 24,
                child: SvgPicture.asset(
                  e.value['icon'] as String,
                  colorFilter: ColorFilter.mode(
                    currentPage.value == e.key ? primaryColor : greyscale30,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            label: (e.value['label'] as String).tr(),
          ),
        )
        .toList();
  }
}
