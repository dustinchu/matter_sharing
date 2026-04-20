class GoogleHomeConfig {
  final String teamID;
  final String clientID;
  final String serverClientID;
  final String appGroup;

  const GoogleHomeConfig({
    required this.teamID,
    required this.clientID,
    required this.serverClientID,
    required this.appGroup,
  });

  Map<String, dynamic> toMap() => {
        'teamID': teamID,
        'clientID': clientID,
        'serverClientID': serverClientID,
        'appGroup': appGroup,
      };
}
