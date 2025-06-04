import 'package:aktau_go/domains/food/food_domain.dart';
import 'package:aktau_go/domains/user/user_domain.dart';
import 'package:aktau_go/interactors/common/aktau_go_rest_client.dart';
import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:aktau_go/router/router.dart';
import 'package:aktau_go/utils/logger.dart';
import 'package:aktau_go/utils/utils.dart';
import 'package:elementary/elementary.dart';
import 'package:elementary_helper/elementary_helper.dart';
import 'package:flutter/material.dart';
import 'package:formz/formz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../forms/inputs/required_formz_input.dart';
import '../../utils/text_editing_controller.dart';
import './basket_model.dart';
import './basket_screen.dart';
import 'forms/food_order_form.dart';

defaultBasketWMFactory(BuildContext context) => BasketWM(BasketModel());

abstract class IBasketWM implements IWidgetModel {
  StateNotifier<int> get step;

  StateNotifier<FoodOrderForm> get foodOrderForm;

  StateNotifier<UserDomain> get me;
  StateNotifier<bool> get isLoading;

  StateNotifier<FormzSubmissionStatus> get foodOrderStatus;

  StateNotifier<List<Map<String, dynamic>>> get selectedProducts;

  TextEditingController get streetTextController;

  TextEditingController get buildingTextController;

  TextEditingController get apartmentTextController;

  TextEditingController get entranceTextController;

  TextEditingController get floorTextController;

  TextEditingController get commentTextController;

  Future<void> handleSubmit();

  void handleNextStep();

  handleAddQuantity(int i, FoodDomain selectedProduct);

  handleSubstractQuantity(int i, FoodDomain selectedProduct);

  void onPop();
}

