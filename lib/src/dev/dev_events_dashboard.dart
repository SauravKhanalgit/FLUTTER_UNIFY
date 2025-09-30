/// Live visual dashboards (streams, events, network timelines) - skeleton
import 'dart:async';

class DevEvent {
  final String stream; // network | bridge | analytics | custom
  final dynamic data;
  final DateTime ts = DateTime.now();
  DevEvent(this.stream, this.data);
}

class DevEventsDashboard {
  DevEventsDashboard._();
  static DevEventsDashboard? _instance;
  static DevEventsDashboard get instance =>
      _instance ??= DevEventsDashboard._();

  final _controller = StreamController<DevEvent>.broadcast();
  Stream<DevEvent> get events => _controller.stream;

  void publish(String stream, dynamic data) {
    _controller.add(DevEvent(stream, data));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
