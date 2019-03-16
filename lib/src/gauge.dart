part of modern_charts;

final _gaugeChartDefaultOptions = <String, dynamic>{
  // String - The background color of the gauges.
  'gaugeBackgroundColor': '#dbdbdb',

  // Map - An object that controls the gauge labels.
  'gaugeLabels': {
    // bool - Whether to show the labels.
    'enabled': true,

    // Map - An object that controls the styling of the gauge labels.
    'style': {
      'color': '#212121',
      'fontFamily': _fontFamily,
      'fontSize': 13,
      'fontStyle': 'normal'
    }
  }
};

class _Gauge extends _Pie {
  String backgroundColor;

  @override
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight) {
    final tmpColor = color;
    final tmpEndAngle = endAngle;

    // Draw the background.

    endAngle = startAngle + _2pi;
    color = backgroundColor;
    super.draw(ctx, 1.0, false);

    // Draw the foreground.

    color = tmpColor;
    endAngle = tmpEndAngle;
    super.draw(ctx, percent, highlight);

    // Draw the percent.

    final fs1 = .75 * innerRadius;
    final font1 = '${fs1}px $_fontFamily';
    final text1 = lerp(oldValue, value, percent).round().toString();
    ctx.font = font1;
    final w1 = ctx.measureText(text1).width;

    final fs2 = .6 * fs1;
    final font2 = '${fs2}px $_fontFamily';
    final text2 = '%';
    ctx.font = font2;
    final w2 = ctx.measureText(text2).width;

    final y = center.y + .3 * fs1;
    ctx
      ..font = font1
      ..fillText(text1, center.x - .5 * w2, y)
      ..font = font2
      ..fillText(text2, center.x + .5 * w1, y);
  }
}


class GaugeChart extends Chart {
  num _gaugeHop;
  num _gaugeInnerRadius;
  num _gaugeOuterRadius;
  num _gaugeCenterY;
  final num _startAngle = -_pi_2;

  GaugeChart(Element container) : super(container) {
    _defaultOptions = extendMap(globalOptions, _gaugeChartDefaultOptions);
    _defaultOptions['legend']['position'] = 'none';
  }

  Point _getGaugeCenter(int index) =>
      new Point((index + .5) * _gaugeHop, _gaugeCenterY);

  num _valueToAngle(num value) => value * _2pi / 100;

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();

    final gaugeCount = _dataTable.rows.length;
    num labelTotalHeight = 0;
    if (_options['gaugeLabels']['enabled']) {
      labelTotalHeight =
          _axisLabelMargin + _options['gaugeLabels']['style']['fontSize'];
    }

    _gaugeCenterY = _seriesAndAxesBox.top + .5 * _seriesAndAxesBox.height;
    _gaugeHop = _seriesAndAxesBox.width / gaugeCount;

    final availW = .618 * _gaugeHop; // Golden ratio.
    final availH = _seriesAndAxesBox.height - 2 * labelTotalHeight;
    _gaugeOuterRadius = .5 * min(availW, availH) / _highlightOuterRadiusFactor;
    _gaugeInnerRadius = .5 * _gaugeOuterRadius;
  }

  @override
  bool _drawSeries(double percent) {
    final style = _options['gaugeLabels']['style'];
    final labelsEnabled = _options['gaugeLabels']['enabled'];
    _seriesContext
      ..strokeStyle = 'white'
      ..textAlign = 'center';
    for (_Gauge gauge in _seriesList[0].entities) {
      final highlight = gauge.index == _focusedEntityIndex;
      gauge.draw(_seriesContext, percent, highlight);

      if (!labelsEnabled) continue;

      final x = gauge.center.x;
      final y = gauge.center.y +
          gauge.outerRadius +
          style['fontSize'] +
          _axisLabelMargin;
      _seriesContext
        ..fillStyle = style['color']
        ..font = _getFont(style)
        ..textAlign = 'center'
        ..fillText(gauge.name, x, y);
    }
    return false;
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    // Override the colors.
    // ignore: parameter_assignments
    color = _getColor(entityIndex);
    // ignore: parameter_assignments
    highlightColor = _changeColorAlpha(color, .5);

    final name = _dataTable.rows[entityIndex][0];
    return new _Gauge()
      ..index = entityIndex
      ..value = value
      ..name = name
      ..color = color
      ..backgroundColor = _options['gaugeBackgroundColor']
      ..highlightColor = highlightColor
      ..oldValue = 0
      ..oldStartAngle = _startAngle
      ..oldEndAngle = _startAngle
      ..center = _getGaugeCenter(entityIndex)
      ..innerRadius = _gaugeInnerRadius
      ..outerRadius = _gaugeOuterRadius
      ..startAngle = _startAngle
      ..endAngle = _startAngle + _valueToAngle(value);
  }

  @override
  void _updateSeries([int index]) {
    final n = _dataTable.rows.length;
    for (var i = 0; i < n; i++) {
      final gauge = _seriesList[0].entities[i] as _Gauge;
      final color = _getColor(i);
      final highlightColor = _changeColorAlpha(color, .5);
      gauge
        ..index = i
        ..name = _dataTable.rows[i][0]
        ..color = color
        ..highlightColor = highlightColor
        ..center = _getGaugeCenter(i)
        ..innerRadius = _gaugeInnerRadius
        ..outerRadius = _gaugeOuterRadius
        ..endAngle = _startAngle + _valueToAngle(gauge.value);
    }
  }

  @override
  void _updateTooltipContent() {
    final gauge = _seriesList[0].entities[_focusedEntityIndex] as _Gauge;
    _tooltip.style
      ..borderColor = gauge.color
      ..padding = '4px 12px';
    final label = _tooltipLabelFormatter(gauge.name);
    final value = _tooltipValueFormatter(gauge.value);
    _tooltip.innerHtml = '$label: <strong>$value%</strong>';
  }

  /*
  @override
  int _getEntityGroupIndex(num x, num y) {
    final p = new Point(x, y);
    for (_Gauge g in _seriesList[0].entities) {
      if (g.containsPoint(p)) return g.index;
    }
    return -1;
  }
*/
  @override
  Point _getTooltipPosition() {
    // ignore: avoid_as
    final gauge = _seriesList[0].entities[_focusedEntityIndex] as _Gauge;
    final x = gauge.center.x - _tooltip.offsetWidth ~/ 2;
    final y = gauge.center.y -
        _highlightOuterRadiusFactor * gauge.outerRadius -
        _tooltip.offsetHeight -
        5;
    return new Point(x, y);
  }
}
