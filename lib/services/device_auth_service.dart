class DeviceAuth {
  // NOTE : must match exactly the Mobile_Api_Key in env in backend
  static const _mobileApikey = "1234782181veryyyyloonngggrandomkey";

  static Map<String, String> systemAuthHeader() {
    return {'Content-Type': 'application/json', 'X-Api-Key': _mobileApikey};
  }
}
