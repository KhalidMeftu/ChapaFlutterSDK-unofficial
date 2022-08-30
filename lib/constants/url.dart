class ChapaUrl {
  static const String baseUrl =
      "https://api.chapa.co/v1/transaction/mobile-initialize";
  static const String chargeCardUrl = "charges?type=card";
  static const String validateCharge = "validate-charge";
  static const String defaultRedirectUrl = "https://chapa.co/";
  static const String verifyTransaction =
      "https://api.chapa.co/v1/transaction/verify/";

  static String getBaseUrl(final bool isDebugMode) {
    return baseUrl;
  }
}
