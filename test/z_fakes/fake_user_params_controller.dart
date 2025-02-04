import 'package:plante/model/user_params.dart';
import 'package:plante/model/user_params_controller.dart';

class FakeUserParamsController implements UserParamsController {
  final _observers = <UserParamsControllerObserver>[];
  UserParams? _userParams;

  @override
  void addObserver(UserParamsControllerObserver observer) =>
      _observers.add(observer);

  @override
  void removeObserver(UserParamsControllerObserver observer) =>
      _observers.remove(observer);

  @override
  Future<UserParams?> getUserParams() async {
    return _userParams;
  }

  @override
  Future<void> setUserParams(UserParams? userParams) async {
    _userParams = userParams;
    _observers.forEach((l) {
      l.onUserParamsUpdate(userParams);
    });
  }

  @override
  UserParams? get cachedUserParams => _userParams;
}
