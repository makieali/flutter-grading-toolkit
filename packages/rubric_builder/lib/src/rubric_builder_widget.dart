import 'package:flutter/material.dart';

import 'rubric_draft.dart';

/// An editable list of rubric criteria with a live points total.
///
/// The widget owns all [TextEditingController]s internally (and disposes them),
/// so callers only ever deal with immutable [RubricDraft] values via
/// [onChanged]. This fixes the controller-leak / model-bound-to-UI pattern
/// common in hand-rolled rubric forms.
class RubricBuilder extends StatefulWidget {
  const RubricBuilder({
    super.key,
    this.initial = const [],
    required this.onChanged,
    this.addButtonLabel = 'Add criterion',
    this.showAutoGraded = true,
    this.showTotal = true,
  });

  /// Rubrics to pre-populate the editor with.
  final List<RubricDraft> initial;

  /// Called whenever the rubric list changes.
  final ValueChanged<List<RubricDraft>> onChanged;

  final String addButtonLabel;

  /// Show the per-row "auto-graded" toggle.
  final bool showAutoGraded;

  /// Show the running total header.
  final bool showTotal;

  @override
  State<RubricBuilder> createState() => _RubricBuilderState();
}

class _Row {
  _Row(RubricDraft d)
      : id = d.id,
        description = TextEditingController(text: d.description),
        requirement = TextEditingController(text: d.requirement),
        points = TextEditingController(
            text: d.points == 0 ? '' : _trim(d.points)),
        autoGraded = d.autoGraded;

  final String? id;
  final TextEditingController description;
  final TextEditingController requirement;
  final TextEditingController points;
  bool autoGraded;

  static String _trim(num n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  RubricDraft toDraft() => RubricDraft(
        id: id,
        description: description.text,
        requirement: requirement.text,
        points: num.tryParse(points.text.trim()) ?? 0,
        autoGraded: autoGraded,
      );

  void dispose() {
    description.dispose();
    requirement.dispose();
    points.dispose();
  }
}

class _RubricBuilderState extends State<RubricBuilder> {
  late final List<_Row> _rows = [
    for (final d in widget.initial) _Row(d),
  ];

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  num get _total =>
      _rows.fold<num>(0, (sum, r) => sum + (num.tryParse(r.points.text.trim()) ?? 0));

  void _emit() {
    widget.onChanged([for (final r in _rows) r.toDraft()]);
    setState(() {}); // refresh the total
  }

  void _add() {
    setState(() => _rows.add(_Row(const RubricDraft())));
    _emit();
  }

  void _removeAt(int index) {
    final removed = _rows.removeAt(index);
    removed.dispose();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showTotal)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rubrics', style: theme.textTheme.titleMedium),
                Text('Total: ${_Row._trim(_total)} pts',
                    key: const Key('rubric_total'),
                    style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        for (var i = 0; i < _rows.length; i++) _buildRow(i),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('add_rubric'),
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: Text(widget.addButtonLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  key: Key('description_$index'),
                  controller: row.description,
                  decoration: const InputDecoration(
                      labelText: 'Description', isDense: true),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: TextField(
                  key: Key('points_$index'),
                  controller: row.points,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Points', isDense: true),
                  onChanged: (_) => _emit(),
                ),
              ),
              IconButton(
                key: Key('remove_$index'),
                tooltip: 'Remove',
                icon: const Icon(Icons.close),
                onPressed: () => _removeAt(index),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('requirement_$index'),
                  controller: row.requirement,
                  decoration: const InputDecoration(
                      labelText: 'Requirement', isDense: true),
                  onChanged: (_) => _emit(),
                ),
              ),
              if (widget.showAutoGraded) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    Checkbox(
                      key: Key('autograded_$index'),
                      value: row.autoGraded,
                      onChanged: (v) {
                        setState(() => row.autoGraded = v ?? true);
                        _emit();
                      },
                    ),
                    const Text('Auto'),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
