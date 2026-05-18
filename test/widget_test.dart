import 'package:flutter_test/flutter_test.dart';
import 'package:trading_simulation/app.dart';
import 'package:trading_simulation/core/di/injection_container.dart';

void main() {
  testWidgets('AppBootstrapper initializes DI and loads TradingApp dashboard', (WidgetTester tester) async {
    // 1. Initialize Dependency Injection container
    await initDI();

    // 2. Pump main application shell
    await tester.pumpWidget(const TradingApp());
    await tester.pumpAndSettle();

    // 3. Verify that the market dashboard header "MarketPulse" renders successfully
    expect(find.text('MarketPulse'), findsOneWidget);
  });
}
