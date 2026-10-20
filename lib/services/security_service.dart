import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
class SecurityService {
  static const _pinKey='app_pin',_bioKey='biometric_enabled'; final _auth=LocalAuthentication();
  Future<bool> hasPin() async=>(await SharedPreferences.getInstance()).getString(_pinKey)?.isNotEmpty==true;
  Future<void> setPin(String pin) async=>(await SharedPreferences.getInstance()).setString(_pinKey,pin);
  Future<bool> checkPin(String pin) async=>pin==(await SharedPreferences.getInstance()).getString(_pinKey);
  Future<bool> biometricEnabled() async=>(await SharedPreferences.getInstance()).getBool(_bioKey)??false;
  Future<void> setBiometric(bool v) async=>(await SharedPreferences.getInstance()).setBool(_bioKey,v);
  Future<bool> canBiometric() async=>await _auth.canCheckBiometrics||await _auth.isDeviceSupported();
  Future<bool> authenticate() async {try{return await _auth.authenticate(localizedReason:'Desbloqueie seu controle financeiro',options:const AuthenticationOptions(biometricOnly:true,stickyAuth:true));}catch(_){return false;}}
}
