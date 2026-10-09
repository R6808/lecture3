/// dart_oo.dart — 统一入口
///
/// 对应实践指南三第五部分：课堂案例复现 dart_oo。
/// 运行 `dart run bin/dart_oo.dart` 可以看到全部演示输出。
/// 运行 `dart test` 可以看到单元测试结果。
library;

import 'package:lecture3/gradebook.dart';
import 'package:lecture3/logger.dart';
import 'package:lecture3/student.dart';

/// 构造演示数据
List<Student> buildSampleStudents() => [
      Student('01', '李华', 92),
      Student('02', '王芳', 55),
      Student('03', '张伟', 78),
      Student.fromJson({'id': '04', 'name': '刘敏', 'score': 88}),
      Student.fromJson({'id': '05', 'name': '陈静', 'score': 61}),
      Student.fresh('06', '赵磊'), // 分数默认 0
      Student('07', '孙悦', 100),
    ];

/// 演示封装与校验
void demoEncapsulation() {
  print('===== 1. 类的封装与校验 =====');

  final s = Student('01', '李华', 92);
  print('创建：$s');
  print('读取分数（getter）：${s.score}');
  print('是否及格（派生 getter）：${s.passed}');
  print('等级：${s.grade}');

  // 通过 setter 合法改分
  s.score = 85;
  print('setter 改成 85 后：${s.score}（等级 ${s.grade}）');

  // setter 非法值：逐个捕获异常，证明校验生效。
  // 这里声明一个局部函数，forEach 传的是它的 tear-off（不是匿名闭包），
  // 于是全项目统计与遍历部分都没有任何手写 for 循环。
  void trySet(double v) {
    try {
      s.score = v;
      print('  设置 $v：错误！竟然没有抛异常');
    } on ArgumentError catch (e) {
      print('  设置 $v：已拦截 → ${e.message}');
    }
  }

  [-1.0, 101.0, 200.0].forEach(trySet);
  print('  改分失败后分数仍是：${s.score}（说明非法赋值没有写进对象）');

  // 命名构造函数 fromJson：注意 JSON 里 score 是 int，需要转 double
  final fromJson = Student.fromJson({'id': '09', 'name': '周涛', 'score': 77});
  print('fromJson 构造：$fromJson');
  print('  score 的运行时类型：${fromJson.score.runtimeType}（JSON 里是 int，已转成 double）');
}

/// 判断一个对象是否具备 Logger 能力
///
/// 形参声明成 Object，让这个 is 判断在编译期无法被静态确定，
/// 从而真实地在运行时验证混入是否生效。
bool _isLogger(Object o) => o is Logger;

/// 演示 Logger mixin：GradeBook 通过 with 获得了日志能力
void demoLoggerMixin() {
  print('\n===== 2. Logger mixin =====');

  final book = GradeBook(buildSampleStudents());
  print('GradeBook 的类型链：');
  print('  book is Logger → ${_isLogger(book)}');
  print('  book.logTag    → ${book.logTag}');
  print('  下面这行日志由 mixin 提供，GradeBook 自己并没有定义 log 方法：');
  book.log('这条日志来自 Logger mixin');
}

/// 演示 Validated mixin 的约定式用法
void demoValidatedMixin() {
  print('\n===== 3. Validated mixin（声明抽象 getter，宿主实现）=====');

  final ok = _Report()..ready = true;
  final bad = _Report();

  try {
    ok.check();
    print('  校验通过的报告：check() 未抛错');
  } on StateError catch (e) {
    print('  意外：${e.message}');
  }

  try {
    bad.check();
    print('  意外：应当抛错却没有');
  } on StateError catch (e) {
    print('  未就绪的报告：check() 抛错 → ${e.message}');
  }
}

/// 用 Validated 的宿主类
class _Report with Validated {
  bool ready = false;

  @override
  bool get isValid => ready;
}

/// 主入口
void main() {
  print('==================================================');
  print(' 课堂作业三 · Dart 语言基础二：面向对象与集合');
  print(' 课堂案例复现 dart_oo');
  print(' 姓名：容磊　学号：20251060108');
  print('==================================================\n');

  demoEncapsulation();
  demoLoggerMixin();
  demoValidatedMixin();

  print('\n===== 4. 成绩册统计（全部用集合链式方法）=====');
  final book = GradeBook(buildSampleStudents());
  book.printReport();

  print('\n===== 5. 边界情况 =====');
  final empty = GradeBook.empty();
  print('空成绩册人数：${empty.count}');
  print('空成绩册平均分：${empty.average}（已做空判断，不会除以 0）');

  print('\n==================================================');
  print(' 全部演示执行完毕');
  print('==================================================');
}
