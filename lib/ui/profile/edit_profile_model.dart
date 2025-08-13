import 'package:aktau_go/interactors/profile_interactor.dart';
import 'package:elementary/elementary.dart';

import '../../domains/user/user_domain.dart';

class EditProfileModel extends ElementaryModel {
  final ProfileInteractor _profileInteractor;

  EditProfileModel(this._profileInteractor) : super();

  Future<UserDomain> getUserProfile() async {
    return await _profileInteractor.fetchUserProfile();
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? middleName,
  }) async {
    await _profileInteractor.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
    );
  }
} 