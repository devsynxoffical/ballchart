import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ballchart/core/widgets/custom_button.dart';

void main() {
  testWidgets('CustomButton renders text and triggers onPressed', (WidgetTester tester) async {
    bool pressed = false;

    // Build the CustomButton in a testable environment.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'CLICK ME',
            onPressed: () {
              pressed = true;
            },
          ),
        ),
      ),
    );

    // Verify button text is displayed.
    expect(find.text('CLICK ME'), findsOneWidget);

    // Tap the button and verify callback.
    await tester.tap(find.text('CLICK ME'));
    await tester.pump();

    expect(pressed, isTrue);
  });
}
