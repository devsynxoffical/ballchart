import 'package:flutter/material.dart';

/// How the coach chose to start the "new strategy" flow (+ menu).
enum StrategyCreationEntry {
  /// All sections: type, name, description, diagram, video, plays, tags.
  fullPlaybook,

  /// Prioritizes a film clip / stream URL (YouTube, Drive, .mp4).
  videoFirst,

  /// Prioritizes a still diagram from the gallery.
  diagramFirst,

  /// Written breakdown + key plays; media optional.
  textOnly,

  /// Scouting / article / Hudl — requires a reference link; optional video.
  linkLibrary,
}

extension StrategyCreationEntryX on StrategyCreationEntry {
  String get title {
    switch (this) {
      case StrategyCreationEntry.fullPlaybook:
        return 'Full playbook entry';
      case StrategyCreationEntry.videoFirst:
        return 'Video & film';
      case StrategyCreationEntry.diagramFirst:
        return 'Diagram / board';
      case StrategyCreationEntry.textOnly:
        return 'Text & concepts';
      case StrategyCreationEntry.linkLibrary:
        return 'External link';
    }
  }

  String get subtitle {
    switch (this) {
      case StrategyCreationEntry.fullPlaybook:
        return 'Name, description, diagram, optional clip, key plays';
      case StrategyCreationEntry.videoFirst:
        return 'Lead with a clip URL, add notes and plays';
      case StrategyCreationEntry.diagramFirst:
        return 'Start from a whiteboard image, add details';
      case StrategyCreationEntry.textOnly:
        return 'Written breakdown without requiring video';
      case StrategyCreationEntry.linkLibrary:
        return 'Hudl, article, or doc link + summary';
    }
  }

  IconData get icon {
    switch (this) {
      case StrategyCreationEntry.fullPlaybook:
        return Icons.auto_awesome_mosaic_outlined;
      case StrategyCreationEntry.videoFirst:
        return Icons.ondemand_video_outlined;
      case StrategyCreationEntry.diagramFirst:
        return Icons.draw_outlined;
      case StrategyCreationEntry.textOnly:
        return Icons.notes_outlined;
      case StrategyCreationEntry.linkLibrary:
        return Icons.link_outlined;
    }
  }
}
