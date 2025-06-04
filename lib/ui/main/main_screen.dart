import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
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
          return Scaffold(
            body: IndexedStack(
              index: currentPage,
              children: wm.getUserScreenByRole(),
            ),
            bottomNavigationBar: Theme(
              data: ThemeData(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: Container(
                // decoration: BoxDecoration(
                //   border: Border(
                //     top: BorderSide(
                //       color: greyscale20,
                //     ),
                //   ),
                // ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.white.withOpacity(0.85),
                  type: BottomNavigationBarType.fixed,
                  showUnselectedLabels: true,
                  showSelectedLabels: true,
                  elevation: 0,
                  // selectedLabelStyle: text500Size10BottomActiveColor.copyWith(
                  //   height: 2,
                  // ),
                  // unselectedLabelStyle:
                  // text500Size10BottomInActiveColor.copyWith(
                  //   height: 2,
                  // ),
                  unselectedFontSize: 10,
                  selectedItemColor: primaryColor,
                  onTap: wm.onPageChanged,
                  currentIndex: currentPage ?? 0,
                  items: wm.getUserBottomItemsByRole(),
                ),
              ),
            ),
          );
        });
  }
}
