class TeamTemplate {
  String id;
  String name;
  List<String> playerNames;

  TeamTemplate({
    required this.id,
    required this.name,
    required this.playerNames,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'playerNames': playerNames,
  };

  factory TeamTemplate.fromJson(Map<String, dynamic> j) => TeamTemplate(
    id: j['id'],
    name: j['name'],
    playerNames: List<String>.from(j['playerNames']),
  );
}
