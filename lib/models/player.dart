class Player {
  String id;
  String name;
  // batting stats
  int runs;
  int ballsFaced;
  bool isOut;
  bool retiredHurt;
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
      retiredHurt = false,
      oversBowled = 0,
      ballsInCurrentOver = 0,
      runsConceded = 0,
      wicketsTaken = 0,
      balls4s = 0,
      balls6s = 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'runs': runs,
    'ballsFaced': ballsFaced,
    'isOut': isOut,
    'retiredHurt': retiredHurt,
    'oversBowled': oversBowled,
    'ballsInCurrentOver': ballsInCurrentOver,
    'runsConceded': runsConceded,
    'wicketsTaken': wicketsTaken,
    'balls4s': balls4s,
    'balls6s': balls6s,
  };

  factory Player.fromJson(Map<String, dynamic> j) =>
      Player(id: j['id'], name: j['name'])
        ..runs = j['runs']
        ..ballsFaced = j['ballsFaced']
        ..isOut = j['isOut']
        ..retiredHurt = j['retiredHurt']
        ..oversBowled = j['oversBowled']
        ..ballsInCurrentOver = j['ballsInCurrentOver']
        ..runsConceded = j['runsConceded']
        ..wicketsTaken = j['wicketsTaken']
        ..balls4s = j['balls4s']
        ..balls6s = j['balls6s'];
}
