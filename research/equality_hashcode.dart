/// 独立研究三：什么时候要重写 == 与 hashCode，写错了会怎样
///
/// 研究问题：项目里的 Student 没有重写 ==，这是偷懒还是有意为之？
/// 如果要重写，有哪些必须守住的约束？不守会出什么故障？
///
/// 结论先说：
///   - Dart 默认的 == 是**引用比较**（等同于 identical），两个内容一样的对象不相等；
///   - 一旦按"内容"重写 ==，就**必须**同时重写 hashCode，否则放进
///     Set / Map 之后会出现"明明相等却查不到、去不掉重"的诡异现象；
///   - 参与 hashCode 的字段必须是**不可变的**，否则对象进 Set 之后再改字段，
///     就再也捞不出来了；
///   - 本项目里 Student 的 score 可变，所以刻意不给它做值相等语义，
///     只有 id + name 这种不可变字段才适合参与。
library;

import 'package:lecture3/student.dart';

// ================================================================
// 三个对照类
// ================================================================

/// 反面教材 A：完全不重写，用默认的引用比较
class IdentityStudent {
  final String id;
  final String name;

  IdentityStudent(this.id, this.name);

  @override
  String toString() => 'IdentityStudent($id,$name)';
}

/// 反面教材 B：只重写 == 不重写 hashCode（**故意的 Bug**）
///
/// 这是最常见的一类错误：单测里用 == 比对象能过，
/// 一放进 Set 去重就失效，而且不报错、静默出错，极难排查。
// ignore: hash_and_equals
class HalfBakedStudent {
  final String id;
  final String name;

  HalfBakedStudent(this.id, this.name);

  @override
  // 这里刻意不写 hashCode，就是要复现"只重写一半"的故障，
  // 所以显式关掉 hash_and_equals 这条规则（正常项目里绝不该关）。
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is HalfBakedStudent && other.id == id && other.name == name;

  // 这里本该有：
  //   @override
  //   int get hashCode => Object.hash(id, name);
  // 故意不写，用来看会发生什么。

  @override
  String toString() => 'HalfBakedStudent($id,$name)';
}

/// 正确写法：== 与 hashCode 配套，且只用不可变字段
class ValueStudent {
  final String id;
  final String name;

  ValueStudent(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueStudent &&
          other.runtimeType == runtimeType &&
          other.id == id &&
          other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'ValueStudent($id,$name)';
}

/// 用来演示"可变字段进了 hashCode"的坑
class MutableKey {
  int id;

  MutableKey(this.id);

