import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TapeDailyLineChartDemoPage(
        startDate: DateTime(2023),
        windowDays: 30,
        pixelsPerDay: 16.0,
        fixedMinY: 0,
        fixedMaxY: 30000000,
        fixedIntervalY: 1000000,
        seed: 2023,
        labelShowScaleThreshold: 3.0,
      ),
    ),
  );
}

/////////////////////////////////////////////////////////////////

class TapeDailyLineChartDemoPage extends StatefulWidget {
  const TapeDailyLineChartDemoPage({
    super.key,
    required this.startDate,
    required this.windowDays,
    required this.pixelsPerDay,
    required this.fixedMinY,
    required this.fixedMaxY,
    required this.fixedIntervalY,
    required this.seed,
    required this.labelShowScaleThreshold,
    this.dataSpots,
  });

  final DateTime startDate;
  final int windowDays;
  final double pixelsPerDay;

  final double fixedMinY;
  final double fixedMaxY;
  final double fixedIntervalY;

  final int seed;

  final double labelShowScaleThreshold;

  final List<FlSpot>? dataSpots;

  @override
  State<TapeDailyLineChartDemoPage> createState() => _TapeDailyLineChartDemoPageState();
}

class _TapeDailyLineChartDemoPageState extends State<TapeDailyLineChartDemoPage> {
  late final TapeDailyChartController tapeDailyChartController;

  final TransformationController _transformationController = TransformationController();

  bool _showPointLabels = false;

  ///
  @override
  void initState() {
    super.initState();

    tapeDailyChartController = TapeDailyChartController(
      startDate: widget.startDate,
      windowDays: widget.windowDays,
      pixelsPerDay: widget.pixelsPerDay,
      fixedMinY: widget.fixedMinY,
      fixedMaxY: widget.fixedMaxY,
      fixedIntervalY: widget.fixedIntervalY,
      seed: widget.seed,
      dataSpots: widget.dataSpots,
    )..init();

    tapeDailyChartController.addListener(_onControllerChanged);

    _transformationController.addListener(_onTransformChanged);
  }

  ///
  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  ///
  void _onTransformChanged() {
    if (!tapeDailyChartController.zoomMode) {
      return;
    }

    final double scale = _transformationController.value.getMaxScaleOnAxis();

    final bool shouldShow = scale >= widget.labelShowScaleThreshold;

    if (shouldShow != _showPointLabels) {
      setState(() {
        _showPointLabels = shouldShow;
      });
    }
  }

