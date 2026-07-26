class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.gameId,
    required this.gameDate,
    required this.awayTeamName,
    required this.homeTeamName,
    this.awayTeamId,
    this.homeTeamId,
    this.myTeamId,
    this.resultForMyTeam,
    this.seatSection,
    this.memo,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      AttendanceModel(
        id: json['id'] as int,
        gameId: json['game_id'] as int,
        gameDate: DateTime.parse(json['game_date'] as String),
        awayTeamId: json['away_team_id'] as int?,
        awayTeamName: json['away_team_name'] as String? ?? '-',
        homeTeamId: json['home_team_id'] as int?,
        homeTeamName: json['home_team_name'] as String? ?? '-',
        myTeamId: json['my_team_id'] as int?,
        resultForMyTeam: json['result_for_my_team'] as String?,
        seatSection: json['seat_section'] as String?,
        memo: json['memo'] as String?,
      );

  final int id;
  final int gameId;
  final DateTime gameDate;
  final int? awayTeamId;
  final String awayTeamName;
  final int? homeTeamId;
  final String homeTeamName;
  final int? myTeamId;
  final String? resultForMyTeam;
  final String? seatSection;
  final String? memo;
}
