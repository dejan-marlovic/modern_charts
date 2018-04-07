part of modern_charts;

final _lineChartDefaultOptions = <String, dynamic>{
  // Map - An object that controls the series.
  'series': {
    // num - The curve tension. The typical value is from 0.3 to 0.5.
    // To draw straight lines, set this to zero.
    'curveTension': .4,

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

      // num - Size of the markers.
      'size': 4
    }
  },

  // Map - An object that controls the x-axis.
  'xAxis': {
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

        // String - The labels' font size.
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

        // String - The title's font size.
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

        // String - The labels' font size.
        'fontSize': 13,

        // String - The labels' font style.
        'fontStyle': 'normal'
      }
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

        // String - The title's font size.
        'fontSize': 15,

        // String - The title's font style.
        'fontStyle': 'normal'
      },

      // The title text. A `null` value means the title is hidden.
      'text': null
    }
  }
};

/// A point in a line chart.
class _Point extends _Entity {
  num oldX;
  num oldY;
  Point oldCp1;
  Point oldCp2;
  num oldPointRadius;

  /// The first control point.
  Point cp1;

  /// The second control point.
  Point cp2;

  num x;
  num y;
  num pointRadius;

  @override
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight) {
    final cx = lerp(oldX, x, percent);
    final cy = lerp(oldY, y, percent);
    final pr = lerp(oldPointRadius, pointRadius, percent);
    if (highlight) {
      ctx
        ..fillStyle = highlightColor
        ..beginPath()
        ..arc(cx, cy, 2 * pr, 0, _2pi)
        ..fill();
    }
    ctx
      ..beginPath()
      ..arc(cx, cy, pr, 0, _2pi)
      ..fill()
      ..stroke();
  }

  @override
  void save() {
    oldX = x;
    oldY = y;
    oldCp1 = cp1;
    oldCp2 = cp2;
    oldPointRadius = pointRadius;
    super.save();
  }

  Point get asPoint => new Point(x, y);
}

class LineChart extends _TwoAxisChart {
  @override
  // ignore: overridden_fields
  final num _xLabelOffsetFactor = 0;

  LineChart(Element container) : super(container) {
    _defaultOptions = extendMap(globalOptions, _lineChartDefaultOptions);
  }