  ///
  @override
  void dispose() {
    tapeDailyChartController.removeListener(_onControllerChanged);
    tapeDailyChartController.dispose();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  ///
  @override
  Widget build(BuildContext context) {
    final double minX = tapeDailyChartController.minX;
    final double maxX = tapeDailyChartController.maxX;

    final DateTime startDt = tapeDailyChartController.dateFromIndex(minX.round());
    final DateTime endDt = tapeDailyChartController.dateFromIndex(maxX.round());

    final bool dragEnabled = !tapeDailyChartController.zoomMode && !tapeDailyChartController.tooltipEnabled;

    final LineChartData backData = tapeDailyChartController.buildBackData();
    final LineChartData frontData = tapeDailyChartController.buildFrontData(context, showPointLabels: _showPointLabels);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _HeaderDaily(
                start: startDt,
                end: endDt,
                today: tapeDailyChartController.todayJst,
                windowDays: tapeDailyChartController.windowDays,
                minY: tapeDailyChartController.fixedMinY,
                maxY: tapeDailyChartController.fixedMaxY,
                tooltipEnabled: tapeDailyChartController.tooltipEnabled,
                tooltipSwitchEnabled: !tapeDailyChartController.zoomMode,
                onToggleTooltip: (bool v) => tapeDailyChartController.setTooltipEnabled(v),
              ),
              const SizedBox(height: 12),
              _FooterDaily(
                onReset: () {
                  _transformationController.value = Matrix4.identity();
                  _showPointLabels = false;
                  tapeDailyChartController.resetToStart();
                },
                onToToday: () {
                  _transformationController.value = Matrix4.identity();
                  _showPointLabels = false;
                  tapeDailyChartController.jumpToTodayWindow();
                },
              ),
              const SizedBox(height: 10),
              _ZoomBar(
                zoomMode: tapeDailyChartController.zoomMode,
                onToggleZoom: () {
                  final bool next = !tapeDailyChartController.zoomMode;

                  if (!next) {
                    _transformationController.value = Matrix4.identity();
                    _showPointLabels = false;
                  }

                  tapeDailyChartController.setZoomMode(next);
                },
                onResetTransform: tapeDailyChartController.zoomMode
                    ? () {
                        _transformationController.value = Matrix4.identity();
                        setState(() {
                          _showPointLabels = false;
                        });
                      }
                    : null,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TapeChartFrame(
                  dragEnabled: dragEnabled,
                  onDragUpdate: tapeDailyChartController.onDragUpdate,
                  onDragEnd: tapeDailyChartController.onDragEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _buildChartStack(
                      backData: backData,
                      frontData: frontData,
                      zoomMode: tapeDailyChartController.zoomMode,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _MonthJumpBar(
                monthStarts: tapeDailyChartController.monthStarts,
                currentWindowStart: startDt,
                onTapMonth: (DateTime monthStart) {
                  _transformationController.value = Matrix4.identity();
                  _showPointLabels = false;
                  tapeDailyChartController.jumpToMonth(monthStart);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///
  Widget _buildChartStack({required LineChartData backData, required LineChartData frontData, required bool zoomMode}) {
    final Widget charts = Stack(
      children: <Widget>[
        Positioned.fill(
          child: LineChart(backData, duration: const Duration(milliseconds: 120), curve: Curves.easeOut),
        ),
        Positioned.fill(
          child: LineChart(frontData, duration: const Duration(milliseconds: 120), curve: Curves.easeOut),
        ),
      ],
    );

    if (!zoomMode) {
      return charts;
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 10.0,
      child: AbsorbPointer(child: charts),
    );
  }
}

/////////////////////////////////////////////////////////////////

class TapeDailyChartController extends ChangeNotifier {
  TapeDailyChartController({
    required this.startDate,
    required this.windowDays,
    required this.pixelsPerDay,
    required this.fixedMinY,
    required this.fixedMaxY,
    required this.fixedIntervalY,
    required this.seed,
    this.dataSpots,
  });

  final DateTime startDate;
  final int windowDays;
  final double pixelsPerDay;

  final double fixedMinY;
  final double fixedMaxY;
  final double fixedIntervalY;

  final int seed;

  final List<FlSpot>? dataSpots;

  late final DateTime todayJst;
  late final List<FlSpot> allSpots;
  late final int maxIndex;

  late final List<DateTime> monthStarts;

  double startIndex = 0;
  double dragAccumDx = 0;

  bool tooltipEnabled = false;

  bool zoomMode = false;

  ///
  void init() {
    final DateTime now = DateTime.now();
    todayJst = DateTime(now.year, now.month, now.day);

    allSpots = _prepareSpots();

    maxIndex = allSpots.isEmpty ? 0 : allSpots.last.x.floor();
    startIndex = 0;

    monthStarts = _buildMonthStarts(start: startDate, endInclusive: todayJst);
  }

  ///
  List<FlSpot> _prepareSpots() {
    if (dataSpots != null && dataSpots!.isNotEmpty) {
      final List<FlSpot> sorted = List<FlSpot>.from(dataSpots!)..sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
      return sorted;
    }

    return _makeDailyDemoSpotsFixedRangeWavy(
      start: startDate,
      endInclusive: todayJst,
      seed: seed,
      minY: fixedMinY,
      maxY: fixedMaxY,
    );
  }

  ///
  double get minX => _clampStartIndex(startIndex);

  ///
  double get maxX => minX + (windowDays - 1).toDouble();

  ///
  DateTime dateFromIndex(int dayIndex) => startDate.add(Duration(days: dayIndex));

  ///
  void setTooltipEnabled(bool v) {
    tooltipEnabled = v;
    dragAccumDx = 0;
    notifyListeners();
  }

  ///
  void setZoomMode(bool v) {
    zoomMode = v;

    dragAccumDx = 0;
    notifyListeners();
  }

  ///
  void resetToStart() {
    startIndex = 0;
    dragAccumDx = 0;
    notifyListeners();
  }

  ///
  void jumpToTodayWindow() {
    startIndex = _clampStartIndex((maxIndex - (windowDays - 1)).toDouble());
    dragAccumDx = 0;
    notifyListeners();
  }

  ///
  void jumpToMonth(DateTime monthStart) {
    final int dayIndex = monthStart.difference(startDate).inDays;
    startIndex = _clampStartIndex(dayIndex.toDouble());
    dragAccumDx = 0;
    notifyListeners();
  }

  ///
  void onDragUpdate(DragUpdateDetails d) {
    if (zoomMode) {
      return;
    }

    if (tooltipEnabled) {
      return;
    }

    dragAccumDx += d.delta.dx;

    while (dragAccumDx <= -pixelsPerDay) {
      dragAccumDx += pixelsPerDay;
      _jumpDays(1);
    }
    while (dragAccumDx >= pixelsPerDay) {
      dragAccumDx -= pixelsPerDay;
      _jumpDays(-1);
    }
  }

  ///
  void onDragEnd(DragEndDetails d) => dragAccumDx = 0;

  ///
  void _jumpDays(int deltaDays) {
    startIndex = _clampStartIndex(startIndex + deltaDays);
    notifyListeners();
  }

  ///
  double _clampStartIndex(double start) {
    final int maxStart = math.max(0, maxIndex - (windowDays - 1));
    if (start < 0) {
      return 0;
    }
    if (start > maxStart) {
      return maxStart.toDouble();
    }
    return start;
  }

  ///
  LineChartData buildFrontData(BuildContext context, {required bool showPointLabels}) {
    final double minX0 = minX;
    final double maxX0 = maxX;

    final List<FlSpot> visibleSpots = _extractVisibleSpots(
      all: allSpots,
      minX: minX0,
      maxX: maxX0,
      extendLastValue: true,
    );

    final Color lineColor = Theme.of(context).colorScheme.primary;

    final bool effectiveTooltip = tooltipEnabled && !zoomMode;

    return LineChartData(
      minX: minX0,
      maxX: maxX0,
      minY: fixedMinY,
      maxY: fixedMaxY,
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 1,
            getTitlesWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: fixedIntervalY,
            getTitlesWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: fixedIntervalY,
            getTitlesWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: <LineChartBarData>[
        LineChartBarData(
          color: lineColor,
          spots: visibleSpots,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: zoomMode
              ? FlDotData(
                  show: showPointLabels,
                  getDotPainter: (FlSpot spot, double percent, LineChartBarData bar, int index) {
                    return ValueLabelDotPainter(
                      color: lineColor,
                      radius: 0.8,
                      backgroundColor: Colors.black.withOpacity(0.55),
                      textStyle: const TextStyle(fontSize: 6, color: Colors.white, fontWeight: FontWeight.w600),
                      labelBuilder: _buildSpotLabel,
                    );
                  },
                )
              : const FlDotData(show: false),
        ),
      ],
      lineTouchData: effectiveTooltip
          ? LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot s) {
                    final DateTime dt = dateFromIndex(s.x.round());
                    final String title = '${dt.year}/${dt.month}/${dt.day}';
                    final String val = s.y.toInt().toString();
                    return LineTooltipItem('$title\n$val', const TextStyle(fontSize: 12));
                  }).toList();
                },
              ),
            )
          : const LineTouchData(enabled: false, handleBuiltInTouches: false),
    );
  }

  ///
  String _buildSpotLabel(FlSpot spot) {
    final DateTime dt = dateFromIndex(spot.x.round());

    final String yyyy = dt.year.toString().padLeft(4, '0');
    final String mm = dt.month.toString().padLeft(2, '0');
    final String dd = dt.day.toString().padLeft(2, '0');
    final String date = '$yyyy-$mm-$dd';

    final int price = spot.y.round();
    final String displayPrice = _toCurrency(price);

    return '$date\n$displayPrice';
  }

  ///
  String _toCurrency(int v) {
    final String s = v.toString();
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int fromEnd = s.length - i;
      b.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        b.write(',');
      }
    }
    return b.toString();
  }

