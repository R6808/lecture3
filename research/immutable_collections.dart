/// 独立研究二：Dart 集合的"不可变"到底有几种，各自能挡住什么
///
/// 研究问题：想让成绩册的数据不被外部改坏，一共有哪些写法？
/// 它们之间有什么区别？哪个才是真正安全的？
///
/// 结论先说：Dart 里"不可变"有三个层次，容易被混为一谈：
///   1. 不给你改的**引用**（final 变量）—— 只锁变量，不锁内容
///   2. 不给你改的**视图/包装**（List.unmodifiable、toList(growable: false)）
///      —— 改就抛 UnsupportedError，但是**浅拷贝**，里面的元素照样能改
///   3. 编译期常量（const 列表）—— 真正的深度不可变 + 规范化（相同内容共享同一个对象）
///
/// 本项目里 GradeBook 用的是第 2 种（List.unmodifiable），
/// 因为成绩册需要在运行时动态构造，用不了 const；而元素 Student 的可变性
/// 由它自己的 setter 校验来管——这是刻意的分层，不是漏掉了。
library;

import 'package:lecture3/gradebook.dart';
import 'package:lecture3/student.dart';

/// 演示 1：final 变量锁不住内容
void experimentFinalVariable() {
  print('===== 实验一：final 只锁变量，不锁内容 =====');

  final list = <int>[1, 2, 3];
  print('final list = [1, 2, 3]');
  list.add(4);
  list[0] = 99;
  print('  执行 list.add(4) 与 list[0] = 99 之后：$list');
  print('  结论：final 只是"这个变量不能重新指向别的列表"，内容随便改。');
  print('  想挡住内容修改，必须换容器，而不是加 final。');
}

/// 演示 2：三种"只读"容器的实际差别
void experimentReadOnlyContainers() {
  print('\n===== 实验二：三种只读容器的差别 =====');

  final source = <int>[1, 2, 3];

  final unmodifiable = List<int>.unmodifiable(source);
  final fixedLength = List<int>.from(source, growable: false);
  const canonical = <int>[1, 2, 3];

  print('List.unmodifiable([1,2,3])      → $unmodifiable');
  print('List.from(..., growable: false) → $fixedLength');
  print('const <int>[1,2,3]              → $canonical');

  print('\n--- 逐个测试"改长度"是否被拦 ---');
  _try('unmodifiable.add(4)', () => unmodifiable.add(4));
  _try('fixedLength.add(4)', () => fixedLength.add(4));
  _try('canonical.add(4)  ', () => canonical.add(4));

  print('\n--- 逐个测试"改元素"是否被拦（关键差异！）---');
  _try('unmodifiable[0] = 9', () => unmodifiable[0] = 9);
  _try('fixedLength[0] = 9 ', () => fixedLength[0] = 9);
  _try('canonical[0] = 9   ', () => canonical[0] = 9);

  print('\n  结论（这是最容易踩的坑）：');
  print('  - List.unmodifiable 长度和元素都拦；');
  print('  - growable: false 只拦"改长度"，**元素照样能改**，不是真的只读；');
  print('  - const 列表两者都拦。');

  print('\n--- 原列表被改动后，unmodifiable 会不会跟着变？---');
  final original = <int>[1, 2, 3];
  final snapshot = List<int>.unmodifiable(original);
  original.add(4);
  original[0] = 99;
  print('  原列表改成 $original 后，snapshot = $snapshot');
  print('  结论：List.unmodifiable 会**拷贝**一份，是快照，之后原列表怎么改都不影响它。');
}

/// 演示 3：不可变只是浅层的 —— 元素本身照样能改
void experimentShallowCopyTrap() {
  print('\n===== 实验三：浅拷贝陷阱（不可变容器，可变元素）=====');

  final students = <Student>[Student('01', '甲', 60)];
  final frozen = List<Student>.unmodifiable(students);

  print('容器已冻结，尝试 frozen.add(...)：');
  _try('  frozen.add(新学生)', () => frozen.add(Student('02', '乙', 70)));

  print('但元素自己还是可变对象，改它的分数不会被拦：');
  frozen[0].score = 95;
  print('  执行 frozen[0].score = 95 之后：${frozen[0]}');
  print('  结论：List.unmodifiable 保护的是"名单"，不是"名单上每个人的分数"。');
  print('  分数这一层的安全由 Student 的 setter 校验负责（越界照样抛错），');
  print('  所以本项目是"容器冻结 + 元素自带校验"两层配合，而不是指望一层包住所有。');
}

