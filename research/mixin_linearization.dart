/// 独立研究一：mixin 的线性化（linearization）顺序
///
/// 研究问题：一个类 with 了多个 mixin，如果它们覆盖了同一个方法，
/// 到底谁生效？方法里写 super.xxx() 又会调到谁？
///
/// 结论先说：Dart 的 mixin 应用是**从右往左**层层包裹的。
/// `class C extends Base with M1, M2` 得到的实际结构是
///     Base ← M1 ← M2
/// 所以 M2（最右边的）覆盖 M1，M2 里的 super 指向 M1，M1 里的 super 指向 Base。
/// 混入顺序一换，结果就整个反过来。
library;

import 'package:lecture3/gradebook.dart';
import 'package:lecture3/logger.dart';
import 'package:lecture3/student.dart';

// ================================================================
// 实验一：多个 mixin 覆盖同一方法时的生效顺序
// ================================================================

/// 基底类
class Base {
  String describe() => 'Base';
}

/// 第一个 mixin：先加自己的标记，再交给 super
mixin M1 on Base {
  @override
  String describe() => 'M1(${super.describe()})';
}

/// 第二个 mixin：同样是先加标记再交给 super
mixin M2 on Base {
  @override
  String describe() => 'M2(${super.describe()})';
}

/// 顺序一：先 M1 后 M2
class C1 extends Base with M1, M2 {}

/// 顺序二：先 M2 后 M1
class C2 extends Base with M2, M1 {}

// ================================================================
// 实验二：mixin 的 on 约束与抽象成员要求
// ================================================================

/// 声明了 on 约束的 mixin：只能混入 Base 及其子类
mixin RequiresBase on Base {
  String tagged() => 'RequiresBase+${describe()}';
}

/// 同时声明抽象成员：宿主必须自己实现 name
mixin NeedsName {
  String get name; // 抽象 getter，宿主必须实现

  String greet() => '你好，$name';
}

/// 宿主类：满足了 NeedsName 的要求
class NamedThing with NeedsName {
  @override
  final String name;

  NamedThing(this.name);
}

// ================================================================
// 实验三：真实项目里的顺序问题 —— GradeBook with Logger
// ================================================================

/// 给成绩册再加一层"带缩进的日志"，用来观察 super 链
mixin IndentedLogger on Logger {
  @override
  void log(String msg) {
    final indented = msg.split('\n').map((l) => '    $l').join('\n');
    super.log(indented);
  }
}

/// 最右边的 IndentedLogger 生效，它调 super.log 才落到 Logger.log
class IndentedGradeBook extends GradeBook with IndentedLogger {
  IndentedGradeBook(super.input);
}

/// 反过来：把 Logger 放在右边，IndentedLogger 就完全不起作用了
class PlainGradeBook extends GradeBook with IndentedLogger, Logger {
  PlainGradeBook(super.input);
}

/// 主函数
void main() {
  print('==================================================');
  print(' 独立研究一：mixin 的线性化顺序');
  print('==================================================\n');

  // ---------- 实验一 ----------
  print('===== 实验一：覆盖顺序 =====');
  print('C1 = Base with M1, M2  →  ${C1().describe()}');
  print('C2 = Base with M2, M1  →  ${C2().describe()}');
  print('');
  print('解读：');
  print('  C1 里最右边的 M2 最先被调用，它的 super 落到 M1，M1 的 super 落到 Base；');
  print('  C2 只是把 with 后面的顺序调换，整条调用链就倒了过来。');
  print('  所以"谁能覆盖谁"只由 with 列表里**从右到左**的位置决定，');
  print('  跟 mixin 的定义顺序、跟 extends 的类都没关系。');

  // ---------- 实验二 ----------
  print('\n===== 实验二：on 约束与抽象成员 =====');
  final withRequiresBase = _WithRequiresBase();
  print('on Base 的 mixin 可以正常混入子类：${withRequiresBase.tagged()}');
  print('宿主实现了抽象 getter 后 greet() 可用：${NamedThing('成绩册').greet()}');
  print('');
  print('解读：');
  print('  - on Base 让"混入到无关类"变成**编译错误**，把运行时才炸的问题提前到编译期；');
  print('  - NeedsName 只声明 String get name 而不实现，宿主类不实现就编译不过——');
  print('    这正是我们项目里 Formattable / Validated 的写法。');
  print('  验证方式：另外写了一个 class Bad extends Unrelated with RequiresBase，');
  print('  用 dart analyze 分析，确实在**编译期**报错（不是运行期）：');
  print('    error - mixin_application_not_implemented_interface:');
  print('      \'RequiresBase\' can\'t be mixed onto \'Unrelated\' because');
  print('      \'Unrelated\' doesn\'t implement \'Base\'.');
  print('  验证完就把那个临时文件删掉了（完整记录见 progress.md）。');

  // ---------- 实验三 ----------
  print('\n===== 实验三：项目里的真实影响 =====');
  print('--- IndentedGradeBook（IndentedLogger 在右，缩进生效）---');
  IndentedGradeBook(const <Student>[]).log('这一行应该带 4 空格缩进');

  print('\n--- PlainGradeBook（Logger 在右，缩进被绕过）---');
  PlainGradeBook(const <Student>[]).log('这一行没有缩进');

  print('');
  print('解读：');
  print('  两个类的 extends 和字段完全一样，只是 with 列表顺序不同，');
  print('  PlainGradeBook 里 IndentedLogger 的 log 被它右边的 Logger.log 覆盖掉了，');
  print('  于是"缩进"这个功能静默失效——这正是线性化顺序最容易踩的坑。');

  // ---------- 边界探究 ----------
  print('\n===== 附：线性化顺序的形式化表述 =====');
  print('对 class C extends B with M1, M2, M3，Dart 会合成为：');
  print('    Object → B → M1 → M2 → M3 → C');
  print('查找某个方法时从右往左找第一个定义；super 则继续往左找。');
  print('所以"最右边优先"不是特例，而是这条线性链上从左到右搜索的直接结果。');

  final students = [
    Student('01', '甲', 92),
    Student('02', '乙', 55),
  ];
  final book = GradeBook(students);
  print('\n附：项目里的 GradeBook 同时是 Logger（混入）与 Object（根类），');
  print('    混入没有占用 extends 位置，DetailedGradeBook 才能继续 extends GradeBook，');
  print('    这就是"用 mixin 替代一层继承"的实际收益。当前人数：${book.count}');
}

/// 用来验证 on 约束的宿主类（必须 extends Base 才能混入 RequiresBase）
class _WithRequiresBase extends Base with RequiresBase {}