  ///
  LineChartData buildBackData() {
    final double minX0 = minX;
    final double maxX0 = maxX;

    final List<VerticalLine> monthLines = _buildMonthBoundaryLines(minX: minX0, maxX: maxX0);

    return LineChartData(
      minX: minX0,
      maxX: maxX0,
      minY: fixedMinY,
      maxY: fixedMaxY,
      lineTouchData: const LineTouchData(enabled: false, handleBuiltInTouches: false),
      gridData: FlGridData(verticalInterval: 1, horizontalInterval: fixedIntervalY),
      extraLinesData: ExtraLinesData(verticalLines: monthLines),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        bottomTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: fixedIntervalY,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value == fixedMinY || value == fixedMaxY) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: fixedIntervalY,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value == fixedMinY || value == fixedMaxY) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right),
              );
            },
          ),
        ),
      ),
    );
  }

  ///
  List<VerticalLine> _buildMonthBoundaryLines({required double minX, required double maxX}) {
    final List<VerticalLine> lines = <VerticalLine>[];

    final DateTime minDt = dateFromIndex(minX.floor());
    final DateTime maxDt = dateFromIndex(maxX.ceil());

    DateTime cursor = DateTime(minDt.year, minDt.month);
    if (cursor.isBefore(minDt)) {
      cursor = DateTime(minDt.year, minDt.month + 1);
    }

    while (!cursor.isAfter(maxDt)) {
      final double x = cursor.difference(startDate).inDays.toDouble();
      lines.add(
        VerticalLine(
          x: x,
          strokeWidth: 1,
          dashArray: const <int>[6, 6],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topLeft,
            style: const TextStyle(fontSize: 10),
            labelResolver: (_) => '${cursor.year}/${cursor.month}',
          ),
        ),
      );
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return lines;
  }

  ///
  static List<DateTime> _buildMonthStarts({required DateTime start, required DateTime endInclusive}) {
    final List<DateTime> list = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month);
    final DateTime endMonth = DateTime(endInclusive.year, endInclusive.month);

    while (!cursor.isAfter(endMonth)) {
      list.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return list;
  }

  ///
  static List<FlSpot> _extractVisibleSpots({
    required List<FlSpot> all,
    required double minX,
    required double maxX,
    required bool extendLastValue,
  }) {
    final int minI = minX.floor();
    final int maxI = maxX.ceil();

    final Map<int, double> byX = <int, double>{};
    for (final FlSpot s in all) {
      byX[s.x.round()] = s.y;
    }

    final List<FlSpot> visible = <FlSpot>[];
    double? lastY;

    for (int x = minI; x <= maxI; x++) {
      final double? y = byX[x];
      if (y != null) {
        lastY = y;
        visible.add(FlSpot(x.toDouble(), y));
      } else if (extendLastValue && lastY != null) {
        visible.add(FlSpot(x.toDouble(), lastY));
      }
    }

    return visible;
  }

  ///
  static List<FlSpot> _makeDailyDemoSpotsFixedRangeWavy({
    required DateTime start,
    required DateTime endInclusive,
    required int seed,
    required double minY,
    required double maxY,
  }) {
    final int days = endInclusive.difference(start).inDays;
    final math.Random rand = math.Random(seed);

    final List<FlSpot> spots = <FlSpot>[];

    final double range = maxY - minY;
    final double mid = (minY + maxY) / 2;

    final double ampYear = range * 0.35;
    final double ampWeek = range * 0.18;
    final double ampShort1 = range * 0.10;
    final double ampShort2 = range * 0.07;

    final double noiseAmp = range * 0.08;

    const double smoothing = 0.55;

    double value = mid;

    for (int i = 0; i <= days; i++) {
      final double yearly = math.sin(2 * math.pi * (i / 365.0));
      final double weekly = math.sin(2 * math.pi * (i / 7.0));
      final double short1 = math.sin(2 * math.pi * (i / 2.6));
      final double short2 = math.sin(2 * math.pi * (i / 4.3));

      final double noise = (rand.nextDouble() - 0.5) * noiseAmp;

      double target = mid + yearly * ampYear + weekly * ampWeek + short1 * ampShort1 + short2 * ampShort2 + noise;

      if (rand.nextDouble() < 0.12) {
        final double jump = (rand.nextDouble() - 0.5) * range * 0.25;
        target += jump;
      }

      final double bias = (rand.nextDouble() - 0.5) * range * 0.03;
      target += bias;

      value = value + (target - value) * smoothing;
      value = value.clamp(minY, maxY);

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }
}

