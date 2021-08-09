
import 'package:flutter/cupertino.dart';

class ManualSwitchModeEvent {
  Brightness oldVal;
  Brightness curVal;
  ManualSwitchModeEvent(this.oldVal, this.curVal);
}

class SystemSwitchModeEvent {
  Brightness oldVal;
  Brightness curVal;
  SystemSwitchModeEvent(this.oldVal, this.curVal);
}