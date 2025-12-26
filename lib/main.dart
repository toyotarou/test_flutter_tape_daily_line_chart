// main.dart
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: TapeDailyLineChartDemoPage()));
}

/////////////////////////////////////////////////////////////////

class TapeDailyLineChartDemoPage extends StatefulWidget {
  const TapeDailyLineChartDemoPage({super.key});

  @override
  State<TapeDailyLineChartDemoPage> createState() => _TapeDailyLineChartDemoPageState();
}

class _TapeDailyLineChartDemoPageState extends State<TapeDailyLineChartDemoPage> {
  static final DateTime _startDate = DateTime(2023);

  static const int _windowDays = 30;

  static const double _pixelsPerDay = 16.0;

  static const double _fixedMinY = 0;
  static const double _fixedMaxY = 30000000;

  static const double _fixedIntervalY = 1000000;

  late final DateTime _todayJst;
  late final List<FlSpot> _allSpots;
  late final int _maxIndex;

  double _startIndex = 0;
  double _dragAccumDx = 0;

  bool _tooltipEnabled = false;

  late final List<DateTime> _monthStarts;

  ///
  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();
    _todayJst = DateTime(now.year, now.month, now.day);

    _allSpots = _makeDailyDemoSpotsFixedRangeWavy(
      start: _startDate,
      endInclusive: _todayJst,
      seed: 2023,
      minY: _fixedMinY,
      maxY: _fixedMaxY,
    );

    _maxIndex = _allSpots.isEmpty ? 0 : _allSpots.last.x.floor();
    _startIndex = 0;

