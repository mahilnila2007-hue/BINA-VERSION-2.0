import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:triax_app/main.dart';
import 'package:triax_app/core/state/triax_app_state.dart';

void main() {
  testWidgets('TRIAX smoke test: launches splash and navigates', (WidgetTester tester) async {
    final state = TriaxAppState();

    await tester.pumpWidget(
      ChangeNotifierProvider<TriaxAppState>.value(
        value: state,
        child: const TriaxApp(),
      ),
    );

    // Verify Splash Screen Elements
    expect(find.text('TRIAX'), findsOneWidget);
    expect(find.text('MULTI-MODAL\nPHYSIOLOGICAL ANALYSIS'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Dashboard is displayed
    expect(find.text('TRIAX Physiological Monitor'), findsOneWidget);
    expect(find.text('EEG (Electroencephalogram)'), findsOneWidget);
    expect(find.text('EMG (Electromyogram)'), findsOneWidget);
    expect(find.text('GSR (Galvanic Skin Response)'), findsOneWidget);

    // Explicitly dispose state timers for clean test lifecycle
    state.dispose();
  });
}
