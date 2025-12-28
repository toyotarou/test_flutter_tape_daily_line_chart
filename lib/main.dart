import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/controllers_mixin.dart';
import 'model/money_sum_model.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  Key _appKey = UniqueKey();

  ///
  void restartApp() => setState(() => _appKey = UniqueKey());

  ///
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MyApp(key: _appKey, onRestart: restartApp),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key, required this.onRestart});

  // ignore: unreachable_from_main
  final VoidCallback onRestart;

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with ControllersMixin<MyApp> {
  ///
  @override
  void initState() {
    super.initState();

    moneySumNotifier.getAllMoneySumData();
  }

  DateTime? _tryParseDate(String s) {
    try {
      final DateTime dt = DateTime.parse(s);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  DateTime _resolveStartDateFromMoneySumList() {
    final List<MoneySumModel> list = moneySumState.moneySumList;

    if (list.isEmpty) {
      // データ未取得時の仮（ここは好みで）
      return DateTime(2023);
    }

    // 先頭が必ず最古とは限らないので、最小日付を取る（安全）
    DateTime? minDt;
    for (final MoneySumModel m in list) {
      final DateTime? dt = _tryParseDate(m.date);
      if (dt == null) {
        continue;
      }

      if (minDt == null || dt.isBefore(minDt)) {
        minDt = dt;
      }
    }

    // 全部パース失敗した場合の保険
    return minDt ?? DateTime(2023);
  }

  ///
  @override
  Widget build(BuildContext context) {
    final DateTime startDate = _resolveStartDateFromMoneySumList();

    return MaterialApp(
      // ignore: always_specify_types
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const <Locale>[Locale('en'), Locale('ja')],

      theme: ThemeData(
        scrollbarTheme: const ScrollbarThemeData().copyWith(
          thumbColor: MaterialStateProperty.all(Colors.greenAccent.withOpacity(0.4)),
        ),
        useMaterial3: false,
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark),
        highlightColor: Colors.grey,
      ),

      themeMode: ThemeMode.dark,
      title: 'LIFETIME LOG',
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        onTap: () => primaryFocus?.unfocus(),
        child: TapeDailyLineChartDemoPage(
          startDate: startDate,
          // ✅ ここが 2014-06-01 起点になる
          windowDays: 30,
          pixelsPerDay: 16.0,
          fixedMinY: 0,
          fixedMaxY: 10000000,
          fixedIntervalY: 1000000,
          seed: 2023,
          labelShowScaleThreshold: 3.0,
          moneySumList: moneySumState.moneySumList,
        ),
      ),
    );
  }
}
