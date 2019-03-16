part of modern_charts;

final _pieChartDefaultOptions = <String, dynamic>{
  // num - If between 0 and 1, displays a donut chart. The hole with have a
  // radius equal to this value times the radius of the chart.
  'pieHole': 0,

  // Map - An object that controls the series.
  'series': {
    /// bool - Whether to draw the slices counterclockwise.
    'counterclockwise': false,

    // Map - An object that controls the series labels.
    'labels': {
      // bool - Whether to show the labels.
      'enabled': false,

      // (num) -> String - A function used to format the labels.
      'formatter': null,

      'style': {
        'color': 'white',
        'fontFamily': _fontFamily,
        'fontSize': 13,
        'fontStyle': 'normal'
      },
    },

    // num - The start angle in degrees. Default is -90, which is 12 o'clock.
    'startAngle': -90,
  },
};

const _clockwise = 1;
const _counterclockwise = -1;
const _highlightOuterRadiusFactor = 1.05;

/// A pie in a pie chart.
class _Pie extends _Entity {
  num oldStartAngle;
  num oldEndAngle;
  num startAngle;
  num endAngle;

  Point center;
  num innerRadius;
  num outerRadius;

  // [_Series] field.
  String name;

  bool get isEmpty => startAngle == endAngle;

  bool containsPoint(Point p) {
    final point = p - center;

    final mag = point.magnitude;
    if (mag > outerRadius || mag < innerRadius) return false;

    var angle = atan2(point.y, point.x);
    final chartStartAngle = (chart as PieChart)._startAngle;

    // Make sure [angle] is in range [chartStartAngle]..[chartStartAngle] + 2pi.
    angle = (angle - chartStartAngle) % _2pi + chartStartAngle;

    // If counterclockwise, make sure [angle] is in range
    // [start] - 2*pi..[start].
    if (startAngle > endAngle) angle -= _2pi;

    if (startAngle <= endAngle) {
      // Clockwise.
      return isInRange(angle, startAngle, endAngle);
    } else {
      // Counterclockwise.
      return isInRange(angle, endAngle, startAngle);
    }
  }

  @override
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight) {
    var a1 = lerp(oldStartAngle, startAngle, percent);
    var a2 = lerp(oldEndAngle, endAngle, percent);
    if (a1 > a2) {
      final tmp = a1;
      a1 = a2;
      a2 = tmp;
    }
    if (highlight) {
      final highlightOuterRadius = _highlightOuterRadiusFactor * outerRadius;
      ctx
        ..fillStyle = highlightColor
        ..beginPath()
        ..arc(center.x, center.y, highlightOuterRadius, a1, a2)
        ..arc(center.x, center.y, innerRadius, a2, a1, true)
        ..fill();
    }
    ctx
      ..fillStyle = color
      ..beginPath()
      ..arc(center.x, center.y, outerRadius, a1, a2)
      ..arc(center.x, center.y, innerRadius, a2, a1, true)
      ..fill()
      ..stroke();

    if (formattedValue != null && chart is PieChart && a2 - a1 > pi / 36) {
      final options = chart._options['series']['labels'];
      if (options['enabled']) {
        final r = .25 * innerRadius + .75 * outerRadius;
        final a = .5 * (a1 + a2);
        final p = polarToCartesian(center, r, a);
        ctx
          ..fillStyle = options['style']['color']
          ..fillText(formattedValue, p.x, p.y);
      }
    }
  }

  @override
  void save() {
    oldStartAngle = startAngle;
    oldEndAngle = endAngle;
    super.save();
  }
}

class PieChart extends Chart {
  Point _center;
  num _outerRadius;
  num _innerRadius;

  /// The start angle in radians.
  num _startAngle;

  /// 1 means clockwise and -1 means counterclockwise.
  num _direction;

  PieChart(Element container) : super(container) {
    _defaultOptions = extendMap(globalOptions, _pieChartDefaultOptions);
  }
  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();
    final rect = _seriesAndAxesBox;
    final halfW = rect.width >> 1;
    final halfH = rect.height >> 1;
    _center = new Point(rect.left + halfW, rect.top + halfH);
    _outerRadius = min(halfW, halfH) / _highlightOuterRadiusFactor;
    num pieHole = _options['pieHole'];
    if (pieHole > 1) pieHole = 0;
    if (pieHole < 0) pieHole = 0;
    _innerRadius = pieHole * _outerRadius;

