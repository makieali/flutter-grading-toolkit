import 'package:flutter/material.dart';
import 'package:rubric_builder/rubric_builder.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});
  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  List<RubricDraft> rubrics = const [
    RubricDraft(description: 'Correct answer', requirement: 'Final value is right', points: 5),
    RubricDraft(description: 'Shows working', requirement: 'Steps are shown', points: 3),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('rubric_builder')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: RubricBuilder(
              initial: rubrics,
              onChanged: (v) => setState(() => rubrics = v),
            ),
          ),
        ),
      ),
    );
  }
}
