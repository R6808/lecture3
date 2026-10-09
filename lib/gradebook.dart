/// gradebook.dart — GradeBook 类：全部统计用集合链式方法实现
///
/// 对应实践指南三第四部分（泛型与集合）与课堂案例 dart_oo 步骤二。
/// 硬性要求：统计功能**禁止手写 for 循环**，一律用 Iterable 高阶方法链。
library;

import 'logger.dart';
import 'student.dart';

/// 成绩册
///
/// 用 with 混入 Logger，获得日志能力而不占用继承位。
class GradeBook with Logger {
  /// 内部用 List 承载（List 有序、可重复，符合"成绩册有一行行记录"的语义）
  final List<Student> students;

  /// 构造时接收列表；用 List.unmodifiable 包一层，
  /// 防止外部拿到引用后绕过本类直接改数据。
  GradeBook(List<Student> input) : students = List.unmodifiable(input);

  /// 空成绩册
  GradeBook.empty() : students = const [];

  /// 学生人数
  int get count => students.length;

  /// 平均分
  ///
  /// fold 把整个列表"折叠"成一个值：第一个参数是初始值，
  /// 第二个参数是累加函数（sum 是累计值，s 是当前元素）。
  double get average {
    if (students.isEmpty) return 0;
    final total = students.fold<double>(0, (sum, s) => sum + s.score);
    return double.parse((total / students.length).toStringAsFixed(2));
  }

  /// 最高分学生
  ///
  /// 用 reduce 做"打擂台"：没有初始值，直接用第一个元素当擂主。
  /// 注意 students 非空时才可调用，否则 reduce 会抛 StateError。
  Student get maxBy => students.reduce((a, b) => a.score >= b.score ? a : b);

  /// 最低分学生
  Student get minBy => students.reduce((a, b) => a.score <= b.score ? a : b);

  /// 及格人数：where 筛选后取长度
  int get countPassed => students.where((s) => s.passed).length;

  /// 不及格学生姓名列表：where 筛选 → map 取值 → toList 落地
  List<String> get failedNames =>
      students.where((s) => !s.passed).map((s) => s.name).toList();

  /// 按等级分档：fold 把列表折叠成一个 Map
  ///
  /// putIfAbsent：键不存在时先放一个空列表再 add，避免"先判断再赋值"的分支。
  Map<String, List<Student>> groupByGrade() {
    return students.fold(<String, List<Student>>{}, (map, s) {
      map.putIfAbsent(s.grade, () => <Student>[]).add(s);
      return map;
    });
  }

  /// 按学号建索引：集合 for 生成器写法
  Map<String, Student> byId() => {for (final s in students) s.id: s};

  /// 按分数降序排列（**不修改原列表**）
  ///
  /// `[...students]` 先复制一份再排序，否则 sort 会原地改动内部列表，
  /// 而内部列表是 unmodifiable 的，直接 sort 会抛 UnsupportedError。
  List<Student> sortedByScoreDesc() =>
      [...students]..sort((a, b) => b.score.compareTo(a.score));

  /// ---------------------------------------------------------------
  /// 自主实践任务 3：集合统计链
  ///
  /// 下面这一串连续使用了 **7 个**链式方法：
  /// where → map → where → fold → any → every → firstWhere
  /// 目标是算出"80 分以上学生的加分后总分，并判断整体是否达标"。
  /// ---------------------------------------------------------------
  Map<String, dynamic> advancedReport({double bonus = 5}) {
    // ① where：筛出分数 >= 80 的学生
    final topGroup = students.where((s) => s.score >= 80);

    // ② map：把每个学生映射成"加分后的分数"
    final boosted = topGroup.map((s) => s.score + bonus);

    // ③ where：再筛一次，去掉加分后仍不足 85 的
    final qualified = boosted.where((v) => v >= 85);

    // ④ fold：把筛选后的分数累加成总分
    final sum = qualified.fold<double>(0, (acc, v) => acc + v);

    // ⑤ any：是否存在满分学生
    final hasFull = students.any((s) => s.score == 100);

    // ⑥ every：是否所有人都有学号（演示 every 的语义）
    final allHasId = students.every((s) => s.id.isNotEmpty);

    // ⑦ firstWhere：找出第一个不及格的学生；找不到时用 orElse 兜底，
    //    否则 firstWhere 会抛 StateError
    final firstFailed = students.firstWhere(
      (s) => !s.passed,
      orElse: () => Student('--', '（无不及格）', 0),
    );

    return {
      '参与人数': students.length,
      '80分以上人数': topGroup.length,
      '加分后达标人数': qualified.length,
      '加分后总分': sum,
      '存在满分学生': hasFull,
      '全部有学号': allHasId,
      '首个不及格': firstFailed.name,
    };
  }

  /// 打印完整统计报告
  void printReport() {
    logTitle('成绩册统计报告');
    log('人数：$count');
    log('平均分：$average');
    log('最高分：${maxBy.name}（${maxBy.score}）');
    log('最低分：${minBy.name}（${minBy.score}）');
    log('及格人数：$countPassed');
    log('不及格名单：${failedNames.isEmpty ? '无' : failedNames.join('、')}');

    log('--- 按等级分档 ---');
    final grouped = groupByGrade();
    // 排序后再打印：Map 的遍历顺序不应被依赖
    // 全程用 map + join 拼字符串，不使用手写循环
    log(
      (grouped.keys.toList()..sort())
          .map((k) => '  $k（${grouped[k]!.length} 人）：'
              '${grouped[k]!.map((s) => s.name).join('、')}')
          .join('\n'),
    );

    log('--- 按分数降序 ---');
    log(
      sortedByScoreDesc()
          .map((s) => '  ${s.name}：${s.score}（${s.grade}）')
          .join('\n'),
    );

    log('--- 统计链结果 ---');
    advancedReport().forEach((k, v) => log('  $k：$v'));
  }
}
