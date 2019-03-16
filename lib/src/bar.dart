part of modern_charts;

final _barChartDefaultOptions = {
  // Map - An object that controls the series.
  'series': {
    // Map - An object that controls the series labels.
    'labels': {
      // bool - Whether to show the labels.
      'enabled': false,

      'style': {
        'color': '#212121',
        'fontFamily': _fontFamily,
        'fontSize': 13,
        'fontStyle': 'normal'
      }
    }
  },

  // Map - An object that controls the x-axis.
  'xAxis': {
    // Map - An object that controls the crosshair.
    'crosshair': {
      // String - The fill color of the crosshair.
      'color': 'rgba(0, 0, 0, .02)',

      // bool - Whether the crosshair is enabled.
      'enabled': false,
    },

    // String - The color of the horizontal grid lines.
    'gridLineColor': '#c0c0c0',

    // num - The width of the horizontal grid lines.
    'gridLineWidth': 1,

    // String - The color of the axis itself.
    'lineColor': '#c0c0c0',

    // num - The width of the axis itself.
    'lineWidth': 1,

    // Map - An object that controls the axis labels.
    'labels': {
      // num - The maximum rotation angle in degrees. Must be <= 90.
      'maxRotation': 0,

      // num - The minimum rotation angle in degrees. Must be >= -90.
      'minRotation': -90,

      'style': {
        // String - The labels' color.
        'color': '#212121',

        // String - The labels' font family.
        'fontFamily': _fontFamily,

        // num - The labels' font size.
        'fontSize': 13,

        // String - The labels' font style.
        'fontStyle': 'normal'
      }
    },

    // String - The position of the axis relative to the chart area.
    // Supported values: 'bottom'.
    'position': 'bottom',

    // Map - An object that controls the axis title.
    'title': {
      // Map - An object that controls the styling of the axis title.
      'style': {
        // String - The title's color.
        'color': '#212121',

        // String - The title's font family.
        'fontFamily': _fontFamily,

        // num - The title's font size.
        'fontSize': 15,

        // String - The title's font style.
        'fontStyle': 'normal'
      },

      // The title text. A `null` value means the title is hidden.
      'text': null
    }
  },

  // Map - An object that controls the y-axis.
  'yAxis': {
    // String - The color of the vertical grid lines.
    'gridLineColor': '#c0c0c0',

    // num - The width of the vertical grid lines.
    'gridLineWidth': 0,

    // String - The color of the axis itself.
    'lineColor': '#c0c0c0',

    // num - The width of the axis itself.
    'lineWidth': 0,

    // num - The interval of the tick marks in axis unit. If `null`, this value
    // is automatically calculated.
    'interval': null,

    // Map - An object that controls the axis labels.
    'labels': {
      // (num value) -> String - A function that formats the labels.
      'formatter': null,

      // Map - An object that controls the styling of the axis labels.
      'style': {
        // String - The labels' color.
        'color': '#212121',

        // String - The labels' font family.
        'fontFamily': _fontFamily,

        // num - The labels' font size.
        'fontSize': 13,

        // String - The labels' font style.
        'fontStyle': 'normal'
      },
    },

    // num - The desired maximum value on the axis. If set, the calculated value
    // is guaranteed to be >= this value.
    'maxValue': null,

    // num - The minimum interval. If `null`, this value is automatically
    // calculated.
    'minInterval': null,

    // num - The desired minimum value on the axis. If set, the calculated value
    // is guaranteed to be <= this value.
    'minValue': null,

    // String - The position of the axis relative to the chart area.
    // Supported values: 'left'.
    'position': 'left',

    // Map - An object that controls the axis title.
    'title': {
      // Map - An object that controls the styling of the axis title.
      'style': {
        // String - The title's color.
        'color': '#212121',

        // String - The title's font family.
        'fontFamily': _fontFamily,

        // num - The title's font size.
        'fontSize': 15,

        // String - The title's font style.
        'fontStyle': 'normal'
      },

      // The title text. A `null` value means the title is hidden.
      'text': null
    }
  }
};

class _Bar extends _Entity {
  num oldLeft;
  num oldWidth;
  num oldHeight;
  num bottom;
  num left;
  num width;
  num height;

  num get right => left + width;

  @override
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight) {
    final x = lerp(oldLeft, left, percent);
    final h = lerp(oldHeight, height, percent);
    final w = lerp(oldWidth, width, percent);
    ctx
      ..fillStyle = color
      ..fillRect(x, bottom - h, w, h);
    if (highlight) {
      ctx
        ..fillStyle = 'rgba(255, 255, 255, .25)'
        ..fillRect(x, bottom - h, w, h);
    }
  }

  @override
  void save() {
    oldLeft = left;
    oldWidth = width;
    oldHeight = height;
    super.save();
  }
}

class BarChart extends _TwoAxisChart {
  num _barWidth;
  final _barSpacing = 0;
  num _barGroupWidth;

