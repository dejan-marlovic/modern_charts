part of modern_charts;

final _radarChartDefaultOptions = <String, dynamic>{
  // Map - An object that controls the series.
  'series': {
    // num - The opacity of the area between a series and the x-axis.
    'fillOpacity': .25,

    // num - The line width of the series.
    'lineWidth': 2,

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
    },

    // Map - An object that controls the markers.
    'markers': {
      // bool - Whether markers are enabled.
      'enabled': true,

      // String - The fill color. If `null`, the stroke color of the series
      // will be used.
      'fillColor': null,

      // num - The line width of the markers.
      'lineWidth': 1,

      // String - The stroke color. If `null`, the stroke color of the series
      // will be used.
      'strokeColor': 'white',

      // num - Size of the markers. To disable markers, set this to zero.
      'size': 4
    }
  },

  // Map - An object that controls the x-axis.
  'xAxis': {
    // String - The color of the horizontal grid lines.
    'gridLineColor': '#c0c0c0',

    // num - The width of the horizontal grid lines.
    'gridLineWidth': 1,

    // Map - An object that controls the axis labels.
    'labels': {
      'style': {
        // String - The labels' color.
        'color': '#212121',

        // String - The labels' font family.
        'fontFamily': _fontFamily,

        // String - The labels' font size.
        'fontSize': 13,

        // String - The labels' font style.
        'fontStyle': 'normal'
      }
    },
  },

  // Map - An object that controls the y-axis.
  'yAxis': {
    // String - The color of the vertical grid lines.
    'gridLineColor': '#c0c0c0',

    // num - The width of the vertical grid lines.
    'gridLineWidth': 1,

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

        // String - The labels' font size.
        'fontSize': 13,

        // String - The labels' font style.
        'fontStyle': 'normal'
      }
    },

    // num - The minimum interval. If `null`, this value is automatically
    // calculated.
    'minInterval': null,
  }
};

class _PolarPoint extends _Entity {
  num oldRadius;
  num oldAngle;
  num oldPointRadius;

  num radius;
  num angle;
  num pointRadius;

  Point center;

  @override
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight) {
    final r = lerp(oldRadius, radius, percent);
    final a = lerp(oldAngle, angle, percent);
    final pr = lerp(oldPointRadius, pointRadius, percent);
    final p = polarToCartesian(center, r, a);
    if (highlight) {
      ctx
        ..fillStyle = highlightColor
        ..beginPath()
        ..arc(p.x, p.y, 2 * pr, 0, _2pi)
        ..fill();
    }
    ctx
      ..fillStyle = color
      ..beginPath()
      ..arc(p.x, p.y, pr, 0, _2pi)
      ..fill()
      ..stroke();
  }

  @override
  void save() {
    oldRadius = radius;
    oldAngle = angle;
    oldPointRadius = pointRadius;
    super.save();
  }
}

class RadarChart extends Chart {
  Point _center;
  num _radius;
  num _angleInterval;
  List<String> _xLabels;
  List<String> _yLabels;
  num _yMaxValue;
  num _yLabelHop;
  ValueFormatter _yLabelFormatter;

  /// Each element is the bounding box of each entity group.
  List<Rectangle> _boundingBoxes;

  RadarChart(Element container) : super(container) {
    _defaultOptions = extendMap(globalOptions, _radarChartDefaultOptions);
  }

  num _getAngle(int entityIndex) => entityIndex * _angleInterval - _pi_2;

  num _valueToRadius(num value) =>
      (value != null) ? value * _radius / _yMaxValue : 0.0;

  void _calculateBoundingBoxes() {
    if (!_options['tooltip']['enabled']) return;

    final seriesCount = _seriesList.length;
    final entityCount = _seriesList.first.entities.length;
    _boundingBoxes = new List<Rectangle>(entityCount);
    for (var i = 0; i < entityCount; i++) {
      num minX = double.maxFinite;
      num minY = double.maxFinite;
      num maxX = -double.maxFinite;
      num maxY = -double.maxFinite;
      for (var j = 0; j < seriesCount; j++) {
        final pp = _seriesList[j].entities[i] as _PolarPoint;
        final cp = polarToCartesian(pp.center, pp.radius, pp.angle);
        minX = min(minX, cp.x);
        minY = min(minY, cp.y);
        maxX = max(maxX, cp.x);
        maxY = max(maxY, cp.y);
      }
      _boundingBoxes[i] = new Rectangle(minX, minY, maxX - minX, maxY - minY);
    }
  }

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();

    _xLabels = _dataTable.getColumnValues(0);
    _angleInterval = _2pi / _xLabels.length;

    final rect = _seriesAndAxesBox;
    final xLabelFontSize = _options['xAxis']['labels']['style']['fontSize'];

