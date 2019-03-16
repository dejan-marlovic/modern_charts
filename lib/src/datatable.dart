library chart.src.datatable;

import 'dart:async';
import 'dart:collection';

class DataCellChangeRecord {
  final int rowIndex;
  final int columnIndex;
  final Object oldValue;
  final Object newValue;
  DataCellChangeRecord(
      this.rowIndex, this.columnIndex, this.oldValue, this.newValue);
  String toString() =>
      'DataCellChangeRecord { rowIndex: $rowIndex, colIndex; $columnIndex, $oldValue, $newValue }';
}

class DataCollectionChangeRecord {
  final int index;
  final int addedCount;
  final int removedCount;
  DataCollectionChangeRecord(this.index, this.addedCount, this.removedCount);

  String toString() =>
      'DataCollectionChangeRecord { index: $index, added: $addedCount, removed: $removedCount}';
}

class _TableEntity {
  int _index;
  DataTable _table;

  int get index => _index;
  DataTable get table => _table;
}

class DataRow extends _TableEntity {
  /// The list that stores the actual data.
  List <Object>_cells;

  /// Creates a new [DataRow] from a list of values.
  ///
  ///  Each value in [values] corresponds to a column. If [values] is too short,
  /// the remaining columns are filled with `null`.
  DataRow._internal(DataTable table, List values) {
    _table = table;
    final n = _table._columns.length;
    final m = values.length;
    var min = m;
    if (min > n) min = n;
    _cells = values.sublist(0, min);
    for (var i = min; i < n; i++) {
      _cells.add(null);
    }
  }

  /// Converts a column index or name to an index.
  int _toIndex(columnIndexOrName) {
    if (columnIndexOrName is num) {
      return columnIndexOrName;
    } else {
      return _table._columnIndexByName[columnIndexOrName];
    }
  }

  /// Returns the value of the column specified by [columnIndexOrName].
  Object operator [](Object columnIndexOrName) => _cells[_toIndex(columnIndexOrName)];

  /// Sets the value of the column specified by [columnIndexOrName].
  void operator []=(Object columnIndexOrName, Object value) {
    final columnIndex = _toIndex(columnIndexOrName);
    final oldValue = _cells[columnIndex];
    _cells[columnIndex] = value;
    _table._onCellChanged(_index, columnIndex, oldValue, value);
  }

  /// Creates a [List] containing all cells in this [DataRow].
  List toList({bool growable: true}) => _cells.toList(growable: growable);
}

class DataColumn extends _TableEntity {
  String _name;
  Type _dataType;

  DataColumn(this._name, this._dataType);

  /// The name of the column.
  String get name => _name;

  /// The type of data stored in the column.
  Type get dataType => _dataType;
}

class DataCollectionIterator<E extends _TableEntity> implements Iterator<E> {
  final DataCollectionBase<E> _iterable;
  final int _length;
  int _index;
  E _current;

  DataCollectionIterator(DataCollectionBase<E> iterable)
      : _iterable = iterable,
        _length = iterable.length,
        _index = 0;

  E get current => _current;

  bool moveNext() {
    final length = _iterable.length;
    if (_length != length) {
      throw new ConcurrentModificationError(_iterable);
    }
    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable.elementAt(_index);
    _index++;
    return true;
  }
}

class DataCollectionBase<E extends _TableEntity> extends ListBase<E> {
  List<E> _base;
  DataTable _table;

  DataCollectionBase(DataTable table)
      : _base = <E>[],
        _table = table;

  void _releaseItems(int start, int end) {
    var s = start;
    while (s < end) {
      _base[s]._table = null;
      s++;
    }
  }

  void _updateItems(int start) {
    var s = start;
    final len = length;
    while (s < len) {
      _base[s]
        .._table = _table
        .._index = s++;
    }
  }

  @override
  Iterator<E> get iterator => new DataCollectionIterator<E>(this);

  @override
  E get first => _base.first;

  @override
  E get last => _base.last;

  @override
  E get single => _base.single;

  @override
  int get length => _base.length;

  @override
  set length(int value) {
    // TODO: implement.
    throw new UnimplementedError();
  }

  @override
  E operator [](int index) => _base[index];

  @override
  void operator []=(int index, E value) {
    // TODO: implement.
    throw new UnimplementedError();
  }

  void add(E value) {
    final index = length;
    _base.add(value);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, 1);
  }

  void addAll(Iterable<E> iterable) {
    final index = length;
    _base.addAll(iterable);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, iterable.length);
  }

  @override
  E elementAt(int index) => _base[index];

  void insert(int index, E value) {
    _base.insert(index, value);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, 1);
  }

  void insertAll(int index, Iterable<E> iterable) {
    _base.insertAll(index, iterable);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, iterable.length);
  }

  bool remove(Object element) {
    final index = _base.indexOf(element);
    if (index == -1) return false;
    removeAt(index);
    return true;
  }

  void clear() {
    final len = length;
    if (len == 0) return;
    _releaseItems(0, len);
    _base.clear();
    _table._onRowsOrColumnsRemoved(this, 0, len);
  }

  E removeAt(int index) {
    final e = _base.removeAt(index).._table = null;
    _updateItems(index);
    _table._onRowsOrColumnsRemoved(this, index, 1);
    return e;
  }

  E removeLast() {
    final e = _base.removeLast().._table = null;
    _table._onRowsOrColumnsRemoved(this, length, 1);
    return e;
  }

  void removeRange(int start, int end) {
    _releaseItems(start, end);
    _base.removeRange(start, end);
    _updateItems(start);
    _table._onRowsOrColumnsRemoved(this, start, end - start);
  }
}