/////////////////////////////////////////////////////////////////

class ValueLabelDotPainter extends FlDotPainter {
  ValueLabelDotPainter({
    required this.color,
    required this.radius,
    required this.textStyle,
    required this.labelBuilder,
    this.backgroundColor,
  });

  final Color color;
  final double radius;
  final TextStyle textStyle;
  final String Function(FlSpot spot) labelBuilder;
  final Color? backgroundColor;

  @override
  Color get mainColor => color;

  ///
  @override
  List<Object?> get props => <Object?>[color, radius, textStyle, backgroundColor];

  ///
  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final Paint dotPaint = Paint()..color = color;
    canvas.drawCircle(offsetInCanvas, radius, dotPaint);

    final String label = labelBuilder(spot);
    if (label.isEmpty) {
      return;
    }

    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 46);

    final Offset textOffset = offsetInCanvas - Offset(textPainter.width, textPainter.height + radius + 2);

    if (backgroundColor != null) {
      const double padX = 2;
      const double padY = 1.5;

      final Rect bgRect = Rect.fromLTWH(
        textOffset.dx - padX,
        textOffset.dy - padY,
        textPainter.width + padX * 2,
        textPainter.height + padY * 2,
      );

      final RRect rRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(2));
      final Paint bgPaint = Paint()..color = backgroundColor!;
      canvas.drawRRect(rRect, bgPaint);
    }

    textPainter.paint(canvas, textOffset);
  }

  ///
  @override
  Size getSize(FlSpot spot) => Size(radius * 2, radius * 2);

  ///
  @override
  bool hitTest(FlSpot spot, Offset touched, Offset center, double extraThreshold) =>
      (touched - center).distance <= radius + extraThreshold;

  ///
  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => this;
}

