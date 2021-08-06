class SettingModel {
  String oldLan;
  String newLan;
  bool isEnvSwitched;
  SettingModel(this.isEnvSwitched,this.oldLan, this.newLan);
}

class SettingSwitchEvent {
  SettingModel setting;
  SettingSwitchEvent(this.setting);
}
