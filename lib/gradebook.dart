/// gradebook.dart — GradeBook 类：全部统计用集合链式方法实现
///
/// 对应实践指南三第四部分（泛型与集合）与课堂案例 dart_oo 步骤二、三。
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

/// ---------------------------------------------------------------
/// 自主实践任务 2：mixin 改造 —— 用混入替代一层继承
/// ---------------------------------------------------------------

/// 报表格式化能力
///
/// 【改造前】原本的写法是让详细成绩册继承成绩册：
///     class DetailedGradeBook extends GradeBook { ... }
/// 问题：
///   1. 只是"多加一个打印格式"，却占用了唯一的 extends 位置，
///      以后若还想让成绩册复用别的实现就没办法了；
///   2. 语义上不成立——详细成绩册并不是"一种成绩册的特例"，
///      而是"成绩册 + 一种额外的输出格式"。
///
/// 【改造后】把"格式化"抽成 mixin，谁需要谁 with 上：
///     class DetailedGradeBook extends GradeBook with Formattable
/// 好处：继承位留给真正的"is-a"关系，横切能力用 mixin 叠加，可以叠多个。
mixin Formattable {
  /// 宿主必须提供：要格式化的标题
  String get reportTitle;

  /// 宿主必须提供：正文各行
  List<String> get reportLines;

  /// 生成带边框的文本框
  ///
  /// 注意不能直接用 String.padRight：它按"字符个数"补空格，
  /// 而中文在终端里占两列，用 padRight 排出来的框会左右错位。
  /// 所以这里用 displayWidth / padToWidth 按**显示宽度**对齐。
  String format() {
    final width = <String>[reportTitle, ...reportLines]
        .map(displayWidth)
        .reduce((a, b) => a > b ? a : b);
    final border = '+${'-' * (width + 2)}+';

    final buffer = StringBuffer();
    buffer.writeln(border);
    buffer.writeln('| ${padToWidth(reportTitle, width)} |');
    buffer.writeln(border);
    reportLines.map((line) => '| ${padToWidth(line, width)} |').forEach(buffer.writeln);
    buffer.write(border);
    return buffer.toString();
  }
}

/// 单个字符在等宽终端里占几列
///
/// 只区分"占两列"的宽字符（中日韩文字、全角标点）和"占一列"的窄字符，
/// 不做完整的 Unicode East Asian Width 表，够本项目用。
int _charWidth(int rune) {
  if (rune >= 0x1100 && rune <= 0x115F) return 2; // 韩文字母
  if (rune >= 0x2E80 && rune <= 0xA4CF) return 2; // CJK 部首 ~ 彝文
  if (rune >= 0xAC00 && rune <= 0xD7A3) return 2; // 韩文音节
  if (rune >= 0xF900 && rune <= 0xFAFF) return 2; // CJK 兼容表意文字
  if (rune >= 0xFE30 && rune <= 0xFE6F) return 2; // CJK 兼容形式
  if (rune >= 0xFF00 && rune <= 0xFF60) return 2; // 全角 ASCII
  if (rune >= 0xFFE0 && rune <= 0xFFE6) return 2; // 全角符号
  return 1;
}

/// 字符串的显示宽度
///
/// 用 runes 而不是 code units 遍历，避免把 emoji 等代理对拆成两半。
int displayWidth(String s) => s.runes.fold<int>(0, (w, r) => w + _charWidth(r));

/// 按显示宽度右补空格
String padToWidth(String s, int width) => s + ' ' * (width - displayWidth(s));

/// 详细成绩册：继承 GradeBook（真正的 is-a 关系），再混入 Formattable
class DetailedGradeBook extends GradeBook with Formattable {
  DetailedGradeBook(super.input);

  @override
  String get reportTitle => '详细成绩册';

  @override
  List<String> get reportLines => [
        '人数：$count',
        '平均分：$average',
        '最高分：${maxBy.name} ${maxBy.score}',
        '及格人数：$countPassed',
        '不及格：${failedNames.isEmpty ? '无' : failedNames.join('、')}',
      ];
}