/////////////////////////////////////////////////////////////////

class TapeChartFrame extends StatelessWidget {
  const TapeChartFrame({
    required this.child,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.dragEnabled,
    super.key,
  });

  final Widget child;
  final void Function(DragUpdateDetails) onDragUpdate;
  final void Function(DragEndDetails) onDragEnd;
  final bool dragEnabled;

  ///
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onHorizontalDragUpdate: dragEnabled ? onDragUpdate : null,
        onHorizontalDragEnd: dragEnabled ? onDragEnd : null,
        child: Stack(children: <Widget>[Positioned.fill(child: child)]),
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////

class _HeaderDaily extends StatelessWidget {
  const _HeaderDaily({
    required this.start,
    required this.end,
    required this.today,
    required this.windowDays,
    required this.minY,
    required this.maxY,
    required this.tooltipEnabled,
    required this.tooltipSwitchEnabled,
    required this.onToggleTooltip,
  });

  final DateTime start;
  final DateTime end;
  final DateTime today;
  final int windowDays;
  final double minY;
  final double maxY;

  final bool tooltipEnabled;
  final bool tooltipSwitchEnabled;
  final ValueChanged<bool> onToggleTooltip;

  ///
  @override
  Widget build(BuildContext context) {
    final String todayStr = '${today.year}/${today.month}/${today.day}';
    final String rangeStr = '${start.year}/${start.month}/${start.day} 〜 ${end.year}/${end.month}/${end.day}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('データ最終日（本日）: $todayStr', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text('表示範囲（$windowDays日）: $rangeStr', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Text('値の箱（ツールチップ）', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Switch(
                // ignore: avoid_bool_literals_in_conditional_expressions
                value: tooltipSwitchEnabled ? tooltipEnabled : false,
                onChanged: tooltipSwitchEnabled ? onToggleTooltip : null,
              ),
              Text(
                tooltipSwitchEnabled ? (tooltipEnabled ? '表示' : '非表示') : '拡大中は無効',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////

class _FooterDaily extends StatelessWidget {
  const _FooterDaily({required this.onReset, required this.onToToday});

  final VoidCallback onReset;
  final VoidCallback onToToday;

  ///
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton(onPressed: onReset, child: const Text('先頭へ')),
        OutlinedButton(onPressed: onToToday, child: const Text('今日付近へ')),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({required this.zoomMode, required this.onToggleZoom, required this.onResetTransform});

  final bool zoomMode;
  final VoidCallback onToggleZoom;
  final VoidCallback? onResetTransform;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (zoomMode) IconButton(onPressed: onResetTransform, icon: const Icon(Icons.lock_reset), tooltip: '拡大リセット'),
        IconButton(
          onPressed: onToggleZoom,
          icon: Icon(Icons.expand, color: zoomMode ? Colors.orange : Colors.black),
          tooltip: zoomMode ? '拡大OFF' : '拡大ON',
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(zoomMode ? 'ピンチ拡大：ON（倍率>=5で点ラベル表示／ツールチップOFF）' : 'ピンチ拡大：OFF（テープドラッグ）')),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////

class _MonthJumpBar extends StatefulWidget {
  const _MonthJumpBar({required this.monthStarts, required this.currentWindowStart, required this.onTapMonth});

  final List<DateTime> monthStarts;
  final DateTime currentWindowStart;
  final ValueChanged<DateTime> onTapMonth;

  @override
  State<_MonthJumpBar> createState() => _MonthJumpBarState();
}

class _MonthJumpBarState extends State<_MonthJumpBar> {
  final ScrollController _sc = ScrollController();

  static const double _estimatedChipWidth = 92.0;
  static const double _estimatedGap = 12.0;

  ///
  @override
  void didUpdateWidget(covariant _MonthJumpBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final DateTime oldMonth = DateTime(oldWidget.currentWindowStart.year, oldWidget.currentWindowStart.month);
    final DateTime newMonth = DateTime(widget.currentWindowStart.year, widget.currentWindowStart.month);

    if (oldMonth.year != newMonth.year || oldMonth.month != newMonth.month) {
      _scrollToSelectedMonth(newMonth, animate: true);
    }
  }

  ///
  @override
  void initState() {
    super.initState();
    final DateTime currentMonth = DateTime(widget.currentWindowStart.year, widget.currentWindowStart.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedMonth(currentMonth, animate: false);
    });
  }

  ///
  void _scrollToSelectedMonth(DateTime selectedMonthStart, {required bool animate}) {
    final int idx = widget.monthStarts.indexWhere(
      (DateTime m) => m.year == selectedMonthStart.year && m.month == selectedMonthStart.month,
    );
    if (idx < 0) {
      return;
    }
    if (!_sc.hasClients) {
      return;
    }

    final double target =
        idx * (_estimatedChipWidth + _estimatedGap) -
        (MediaQuery.of(context).size.width / 2) +
        (_estimatedChipWidth / 2);

    final double clamped = target.clamp(0.0, _sc.position.maxScrollExtent);

    if (animate) {
      _sc.animateTo(clamped, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    } else {
      _sc.jumpTo(clamped);
    }
  }

  ///
  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  ///
  @override
  Widget build(BuildContext context) {
    final DateTime currentMonthStart = DateTime(widget.currentWindowStart.year, widget.currentWindowStart.month);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all()),
      child: SingleChildScrollView(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: widget.monthStarts.map((DateTime m) {
            final bool selected = m.year == currentMonthStart.year && m.month == currentMonthStart.month;
            final String label = '${m.year}/${m.month.toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => widget.onTapMonth(m),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
