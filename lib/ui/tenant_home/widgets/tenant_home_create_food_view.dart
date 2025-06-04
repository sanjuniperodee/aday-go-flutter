import 'package:aktau_go/core/colors.dart';
import 'package:aktau_go/core/text_styles.dart';
import 'package:aktau_go/domains/food/food_category_domain.dart';
import 'package:aktau_go/domains/food/food_domain.dart';
import 'package:aktau_go/ui/basket/basket_screen.dart';
import 'package:aktau_go/ui/widgets/primary_button.dart';
import 'package:aktau_go/utils/num_utils.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../../core/button_styles.dart';
import '../../widgets/pretty_wave_button.dart';

class TenantHomeFoodsView extends StatefulWidget {
  final ScrollController scrollController;
  final List<FoodCategoryDomain> foodCategories;
  final List<FoodDomain> foods;
  final VoidCallback onScrollDown;

  const TenantHomeFoodsView({
    super.key,
    required this.scrollController,
    required this.foodCategories,
    required this.foods,
    required this.onScrollDown,
  });

  @override
  State<TenantHomeFoodsView> createState() => _TenantHomeFoodsViewState();
}

class _TenantHomeFoodsViewState extends State<TenantHomeFoodsView> {
  int currentTab = 0;
  PageController _pageController = PageController();
  final controller = AutoScrollController();

  List<Map<String, dynamic>> selectedProductQuantity = [];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  child: Text(
                    'Выберите блюда из меню',
                    style: text500Size20Greyscale90,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    controller: controller,
                    children: [
                      for (int index = 0;
                          index < widget.foodCategories.length;
                          index++)
                        AutoScrollTag(
                          index: index,
                          key: Key('category_${index}'),
                          controller: controller,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                currentTab = index;
                              });
                              _pageController.jumpToPage(currentTab);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                border: currentTab == index
                                    ? Border(
                                        bottom: BorderSide(
                                          color: primaryColor,
                                          width: 2,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Text(widget.foodCategories[index].name),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        currentTab = page;

                        controller.scrollToIndex(page,
                            preferPosition: AutoScrollPosition.begin);
                      });
                    },
                    children: [
                      for (int j = 0; j < widget.foodCategories.length; j++)
                        ListView(
                          padding: EdgeInsets.only(top: 16),
                          // controller: widget.scrollController,
                          children: [
                            for (int foodIndex = 0;
                                foodIndex < widget.foods.length;
                                foodIndex++)
                              if (widget.foods[foodIndex].parentId ==
                                  widget.foodCategories[j].id)
                                Builder(
                                  builder: (context) {
                                    int selectedIndex = selectedProductQuantity
                                        .indexWhere((food) =>
                                            (food['food'] as FoodDomain).id ==
                                            widget.foods[foodIndex].id);

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 108,
                                            height: 108,
                                            margin: const EdgeInsets.only(
                                                right: 16),
                                            clipBehavior: Clip.hardEdge,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Image.network(
                                              "https://api.aktau-go.kz/img/${widget.foods[foodIndex].id}",
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.only(
                                                      bottom: 4),
                                                  child: Text(
                                                    widget
                                                        .foods[foodIndex].name,
                                                    style:
                                                        text400Size16Greyscale90,
                                                  ),
                                                ),
                                                Container(
                                                  width: double.infinity,
                                                  margin: const EdgeInsets.only(
                                                      bottom: 4),
                                                  child: Text(
                                                    widget.foods[foodIndex]
                                                        .description,
                                                    style:
                                                        text400Size12Greyscale30,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        NumUtils.humanizeNumber(
                                                              widget
                                                                  .foods[
                                                                      foodIndex]
                                                                  .price,
                                                              isCurrency: true,
                                                            ) ??
                                                            '',
                                                        style:
                                                            text400Size16Greyscale90,
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        if (selectedIndex != -1)
                                                          SizedBox(
                                                            width: 48,
                                                            child: PrimaryButton
                                                                .primary(
                                                              onPressed: () {
                                                                selectedProductQuantity[
                                                                    selectedIndex] = {
                                                                  ...selectedProductQuantity[
                                                                      selectedIndex],
                                                                  'quantity':
                                                                      selectedProductQuantity[selectedIndex]
                                                                              [
                                                                              'quantity'] -
                                                                          1,
                                                                };

                                                                setState(() {});
                                                                widget
                                                                    .onScrollDown();
                                                              },
                                                              style:
                                                                  primaryRounded8Padding,
                                                              child: Icon(
                                                                Icons.remove,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        if (selectedIndex != -1)
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16),
                                                            child: Text(
                                                              '${selectedProductQuantity[selectedIndex]['quantity']}',
                                                              style:
                                                                  text400Size16Greyscale90,
                                                            ),
                                                          ),
                                                        SizedBox(
                                                          width: 48,
                                                          child: PrimaryButton
                                                              .primary(
                                                            onPressed: () {
                                                              if (selectedIndex ==
                                                                  -1) {
                                                                selectedProductQuantity
                                                                    .add({
                                                                  'food': widget
                                                                          .foods[
                                                                      foodIndex],
                                                                  'quantity': 1,
                                                                });
                                                              } else {
                                                                selectedProductQuantity[
                                                                    selectedIndex] = {
                                                                  ...selectedProductQuantity[
                                                                      selectedIndex],
                                                                  'quantity':
                                                                      (selectedProductQuantity[selectedIndex]['quantity']
                                                                              as int) +
                                                                          1,
                                                                };
                                                              }
                                                              setState(() {});
                                                              widget
                                                                  .onScrollDown();
                                                            },
                                                            style:
                                                                primaryRounded8Padding,
                                                            child: Icon(
                                                              Icons.add,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          ],
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
          if (selectedProductQuantity.isNotEmpty)
            Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: greyscale10,
                    ),
                  ),
                ),
                child: PrettyWaveButton(
                  backgroundColor: primaryColor,
                  child: Text(
                    'Перейти в корзину (${selectedProductQuantity.fold<int>(0, (prev, curr) => prev += (curr['quantity'] as int))})',
                    style: text400Size16White,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BasketScreen(
                          selectedProducts: selectedProductQuantity,
                        ),
                      ),
                    );
                  },
                )
                // PrimaryButton.primary(
                //             onPressed: () {
                //               Navigator.of(context).push(
                //                 MaterialPageRoute(
                //                   builder: (context) => BasketScreen(
                //                     selectedProducts: selectedProductQuantity,
                //                   ),
                //                 ),
                //               );
                //             },
                //             text:
                //                 'Перейти в корзину (${selectedProductQuantity.fold<int>(0, (prev, curr) => prev += (curr['quantity'] as int))})',
                //             textStyle: text400Size16White,
                //           ),
                ),
        ],
      ),
    );
  }
}
