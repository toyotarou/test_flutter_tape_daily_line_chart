import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../model/money_sum_model.dart';

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
    required this.moneySumList,
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

  final List<MoneySumModel> moneySumList;

  @override
  State<TapeDailyLineChartDemoPage> createState() => _TapeDailyLineChartDemoPageState();
}

/////////////////////////////////////////////////////////////////

class _TapeDailyLineChartDemoPageState extends State<TapeDailyLineChartDemoPage> {
  late TapeDailyChartController tapeDailyChartController;

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
      moneySumList: widget.moneySumList,
    )..init();

    tapeDailyChartController.addListener(_onControllerChanged);

    _transformationController.addListener(_onTransformChanged);
  }

  ///
  @override
  void didUpdateWidget(covariant TapeDailyLineChartDemoPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool startDateChanged =
        oldWidget.startDate.year != widget.startDate.year ||
        oldWidget.startDate.month != widget.startDate.month ||
        oldWidget.startDate.day != widget.startDate.day;

    final bool moneyListChanged = oldWidget.moneySumList != widget.moneySumList;
    final bool spotsChanged = oldWidget.dataSpots != widget.dataSpots;

    if (!startDateChanged && !moneyListChanged && !spotsChanged) {
      return;
    }

    tapeDailyChartController.removeListener(_onControllerChanged);
    tapeDailyChartController.dispose();

    tapeDailyChartController = TapeDailyChartController(
      startDate: widget.startDate,
      windowDays: widget.windowDays,
      pixelsPerDay: widget.pixelsPerDay,
      fixedMinY: widget.fixedMinY,
      fixedMaxY: widget.fixedMaxY,
      fixedIntervalY: widget.fixedIntervalY,
      seed: widget.seed,
      dataSpots: widget.dataSpots,
      moneySumList: widget.moneySumList,
    )..init();

    tapeDailyChartController.addListener(_onControllerChanged);

    _transformationController.value = Matrix4.identity();
    _showPointLabels = false;

    setState(() {});
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

    final LineChartData backgroundData = tapeDailyChartController.buildBackgroundData();
    final LineChartData axisData = tapeDailyChartController.buildAxisData();
    final LineChartData monthlyPowerData = tapeDailyChartController.buildMonthlyPowerData(context);
    final LineChartData mainData = tapeDailyChartController.buildMainData(context, showPointLabels: _showPointLabels);

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
                      backgroundData: backgroundData,
                      axisData: axisData,
                      monthlyPowerData: monthlyPowerData,
                      mainData: mainData,
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
  Widget _buildChartStack({
    required LineChartData backgroundData,
    required LineChartData axisData,
    required LineChartData monthlyPowerData,
    required LineChartData mainData,
    required bool zoomMode,
  }) {
    final List<MonthBandLabel> monthLabels = tapeDailyChartController.buildMonthBandLabels();

    final Widget charts = Stack(
      children: <Widget>[
        Positioned.fill(
          child: LineChart(backgroundData, duration: const Duration(milliseconds: 120), curve: Curves.easeOut),
        ),

        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: MonthBandLabelPainter(
                labels: monthLabels,
                minX: tapeDailyChartController.minX,
                maxX: tapeDailyChartController.maxX,
                minY: tapeDailyChartController.fixedMinY,
                maxY: tapeDailyChartController.fixedMaxY,
              ),
            ),
          ),
        ),

        Positioned.fill(
          child: LineChart(axisData, duration: const Duration(milliseconds: 120), curve: Curves.easeOut),
        ),

        Positioned.fill(
          child: LineChart(monthlyPowerData, duration: const Duration(milliseconds: 120), curve: Curves.easeOut),
        ),

        Positioned.fill(
          child: LineChart(mainData, duration: const Duration(milliseconds: 120), curve: Curves.easeOut),
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
    required this.moneySumList,
  });

  final DateTime startDate;
  final int windowDays;
  final double pixelsPerDay;

  final double fixedMinY;
  final double fixedMaxY;
  final double fixedIntervalY;

  final int seed;

  final List<FlSpot>? dataSpots;

  final List<MoneySumModel> moneySumList;

  late final DateTime todayJst;

  late final List<FlSpot> allSpots;
  late final int maxIndex;

  late final List<DateTime> monthStarts;

  double startIndex = 0;
  double dragAccumDx = 0;

  bool tooltipEnabled = false;

  bool zoomMode = false;

  static const double _monthBoundaryBandWidthX = 1.0;

  static const double _dayHalf = 0.5;

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
  DateTime? _tryParseDate(String s) {
    try {
      final DateTime dt = DateTime.parse(s);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  ///
  List<FlSpot> _prepareSpots() {
    if (dataSpots != null && dataSpots!.isNotEmpty) {
      final List<FlSpot> sorted = List<FlSpot>.from(dataSpots!)..sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
      return sorted;
    }

    final List<FlSpot> moneySpots = _makeSpotsFromMoneySumList();
    if (moneySpots.isNotEmpty) {
      return moneySpots;
    }

    return <FlSpot>[];
  }

  ///
  List<FlSpot> _makeSpotsFromMoneySumList() {
    if (moneySumList.isEmpty) {
      return <FlSpot>[];
    }

    final List<MoneySumModel> sorted = List<MoneySumModel>.from(moneySumList)
      ..sort((MoneySumModel a, MoneySumModel b) {
        final DateTime? da = _tryParseDate(a.date);
        final DateTime? db = _tryParseDate(b.date);
        if (da == null && db == null) {
          return 0;
        }
        if (da == null) {
          return 1;
        }
        if (db == null) {
          return -1;
        }
        return da.compareTo(db);
      });

    final List<FlSpot> spots = <FlSpot>[];

    for (final MoneySumModel m in sorted) {
      final DateTime? dt = _tryParseDate(m.date);
      if (dt == null) {
        continue;
      }

      final int x = dt.difference(startDate).inDays;
      if (x < 0) {
        continue;
      }

      spots.add(FlSpot(x.toDouble(), m.sum.toDouble()));
    }

    spots.sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
    return spots;
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
  LineChartData buildBackgroundData() {
    final double minX0 = minX;
    final double maxX0 = maxX;

    final List<VerticalRangeAnnotation> ranges = <VerticalRangeAnnotation>[
      ..._buildOddMonthBands(minX: minX0, maxX: maxX0),
      ..._buildMonthBoundaryBands(minX: minX0, maxX: maxX0),
    ];

    return LineChartData(
      minX: minX0,
      maxX: maxX0,
      minY: fixedMinY,
      maxY: fixedMaxY,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false, handleBuiltInTouches: false),
      rangeAnnotations: RangeAnnotations(verticalRangeAnnotations: ranges),
    );
  }

  ///
  LineChartData buildAxisData() {
    final double minX0 = minX;
    final double maxX0 = maxX;

    return LineChartData(
      minX: minX0,
      maxX: maxX0,
      minY: fixedMinY,
      maxY: fixedMaxY,
      lineTouchData: const LineTouchData(enabled: false, handleBuiltInTouches: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(drawVerticalLine: false, horizontalInterval: fixedIntervalY),
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
  LineChartData buildMainData(BuildContext context, {required bool showPointLabels}) {
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
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
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
              touchSpotThreshold: 40,
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot s) {
                    final DateTime dt = dateFromIndex(s.x.round());
                    final String title =
                        '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
                    final String val = _toCurrency(s.y.round());
                    return LineTooltipItem('$title\n$val', const TextStyle(fontSize: 12, color: Colors.white));
                  }).toList();
                },
              ),
            )
          : const LineTouchData(enabled: false, handleBuiltInTouches: false),
    );
  }

  ///
  LineChartData buildMonthlyPowerData(BuildContext context) {
    final double minX0 = minX;
    final double maxX0 = maxX;

    final DateTime minDt = dateFromIndex(minX0.floor());
    final DateTime maxDt = dateFromIndex(maxX0.ceil());

    DateTime cursor = DateTime(minDt.year, minDt.month);
    final DateTime endMonth = DateTime(maxDt.year, maxDt.month);

    final List<List<FlSpot>> monthSegments = <List<FlSpot>>[];

    while (!cursor.isAfter(endMonth)) {
      final DateTime monthStartDt = DateTime(cursor.year, cursor.month);
      final DateTime monthEndDt = DateTime(cursor.year, cursor.month + 1, 0);

      final int monthStartIdx = monthStartDt.difference(startDate).inDays;
      final int monthEndIdx = monthEndDt.difference(startDate).inDays;

      final int s = math.max(minX0.floor(), monthStartIdx);
      final int e = math.min(maxX0.ceil(), monthEndIdx);

      if (e <= s) {
        cursor = DateTime(cursor.year, cursor.month + 1);
        continue;
      }

      final double? yStart = _valueAtIndexWithFallback(s);
      final double? yEnd = _valueAtIndexWithFallback(e);

      if (yStart != null && yEnd != null) {
        monthSegments.add(<FlSpot>[FlSpot(s.toDouble(), yStart), FlSpot(e.toDouble(), yEnd)]);
      }

      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    final Color base = Theme.of(context).colorScheme.primary;
    final Color thickColor = base.withOpacity(0.28);

    final List<LineChartBarData> bars = monthSegments.map((List<FlSpot> seg) {
      return LineChartBarData(
        spots: seg,
        color: thickColor,
        barWidth: 10,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
      );
    }).toList();

    return LineChartData(
      minX: minX0,
      maxX: maxX0,
      minY: fixedMinY,
      maxY: fixedMaxY,
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: bars,
      lineTouchData: const LineTouchData(enabled: false, handleBuiltInTouches: false),
    );
  }

  ///
  double? _valueAtIndexWithFallback(int dayIndex) {
    if (allSpots.isEmpty) {
      return null;
    }

    final int x = dayIndex;

    final int exact = allSpots.indexWhere((FlSpot s) => s.x.round() == x);
    if (exact >= 0) {
      return allSpots[exact].y;
    }

    for (int i = allSpots.length - 1; i >= 0; i--) {
      final int sx = allSpots[i].x.round();
      if (sx <= x) {
        return allSpots[i].y;
      }
    }

    for (int i = 0; i < allSpots.length; i++) {
      final int sx = allSpots[i].x.round();
      if (sx >= x) {
        return allSpots[i].y;
      }
    }

    return null;
  }

  ///
  double _clampAnnotX(double x, {required double minX, required double maxX}) {
    final double minA = minX - _dayHalf;
    final double maxA = maxX + _dayHalf;
    if (x < minA) {
      return minA;
    }
    if (x > maxA) {
      return maxA;
    }
    return x;
  }

  ///
  List<VerticalRangeAnnotation> _buildOddMonthBands({required double minX, required double maxX}) {
    final List<VerticalRangeAnnotation> ranges = <VerticalRangeAnnotation>[];

    final DateTime minDt = dateFromIndex(minX.floor());
    final DateTime maxDt = dateFromIndex(maxX.ceil());

    DateTime cursor = DateTime(minDt.year, minDt.month);
    final DateTime endMonth = DateTime(maxDt.year, maxDt.month);

    while (!cursor.isAfter(endMonth)) {
      if (cursor.month.isOdd) {
        final DateTime monthStart = DateTime(cursor.year, cursor.month);
        final DateTime monthEnd = DateTime(cursor.year, cursor.month + 1, 0);

        final int sIdx = monthStart.difference(startDate).inDays;
        final int eIdx = monthEnd.difference(startDate).inDays;

        final double x1 = _clampAnnotX(sIdx.toDouble() - _dayHalf, minX: minX, maxX: maxX);
        final double x2 = _clampAnnotX(eIdx.toDouble() + _dayHalf, minX: minX, maxX: maxX);

        if (x2 > x1) {
          ranges.add(VerticalRangeAnnotation(x1: x1, x2: x2, color: Colors.yellowAccent.withOpacity(0.10)));
        }
      }

      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return ranges;
  }

  ///
  List<VerticalRangeAnnotation> _buildMonthBoundaryBands({required double minX, required double maxX}) {
    final List<VerticalRangeAnnotation> ranges = <VerticalRangeAnnotation>[];

    final DateTime minDt = dateFromIndex(minX.floor());
    final DateTime maxDt = dateFromIndex(maxX.ceil());

    DateTime cursor = DateTime(minDt.year, minDt.month);
    if (cursor.isBefore(minDt)) {
      cursor = DateTime(minDt.year, minDt.month + 1);
    }

    while (!cursor.isAfter(maxDt)) {
      final int idx = cursor.difference(startDate).inDays;

      final double boundaryX = idx.toDouble() - _dayHalf;

      final double x1 = _clampAnnotX(boundaryX - (_monthBoundaryBandWidthX / 2), minX: minX, maxX: maxX);
      final double x2 = _clampAnnotX(boundaryX + (_monthBoundaryBandWidthX / 2), minX: minX, maxX: maxX);

      if (x2 > x1) {
        ranges.add(VerticalRangeAnnotation(x1: x1, x2: x2, color: Colors.white.withOpacity(0.35)));
      }

      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return ranges;
  }

  ///
  List<MonthBandLabel> buildMonthBandLabels() {
    final double minX0 = minX;
    final double maxX0 = maxX;

    final DateTime minDt = dateFromIndex(minX0.floor());
    final DateTime maxDt = dateFromIndex(maxX0.ceil());

    DateTime cursor = DateTime(minDt.year, minDt.month);
    final DateTime endMonth = DateTime(maxDt.year, maxDt.month);

    final List<MonthBandLabel> labels = <MonthBandLabel>[];

    while (!cursor.isAfter(endMonth)) {
      final DateTime monthStart = DateTime(cursor.year, cursor.month);
      final DateTime monthEnd = DateTime(cursor.year, cursor.month + 1, 0);

      final int sIdx = monthStart.difference(startDate).inDays;
      final int eIdx = monthEnd.difference(startDate).inDays;

      final double x1 = _clampAnnotX(sIdx.toDouble() - _dayHalf, minX: minX0, maxX: maxX0);
      final double x2 = _clampAnnotX(eIdx.toDouble() + _dayHalf, minX: minX0, maxX: maxX0);

      if (x2 > x1) {
        final double centerX = (x1 + x2) / 2;

        labels.add(MonthBandLabel(year: cursor.year, month: cursor.month, centerX: centerX));
      }

      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    return labels;
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
}

/////////////////////////////////////////////////////////////////

class MonthBandLabel {
  MonthBandLabel({required this.year, required this.month, required this.centerX});

  final int year;
  final int month;

  final double centerX;

  String get text => '$year/${month.toString().padLeft(2, '0')}';
}

/////////////////////////////////////////////////////////////////

class MonthBandLabelPainter extends CustomPainter {
  MonthBandLabelPainter({
    required this.labels,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final List<MonthBandLabel> labels;

  final double minX;
  final double maxX;

  final double minY;
  final double maxY;

  ///
  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) {
      return;
    }
    if (maxX == minX) {
      return;
    }

    final double y = size.height * 0.18;

    for (final MonthBandLabel label in labels) {
      final double px = _xToPx(label.centerX, size.width);

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: label.text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.55)),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final Offset pos = Offset(px - tp.width / 2, y - tp.height / 2);

      tp.paint(canvas, pos);
    }
  }

  ///
  double _xToPx(double x, double width) {
    final double t = (x - minX) / (maxX - minX);
    return t * width;
  }

  ///
  @override
  bool shouldRepaint(covariant MonthBandLabelPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.minX != minX ||
        oldDelegate.maxX != maxX ||
        oldDelegate.minY != minY ||
        oldDelegate.maxY != maxY;
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

  ///
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

  ///
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

//=====

class _MonthJumpBarState extends State<_MonthJumpBar> {
  final ScrollController _sc = ScrollController();

  late List<GlobalKey> _chipKeys;

  ///
  @override
  void initState() {
    super.initState();
    _rebuildKeys();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSelectedMonthVisible(animate: false);
    });
  }

  ///
  @override
  void didUpdateWidget(covariant _MonthJumpBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.monthStarts.length != widget.monthStarts.length) {
      _rebuildKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureSelectedMonthVisible(animate: false);
      });
      return;
    }

    final DateTime oldMonth = DateTime(oldWidget.currentWindowStart.year, oldWidget.currentWindowStart.month);
    final DateTime newMonth = DateTime(widget.currentWindowStart.year, widget.currentWindowStart.month);

    if (oldMonth.year != newMonth.year || oldMonth.month != newMonth.month) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureSelectedMonthVisible(animate: true);
      });
    }
  }

  ///
  void _rebuildKeys() {
    _chipKeys = List<GlobalKey>.generate(widget.monthStarts.length, (_) => GlobalKey());
  }

  ///
  int _selectedIndex() {
    final DateTime currentMonthStart = DateTime(widget.currentWindowStart.year, widget.currentWindowStart.month);
    return widget.monthStarts.indexWhere(
      (DateTime m) => m.year == currentMonthStart.year && m.month == currentMonthStart.month,
    );
  }

  ///
  Future<void> _ensureSelectedMonthVisible({required bool animate}) async {
    if (!mounted) {
      return;
    }
    if (!_sc.hasClients) {
      return;
    }

    final int idx = _selectedIndex();
    if (idx < 0 || idx >= _chipKeys.length) {
      return;
    }

    final BuildContext? chipCtx = _chipKeys[idx].currentContext;
    if (chipCtx == null) {
      return;
    }

    await Scrollable.ensureVisible(
      chipCtx,
      alignment: 0.5,
      duration: animate ? const Duration(milliseconds: 220) : Duration.zero,
      curve: Curves.easeOut,
    );
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
          children: List<Widget>.generate(widget.monthStarts.length, (int i) {
            final DateTime m = widget.monthStarts[i];
            final bool selected = m.year == currentMonthStart.year && m.month == currentMonthStart.month;
            final String label = '${m.year}/${m.month.toString().padLeft(2, '0')}';

            return Padding(
              key: _chipKeys[i],
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) {
                  widget.onTapMonth(m);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _ensureSelectedMonthVisible(animate: true);
                  });
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
