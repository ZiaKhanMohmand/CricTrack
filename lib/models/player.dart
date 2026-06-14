class Player {
  String id;
  String name;
  // batting stats
  int runs;
  int ballsFaced;
  bool isOut;
  // bowling stats
  int oversBowled;
  int ballsInCurrentOver;
  int runsConceded;
  int wicketsTaken;

  int balls4s;
  int balls6s;

  Player({required this.name, required this.id})
    : runs = 0,
      ballsFaced = 0,
      isOut = false,
      oversBowled = 0,
      ballsInCurrentOver = 0,
      runsConceded = 0,
      wicketsTaken = 0,
      balls4s = 0,
      balls6s = 0;
}
