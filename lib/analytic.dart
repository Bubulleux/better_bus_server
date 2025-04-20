class ApiAnalytic {
  int dayStatus = 0;
  int weekStatus = 0;
  int totalFromStart = 0;
  DateTime start = DateTime.now();
  bool hookStarted = false;

  void startHook() {
    if (hookStarted) return;
    dayHook();
    weekHook();
    hookStarted = true;
  }

  void dayHook() {
    dayStatus = 0;
    Future.delayed(Duration(days: 1)).then((_) => dayHook());
  }

  void weekHook() {
    weekStatus = 0;
    Future.delayed(Duration(days: 7)).then((_) => weekHook());
  }

  void gotStatus() {
    dayStatus += 1;
    weekStatus += 1;
    totalFromStart += 1;
  }

  Map<String, dynamic> getAnalytic() {
    return {
      "24h status": dayStatus,
      "1 week status": weekStatus,
      "total": totalFromStart,
      "start" : start.toIso8601String(),
    };
  }
}