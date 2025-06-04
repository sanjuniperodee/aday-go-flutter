import 'package:aktau_go/forms/inputs/phone_formz_input.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

import 'inputs/otp_formz_input.dart';

class OtpConfirmForm with FormzMixin, EquatableMixin {
  final PhoneFormzInput phone;
  final OtpFormzInput otp;

  OtpConfirmForm({
    this.phone = const PhoneFormzInput.pure(),
    this.otp = const OtpFormzInput.pure(),
  });

  @override
  List<FormzInput> get inputs => [
        phone,
        otp,
      ];

  @override
  List<Object?> get props => [
        phone,
        otp,
      ];

  OtpConfirmForm copyWith({
    PhoneFormzInput? phone,
    OtpFormzInput? otp,
  }) =>
      OtpConfirmForm(
        phone: phone ?? this.phone,
        otp: otp ?? this.otp,
      );
}
