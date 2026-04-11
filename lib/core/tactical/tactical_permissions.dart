/// Normalized role checks for create / edit / run strategy and battle controls.
class TacticalPermissions {
  TacticalPermissions._();

  static bool canCreateStrategy(String? role) {
    return role == 'admin' || role == 'head_coach' || role == 'coach' || role == 'assistant_coach';
  }

  static bool canEditStrategy(String? role) => canCreateStrategy(role);

  static bool canRunTacticalLab(String? role) {
    return canCreateStrategy(role) || role == 'player';
  }

  static bool canControlBattle(String? role) {
    return role == 'admin' || role == 'head_coach' || role == 'coach';
  }

  static bool canLogBattleEvents(String? role) => canControlBattle(role) || role == 'assistant_coach';
}