    // [_radius]*factor equals the height of the largest polygon.
    final factor = 1 + sin((_xLabels.length >> 1) * _angleInterval - _pi_2);
    _radius = min(rect.width, rect.height) / factor -
        factor * (xLabelFontSize + _axisLabelMargin);
    _center =
        new Point(rect.left + rect.width / 2, rect.top + rect.height / factor);

    // The minimum value on the y-axis is always zero.
    num yInterval = _options['yAxis']['interval'];
    if (yInterval == null) {
      final yMinInterval = _options['yAxis']['minInterval'];
      _yMaxValue = findMaxValue(_dataTable);
      yInterval = calculateInterval(_yMaxValue, 3, yMinInterval);
      _yMaxValue = (_yMaxValue / yInterval).ceilToDouble() * yInterval;
    }

    _yLabelFormatter = _options['yAxis']['labels']['formatter'];
    if (_yLabelFormatter == null) {
      final decimalPlaces = getDecimalPlaces(yInterval);
      final numberFormat = new NumberFormat.decimalPattern()
        ..maximumFractionDigits = decimalPlaces
        ..minimumFractionDigits = decimalPlaces;
      _yLabelFormatter = numberFormat.format;
    }
    _entityValueFormatter = _yLabelFormatter;

    _yLabels = <String>[];
    num value = 0.0;
    while (value <= _yMaxValue) {
      _yLabels.add(_yLabelFormatter(value));
      value += yInterval;
    }

    _yLabelHop = _radius / (_yLabels.length - 1);

    // Tooltip.