    final opt = _options['series'];
    _entityValueFormatter =
        opt['labels']['formatter'] ?? _defaultValueFormatter;
    _direction = opt['counterclockwise'] ? _counterclockwise : _clockwise;
    _startAngle = deg2rad(opt['startAngle']);
  }

  @override
  void _dataRowsChanged(DataCollectionChangeRecord record) {
    _updateSeriesVisible(record.index, record.removedCount, record.addedCount);
    super._dataRowsChanged(record);
    _updateLegendContent();
  }

  @override
  bool _drawSeries(double percent) {
    _seriesContext
      ..lineWidth = 2
      ..strokeStyle = '#fff'
      ..textAlign = 'center'
      ..textBaseline = 'middle';
    //var pies = _seriesList.first.entities as List<_pie>;
    final labelOptions = _options['series']['labels'];
    _seriesContext.font = _getFont(labelOptions['style']);
    for (var e in _seriesList.first.entities) {
      final pie = e as _Pie;
      if (pie.isEmpty && percent == 1.0) continue;
      final highlight =
          pie.index == _focusedSeriesIndex || pie.index == _focusedEntityIndex;
      pie.draw(_seriesContext, percent, highlight);
    }

    return false;
  }

  @override
  int _getEntityGroupindex(num x, num y) {
    final p = new Point(x, y);
    final entities = _seriesList.first.entities;
    for (var i = entities.length - 1; i >= 0; i--) {
      // ignore: avoid_as
      final pie = entities[i] as _Pie;
      if (pie.containsPoint(p)) return i;
    }
    return -1;
  }

  @override
  List<String> _getLegendLabels() => _dataTable.getColumnValues(0);

  @override
  Point _getTooltipPosition() {
    final pie = _seriesList.first.entities[_focusedEntityIndex] as _Pie;
    final angle = .5 * (pie.startAngle + pie.endAngle);
    final radius = .5 * (_innerRadius + _outerRadius);
    final point = polarToCartesian(_center, radius, angle);
    final x = point.x - .5 * _tooltip.offsetWidth;
    final y = point.y - _tooltip.offsetHeight;
    return new Point(x, y);
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
    var startAngle = _startAngle;
    if (entityIndex > 0 && _seriesList != null) {
      final prevpie = _seriesList[0].entities[entityIndex - 1] as _Pie;
      startAngle = prevpie.endAngle;
    }
    return new _Pie()
      ..index = entityIndex
      ..value = value
      ..formattedValue = value != null ? _entityValueFormatter(value) : null
      ..name = name
      ..color = color
      ..highlightColor = highlightColor
      ..oldStartAngle = startAngle
      ..oldEndAngle = startAngle
      ..center = _center
      ..innerRadius = _innerRadius
      ..outerRadius = _outerRadius
      ..startAngle = startAngle
      ..endAngle = startAngle; // To be updated in [_updateSeries].
  }

  @override
  void _updateSeries([int index]) {
    // Example data table:
    //   Browser  Share
    //   Chrome   .35
    //   IE       .30
    //   Firefox  .20
    //   Other    .15

    var sum = 0.0;
    var startAngle = _startAngle;
    final pieCount = _dataTable.rows.length;
    //var pies = _seriesList[0].entities as List<_pie>;

    // Sum the values of all visible pies.
    for (var i = 0; i < pieCount; i++) {
      if (_seriesStates[i].index >= _VisibilityState.showing.index) {
        sum += (_seriesList[0].entities[i] as _Pie).value;
      }
    }

    for (var i = 0; i < pieCount; i++) {
      final pie = _seriesList[0].entities[i] as _Pie;
      final color = _getColor(i);
      pie
        ..index = i
        ..name = _dataTable.rows[i][0]
        ..color = color
        ..highlightColor = _getHighlightColor(color)
        ..center = _center;

      if (_seriesStates[i].index >= _VisibilityState.showing.index) {
        pie
          ..startAngle = startAngle
          ..endAngle = startAngle + _direction * pie.value * _2pi / sum;
        startAngle = pie.endAngle;
      } else {
        pie
          ..startAngle = startAngle
          ..endAngle = startAngle;
      }
    }
  }

  @override
  void _seriesVisibilityChanged(int index) => _updateSeries();

  @override
  void _updateTooltipContent() {
    final pie = _seriesList[0].entities[_focusedEntityIndex] as _Pie;
    _tooltip.style
      ..borderColor = pie.color
      ..padding = '4px 12px';
    final label = _tooltipLabelFormatter(pie.name);
    final value = _tooltipValueFormatter(pie.value);
    _tooltip.innerHtml = '$label: <strong>$value</strong>';
  }
}
