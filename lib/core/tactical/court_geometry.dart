import 'package:flutter/material.dart';

import 'tactical_entities.dart';

/// Full court: x ∈ [0,1] left–right, y ∈ [0,1] **north basket → south basket** (defense guards north hoop, offense attacks south).
@immutable
class FullCourtLayout {
  final List<Offset> offense;
  final List<Offset> defense;

  const FullCourtLayout({required this.offense, required this.defense});

  static const int playersPerTeam = 5;
}

/// Normalized half-court coordinates: (0,0) top-left, (1,1) bottom-right — offense toward bottom hoop.
class CourtSlots {
  CourtSlots._();

  /// Full 94×50 style layout: **10 players** — bottom five = offense (O1–O5), top five = defense (D1–D5).
  static FullCourtLayout fullCourt(FormationPreset f) {
    switch (f) {
      case FormationPreset.fastBreak:
        return FullCourtLayout(
          offense: const [
            Offset(0.5, 0.90),
            Offset(0.12, 0.62),
            Offset(0.88, 0.62),
            Offset(0.22, 0.55),
            Offset(0.78, 0.55),
          ],
          defense: const [
            Offset(0.5, 0.10),
            Offset(0.88, 0.28),
            Offset(0.12, 0.28),
            Offset(0.75, 0.38),
            Offset(0.25, 0.38),
          ],
        );
      case FormationPreset.press:
        return FullCourtLayout(
          offense: const [
            Offset(0.5, 0.86),
            Offset(0.18, 0.70),
            Offset(0.82, 0.70),
            Offset(0.30, 0.62),
            Offset(0.70, 0.62),
          ],
          defense: const [
            Offset(0.5, 0.08),
            Offset(0.15, 0.18),
            Offset(0.85, 0.18),
            Offset(0.28, 0.30),
            Offset(0.72, 0.30),
          ],
        );
      case FormationPreset.zone23:
        return FullCourtLayout(
          offense: const [
            Offset(0.5, 0.88),
            Offset(0.14, 0.68),
            Offset(0.86, 0.68),
            Offset(0.26, 0.58),
            Offset(0.74, 0.58),
          ],
          defense: const [
            Offset(0.5, 0.12),
            Offset(0.18, 0.22),
            Offset(0.82, 0.22),
            Offset(0.12, 0.36),
            Offset(0.88, 0.36),
          ],
        );
      case FormationPreset.zone32:
        return FullCourtLayout(
          offense: const [
            Offset(0.5, 0.87),
            Offset(0.20, 0.66),
            Offset(0.80, 0.66),
            Offset(0.38, 0.58),
            Offset(0.62, 0.58),
          ],
          defense: const [
            Offset(0.5, 0.14),
            Offset(0.30, 0.26),
            Offset(0.70, 0.26),
            Offset(0.18, 0.38),
            Offset(0.82, 0.38),
          ],
        );
      case FormationPreset.man23:
      case FormationPreset.man32:
        return FullCourtLayout(
          offense: const [
            Offset(0.5, 0.88),
            Offset(0.16, 0.70),
            Offset(0.84, 0.70),
            Offset(0.24, 0.60),
            Offset(0.76, 0.60),
          ],
          defense: const [
            Offset(0.5, 0.12),
            Offset(0.84, 0.30),
            Offset(0.16, 0.30),
            Offset(0.72, 0.42),
            Offset(0.28, 0.42),
          ],
        );
    }
  }

  /// Legacy half-court only (5 spots) — used for backward-compatible step validation if needed.
  static List<Offset> formationOffsets(FormationPreset f) {
    switch (f) {
      case FormationPreset.fastBreak:
        return [
          const Offset(0.5, 0.92),
          const Offset(0.15, 0.55),
          const Offset(0.85, 0.55),
          const Offset(0.2, 0.25),
          const Offset(0.8, 0.25),
        ];
      case FormationPreset.press:
        return [
          const Offset(0.5, 0.85),
          const Offset(0.12, 0.7),
          const Offset(0.88, 0.7),
          const Offset(0.3, 0.45),
          const Offset(0.7, 0.45),
        ];
      case FormationPreset.zone23:
      case FormationPreset.zone32:
      case FormationPreset.man23:
      case FormationPreset.man32:
        return [
          const Offset(0.5, 0.88),
          const Offset(0.18, 0.62),
          const Offset(0.82, 0.62),
          const Offset(0.28, 0.32),
          const Offset(0.72, 0.32),
        ];
    }
  }

  /// 1-based slot → list index.
  static int slotToIndex(int slot) => (slot.clamp(1, 5)) - 1;

  static Offset positionForSlot(FormationPreset f, int slot) {
    final o = formationOffsets(f);
    return o[slotToIndex(slot).clamp(0, o.length - 1)];
  }

  /// Map normalized court coords (x = sideline, y = north→south) to canvas pixels.
  static Offset normToPixel(Offset norm, Size size) =>
      Offset(norm.dx * size.width, norm.dy * size.height);

  static Offset pixelToNorm(Offset pixel, Size size) => Offset(
        (pixel.dx / size.width).clamp(0.0, 1.0),
        (pixel.dy / size.height).clamp(0.0, 1.0),
      );
}

/// Ball state: which 1-based slot possesses the rock.
@immutable
class BallState {
  final int ownerSlot;

  const BallState({required this.ownerSlot});

  BallState passTo(int slot) => BallState(ownerSlot: slot);
}