/// 演示 4：const 的规范化（canonicalization）
void experimentConstCanonicalization() {
  print('\n===== 实验四：const 的规范化 =====');

  const a = <int>[1, 2, 3];
  const b = <int>[1, 2, 3];
  final c = <int>[1, 2, 3];

  print('const a = [1,2,3]; const b = [1,2,3]; final c = [1,2,3];');
  print('  identical(a, b) = ${identical(a, b)}   ← 内容相同的 const 共享同一个对象');
  print('  identical(a, c) = ${identical(a, c)}   ← c 是运行时新建的，不是同一个');
  print('  a == c          = ${a == c}            ← List 的 == 是引用比较，不是逐元素比较');
  print('  结论 1：const 会被编译器规范化，相同内容只存一份，省内存；');
  print('  结论 2：Dart 的 List/Map 没有重写 ==，a == c 是 false，');
  print('          要比内容必须用 listEquals 或自己逐元素比。');
}

/// 演示 5：项目里的实际用法为什么长这样
void experimentProjectUsage() {
  print('\n===== 实验五：GradeBook 里的设计取舍 =====');

  final input = <Student>[Student('01', '甲', 92), Student('02', '乙', 55)];
  final book = GradeBook(input);

  print('构造 GradeBook 后，外部拿着原列表试着改：');
  input.add(Student('03', '丙', 100));
  print('  原列表加了 1 人，成绩册人数 = ${book.count}（没有被影响，因为构造时拷贝了）');

  print('外部直接改成绩册自己的列表：');
  _try('  book.students.add(...)', () => book.students.add(Student('04', '丁', 70)));
  _try('  book.students[0] = ...', () => book.students[0] = Student('04', '丁', 70));

  print('那排序怎么办？内部列表不可变，sort 会失败，所以是先复制再排序：');
  _try('  book.students.sort(...)  直接排内部列表',
      () => book.students.sort((x, y) => x.score.compareTo(y.score)));
  final sorted = book.sortedByScoreDesc();
  print('  book.sortedByScoreDesc() → ${sorted.map((s) => '${s.name}${s.score}').join('、')}');
  print('  内部顺序仍为 → ${book.students.map((s) => '${s.name}${s.score}').join('、')}');
  print('  结论：sortedByScoreDesc 里那句 [...students]..sort(...) 的复制不是多余的，');
  print('        少了它就会直接抛 UnsupportedError。');

  print('\n--- Map / Set 也有对应的不可变包装 ---');
  final m = Map<String, int>.unmodifiable({'a': 1});
  final s = Set<int>.unmodifiable({1, 2});
  _try('  map["b"] = 2', () => m['b'] = 2);
  _try('  set.add(3)  ', () => s.add(3));
  print('  注意：只有 List.unmodifiable / Map.unmodifiable / Set.unmodifiable 三个工厂，');
  print('        没有"不可变 List 视图"这种东西，想只读视图得自己写包装类。');
}

/// 跑一段可能抛错的代码，把异常类型与消息打出来
void _try(String label, void Function() action) {
  try {
    action();
    print('    $label → 没有报错（居然改成功了！）');
  } catch (e) {
    print('    $label → ${e.runtimeType}');
  }
}

/// 主函数
void main() {
  print('==================================================');
  print(' 独立研究二：集合的不可变');
  print('==================================================\n');

  experimentFinalVariable();
  experimentReadOnlyContainers();
  experimentShallowCopyTrap();
  experimentConstCanonicalization();
  experimentProjectUsage();

  print('\n==================================================');
  print(' 总结：选哪种"不可变"取决于要挡谁');
  print('   挡外部改名单        → List.unmodifiable（本项目采用，运行期构造）');
  print('   挡外部改长度        → toList(growable: false)（元素仍可改）');
  print('   编译期就定死        → const 列表（还能省内存，但只能放常量）');
  print('   挡元素被改坏        → 靠元素自己的 setter 校验，容器帮不上忙');
  print('==================================================');
}
