import 'package:event_bus/event_bus.dart';

class EventBusHelp {
  static final EventBus eventBus = new EventBus();

  static EventBus getInstance() {
    return eventBus;
  }
}