class BasketWM extends WidgetModel<BasketScreen, BasketModel>
    implements IBasketWM {
  BasketWM(
    BasketModel model,
  ) : super(model);

  @override
  StateNotifier<int> step = StateNotifier(
    initValue: 0,
  );

  @override
  StateNotifier<FoodOrderForm> foodOrderForm = StateNotifier(
    initValue: FoodOrderForm(),
  );

  @override
  StateNotifier<bool> isLoading = StateNotifier(
    initValue: false,
  );

  @override
  StateNotifier<UserDomain> me = StateNotifier();

  @override
  final StateNotifier<FormzSubmissionStatus> foodOrderStatus = StateNotifier(
    initValue: FormzSubmissionStatus.initial,
  );

  @override
  late final StateNotifier<List<Map<String, dynamic>>> selectedProducts =
      StateNotifier(
    initValue: widget.selectedProducts,
  );

  @override
  final StateNotifier<Position> userPosition = StateNotifier();

  @override
  late final TextEditingController apartmentTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (apartment) {
      foodOrderForm.accept(foodOrderForm.value!.copyWith(
        apartment: Required.dirty(num.tryParse(apartment)),
      ));
    },
  );

  @override
  late final TextEditingController buildingTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (building) {
      foodOrderForm.accept(foodOrderForm.value!.copyWith(
        building: Required.dirty(num.tryParse(building)),
      ));
    },
  );

  @override
  late final TextEditingController commentTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (comment) {
      foodOrderForm.accept(foodOrderForm.value!.copyWith(
        comment: comment,
      ));
    },
  );

  @override
  late final TextEditingController entranceTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (entrance) {
      foodOrderForm.accept(foodOrderForm.value!.copyWith(
        entrance: Required.dirty(num.tryParse(entrance)),
      ));
    },
  );

  @override
  late final TextEditingController floorTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (level) {
      foodOrderForm.accept(foodOrderForm.value!.copyWith(
        level: Required.dirty(num.tryParse(level)),
      ));
    },
  );

  @override
  late final TextEditingController streetTextController =
      createTextEditingController(
    initialText: '',
    onChanged: (street) {
      foodOrderForm.accept(foodOrderForm.value!.copyWith(
        street: Required.dirty(street),
      ));
    },
  );

  @override
  void initWidgetModel() {
    super.initWidgetModel();
    Geolocator.getPositionStream().listen((data) {
      userPosition.accept(data);
    });
    fetchMe();
  }

  Future<bool> _handlePermission() async {
    // Проверка статуса разрешения
    PermissionStatus status = await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Запрос разрешения
      PermissionStatus result = await Permission.locationWhenInUse.request();
      return result.isGranted;
    } else if (status.isPermanentlyDenied) {
      // Перенаправление пользователя в настройки приложения
      await openAppSettings();
      return false;
    }

    return false;
  }

  Future<int?> _checkLocation() async {
    // Проверка и запрос разрешений
    if (!await _handlePermission()) {
      return null;
    }

    try {
      // Получение текущего местоположения
      var position = userPosition.value!;
      var idshop = 9;

      // Вычисление расстояния до целевых координат
      double aktauDistanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        43.39,
        51.09,
      );

      // Вычисление расстояния до целевых координат
      double zhanaOzenDistanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        43.3412,
        52.8619,
      );

      if (aktauDistanceInMeters <= 40000) {
        idshop = 9;
      } else {
        logger.w(aktauDistanceInMeters);
      }

      if (zhanaOzenDistanceInMeters <= 40000) {
        idshop = 13;
      } else {
        logger.w(zhanaOzenDistanceInMeters);
      }

      return idshop;
    } catch (e) {
      logger.e(e);
    }
    return -1;
  }

  @override
  Future<void> handleSubmit() async {
    isLoading.accept(true);
    try {
      var idshop = await _checkLocation();

      await inject<AktauGoRestClient>().createNewFoodOrder(body: {
        "name": me.value?.firstName,
        "phone": me.value?.phone,
        "idshop": idshop,
        "district": streetTextController.text,
        "house": buildingTextController.text,
        "flat": foodOrderForm.value!.apartment.value,
        "porch": foodOrderForm.value!.entrance.value,
        "floor": foodOrderForm.value!.floor.value,
        "totalsm": selectedProducts.value!.fold(0, (prev, curr) {
          prev +=
              (curr['food'] as FoodDomain).price * (curr['quantity'] as int);
          return prev;
        }),
        "docitems": [
          ...?selectedProducts.value
              ?.map(
                (e) => {
                  "idmenu": (e['food'] as FoodDomain).id,
                  "name": (e['food'] as FoodDomain).name,
                  "kolvo": (e['quantity'] as int),
                  "amount":
                      (e['food'] as FoodDomain).price * e['quantity'] as int,
                },
              )
              .toList(),
        ]
      });

      final snackBar = SnackBar(
        content: Text(
          'Заказ был отправлен',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      Routes.router.popUntil((predicate) => predicate.isFirst);
    } on Exception catch (e) {
      logger.e(e);
      final snackBar = SnackBar(
        content: Text(
          'Не удалось создать заказ',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    isLoading.accept(false);
  }

  @override
  void handleNextStep() {
    step.accept(1);
  }

  @override
  handleAddQuantity(int i, FoodDomain selectedProduct) {
    List<Map<String, dynamic>> temp = [...(selectedProducts.value ?? [])];

    temp[i] = {
      ...temp[i],
      'quantity': (temp[i]['quantity'] as num) + 1,
    };

    selectedProducts.accept(temp);
  }

  @override
  handleSubstractQuantity(int i, FoodDomain selectedProduct) {
    List<Map<String, dynamic>> temp = [...(selectedProducts.value ?? [])];

    if ((temp[i]['quantity'] as num) == 1) {
      temp.removeAt(i);
    } else {
      temp[i] = {
        ...temp[i],
        'quantity': (temp[i]['quantity'] as num) - 1,
      };
    }

    selectedProducts.accept(temp);
  }

  @override
  void onPop() {
    if (step.value == 0) {
      Navigator.of(context).pop();
    } else {
      step.accept(step.value! - 1);
    }
  }

  void fetchMe() async {
    final response = await inject<ProfileInteractor>().fetchUserProfile();
    me.accept(response);
  }
}
