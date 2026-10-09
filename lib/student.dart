/// student.dart — Student 类：字段封装、命名构造、校验 setter
///
/// 对应实践指南三第二部分（类与构造函数）与课堂案例 dart_oo 步骤一。
library;

/// 学生成绩模型
///
/// 设计要点（自主实践任务 1：类设计合理性）：
/// - 三个字段：id 与 name 不可变（final），score 可改（因为要允许改分）
/// - score 用下划线前缀私有，外部只能通过 getter 读、通过 setter 改
/// - setter 内置范围校验，非法值直接抛 ArgumentError，杜绝脏数据进对象
/// - 提供命名构造函数 fromJson，作为从 Map/JSON 造对象的标准入口
class Student {
  /// 学号（不可变）
  final String id;

  /// 姓名（不可变）
  final String name;

  /// 分数（私有，只能通过 score getter/setter 访问）
  double _score;

  /// 主构造函数：位置参数 + 位置可选参数（分数默认 0）
  Student(this.id, this.name, [this._score = 0]) {
    // 构造体内也校验一次，防止绕过 setter 传入非法初值
    _validate(_score);
  }

  /// 命名构造函数：从 Map/JSON 造对象
  ///
  /// 初始化列表在构造体执行前运行。
  /// 用 `(json['score'] as num).toDouble()` 而不是直接 `as double`，
  /// 因为 JSON 里的整数（如 92）会被解析成 int，直接转 double 会抛类型错误。
  Student.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        _score = (json['score'] as num).toDouble() {
    _validate(_score);
  }

  /// 命名构造函数：只有学号姓名，分数默认 0
  Student.fresh(this.id, this.name) : _score = 0;

  /// 分数校验：越界直接抛错，不返回 false
  static void _validate(double v) {
    if (v < 0 || v > 100) {
      throw ArgumentError('分数越界：$v（应在 0~100 之间）');
    }
  }

  /// getter：外部只读
  double get score => _score;

  /// setter：带校验，非法值抛 ArgumentError
  set score(double v) {
    _validate(v);
    _score = v;
  }

  /// 是否及格（派生属性，用 getter 而不是存字段，避免两处数据不一致）
  bool get passed => _score >= 60;

  /// 等级档位
  String get grade {
    if (_score >= 90) return '优';
    if (_score >= 80) return '良';
    if (_score >= 70) return '中';
    if (_score >= 60) return '及格';
    return '不及格';
  }

  /// 转回 Map，便于打印与序列化
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': _score,
      };

  @override
  String toString() => 'Student($id, $name, ${_score.toStringAsFixed(1)})';
}
