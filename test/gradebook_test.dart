/// gradebook_test.dart — 单元测试
///
/// 对应实践指南三第六部分：为成绩册统计与校验写单元测试（至少 2 个用例，
/// 其中一个必须覆盖异常分支）。
///
/// 说明：测试用的是**独立的测试数据**，不复用 bin/dart_oo.dart 里的演示数据，
/// 这样改动演示数据不会连带把测试改坏。
library;

import 'package:lecture3/gradebook.dart';
import 'package:lecture3/logger.dart';
import 'package:lecture3/student.dart';
import 'package:test/test.dart';

/// 测试用固定数据集，分数与姓名都刻意选了能区分边界值的组合
List<Student> sample() => [
      Student('01', '甲', 92), // 优
      Student('02', '乙', 55), // 不及格
      Student('03', '丙', 78), // 中
      Student('04', '丁', 88), // 良
      Student('05', '戊', 61), // 及格
      Student('06', '己', 0), // 边界：0 分，不及格
      Student('07', '庚', 100), // 边界：100 分，优
    ];

void main() {
  // ============================================================
  // 第一组：正常分支 —— 统计结果是否正确
  // ============================================================
  group('GradeBook 统计', () {
    test('人数 / 平均分 / 最高分 / 最低分 计算正确', () {
      final book = GradeBook(sample());

      expect(book.count, 7);
      // 总分 474，474 / 7 = 67.714...，四舍五入保留两位 → 67.71
      expect(book.average, 67.71);
      expect(book.maxBy.name, '庚');
      expect(book.maxBy.score, 100);
      expect(book.minBy.name, '己');
      expect(book.minBy.score, 0);
    });

    test('及格人数与不及格名单正确', () {
      final book = GradeBook(sample());

      expect(book.countPassed, 5);
      expect(book.failedNames, ['乙', '己']);
    });

    test('按等级分档正确', () {
      final book = GradeBook(sample());
      final grouped = book.groupByGrade();

      expect(grouped.keys.toSet(), {'优', '良', '中', '及格', '不及格'});
      expect(grouped['优']!.map((s) => s.name).toList(), ['甲', '庚']);
      expect(grouped['不及格']!.map((s) => s.name).toList(), ['乙', '己']);
      expect(grouped['良']!.length, 1);
    });

    test('按学号建索引后可以取回同一个对象', () {
      final book = GradeBook(sample());
      final index = book.byId();

      expect(index.length, 7);
      expect(index['03']!.name, '丙');
      expect(index['03'], same(book.students[2]));
    });

    test('降序排序结果正确，且不破坏原列表顺序', () {
      final book = GradeBook(sample());
      final before = book.students.map((s) => s.name).toList();

      final sorted = book.sortedByScoreDesc();
      expect(sorted.map((s) => s.score).toList(), [100, 92, 88, 78, 61, 55, 0]);

      // 关键断言：排序不修改原列表（不可变性）
      expect(book.students.map((s) => s.name).toList(), before);
    });

    test('集合统计链 advancedReport 的结果正确', () {
      final book = GradeBook(sample());
      final r = book.advancedReport(bonus: 5);

      expect(r['参与人数'], 7);
      expect(r['80分以上人数'], 3); // 甲92 丁88 庚100
      expect(r['加分后达标人数'], 3);
      expect(r['加分后总分'], 295.0); // (92+5)+(88+5)+(100+5)
      expect(r['存在满分学生'], isTrue);
      expect(r['全部有学号'], isTrue);
      expect(r['首个不及格'], '乙');
    });

    test('空成绩册不抛异常：平均分为 0', () {
      final empty = GradeBook.empty();

      expect(empty.count, 0);
      expect(empty.average, 0);
      expect(empty.countPassed, 0);
      expect(empty.failedNames, isEmpty);
      // 空册里没有任何"第一个不及格"，应走到 orElse 兜底而不是抛 StateError
      expect(empty.advancedReport()['首个不及格'], '（无不及格）');
    });

    test('内部列表不可被外部修改', () {
      final book = GradeBook(sample());

      expect(() => book.students.add(Student('99', '壬', 50)),
          throwsUnsupportedError);
    });
  });

  // ============================================================
  // 第二组：异常分支 —— 非法分数必须被拦截
  // ============================================================
  group('Student 分数校验（异常分支）', () {
    test('setter 传负数抛 ArgumentError', () {
      final s = Student('01', '甲', 80);

      expect(() => s.score = -1, throwsArgumentError);
      // 抛错后原值必须保持不变，不能出现"改坏一半"的状态
      expect(s.score, 80);
    });

    test('setter 传超过 100 的数抛 ArgumentError', () {
      final s = Student('01', '甲', 80);

      expect(() => s.score = 101, throwsArgumentError);
      expect(() => s.score = 1000, throwsArgumentError);
      expect(s.score, 80);
    });

    test('异常信息里带有越界数值，便于排查', () {
      final s = Student('01', '甲', 80);

      expect(
        () => s.score = 120,
        throwsA(isA<ArgumentError>()
            .having((e) => e.message, 'message', contains('120'))),
      );
    });

    test('边界值 0 和 100 是合法的，不能被误拦', () {
      final s = Student('01', '甲', 80);

      s.score = 0;
      expect(s.score, 0);
      s.score = 100;
      expect(s.score, 100);
    });

    test('构造函数传入非法初值也要抛错', () {
      expect(() => Student('01', '甲', -5), throwsArgumentError);
      expect(() => Student('01', '甲', 150), throwsArgumentError);
    });

    test('fromJson 遇到越界分数同样抛错', () {
      expect(
        () => Student.fromJson({'id': '01', 'name': '甲', 'score': 200}),
        throwsArgumentError,
      );
    });
  });

  // ============================================================
  // 第三组：构造函数与 mixin
  // ============================================================
  group('构造函数与 mixin', () {
    test('fromJson 把 JSON 里的 int 分数转成 double', () {
      final s = Student.fromJson({'id': '04', 'name': '丁', 'score': 88});

      expect(s.score, 88.0);
      expect(s.score, isA<double>());
      expect(s.name, '丁');
    });

    test('Student.fresh 默认 0 分，等级为不及格', () {
      final s = Student.fresh('08', '辛');

      expect(s.score, 0);
      expect(s.passed, isFalse);
      expect(s.grade, '不及格');
    });

    test('等级档位在边界点上正确', () {
      expect(Student('a', 'a', 90).grade, '优');
      expect(Student('a', 'a', 89.9).grade, '良');
      expect(Student('a', 'a', 80).grade, '良');
      expect(Student('a', 'a', 70).grade, '中');
      expect(Student('a', 'a', 60).grade, '及格');
      expect(Student('a', 'a', 59.9).grade, '不及格');
    });

    test('GradeBook 通过 with 获得了 Logger 能力', () {
      final book = GradeBook(sample());

      expect(book, isA<Logger>());
      expect(book.logTag, 'GradeBook');
      // log 方法来自 mixin，GradeBook 自己并没有定义
      expect(() => book.log('测试日志'), returnsNormally);
    });

    test('Validated mixin 声明抽象 getter，未就绪时 check() 抛 StateError', () {
      final ok = _FakeReport()..ready = true;
      final bad = _FakeReport();

      expect(() => ok.check(), returnsNormally);
      expect(() => bad.check(), throwsStateError);
    });
  });
}

/// 测试用最小宿主类：只为验证 Validated mixin 的行为
class _FakeReport with Validated {
  bool ready = false;

  @override
  bool get isValid => ready;
}
