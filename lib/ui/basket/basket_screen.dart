import 'package:aktau_go/domains/food/food_domain.dart';
import 'package:aktau_go/ui/basket/forms/food_order_form.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:elementary/elementary.dart';

import '../../core/button_styles.dart';
import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../utils/num_utils.dart';
import '../widgets/primary_button.dart';
import '../widgets/rounded_text_field.dart';
import 'basket_wm.dart';

class BasketScreen extends ElementaryWidget<IBasketWM> {
  final List<Map<String, dynamic>> selectedProducts;

  BasketScreen({
    Key? key,
    required this.selectedProducts,
  }) : super(
          (context) => defaultBasketWMFactory(context),
        );

  @override
  Widget build(IBasketWM wm) {
    return TripleSourceBuilder(
        firstSource: wm.foodOrderForm,
        secondSource: wm.step,
        thirdSource: wm.selectedProducts,
        builder: (
          context,
          FoodOrderForm? foodOrderForm,
          int? step,
          List<Map<String, dynamic>>? selectedProducts,
        ) {
          selectedProducts = selectedProducts ?? [];
          if (step == 0) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Корзина'),
                leading: IconButton(
                    onPressed: wm.onPop, icon: Icon(Icons.chevron_left)),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Корзина',
                            style: text500Size20Greyscale90,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '(${selectedProducts.length} позиции)',
                            style: text400Size12Greyscale90,
                          ),
                        ),
                        Divider(color: greyscale30),
                        const SizedBox(height: 24),
                        for (int i = 0; i < selectedProducts.length; i++)
                          Builder(builder: (context) {
                            final selectedProduct =
                                selectedProducts![i]['food'] as FoodDomain;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 108,
                                    height: 108,
                                    margin: const EdgeInsets.only(right: 16),
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Image.network(
                                      "https://api.aktau-go.kz/img/${selectedProduct.id}",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            selectedProduct.name,
                                            style: text400Size16Greyscale90,
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            selectedProduct.description,
                                            style: text400Size12Greyscale30,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                NumUtils.humanizeNumber(
                                                      selectedProduct.price,
                                                      isCurrency: true,
                                                    ) ??
                                                    '',
                                                style: text400Size16Greyscale90,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: 48,
                                                  child: PrimaryButton.primary(
                                                    onPressed: () => wm
                                                        .handleSubstractQuantity(
                                                            i, selectedProduct),
                                                    style:
                                                        primaryRounded8Padding,
                                                    child: Icon(
                                                      Icons.remove,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Text(
                                                    '${selectedProducts[i]['quantity']}',
                                                    style:
                                                        text400Size16Greyscale90,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 48,
                                                  child: PrimaryButton.primary(
                                                    onPressed: () =>
                                                        wm.handleAddQuantity(
                                                            i, selectedProduct),
                                                    style:
                                                        primaryRounded8Padding,
                                                    child: Icon(
                                                      Icons.add,
                                                      color: Colors.white,
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
                          })
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: greyscale10,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'Итого: ${selectedProducts.fold(0, (prev, curr) {
                                  prev += (curr['food'] as FoodDomain).price *
                                      (curr['quantity'] as int);
                                  return prev;
                                })} ₸',
                                style: text500Size20Greyscale90,
                              ),
                            ),
                            Text(
                              'Сумма без учёта доставки',
                              style: text400Size12Error,
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: PrimaryButton.primary(
                            onPressed: wm.handleNextStep,
                            text: 'Продолжить',
                            textStyle: text400Size16White,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text('Оформление заказа'),
              leading: IconButton(
                  onPressed: wm.onPop, icon: Icon(Icons.chevron_left)),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Укажите адрес',
                          style: text500Size20Greyscale90,
                        ),
                      ),
                      Divider(color: greyscale30),
                      const SizedBox(height: 24),
                      Container(
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: RoundedTextField(
                          backgroundColor: Colors.white,
                          controller: wm.streetTextController,
                          hintText: 'Улица/мкр*',
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: RoundedTextField(
                                backgroundColor: Colors.white,
                                controller: wm.buildingTextController,
                                keyboardType: TextInputType.number,
                                hintText: 'Дом*',
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: RoundedTextField(
                                backgroundColor: Colors.white,
                                controller: wm.apartmentTextController,
                                keyboardType: TextInputType.number,
                                hintText: 'Квартира*',
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: RoundedTextField(
                                backgroundColor: Colors.white,
                                controller: wm.entranceTextController,
                                keyboardType: TextInputType.number,
                                hintText: 'Подъезд',
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 48,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: RoundedTextField(
                                backgroundColor: Colors.white,
                                controller: wm.floorTextController,
                                keyboardType: TextInputType.number,
                                hintText: 'Этаж',
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 48,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: RoundedTextField(
                          backgroundColor: Colors.white,
                          controller: wm.commentTextController,
                          hintText: 'Комментарий',
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: greyscale10,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Итого: ${selectedProducts.fold(0, (prev, curr) {
                                prev += (curr['food'] as FoodDomain).price *
                                    (curr['quantity'] as int);
                                return prev;
                              })} ₸',
                              style: text500Size20Greyscale90,
                            ),
                          ),
                          Text(
                            'Сумма без учёта доставки',
                            style: text400Size12Error,
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: StateNotifierBuilder(
                            listenableState: wm.isLoading,
                            builder: (
                              context,
                              bool? isLoading,
                            ) {
                              return PrimaryButton.primary(
                                isLoading: isLoading,
                                onPressed: foodOrderForm!.isValid
                                    ? wm.handleSubmit
                                    : null,
                                text: 'Заказать',
                                textStyle: text400Size16White,
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}
