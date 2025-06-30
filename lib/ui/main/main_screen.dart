import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../widgets/network_status_widget.dart';
import './main_wm.dart';

class MainScreen extends ElementaryWidget<IMainWM> {
  MainScreen({
    Key? key,
  }) : super(
          (context) => defaultMainWMFactory(context),
        );

  @override
  Widget build(IMainWM wm) {
    return DoubleSourceBuilder(
        firstSource: wm.currentPage,
        secondSource: wm.currentRole,
        builder: (
          context,
          int? currentPage,
          String? currentRole,
        ) {
          return NetworkStatusWidget(
            child: Scaffold(
              body: IndexedStack(
                index: currentPage,
                children: wm.getUserScreenByRole(),
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: BottomNavigationBar(
                    backgroundColor: Colors.white,
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: true,
                    showSelectedLabels: true,
                    elevation: 0,
                    selectedItemColor: primaryColor,
                    unselectedItemColor: Colors.grey.shade500,
                    selectedLabelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: wm.onPageChanged,
                    currentIndex: currentPage ?? 0,
                    items: wm.getUserBottomItemsByRole(),
                  ),
                ),
              ),
            ),
          );
        });
  }
}