  BarChart(Element container) : super(container) {
    _defaultOptions = extendMap(globalOptions, _barChartDefaultOptions);
  }

  num _getBarLeft(int seriesIndex, int barIndex) => _xLabelX(barIndex) -
        .5 * _barGroupWidth +
        _countVisibleSeries(seriesIndex) * (_barWidth + _barSpacing);

  void _updateBarWidth() {
    final count = _countVisibleSeries();
    if (count > 0) {
      _barWidth = (_barGroupWidth + _barSpacing) / count - _barSpacing;
    } else {
      _barWidth = 0.0;
    }
  }

  num _valueToBarHeight(num value) {
    if (value != null) return _xAxisTop - _valueToY(value);
    return 0;
  }

  @override
  void _calculateAverageYValues([int index]) {
    if (!_options['tooltip']['enabled']) return;

    final entityCount = _seriesList.first.entities.length;
    final start = index ?? 0;
    final end = index == null ? entityCount : index + 1;

    _averageYValues ??= <num>[];
    _averageYValues.length = entityCount;

    for (var i = start; i < end; i++) {
      num sum = 0.0;
      num count = 0;
      for (var j = _seriesList.length - 1; j >= 0; j--) {
        final state = _seriesStates[j];
        if (state == _VisibilityState.hidden) continue;
        if (state == _VisibilityState.hiding) continue;

        final bar = _seriesList[j].entities[i] as _Bar;
        if (bar.value != null) {
          sum += bar.height;
          count++;
        }
      }
      _averageYValues[i] = (count > 0) ? _xAxisTop - sum / count : null;
    }
  }

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();
    _barGroupWidth = .618 * _xLabelHop; // Golden ratio.
    _tooltipOffset = .5 * _xLabelHop + 4;
    _updateBarWidth();
  }

  @override
  bool _drawSeries(double percent) {
    // ignore: prefer_final_locals
    for (var i = 0, n = _seriesList.length; i < n; i++) {
      if (_seriesStates[i] == _VisibilityState.hidden) continue;

      final series = _seriesList[i];

      // Draw the bars.
      for (_Bar bar in series.entities) {
        if (bar.value == null) continue;
        bar.draw(_seriesContext, percent, false);
      }

      var opt = _options['xAxis']['crosshair'];
      if (_focusedEntityIndex >= 0 && opt['enabled']) {
        _seriesContext
          ..fillStyle = opt['color']
          ..fillRect(_yAxisLeft + _xLabelHop * _focusedEntityIndex,
              _xAxisTop - _yAxisLength, _xLabelHop, _yAxisLength);
      }

      // Draw the labels.
      if (percent == 1.0) {
        opt = _options['series']['labels'];
        if (!opt['enabled']) continue;
        _seriesContext
          ..fillStyle = opt['style']['color']
          ..font = _getFont(opt['style'])
          ..textAlign = 'center'
          ..textBaseline = 'alphabetic';
        for (_Bar bar in series.entities) {
          if (bar.value == null) continue;
          final x = bar.left + .5 * bar.width;
          final y = _xAxisTop - bar.height - 5;
          _seriesContext.fillText(bar.formattedValue, x, y);
        }
      }
    }

    return false;
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    final left = _getBarLeft(seriesIndex, entityIndex);
    final oldLeft = left;
    final height = _valueToBarHeight(value);

    // Animate width.
    var oldHeight = height;
    num oldWidth = 0.0;

    if (_seriesList == null) {
      // Data table changed. Animate height.
      oldHeight = 0;
      oldWidth = _barWidth;
    }

    return new _Bar()
      ..index = entityIndex
      ..value = value
      ..formattedValue = value != null ? _entityValueFormatter(value) : null
      ..color = color
      ..highlightColor = highlightColor
      ..bottom = _xAxisTop
      ..oldLeft = oldLeft
      ..left = left
      ..oldHeight = oldHeight
      ..height = height
      ..oldWidth = oldWidth
      ..width = _barWidth;
  }

  @override
  void _updateSeries([int index]) {
    final entityCount = _dataTable.rows.length;
    for (var i = 0; i < _seriesList.length; i++) {
      final series = _seriesList[i];
      var left = _getBarLeft(i, 0);
      var barWidth = 0.0;
      if (_seriesStates[i].index >= _VisibilityState.showing.index) {
        barWidth = _barWidth;
      }
      final color = _getColor(i);
      final highlightColor = _getHighlightColor(color);
      series
        ..color = color
        ..highlightColor = highlightColor;
      for (var j = 0; j < entityCount; j++) {
        final bar = (series.entities[j] as _Bar)
          ..index = j
          ..color = color
          ..highlightColor = highlightColor
          ..left = left
          ..bottom = _xAxisTop
          ..width = barWidth;

        bar.height = _valueToBarHeight(bar.value);
        left += _xLabelHop;
      }
    }
  }

  @override
  void _seriesVisibilityChanged(int index) {
    _updateBarWidth();
    _updateSeries();
    _calculateAverageYValues();
  }
}
