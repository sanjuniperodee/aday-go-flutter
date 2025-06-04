import 'package:aktau_go/forms/inputs/required_formz_input.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

class FoodOrderForm with EquatableMixin, FormzMixin {
  final Required<String> street;
  final Required<num> apartment;
  final Required<num> building;
  final Required<num> entrance;
  final Required<num> floor;
  final String comment;

  FoodOrderForm({
    this.street = const Required.pure(),
    this.apartment = const Required.pure(),
    this.building = const Required.pure(),
    this.entrance = const Required.pure(),
    this.floor = const Required.pure(),
    this.comment = '',
  });

  @override
  List<FormzInput> get inputs => [
        street,
    apartment,
        building,
        entrance,
        floor,
      ];

  @override
  List<Object?> get props => [
        street,
    apartment,
        building,
        entrance,
        floor,
        comment,
      ];

  FoodOrderForm copyWith({
    Required<String>? street,
    Required<num>? apartment,
    Required<num>? building,
    Required<num>? entrance,
    Required<num>? level,
    String? comment,
  }) =>
      FoodOrderForm(
        street: street ?? this.street,
        apartment: apartment ?? this.apartment,
        building: building ?? this.building,
        entrance: entrance ?? this.entrance,
        floor: level ?? this.floor,
        comment: comment ?? this.comment,
      );
}