    _tooltipValueFormatter =
        _options['tooltip']['valueFormatter'] ?? _yLabelFormatter;
  }

  @override
  void _drawAxesAndGrid() {
    final xLabelCount = _xLabels.length;
    final yLabelCount = _yLabels.length;

    // x-axis grid lines (i.e. concentric equilateral polygons).

    var lineWidth = _options['xAxis']['gridLineWidth'];
    if (lineWidth > 0) {
      _axesContext
        ..lineWidth = lineWidth
        ..strokeStyle = _options['xAxis']['gridLineColor']
        ..beginPath();
      var radius = _radius;
      for (var i = yLabelCount - 1; i >= 1; i--) {
        var angle = -_pi_2 + _angleInterval;
        _axesContext.moveTo(_center.x, _center.y - radius);
        for (var j = 0; j < xLabelCount; j++) {
          final point = polarToCartesian(_center, radius, angle);
          _axesContext.lineTo(point.x, point.y);
          angle += _angleInterval;
        }
        radius -= _yLabelHop;
      }
      _axesContext.stroke();
    }

    // y-axis grid lines (i.e. radii from the center to the x-axis labels).

    lineWidth = _options['yAxis']['gridLineWidth'];
    if (lineWidth > 0) {
      _axesContext
        ..lineWidth = lineWidth
        ..strokeStyle = _options['yAxis']['gridLineColor']
        ..beginPath();
      num angle = -_pi_2;
      for (var i = 0; i < xLabelCount; i++) {
        final point = polarToCartesian(_center, _radius, angle);
        _axesContext
          ..moveTo(_center.x, _center.y)
          ..lineTo(point.x, point.y);
        angle += _angleInterval;
      }
      _axesContext.stroke();
    }

    // y-axis labels - don't draw the first (at center) and the last ones.

    var style = _options['yAxis']['labels']['style'];
    final x = _center.x - _axisLabelMargin;
    var y = _center.y - _yLabelHop;
    _axesContext
      ..fillStyle = style['color']
      ..font = _getFont(style)
      ..textAlign = 'right'
      ..textBaseline = 'middle';
    for (var i = 1; i <= yLabelCount - 2; i++) {
      _axesContext.fillText(_yLabels[i], x, y);
      y -= _yLabelHop;
    }

    // x-axis labels.

    style = _options['xAxis']['labels']['style'];
    _axesContext
      ..fillStyle = style['color']
      ..font = _getFont(style)
      ..textAlign = 'center'
      ..textBaseline = 'middle';
    final fontSize = style['fontSize'];
    var angle = -_pi_2;
    final radius = _radius + _axisLabelMargin;
    for (var i = 0; i < xLabelCount; i++) {
      _drawText(_axesContext, _xLabels[i], radius, angle, fontSize);
      angle += _angleInterval;
    }
  }

  void _drawText(CanvasRenderingContext2D ctx, String text, num radius,
      num angle, num fontSize) {
    final w = ctx.measureText(text).width;
    final x = _center.x + cos(angle) * (radius + .5 * w);
    final y = _center.y + sin(angle) * (radius + .5 * fontSize);
    ctx.fillText(text, x, y);
  }

  @override
  bool _drawSeries(double percent) {
    final fillOpacity = _options['series']['fillOpacity'];
    final seriesLineWidth = _options['series']['lineWidth'];
    final markerOptions = _options['series']['markers'];
    final markerSize = markerOptions['size'];
    final pointCount = _xLabels.length;

    for (var i = 0; i < _seriesList.length; i++) {
      if (_seriesStates[i] == _VisibilityState.hidden) continue;

      final series = _seriesList[i];
      final scale = (i != _focusedSeriesIndex) ? 1 : 2;

      // Draw the polygon.

      _seriesContext
        ..lineWidth = scale * seriesLineWidth
        ..strokeStyle = series.color
        ..beginPath();
      for (var j = 0; j < pointCount; j++) {
        final point = series.entities[j] as _PolarPoint;
        // TODO: Optimize.
        final radius = lerp(point.oldRadius, point.radius, percent);
        final angle = lerp(point.oldAngle, point.angle, percent);
        final p = polarToCartesian(_center, radius, angle);
        if (j > 0) {
          _seriesContext.lineTo(p.x, p.y);
        } else {
          _seriesContext.moveTo(p.x, p.y);
        }
      }
      _seriesContext
        ..closePath()
        ..stroke();

      // Optionally fill the polygon.

      if (fillOpacity > 0) {
        _seriesContext
          ..fillStyle = _changeColorAlpha(series.color, fillOpacity)
          ..fill();
      }

      // Draw the markers.

      if (markerSize > 0) {
        final fillColor = markerOptions['fillColor'] ?? series.color;
        final strokeColor = markerOptions['strokeColor'] ?? series.color;
        _seriesContext
          ..fillStyle = fillColor
          ..lineWidth = scale * markerOptions['lineWidth']
          ..strokeStyle = strokeColor;
        for (var p in series.entities) {
          if (markerOptions['enabled']) {
            p.draw(_seriesContext, percent, p.index == _focusedEntityIndex);
          } else if (p.index == _focusedEntityIndex) {
            // Only draw marker on hover.
            p.draw(_seriesContext, percent, true);
          }
        }
      }
    }

    return false;
  }

  /*
  @override
  int _getEntityGroupIndex(num x, num y) {
    final p = new Point(x - _center.x, y - _center.y);
    if (p.magnitude >= _radius) return -1;
    final angle = atan2(p.y, p.x);
    final points = _seriesList.first.entities as List<_PolarPoint>;
    for (var i = points.length - 1; i >= 0; i--) {
      final delta = angle - points[i].angle;
      if (delta.abs() < .5 * _angleInterval) return i;
      if ((delta + _2pi).abs() < .5 * _angleInterval) return i;
    }
    return -1;
  }
  */

  @override
  Point _getTooltipPosition() {
    final box = _boundingBoxes[_focusedEntityIndex];
    final offset = _options['series']['markers']['size'] * 2 + 5;
    var x = box.right + offset;
    final y = box.top + (box.height - _tooltip.offsetHeight) ~/ 2;
    if (x + _tooltip.offsetWidth > _width)
      x = box.left - _tooltip.offsetWidth - offset;
    return new Point(x, y);
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    final angle = _getAngle(entityIndex);
    return new _PolarPoint()
      ..index = entityIndex
      ..value = value
      ..color = color
      ..highlightColor = highlightColor
      ..center = _center
      ..oldRadius = 0
      ..oldAngle = angle
      ..oldPointRadius = 0
      ..radius = _valueToRadius(value)
      ..angle = angle
      ..pointRadius = _options['series']['markers']['size'];
  }

  @override
  void _updateSeries([int index]) {
    final entityCount = _dataTable.rows.length;
    for (var i = 0; i < _seriesList.length; i++) {
      final series = _seriesList[i];
      final color = _getColor(i);
      final highlightColor = _getHighlightColor(color);
      final visible = _seriesStates[i].index >= _VisibilityState.showing.index;
      series
        ..color = color
        ..highlightColor = highlightColor;
      for (var j = 0; j < entityCount; j++) {
        final p = series.entities[j] as _PolarPoint
          ..index = j
          ..center = _center
          ..angle = _getAngle(j)
          ..color = color
          ..highlightColor = highlightColor;

        p.radius = visible ? _valueToRadius(p.value) : 0.0;
      }
    }
  }

  @override
  void _seriesVisibilityChanged(int index) {
    final visible =
        _seriesStates[index].index >= _VisibilityState.showing.index;
    final markerSize = _options['series']['markers']['size'];
    for (_PolarPoint p in _seriesList[index].entities) {
      if (visible) {
        p
          ..radius = _valueToRadius(p.value)
          ..pointRadius = markerSize;
      } else {
        p
          ..radius = 0.0
          ..pointRadius = 0;
      }
    }

    _calculateBoundingBoxes();
  }

  @override
  void update() {
    super.update();
    _calculateBoundingBoxes();
  }
}
