import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'state/toe_tap_controller.dart';
import 'ui/screens/toe_tap_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for mobile sports camera tracking
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure high-contrast athletic status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FlickitToeTapApp());
}

/// Root Application Widget.
class FlickitToeTapApp extends StatelessWidget {
  const FlickitToeTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ToeTapController>(
      create: (_) => ToeTapController(),
      child: MaterialApp(
        title: 'Flickit Toe Tap Counter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ToeTapScreen(),
      ),
    );
  }
}
