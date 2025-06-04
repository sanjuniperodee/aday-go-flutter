import 'package:aktau_go/forms/inputs/required_formz_input.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

class DriverOrderForm with EquatableMixin, FormzMixin {
  final Required<String> fromAddress;
  final Required<String> fromMapboxId;
  final Required<String> toAddress;
  final Required<String> toMapboxId;
  final Required<num> cost;
  final String comment;

  DriverOrderForm({
    this.fromAddress = const Required.pure(),
    this.fromMapboxId = const Required.pure(),
    this.toAddress = const Required.pure(),
    this.toMapboxId = const Required.pure(),
    this.cost = const Required.pure(),
    this.comment = '',
  });

  @override
  List<FormzInput> get inputs => [
        fromAddress,
        // fromMapboxId,
        toAddress,
        // toMapboxId,
        cost,
      ];

  @override
  List<Object?> get props => [
        fromAddress,
        fromMapboxId,
        toAddress,
        toMapboxId,
        cost,
        comment,
      ];

  DriverOrderForm copyWith({
    Required<String>? fromAddress,
    Required<String>? fromMapboxId,
    Required<String>? toAddress,
    Required<String>? toMapboxId,
    Required<num>? cost,
    String? comment,
  }) =>
      DriverOrderForm(
        fromAddress: fromAddress ?? this.fromAddress,
        fromMapboxId: fromMapboxId ?? this.fromMapboxId,
        toAddress: toAddress ?? this.toAddress,
        toMapboxId: toMapboxId ?? this.toMapboxId,
        cost: cost ?? this.cost,
        comment: comment ?? this.comment,
      );
}