class DataRowCollection extends DataCollectionBase<DataRow> {
  DataRowCollection(DataTable table) : super(table);

  DataRow _toDataRow(value) =>
      value is DataRow ? value : new DataRow._internal(_table, value);

  /// Adds [value] to this collection.
  ///
  /// [value] can be a [DataRow] or a [List].
  @override
  void add(Object value) {
    super.add(_toDataRow(value));
  }

  /// Adds all elements of [iterable] to this collection.
  ///
  /// Each element in [iterable] can be a [DataRow] or a [List].
  @override
  void addAll(Iterable iterable) {
    super.addAll(iterable.map(_toDataRow));
  }

  /// Inserts [value] at position [index] in this collection.
  ///
  /// [value] can be a [DataRow] or a [List].
  @override
  void insert(int index, Object value) {
    super.insert(index, _toDataRow(value));
  }

  /// Inserts all elements of [iterable] at position [index] in this collection.
  ///
  /// Each element in [iterable] can be a [DataRow] or a [List].
  @override
  void insertAll(int index, Iterable iterable) {
    super.insertAll(index, iterable.map(_toDataRow));
  }
}

class DataColumnCollection extends DataCollectionBase<DataColumn> {
  DataColumnCollection(DataTable table) : super(table);

  /// Adds a new column given its [name] and [type].
  void add2(String name, Type type) {
    add(new DataColumn(name, type));
  }
}

class DataTable {
  Map<String, int> _columnIndexByName;
  DataColumnCollection _columns;
  DataRowCollection _rows;

  StreamController<DataCellChangeRecord> _cellChangeController;
  StreamController<DataCollectionChangeRecord> _columnsChangeController;
  StreamController<DataCollectionChangeRecord> _rowsChangeController;

  /// Creates a [DataTable] with optional data [data].
  ///
  /// The first row in [data] contains the column names.
  /// The data type of each column is determined by the first non-null value
  /// in that column.
  ///
  /// All values in each column are expected to be of the same type,
  /// and all rows are expected to have the same length.
  DataTable([List<List> data]) {
    _columnIndexByName = <String, int>{};
    _rows = new DataRowCollection(this);
    _columns = new DataColumnCollection(this);

    if (data == null) return;

    final colCount = data.first.length;
    final rowCount = data.length;

    for (var colIndex = 0; colIndex < colCount; colIndex++) {
      final name = data[0][colIndex];
      var type = Object;
      for (var rowIndex = 1; rowIndex < rowCount; rowIndex++) {
        final value = data[rowIndex][colIndex];
        if (value == null) continue;
        if (value is String) type = String;
        if (value is num) type = num;
        if (value is List) type = List;
        break;
      }
      _columns.add2(name, type);
    }

    _rows.addAll(data.getRange(1, rowCount));
  }

  void _onCellChanged(int rowIndex, int columnIndex, oldValue, newValue) {
    if (_cellChangeController != null) {
      final record =
          new DataCellChangeRecord(rowIndex, columnIndex, oldValue, newValue);
      _cellChangeController.add(record);
    }
  }

  void _onRowsOrColumnsInserted(
      DataCollectionBase source, int index, int count) {
    final record = new DataCollectionChangeRecord(index, count, 0);
    if (source == _columns) {
      _insertColumns(index, count);
      _updateColumnIndexes(index);
      _columnsChangeController?.add(record);
    } else {
      _rowsChangeController?.add(record);
    }
  }

  void _onRowsOrColumnsRemoved(
      DataCollectionBase source, int index, int count) {
    final record = new DataCollectionChangeRecord(index, 0, count);
    if (source == _columns) {
      _removeColumns(index, count);
      _updateColumnIndexes(index);
      _columnsChangeController?.add(record);
    } else {
      _rowsChangeController?.add(record);
    }
  }

  void _insertColumns(int start, int count) {
    for (var row in _rows) {
      row._cells.insertAll(start, <int>[count]);
    }
  }

  void _removeColumns(int start, int count) {
    for (var row in _rows) {
      row._cells.removeRange(start, start + count);
    }
  }

  void _updateColumnIndexes(int start) {
    final end = _columns.length;
    var s = start;
    while (s < end) {
      _columnIndexByName[_columns[start].name] = s++;
    }
  }

  /// The columns in this [DataTable].
  DataColumnCollection get columns => _columns;

  /// The rows (without the header row) in this [DataTable].
  DataRowCollection get rows => _rows;

  /// Fired when a cell is changed.
  Stream<DataCellChangeRecord> get onCellChange {
    _cellChangeController ??= new StreamController.broadcast(
        sync: true,
        onCancel: () {
          _cellChangeController = null;
        });
    return _cellChangeController.stream;
  }

  /// Fired when [columns] are changed.
  Stream<DataCollectionChangeRecord> get onColumnsChange {
    _columnsChangeController ??= new StreamController.broadcast(
        sync: true,
        onCancel: () {
          _columnsChangeController = null;
        });
    return _columnsChangeController.stream;
  }

  /// Fired when [rows] are changed.
  Stream<DataCollectionChangeRecord> get onRowsChange {
    _rowsChangeController ??= new StreamController.broadcast(
        sync: true,
        onCancel: () {
          _rowsChangeController = null;
        });
    return _rowsChangeController.stream;
  }

  /// Gets the index of the column specified by [name].
  int getColumnIndexByName(String name) {
    if (_columnIndexByName.containsKey(name)) {
      return _columnIndexByName[name];
    }
    return -1;
  }

  /// Gets the values of the column specified by [columnIndex].
  List<String> getColumnValues(int columnIndex) {
    final list = <String>[];
    for (var row in _rows) {
      list.add(row[columnIndex]);
    }
    return list;
  }
}