  @override
  void _calculateAverageYValues([int index]) {
    if (!_options['tooltip']['enabled']) return;

    final entityCount = _dataTable.rows.length;
    final start = index ?? 0;
    final end = index == null ? entityCount : index + 1;

    _averageYValues ??= <num>[];
    _averageYValues.length = entityCount;

    for (var i = start; i < end; i++) {
      num sum = 0.0;
      num count = 0;
      for (var j = _seriesList.length - 1; j >= 0; j--) {
        if (_seriesStates[j].index <= _VisibilityState.hiding.index) continue;
        // ignore: avoid_as
        final point = _seriesList[j].entities[i] as _Point;
        if (point.value != null) {
          sum += point.y;
          count++;
        }
      }
      _averageYValues[i] = (count > 0) ? sum / count : null;
    }
  }

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();
    _tooltipOffset = _options['series']['markers']['size'] * 2 + 5;
  }

  List<_Entity> _lerpPoints(List<_Entity> points, double percent) =>
      points.map((e) {
        // ignore: avoid_as
        final p = e as _Point;
        final x = lerp(p.oldX, p.x, percent);
        final y = lerp(p.oldY, p.y, percent);
        final cp1 = (p.cp1 != null) ? lerp(p.oldCp1, p.cp1, percent) : null;
        final cp2 = (p.cp2 != null) ? lerp(p.oldCp2, p.cp2, percent) : null;
        return new _Point()
          ..index = p.index
          ..value = p.value
          ..color = p.color
          ..highlightColor = p.highlightColor
          ..oldPointRadius = p.oldPointRadius
          ..oldX = p.oldX
          ..oldY = p.oldY
          ..pointRadius = p.pointRadius
          ..x = x
          ..y = y
          ..cp1 = cp1
          ..cp2 = cp2;
      }).toList();

  @override
  bool _drawSeries(double percent) {
    void curveTo(Point cp1, Point cp2, _Point p) {
      if (cp2 == null && cp1 == null) {
        _seriesContext.lineTo(p.x, p.y);
      } else if (cp2 == null) {
        _seriesContext.quadraticCurveTo(cp1.x, cp1.y, p.x, p.y);
      } else if (cp1 == null) {
        _seriesContext.quadraticCurveTo(cp2.x, cp2.y, p.x, p.y);
      } else {
        _seriesContext.bezierCurveTo(cp1.x, cp1.y, cp2.x, cp2.y, p.x, p.y);
      }
    }

    final seriesCount = _seriesList.length;
    final entityCount = _dataTable.rows.length;
    final fillOpacity = _options['series']['fillOpacity'];
    final seriesLineWidth = _options['series']['lineWidth'];
    final markerOptions = _options['series']['markers'];
    final markerSize = markerOptions['size'];

    for (var i = 0; i < seriesCount; i++) {
      if (_seriesStates[i] == _VisibilityState.hidden) continue;

      final series = _seriesList[i];
      final points = _lerpPoints(series.entities, percent);
      final scale = (i != _focusedSeriesIndex) ? 1 : 2;

      _seriesContext.lineJoin = 'round';

      // Draw series with filling.

      if (fillOpacity > 0.0) {
        final color = _changeColorAlpha(series.color, fillOpacity);
        _seriesContext
          ..fillStyle = color
          ..strokeStyle = color;
        var j = 0;
        final condition = true;
        while (condition) {
          // Skip points with a null value.
          while (j < entityCount && points[j].value == null) j++;

          // Stop if we have reached the end of the series.
          if (j == entityCount) break;

          // Connect a series of contiguous points with a non-null value and
          // fill the area between them and the x-axis.
          var p = points[j] as _Point;
          _seriesContext
            ..beginPath()
            ..moveTo(p.x, _xAxisTop)
            ..lineTo(p.x, p.y);
          var lastPoint = p;
          var count = 1;
          while (++j < entityCount && points[j].value != null) {
            p = points[j];
            curveTo(lastPoint.cp2, p.cp1, p);
            lastPoint = p;
            count++;
          }
          if (count >= 2) {
            _seriesContext
              ..lineTo(lastPoint.x, _xAxisTop)
              ..closePath()
              ..fill();
          }
        }
      }

      // Draw series without filling.

      if (seriesLineWidth > 0) {
        var lastPoint = new _Point();
        _seriesContext
          ..lineWidth = scale * seriesLineWidth
          ..strokeStyle = series.color
          ..beginPath();
        for (var e in points) {
          // ignore: avoid_as
          final p = e as _Point;
          if (p.value != null) {
            if (lastPoint.value != null) {
              curveTo(lastPoint.cp2, p.cp1, p);
            } else {
              _seriesContext.moveTo(p.x, p.y);
            }
          }
          lastPoint = p;
        }
        _seriesContext.stroke();
      }

      // Draw markers.

      if (markerSize > 0) {
        final fillColor = markerOptions['fillColor'] ?? series.color;
        final strokeColor = markerOptions['strokeColor'] ?? series.color;
        _seriesContext
          ..fillStyle = fillColor
          ..lineWidth = scale * markerOptions['lineWidth']
          ..strokeStyle = strokeColor;
        for (var p in points) {
          if (p.value != null) {
            if (markerOptions['enabled']) {
              p.draw(_seriesContext, 1.0, p.index == _focusedEntityIndex);
            } else if (p.index == _focusedEntityIndex) {
              // Only draw marker on hover.
              p.draw(_seriesContext, 1.0, true);
            }
          }
        }
      }
    }

    // Draw labels only on the last frame.

    final labelOptions = _options['series']['labels'];
    if (percent == 1.0 && labelOptions['enabled']) {
      _seriesContext
        ..fillStyle = labelOptions['style']['color']
        ..font = _getFont(labelOptions['style'])
        ..textAlign = 'center'
        ..textBaseline = 'alphabetic';
      //for (var i = 0; i < seriesCount; i++) {
      var i = 0;
      for (var series in _seriesStates) {
        if (series != _VisibilityState.shown) continue;

        final points = _seriesList[i].entities as List<_Point>;
        for (var p in points) {
          if (p.value != null) {
            final y = p.y - markerSize - 5;
            _seriesContext.fillText(p.formattedValue, p.x, y);
          }
        }
        i++;
      }
    }

    return false;
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    final x = _xLabelX(entityIndex);
    final oldY = _xAxisTop;
    // oldCp1 and oldCp2 are calculated in [_updateSeries].
    return new _Point()
      ..index = entityIndex
      ..value = value
      ..formattedValue = value != null ? _entityValueFormatter(value) : null
      ..color = color
      ..highlightColor = highlightColor
      ..oldX = x
      ..oldY = oldY
      ..oldPointRadius = 09
      ..x = x
      ..y = _valueToY(value)
      ..pointRadius = _options['series']['markers']['size'];
  }

  @override
  void _updateSeries([int index]) {
    final entityCount = _dataTable.rows.length;
    final markerSize = _options['series']['markers']['size'];
    final curveTension = _options['series']['curveTension'];
    final curve = curveTension > 0 && entityCount > 2;

    final start = index ?? 0;
    final end = (index == null) ? _seriesList.length : index + 1;
    for (var i = start; i < end; i++) {
      final visible = _seriesStates[i].index >= _VisibilityState.showing.index;
      final series = _seriesList[i];
      final entities = series.entities;
      final color = _getColor(i);
      final highlightColor = _getHighlightColor(color);
      series
        ..color = color
        ..highlightColor = highlightColor;

      for (var j = 0; j < entityCount; j++) {
        // ignore: avoid_as
        final e = (entities[j] as _Point)
          ..index = j
          ..color = color
          ..highlightColor = highlightColor
          ..x = _xLabelX(j)
          ..pointRadius = visible ? markerSize : 0;

          e.y = visible ? _valueToY(e.value) : _xAxisTop;
      }

      if (!curve) continue;

      var e2 = entities[0] as _Point; // ignore: avoid_as
      var e3 = entities[1] as _Point; // ignore: avoid_as
      for (var j = 2; j < entityCount; j++) {
        final e1 = e2;
        e2 = e3;
        e3 = entities[j];
        if (e1.value == null) continue;
        if (e2.value == null) continue;
        if (e3.value == null) continue;
        final list = calculateControlPoints(
            e1.asPoint, e2.asPoint, e3.asPoint, curveTension);
        e2
          ..cp1 = list[0]
          ..cp2 = list[1]
          ..oldCp1 ??= new Point(e2.cp1.x, _xAxisTop)
          ..oldCp2 ??= new Point(e2.cp2.x, _xAxisTop);
      }
    }
  }

  @override
  void _seriesVisibilityChanged(int index) {
    _updateSeries(index);
    _calculateAverageYValues();
  }
}
