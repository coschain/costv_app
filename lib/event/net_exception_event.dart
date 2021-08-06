class NetExceptionEvent {
  static final Map<String, NetExceptionEvent> _cache =
      <String, NetExceptionEvent>{};

  final String tag;
  final String msg;

  NetExceptionEvent(this.tag, this.msg);

  factory NetExceptionEvent.create(tag, str) {
    if (_cache.containsKey(str)) {
      return _cache[str];
    } else {
      final event = NetExceptionEvent(tag, str);
      _cache[str] = event;
      return event;
    }
  }
}