  @override
  bool operator ==(Object other) => other is MutableKey && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MutableKey($id)';
}

// ================================================================
// 实验
// ================================================================

/// 实验一：默认的 == 是引用比较
void experimentDefaultEquality() {
  print('===== 实验一：默认 == 是引用比较 =====');

  final a = IdentityStudent('01', '甲');
  final b = IdentityStudent('01', '甲');

  print('a = $a');
  print('b = $b');
  print('  a == b           → ${a == b}      ← 内容完全一样，但因为不是同一个对象');
  print('  identical(a, b)  → ${identical(a, b)}');
  print('  a == a           → ${a == a}       ← 自反性：自己一定等于自己');
  print('  HashSet 去重后：${{a, b}.length} 个元素  ← 两个"重复"的学生都被留下了');

  final c = a;
  print('  final c = a; c == a → ${c == a}     ← 指向同一对象才相等');
  print('  结论：不重写 == 就是"身份相等"，两个人同名同姓也还是两个人。');
}

/// 实验二：只重写 == 不重写 hashCode 的故障
void experimentHalfBaked() {
  print('\n===== 实验二：只重写 ==、忘了 hashCode =====');

  final a = HalfBakedStudent('01', '甲');
  final b = HalfBakedStudent('01', '甲');

  print('a = $a, b = $b');
  print('  a == b                     → ${a == b}    ← == 说它们相等，看起来没问题');
  print('  a.hashCode == b.hashCode   → ${a.hashCode == b.hashCode}   ← 但哈希值不一样！');

  print('\n  这个自相矛盾的状态会造成三种静默故障：');
  final asSet = <HalfBakedStudent>{a, b};
  print('  ① Set 去重失效：{a, b} 里有 ${asSet.length} 个元素（期望 1 个）');
  print('     set.contains(b) → ${asSet.contains(b)}');

  final asMap = <HalfBakedStudent, double>{a: 92};
  print('  ② Map 查不到：map[a] = 92');
  print('     map[b] → ${asMap[b]}   ← b 明明"等于" a，却取不到值');

  final c = HalfBakedStudent('01', '甲');
  print('  ③ 删不掉：另造一个和 a 相等的 c，set.remove(c)');
  print('     set.remove(c) → ${asSet.remove(c)}，集合里还剩 ${asSet.length} 个元素');
  print('     （c 与 a 相等，理应能被删掉，却因为哈希值不同而找不到）');

  print('\n  根因：set 先按 hashCode 找桶，再用 == 在桶内比较。');
  print('        hashCode 不一致 → 连桶都找错，后面的 == 根本没机会执行。');

  print('\n  --- 对照组：List.contains 完全不受影响 ---');
  final list = <HalfBakedStudent>[a];
  print('     list = [a]，另造相等的 c');
  print('     list.contains(c) → ${list.contains(c)}   ← 居然是 true！');
  print('     list.indexOf(c)  → ${list.indexOf(c)}');
  print('     原因：List.contains / indexOf / remove 是**线性扫描**，只逐个调 ==，');
  print('           根本不用 hashCode，所以"只重写 == "在这条路径上看起来一切正常。');
  print('     这正是这个 Bug 难查的地方：');
  print('       List.contains(c) → true（正常）');
  print('       Set.contains(c)  → false（异常）');
  print('       同一份数据、同一个相等语义，换个容器结论就相反。');

  print('\n  结论：== 与 hashCode 是一份契约的两半——');
  print('        两个对象 == 为 true 时，hashCode 必须相同；');
  print('        hashCode 相同不代表 == 为 true（那只是哈希冲突，正常现象）。');
  print('        只写一半，所有基于哈希的容器（Set / Map / HashSet）全部行为异常。');
  print('        dart analyze 的 hash_and_equals 规则就是专门抓这个的。');
}

/// 实验三：配套重写之后一切正常
void experimentCorrect() {
  print('\n===== 实验三：== 与 hashCode 配套重写 =====');

  final a = ValueStudent('01', '甲');
  final b = ValueStudent('01', '甲');
  final c = ValueStudent('02', '乙');

  print('  a == b                     → ${a == b}');
  print('  a.hashCode == b.hashCode   → ${a.hashCode == b.hashCode}');
  print('  a == c                     → ${a == c}');

  final set = <ValueStudent>{a, b, c};
  print('  {a, b, c} 去重后 → ${set.length} 个元素：$set');

  final map = <ValueStudent, double>{a: 92};
  print('  map[a] = 92 之后，map[b] → ${map[b]}   ← 相等就能取到值了');

  print('\n  顺便验证等价关系的三条性质：');
  final d = ValueStudent('01', '甲');
  print('    自反 a == a              → ${a == a}');
  print('    对称 a == b 且 b == a    → ${a == b && b == a}');
  print('    传递 a == b 且 b == d 时 a == d → ${a == b && b == d && a == d}');
  print('  这三条必须成立，否则集合的行为会变得无法预测。');

  print('\n  与 String / int 的一致性：');
  print('    "abc" == "abc" → ${'abc' == 'abc'}  （String 已经重写过值相等）');
  print('    1 == 1         → ${1 == 1}');
  print('    [1] == [1]     → ${[1] == [1]}   ← List 没有重写，仍是引用比较');
  print('  结论：Dart 只给 String / num / bool / Symbol 等做了值相等，');
  print('        集合类型故意不做，因为可变容器的内容会变，做值相等反而危险。');
}

/// 实验四：可变字段进 hashCode 的坑
void experimentMutableHashCode() {
  print('\n===== 实验四：把可变字段写进 hashCode 的坑 =====');

  final key = MutableKey(1);
  final set = <MutableKey>{key};
  print('  key = $key，放进 Set 后 size = ${set.length}');
  print('  set.contains(key) → ${set.contains(key)}');

  print('\n  现在改掉 key 的 id（对象还是同一个，位置没动）：');
  key.id = 2;
  print('  key.id = 2 之后，key = $key');
  print('  set.contains(key) → ${set.contains(key)}   ← 自己都找不到自己了！');
  print('  set.length        → ${set.length}   ← 元素还在里面，但谁也拿不到了');
  print('  set.remove(key)   → ${set.remove(key)}，之后 size = ${set.length}');

  print('\n  原因：进 Set 时按 hashCode=1 放进了 1 号桶，');
  print('        改完字段后 hashCode 变成 2，查找时去 2 号桶找，自然找不到。');
  print('  结论：参与 hashCode 的字段必须是 final。');
  print('        如果一个字段天生要变（比如分数），那就别让它参与 == / hashCode，');
  print('        或者干脆不给这个类做值相等语义。');

  print('\n  那项目里的 Student 是怎么处理的？');
  final s = Student('01', '甲', 60);
  print('    Student 有可变的 _score，所以**刻意不重写 == 和 hashCode**：');
  print('    Student("01","甲",60) == Student("01","甲",60) → '
      '${Student('01', '甲', 60) == Student('01', '甲', 60)}');
  print('    这样它就永远只能按身份比较，不会因为改分而"从 Set 里消失"。');
  print('    需要判断"是不是同一个学生"时，项目里用 byId() 返回的 Map 按学号查，');
  print('    而不是依赖 ==。当前示例：$s');
}

/// 实验五：集合的哈希值怎么算
void experimentHashingUtilities() {
  print('\n===== 实验五：hashCode 的正确写法 =====');

  print('  ① 手写位运算（老旧写法，容易出错）：');
  print('     int get hashCode => id.hashCode ^ name.hashCode;');
  print('     问题：a^b 是对称的，hash("甲","乙") 和 hash("乙","甲") 会撞在一起。');

  print('\n  ② 官方推荐 Object.hash（本项目用法）：');
  print('     int get hashCode => Object.hash(id, name);');
  print('     它内部做了混合，顺序不同结果不同，且只有一次对象分配。');

  print('\n  ③ 字段很多时用 Object.hashAll：');
  print('     int get hashCode => Object.hashAll([id, name, className]);');

  print('\n  ④ 实测对比：');
  final x = ValueStudent('01', '甲');
  final y = ValueStudent('01', '乙');
  print('     ValueStudent("01","甲").hashCode = ${x.hashCode}');
  print('     ValueStudent("01","乙").hashCode = ${y.hashCode}');
  print('     两者不同 → ${x.hashCode != y.hashCode}（只是说明分布，不是必须）');

  print('\n  注意：hashCode 只要求"相等则同哈希"，**不要求"不同则不同哈希"**。');
  print('        上面这个结果是实现细节，不能写进测试断言里。');

  print('\n  ⑤ 如果要给 Student 加值相等语义，正确做法是：');
  print('     新增一个只由不可变字段决定的"身份"，例如：');
  print('       @override');
  print('       int get hashCode => Object.hash(id, name);   // 不含 score');
  print('     并把 == 也限定成比 id + name，让分数完全不影响相等判断。');
  print('     这样改分不会破坏 Set / Map，语义上也说得通——');
  print('     "同一个学生的分数变了"，他当然还是同一个学生。');
}

/// 主函数
void main() {
  print('==================================================');
  print(' 独立研究三：== 与 hashCode 的重写');
  print('==================================================\n');

  experimentDefaultEquality();
  experimentHalfBaked();
  experimentCorrect();
  experimentMutableHashCode();
  experimentHashingUtilities();

  print('\n==================================================');
  print(' 一句话总结');
  print('   重写 == 就必须重写 hashCode；参与哈希的字段必须 final；');
  print('   字段会变就别做值相等语义 —— 本项目 Student 的选择正是第三条。');
  print('==================================================');
}
