class VideoSettlementBean {
  String _vestStatus = '';
  String _moneySymbol = '';
  String _totalRevenue = '';
  String _totalRevenueVest = '';
  String _settlementBonus = '';
  String _settlementBonusVest = '';
  String _settlementTime = '';
  String _giftRevenue = '';
  String _giftRevenueVest = '';

  String get getVestStatus => _vestStatus;

  set setVestStatus(String value) {
    _vestStatus = value;
  }

  String get getMoneySymbol => _moneySymbol;

  set setMoneySymbol(String value) {
    _moneySymbol = value;
  }

  String get getTotalRevenue => _totalRevenue;

  set setTotalRevenue(String value) {
    _totalRevenue = value;
  }

  String get getTotalRevenueVest => _totalRevenueVest;

  String get getGiftRevenueVest => _giftRevenueVest;

  set setGiftRevenueVest(String value) {
    _giftRevenueVest = value;
  }

  String get getGiftRevenue => _giftRevenue;

  set setGiftRevenue(String value) {
    _giftRevenue = value;
  }

  String get getSettlementTime => _settlementTime;

  set setSettlementTime(String value) {
    _settlementTime = value;
  }

  String get getSettlementBonus => _settlementBonus;

  set setSettlementBonus(String value) {
    _settlementBonus = value;
  }

  set setTotalRevenueVest(String value) {
    _totalRevenueVest = value;
  }

  String get getSettlementBonusVest => _settlementBonusVest;

  set setSettlementBonusVest(String value) {
    _settlementBonusVest = value;
  }
}