    _monthStarts = _buildMonthStarts(start: _startDate, endInclusive: _todayJst);
  }

  ///
  @override
  Widget build(BuildContext context) {
    final double minX = _clampStartIndex(_startIndex);
    final double maxX = minX + (_windowDays - 1).toDouble();

    final DateTime startDt = _dateFromIndex(minX.round());
    final DateTime endDt = _dateFromIndex(maxX.round());

    final List<FlSpot> visibleSpots = _extractVisibleSpots(
      all: _allSpots,
      minX: minX,
      maxX: maxX,
      extendLastValue: true,
    );

    final List<VerticalLine> monthLines = _buildMonthBoundaryLines(minX: minX, maxX: maxX);

    final Color lineColor = Theme.of(context).colorScheme.primary;

    final LineChartData backData = _buildBackChartData(minX: minX, maxX: maxX, monthLines: monthLines);

    final LineChartData frontData = _buildFrontChartData(
      minX: minX,
      maxX: maxX,
      spots: visibleSpots,
      lineColor: lineColor,
      tooltipEnabled: _tooltipEnabled,
    );

    final bool dragEnabled = !_tooltipEnabled;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              _HeaderDaily(
                start: startDt,
                end: endDt,
                today: _todayJst,
                windowDays: _windowDays,
                minY: _fixedMinY,
                maxY: _fixedMaxY,
                tooltipEnabled: _tooltipEnabled,
                onToggleTooltip: (bool v) => setState(() => _tooltipEnabled = v),
              ),
              const SizedBox(height: 12),
              _FooterDaily(
                onReset: () => setState(() => _startIndex = 0),
                onToToday: () =>
                    setState(() => _startIndex = _clampStartIndex((_maxIndex - (_windowDays - 1)).toDouble())),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _TapeChartFrame(
                  dragEnabled: dragEnabled,
                  onDragUpdate: _onDragUpdate,
                  onDragEnd: _onDragEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: LineChart(
                            backData,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                          ),
                        ),
                        Positioned.fill(
                          child: LineChart(
                            frontData,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _MonthJumpBar(
                monthStarts: _monthStarts,
                currentWindowStart: startDt,
                onTapMonth: (DateTime monthStart) {
                  final int dayIndex = monthStart.difference(_startDate).inDays;
                  setState(() => _startIndex = _clampStartIndex(dayIndex.toDouble()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///
  void _onDragUpdate(DragUpdateDetails d) {
    _dragAccumDx += d.delta.dx;

    while (_dragAccumDx <= -_pixelsPerDay) {
      _dragAccumDx += _pixelsPerDay;
      _jumpDays(1);
    }
    while (_dragAccumDx >= _pixelsPerDay) {
      _dragAccumDx -= _pixelsPerDay;
      _jumpDays(-1);
    }
  }

  ///
  void _onDragEnd(DragEndDetails d) {
    _dragAccumDx = 0;
  }

  ///
  void _jumpDays(int deltaDays) {
    setState(() {
      _startIndex = _clampStartIndex(_startIndex + deltaDays);
    });
  }

  ///
  double _clampStartIndex(double start) {
    final int maxStart = math.max(0, _maxIndex - (_windowDays - 1));
    if (start < 0) {
      return 0;
    }
    if (start > maxStart) {
      return maxStart.toDouble();
    }
    return start;
  }

  ///
  DateTime _dateFromIndex(int dayIndex) {
    return _startDate.add(Duration(days: dayIndex));
  }

  ///
  LineChartData _buildBackChartData({
    required double minX,
    required double maxX,
    required List<VerticalLine> monthLines,
  }) {
    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: _fixedMinY,
      maxY: _fixedMaxY,
      lineTouchData: const LineTouchData(enabled: false, handleBuiltInTouches: false),
      gridData: const FlGridData(verticalInterval: 1, horizontalInterval: _fixedIntervalY),
      extraLinesData: ExtraLinesData(verticalLines: monthLines),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        bottomTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            interval: _fixedIntervalY,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value == _fixedMinY || value == _fixedMaxY) {
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
            interval: _fixedIntervalY,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value == _fixedMinY || value == _fixedMaxY) {
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
  LineChartData _buildFrontChartData({
    required double minX,
    required double maxX,
    required List<FlSpot> spots,
    required Color lineColor,
    required bool tooltipEnabled,
  }) {
    return LineChartData(
      minX: minX,
      maxX: maxX,
      minY: _fixedMinY,
      maxY: _fixedMaxY,
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
            interval: _fixedIntervalY,
            getTitlesWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _fixedIntervalY,
            getTitlesWidget: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: <LineChartBarData>[
        LineChartBarData(color: lineColor, spots: spots, barWidth: 3, dotData: const FlDotData(show: false)),
      ],
      lineTouchData: tooltipEnabled
          ? LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot s) {
                    final DateTime dt = _dateFromIndex(s.x.round());
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
  List<VerticalLine> _buildMonthBoundaryLines({required double minX, required double maxX}) {
    final List<VerticalLine> lines = <VerticalLine>[];

    final DateTime minDt = _dateFromIndex(minX.floor());
    final DateTime maxDt = _dateFromIndex(maxX.ceil());

    DateTime cursor = DateTime(minDt.year, minDt.month);
    if (cursor.isBefore(minDt)) {
      cursor = DateTime(minDt.year, minDt.month + 1);
    }

    while (!cursor.isAfter(maxDt)) {
      final double x = cursor.difference(_startDate).inDays.toDouble();
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

  List<DateTime> _buildMonthStarts({required DateTime start, required DateTime endInclusive}) {
    final List<DateTime> list = <DateTime>[];
    DateTime cursor = DateTime(start.year, start.month);
    final DateTime endMonth = DateTime(endInclusive.year, endInclusive.month);

    while (!cursor.isAfter(endMonth)) {
      list.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return list;
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
    required this.onToggleTooltip,
  });

  final DateTime start;
  final DateTime end;
  final DateTime today;
  final int windowDays;
  final double minY;
  final double maxY;

  final bool tooltipEnabled;
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
              Switch(value: tooltipEnabled, onChanged: onToggleTooltip),
              Text(tooltipEnabled ? '表示' : '非表示', style: const TextStyle(fontSize: 12)),
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

class _MonthJumpBar extends StatelessWidget {
  const _MonthJumpBar({required this.monthStarts, required this.currentWindowStart, required this.onTapMonth});

  final List<DateTime> monthStarts;
  final DateTime currentWindowStart;
  final ValueChanged<DateTime> onTapMonth;

  @override
  Widget build(BuildContext context) {
    final DateTime currentMonthStart = DateTime(currentWindowStart.year, currentWindowStart.month);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all()),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: monthStarts.map((DateTime m) {
            final bool selected = m.year == currentMonthStart.year && m.month == currentMonthStart.month;
            final String label = '${m.year}/${m.month.toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(label, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => onTapMonth(m),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////

class _TapeChartFrame extends StatelessWidget {
  const _TapeChartFrame({
    required this.child,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.dragEnabled,
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

        /// Stack必要
        child: Stack(children: <Widget>[Positioned.fill(child: child)]),
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////

List<FlSpot> _extractVisibleSpots({
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

/////////////////////////////////////////////////////////////////

List<FlSpot> _makeDailyDemoSpotsFixedRangeWavy({
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
