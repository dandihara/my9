class GameModel {
  const GameModel({
    required this.id,
    required this.gameDate,
    required this.awayTeamName,
    required this.homeTeamName,
    required this.status,
    this.gameTime,
    this.stadiumName,
    this.awayScore,
    this.homeScore,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) => GameModel(
        id: json['id'] as int,
        gameDate: DateTime.parse(json['game_date'] as String),
        gameTime: json['game_time'] as String?,
        awayTeamName: json['away_team_name'] as String? ?? '-',
        homeTeamName: json['home_team_name'] as String? ?? '-',
        stadiumName: json['stadium_name'] as String?,
        status: json['status'] as String,
        awayScore: json['away_score'] as int?,
        homeScore: json['home_score'] as int?,
      );

  final int id;
  final DateTime gameDate;
  final String? gameTime;
  final String awayTeamName;
  final String homeTeamName;
  final String? stadiumName;
  final String status;
  final int? awayScore;
  final int? homeScore;

  String get scoreText {
    if (awayScore == null || homeScore == null) return 'VS';
    return '$awayScore : $homeScore';
  }
}
