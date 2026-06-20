import 'package:flutter/foundation.dart';

/// An editable, **controller-free** rubric criterion.
///
/// Unlike the original app's model (which embedded `TextEditingController`s and
/// leaked them), this is a plain immutable value object: easy to serialize,
/// store, diff, and feed to a grader. The [RubricBuilder] widget owns the
/// controllers internally and emits these.
@immutable
class RubricDraft {
  const RubricDraft({
    this.id,
    this.description = '',
    this.requirement = '',
    this.points = 0,
    this.autoGraded = true,
  });

  final String? id;

  /// Short label, e.g. "Correct final answer".
  final String description;

  /// What the answer must satisfy to earn the points.
  final String requirement;

  /// Points this criterion is worth.
  final num points;

  /// Whether this criterion is intended for automatic grading.
  final bool autoGraded;

  RubricDraft copyWith({
    String? id,
    String? description,
    String? requirement,
    num? points,
    bool? autoGraded,
  }) =>
      RubricDraft(
        id: id ?? this.id,
        description: description ?? this.description,
        requirement: requirement ?? this.requirement,
        points: points ?? this.points,
        autoGraded: autoGraded ?? this.autoGraded,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'description': description,
        'requirement': requirement,
        'points': points,
        'autoGraded': autoGraded,
      };

  factory RubricDraft.fromJson(Map<String, dynamic> json) => RubricDraft(
        id: json['id'] as String?,
        description: json['description'] as String? ?? '',
        requirement: json['requirement'] as String? ?? '',
        points: json['points'] as num? ?? 0,
        autoGraded: json['autoGraded'] as bool? ?? true,
      );

  /// Total points across a list of rubrics.
  static num total(Iterable<RubricDraft> rubrics) =>
      rubrics.fold<num>(0, (sum, r) => sum + r.points);

  @override
  bool operator ==(Object other) =>
      other is RubricDraft &&
      other.id == id &&
      other.description == description &&
      other.requirement == requirement &&
      other.points == points &&
      other.autoGraded == autoGraded;

  @override
  int get hashCode =>
      Object.hash(id, description, requirement, points, autoGraded);
}
