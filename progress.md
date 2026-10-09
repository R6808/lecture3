# 进度报告3（第 5 周·Dart 语言基础二：面向对象与集合）

- 姓名：容磊　学号：20251060108
- 仓库：`lecture3`
- 对应实践指南：《学生实践指南三　Dart 语言基础二：面向对象与集合》
- 对应课堂案例：`dart_oo`

---

## 一、任务理解

本次作业是在上一课 Dart 语法基础上，进入"Dart 语言基础二"这个单元，核心就两件事：
**用类组织程序**，**用集合组织数据**。具体要求我理解成三层：

1. **课堂案例复现（必做）**：跟着课堂案例做一遍 `dart_oo`——用类建模一个"课程成绩册"，
   能算平均分、最高分、及格人数、按等级分档，并且这些统计**必须用集合的链式方法写，
   不许手写 `for` 循环**。还要把日志能力抽成 mixin 混进来，并为核心逻辑写单元测试。
   指南把这一步拆成三个小步，要求每步一次 Git 提交。

2. **自主实践基本要求（必做）**：五件事——类的字段/构造/封装设计要合理；
   用 mixin 改造，替掉代码里的一层继承并说明理由；集合统计链至少组合 5 个链式方法；
   用 `test` 包写至少 2 个用例且要覆盖异常路径；最后如实标注 AI 的使用方式。

3. **独立研究任务（选做）**：三个小实验——mixin 线性化顺序、集合的不可变、
   `==` 与 `hashCode` 重写。要求以手工编程和官方文档检索为主，写清探索过程与结论。

**验收标准**（我按指南写的检查点逐条抄下来，作为自查依据）：
- `dart run` 的统计输出正确；
- `dart test` 全绿；
- `dart analyze` 无告警；
- 能口头解释 `with` 顺序对同名方法的影响；
- 代码推到独立仓库 `lecture3`，含 README，提交次数 3 次以上，提交信息规范。

我给自己加的额外一条：统计部分要做到**全项目 0 处手写 `for` 循环**，
这样"是否真的用了链式方法"就不用靠嘴说，直接看代码即可。
（用 `Select-String -Pattern '\bfor\s*\('` 全项目扫过一遍，只命中 1 处，
是 `byId()` 里的集合 `for` 生成器 `{for (final s in students) s.id: s}`——
这是指南 4.2 节点名教的写法，属于集合字面量语法，不是命令式的循环语句。）

---

## 二、环境与工具

| 项目 | 内容 |
| --- | --- |
| 操作系统 | Windows（本机） |
| Dart SDK | 3.13.4 (stable) |
| 依赖 | `test: ^1.25.6`（dev_dependency）、`lints: ^6.0.0`、`path: ^1.9.0` |
| 编辑器 / AI 工具 | TraeCode |
| 运行目标 | **命令行（Dart VM）**。本次作业是纯 Dart 语言与集合的训练，不涉及 Flutter 界面，所以没有用 Web / 模拟器 / 真机；用 `dart run` 直接跑，输出即证据 |
| 项目创建方式 | `dart create lecture3 --template=console` |
| 仓库 | 本次单独新建仓库 `lecture3`（按提交要求：每次作业一个独立项目仓库） |

工程目录：

```
lecture3/
├── bin/dart_oo.dart              案例复现统一入口
├── lib/student.dart              Student：封装、命名构造、校验 setter
├── lib/logger.dart               Logger / Validated 两个能力 mixin
├── lib/gradebook.dart            GradeBook 统计 + Formattable mixin
├── test/gradebook_test.dart      22 个用例
├── research/                     三个独立研究模块
├── images/                       证据截图
├── progress.md                   本报告
└── README.md
```

---

## 三、过程记录

按时间线记录主要操作（每一步都在这个仓库里留下了对应的提交）：

1. **建工程**：`dart create lecture3 --template=console`，删掉模板自带的
   `lib/lecture3.dart`、`bin/lecture3.dart`、`test/lecture3_test.dart`，
   把 `pubspec.yaml` 的包名确认为 `lecture3`。

2. **步骤一·建模**：写 `lib/student.dart`（`Student` 类：`id`/`name` 为 `final`、
   `_score` 私有、主构造 + `fromJson` + `fresh` 三个构造函数、`score` 的 setter 带范围校验、
   `passed`/`grade` 用派生 getter）与 `lib/gradebook.dart`（`GradeBook` 内部持 `List<Student>`，
   构造时用 `List.unmodifiable` 包一层）。跑 `dart analyze` 确认无告警后提交。
   → 提交 `feat: Student & GradeBook models`

3. **步骤二·统计功能**：给 `GradeBook` 加 `average`（`fold`）、`maxBy`/`minBy`（`reduce`）、
   `countPassed`（`where().length`）、`groupByGrade`（`fold` + `putIfAbsent`）、
   `byId`（集合 `for` 生成器）、`sortedByScoreDesc`（`[...students]..sort`），
   以及串联 7 个链式方法的 `advancedReport`。**全程没有写一个 `for` 循环**。
   写完先 `dart analyze`，再临时写一个小入口把统计打印出来肉眼核对一遍
   （人数 7、平均分 67.71、最高分孙悦 100、最低分赵磊 0、及格 5 人），确认无误后提交。
   → 提交 `feat: gradebook stats via collection chains`

4. **步骤三·mixin 与测试**：新建 `lib/logger.dart`，把日志能力抽成 `mixin Logger`
   （含 `logTag` getter 与 `log`/`logTitle` 两个方法），把 `GradeBook` 改成
   `class GradeBook with Logger`，并把 `printReport()` 里原本的 `print(...)`
   **逐个换成 mixin 提供的 `log(...)`**。同时加了一个 `mixin Validated` 演示
   "mixin 声明抽象 getter、宿主类负责实现"这种约定。再写 `bin/dart_oo.dart`
   统一入口和 `test/gradebook_test.dart`，`dart test` 全绿后提交。
   → 提交 `feat: Logger mixin & unit tests`

5. **mixin 改造（自主实践任务 2）**：把"格式化输出"从继承改成混入。
   改造前是让 `DetailedGradeBook extends GradeBook` 来获得格式化能力；
   改造后抽出 `mixin Formattable`，写成 `extends GradeBook with Formattable`。
   顺手修了一个排版问题：文本框原来用 `String.padRight` 对齐，中文占两列导致边框歪掉，
   改成按显示宽度对齐（`displayWidth` / `padToWidth`），并补了 3 个用例。
   → 提交 `refactor: 用 mixin Formattable 替代一层继承`

6. **三个独立研究模块**：分别写 `research/mixin_linearization.dart`、
   `research/immutable_collections.dart`、`research/equality_hashcode.dart`，
   每个都能 `dart run` 单独跑，把实测输出直接打进程序里作为结论依据。
   → 提交 `feat: 独立研究任务（mixin线性化 / 集合不可变 / ==与hashCode）`

7. **统一格式**：对 `bin lib test research` 跑 `dart format`，7 个文件被规整，
   复检 0 changed，之后 `dart analyze` 仍无告警、22 个用例仍全绿。
   → 提交 `style: dart format 统一代码格式`

8. **补文档与证据**：写 `README.md`、本报告，并用脚本把真实的命令输出渲染成
   `images/` 下的 9 张截图。

---

## 四、关键代码

### 4.1 集合统计链（自主实践任务 3：至少 5 个链式方法）

`lib/gradebook.dart` 里的 `advancedReport()`，**连续用了 7 个链式方法**：

```dart
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

  // ⑥ every：是否所有人都有学号
  final allHasId = students.every((s) => s.id.isNotEmpty);

  // ⑦ firstWhere：找出第一个不及格的学生；找不到时用 orElse 兜底
  final firstFailed = students.firstWhere(
    (s) => !s.passed,
    orElse: () => Student('--', '（无不及格）', 0),
  );

  return { /* ...聚合结果... */ };
}
```

逐行解释：

- **① `where`** 返回的是一个惰性的 `Iterable`，不会立刻建新列表；
  后面的 `map`、`where` 会继续挂在同一条惰性链上，直到 `fold` 才真正遍历一次。
  这也是链式写法比"边遍历边判断"更省的原因——只遍历一遍，不产生中间列表。
- **② `map`** 把 `Student` 映射成 `double`，链上的元素类型从 `Student` 变成 `double`，
  这一步正是"从对象里取需要的字段"的标准做法。
- **③ 第二个 `where`** 演示链式方法可以任意串联，且每次都会收窄元素集合。
- **④ `fold<double>`** 是"折叠"：第一个参数是初始值 `0`，第二个参数是累加函数；
  显式写出 `<double>` 是因为不写的话初始值 `0` 会被推成 `int`，累加小数会出错。
- **⑤ `any` / ⑥ `every`** 是判定类方法，返回 `bool`，短路求值——
  一旦能确定结果就不再往下遍历。注意这两个是挂在 `students` 上而不是链尾，
  因为它们是"对整个成绩册"的判断，不参与前面的筛选。
- **⑦ `firstWhere`** 有坑：**找不到匹配元素时会抛 `StateError`**，
  所以必须给 `orElse` 兜底。本项目里"全班都及格"是合法情况，
  不给 `orElse` 就会在空成绩册上直接崩掉（`test/` 里有一条用例专门盯这个）。

AI 标注：这段代码由 AI 辅助生成初稿，我逐行核对了每个方法的返回值类型与惰性语义，
并补了 `fold<double>` 的显式类型参数；`orElse` 兜底是我在测试里发现空成绩册会抛
`StateError` 之后加上的。验证方式见 `test/gradebook_test.dart` 第一组第 6、7 条用例。

### 4.2 mixin 改造前后对照（自主实践任务 2）

**改造前**——用继承拿格式化能力：

```dart
class DetailedGradeBook extends GradeBook {
  String format() { /* 拼文本框 */ }
}
```

**改造后**——抽成 mixin 混入：

```dart
mixin Formattable {
  String get reportTitle;          // 抽象成员：宿主必须提供
  List<String> get reportLines;    // 抽象成员：宿主必须提供

  String format() {
    final width = <String>[reportTitle, ...reportLines]
        .map(displayWidth)
        .reduce((a, b) => a > b ? a : b);
    final border = '+${'-' * (width + 2)}+';
    // ... 按显示宽度逐行补齐 ...
  }
}

class DetailedGradeBook extends GradeBook with Formattable { ... }
```

逐行解释与改造理由：

- `mixin Formattable` 里**只声明、不实现** `reportTitle` 和 `reportLines` 两个抽象成员，
  这等于给宿主类立了个契约：想获得 `format()`，就得先告诉我标题和正文。
  编译期就会检查，漏实现直接编译不过。
- `format()` 是按**显示宽度**而不是字符个数对齐的。中文在等宽终端里占两列，
  一开始用 `String.padRight` 排出来的框左右是歪的（见第六节的问题记录）。
  现在用 `.map(displayWidth).reduce(...)` 取最大显示宽度，再用 `padToWidth` 补齐。
- **为什么改成 mixin**：格式化是"横切能力"，和"是不是成绩册"没有关系。
  用 `extends` 拿到它，等于宣称"详细成绩册是一种格式化器"，语义不成立；
  更实际的问题是 Dart 每个类**只能 `extends` 一个父类**，用继承去拿一个附加能力，
  就把唯一的继承位占掉了，以后真想复用某个父类的实现就没位置了。
  改成 mixin 之后，`extends` 位留给了真正的 is-a 关系
  （`DetailedGradeBook` is-a `GradeBook`），能力靠 `with` 叠加，还能叠多个。
- 同样的道理在步骤三已经用过一次：`class GradeBook with Logger` 拿日志能力，
  这样后面 `DetailedGradeBook extends GradeBook with Formattable` 才能同时拥有
  继承、日志、格式化三样东西。

AI 标注：改造方向由我确认（指南明确要求"用混入替代一层继承并说明理由"），
mixin 骨架由 AI 辅助生成，`displayWidth` 的两列宽字符判定表由我查阅 Dart 的
`runes` 文档后逐条核对。验证方式是 `test/` 里那两条断言
——`detailed is GradeBook` / `is Formattable` 同时为真，以及"文本框每行显示宽度完全一致"。

### 4.3 带校验的 setter（自主实践任务 1：类设计合理性）

`lib/student.dart` 的封装部分：

```dart
class Student {
  final String id;      // 不可变
  final String name;    // 不可变
  double _score;        // 私有：下划线前缀

  Student(this.id, this.name, [this._score = 0]) {
    _validate(_score);  // 构造体内也校验，防止绕过 setter 传非法初值
  }

  Student.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      _score = (json['score'] as num).toDouble() {
    _validate(_score);
  }

  static void _validate(double v) {
    if (v < 0 || v > 100) throw ArgumentError('分数越界：$v（应在 0~100 之间）');
  }

  double get score => _score;

  set score(double v) {
    _validate(v);
    _score = v;
  }

  bool get passed => _score >= 60;
}
```

逐行解释：

- `final String id` / `final String name`：学号和姓名一旦确定就不该再变，用 `final` 锁死。
- `double _score`：Dart 没有 `private` 关键字，**库内用下划线前缀表示私有**。
  这样外部代码只能通过 `score` 这个 getter/setter 访问，无法绕过校验直接改字段。
- 主构造函数用了**位置可选参数** `[this._score = 0]`，不传分数时默认 0 分。
- 构造体里又调了一次 `_validate`：因为 `_score` 是私有字段，构造时直接赋值是绕过 setter 的，
  如果不校验，`Student('01','甲',-5)` 这种非法对象就能被造出来。
- `fromJson` 是**命名构造函数**，用初始化列表（冒号后）在构造体执行前赋值。
  这里 `(json['score'] as num).toDouble()` 是关键：JSON 解码出来的 `92` 是 `int`，
  直接 `as double` 会在运行期抛 `type 'int' is not a subtype of type 'double'`（见第六节）。
  先转成 `num` 再 `.toDouble()` 就两条路都走得通。
- `_validate` 做成 `static`：它不依赖任何实例状态，静态方法可以被两个构造函数共用。
  越界时**直接抛异常**而不是返回 `false`——因为"传入非法分数"是调用方的 bug，
  不该让被调用方去猜怎么处理。
- `set score` 先校验、后赋值，保证"要么改成功、要么原值不动"，不会出现改坏一半的状态。
- `bool get passed => _score >= 60;` 是**派生属性**：它由 `_score` 算出来，
  不单独存字段。存字段的话改分时就要记得同步改两处，早晚不一致。

AI 标注：由 AI 辅助生成，我逐项核对了指南 2.1 节的示例并做了两处增强
（构造体内补校验、`as num` 的转换），验证方式见 `test/gradebook_test.dart`
第二组 6 条异常用例与第三组 3 条构造用例。

---

## 五、检查点结果

| 检查点 | 命令 | 实测结果 | 证据 |
| --- | --- | --- | --- |
| 统计输出正确 | `dart run bin/dart_oo.dart` | 人数 7、平均分 67.71、最高分 孙悦（100）、最低分 赵磊（0）、及格 5 人、不及格 王芳/赵磊；按等级分档与降序排列均正确；统计链结果 7 项全部符合手算 | 图 01、02 |
| 测试全部通过 | `dart test` | `All tests passed!`，**22 个用例**（统计 8 + 异常分支 6 + 构造与 mixin 6 + 显示宽度 2） | 图 03 |
| 静态检查 | `dart analyze` | `No issues found!` | 图 04 |
| 格式规范 | `dart format --set-exit-if-changed` | `Formatted 8 files (0 changed)` | 图 04 |
| Git 规范 | `git log --oneline` | 6 次提交，前三次提交信息与指南第五部分完全一致 | 图 09 |

关于"统计输出正确"的核对方法：我不是只看程序跑通了，而是把演示数据手算了一遍——
7 个学生分数是 92、55、78、88、61、0、100，总分 474，`474 / 7 = 67.7142…`，
程序输出 67.71（四舍五入保留两位），对得上；
80 分以上有 3 人（92、88、100），各加 5 分后是 97、93、105，全部 ≥85，
所以"加分后达标人数 3、总分 295"也对得上。这些数字同样写进了单元测试做断言，
以后改代码一旦算错，测试会立刻红。

异常路径的覆盖：第二组 6 条用例专门打校验逻辑——负数、101、1000、120 都要抛
`ArgumentError`；抛错后原值必须保持不变；边界值 0 和 100 不能被误拦；
构造函数直接传非法初值和 `fromJson` 传越界分数也都要抛错。
指南要求"至少 2 个用例覆盖正常与异常"，这里做到了 22 个。

---

## 六、问题与调试

### 问题 1（真实类型错误）：`type 'int' is not a subtype of type 'double'`

**现象**：写 `Student.fromJson` 时，一开始按最直观的写法把 JSON 的值直接赋给 `double` 字段：

```dart
BadStudent.fromJson(Map<String, dynamic> json)
  : id = json['id'] as String,
    name = json['name'] as String,
    _score = json['score'];      // ← 问题在这里
```

然后用 `{'id': '01', 'name': '李华', 'score': 92}` 去构造，程序直接崩：

```
Unhandled exception:
type 'int' is not a subtype of type 'double'
#0      new BadStudent.fromJson (.../_scratch_type_error.dart:11:7)
#1      main (.../_scratch_type_error.dart:19:24)
```

**定位过程**：这一步最反直觉的地方是——**`dart analyze` 完全没报错**。
我特意先跑了静态分析，它只给出一条无关的提示
（`prefer_final_fields`，说 `_score` 可以是 `final`），压根没提类型问题。
原因是我当时的字段声明还是 `double _score;`，而 `json['score']` 的静态类型是 `dynamic`，
`dynamic` 可以赋给任何类型，编译器不做检查，**把错误推迟到了运行期**。

**根因**：Dart 里 `92`（整数）的类型是 `int`，而 `int` **不是** `double` 的子类型
（Dart 不把整数隐式转成浮点）。JSON 解码出来的数值，整数就是 `int`，
带小数点的才是 `double`。所以 `"score": 92` 解出来是 `int`，
赋给 `double` 字段时就炸了。

**解决方案**：先转成 `num` 再调 `.toDouble()`，`int` 和 `double` 都走 `num` 这条路：

```dart
_score = (json['score'] as num).toDouble() {
  _validate(_score);
}
```

**验证**：`bin/dart_oo.dart` 里专门打印了这一行的效果，
输出 `score 的运行时类型：double（JSON 里是 int，已转成 double）`；
`test/gradebook_test.dart` 里也有一条用例断言 `expect(s.score, isA<double>())`。

**这题给我的教训**：`dynamic` 是把静态检查关掉的开关。
只要数据从 `dynamic` 流进来（JSON、平台通道返回的 Map），编译器就帮不上忙，
必须自己显式转一次类型。指南 2.1 节给的 `(json['score'] as num).toDouble()`
不是啰嗦，是必须的。

### 问题 2：文本框用 `padRight` 对齐，中文导致边框歪掉

**现象**：`Formattable.format()` 生成的文本框，右边框参差不齐：

```
┌──────────────┐
│ 详细成绩册        │
│ 平均分：67.71    │
└──────────────┘
```

**定位过程**：一开始怀疑是 `padRight` 的宽度算错了，于是把 `reportTitle.length`
和每一行的 `line.length` 打出来看，发现宽度确实是最大值没错。
后来才反应过来：`String.length` 数的是**字符个数**，而中文在等宽终端里
**占两列**。"详细成绩册" 5 个字符、显示宽度是 10，而 "平均分：67.71"
9 个字符、显示宽度是 13——字符个数和显示宽度根本不是一个东西，
按字符个数补空格，补出来的自然对不齐。

**解决方案**：加两个工具函数按**显示宽度**对齐——
`displayWidth` 用 `runes` 遍历（而不是按 code unit，避免把 emoji 之类的代理对拆成两半），
按东亚宽字符的码点区间判断每个字符占 1 列还是 2 列；
`padToWidth` 则补 `宽度差` 个空格。

**验证**：`test/` 里加了一条断言，把文本框每一行的 `displayWidth` 收进一个 `Set`，
断言 `set.length == 1`——只要有任何一行对不齐，这条用例立刻红。
另外还补了 2 条直接测 `displayWidth` / `padToWidth` 的用例。

### 问题 3：包名和 import 路径对不上，一次报了 76 个错

**现象**：`dart create lecture3` 建出来的工程，`pubspec.yaml` 里 `name: lecture3`，
但我在 `bin/` 和 `test/` 里写成了 `import 'package:dart_oo/gradebook.dart';`
（因为课堂案例叫 `dart_oo`，顺手就写成了案例名）。一跑 `dart analyze`，
直接刷出 76 个问题，全是 `Target of URI doesn't exist` 和
`The function 'Student' isn't defined` 这类连锁错误。

**定位过程**：错误数量多得吓人，但第一条 `uri_does_not_exist` 就指明了方向——
`package:` 后面的名字必须和 `pubspec.yaml` 的 `name` 字段一致，
而不是和"案例名"或"仓库名"一致。

**解决方案**：把两个文件里的 import 统一改成 `package:lecture3/...`。
改完 76 个问题一次性全消失了。

**教训**：报错数量多不等于问题多，通常只是第一个错误引发的连锁反应，
先修第一个就好。

### 另外记录两个被静态分析抓出来的告警

- **`unnecessary_type_check`（类型检查恒为真）**：演示 `book is GradeBook` /
  `is Formattable` / `is Logger` 时，因为 `book` 的静态类型已经是 `DetailedGradeBook`，
  这些 `is` 判断编译期就能确定是 `true`，分析器提示"多余"。改成把对象作为
  `Object` 类型的**函数参数**传进去（`describeTypeChain(Object o)`），
  静态就无法确定了，运行时才真正去查类型链——这样验证才有意义。
- **`avoid_function_literals_in_foreach_calls`**：为了满足"不写 `for` 循环"，
  我把 `Iterable.forEach` 用得很密，风格检查建议改回 `for`。
  但这里是刻意不用 `for` 的：于是把匿名闭包换成**具名局部函数的 tear-off**
  （`values.forEach(trySet)`），既保住了"零手写循环"，又不触发这条风格告警。

---

## 七、AI使用记录

本次使用 TraeCode 辅助。逐条记录如下（用途 / 指令摘要 / 输出 / 本人验证方式）：

| 序 | 用途 | 指令摘要 | 输出 | 本人验证方式 |
| --- | --- | --- | --- | --- |
| 1 | 生成 `Student` 类骨架 | "按实践指南 2.1 节的 Student 示例，写类定义与封装：final 字段、私有 _score、位置可选参数的主构造、命名构造 fromJson、带校验的 getter/setter、派生 getter passed" | `lib/student.dart` 初稿 | 对照指南 2.1 逐行核对；补了构造体内的校验；用 6 条异常用例 + 3 条构造用例验证 |
| 2 | 生成集合统计方法 | "GradeBook 要实现 average / maxBy / minBy / countPassed / groupByGrade / byId / sortedByScoreDesc，全部用集合链式方法，禁止手写 for 循环" | `lib/gradebook.dart` 统计部分初稿 | 手算了一遍演示数据的 7 项统计结果与程序输出逐项比对；每个方法都补了单元测试断言 |
| 3 | 设计集合统计链 | "设计一条至少串联 5 个链式方法的统计链，要能体现 where / map / fold 的组合" | `advancedReport()`，实到 7 个方法 | 数了一遍确实是 7 个；核对每步返回类型；发现空成绩册会在 `firstWhere` 抛 `StateError`，补了 `orElse` 兜底并加用例 |
| 4 | 抽取 Logger mixin | "把日志能力抽成 mixin Logger，含 logTag getter 与 log / logTitle 方法，并混入 GradeBook 替换原来的 print" | `lib/logger.dart`、`GradeBook with Logger` | 跑 `dart analyze` 确认无告警；`dart run` 看到日志前缀 `[GradeBook]`；加用例断言 `book is Logger` |
| 5 | mixin 改造方案对照 | "把 DetailedGradeBook 的格式化能力从继承改成 mixin，并说明改造理由" | `mixin Formattable` + 改造前后注释 | 确认改造后 `is GradeBook` 与 `is Formattable` 同时为真；把"理由"这一段按自己的话重写进了代码注释和本报告 |
| 6 | 排查中文对齐 | "文本框右边框对不齐，padRight 已按最大长度补齐，为什么还歪" | 指出中文占两列、`String.length` 数字符不数列；给出 `displayWidth` / `padToWidth` 实现 | 打印每行的字符个数与显示宽度对照确认；补 3 条用例，含"每行显示宽度必须一致"的断言 |
| 7 | 排查 76 个编译错误 | 贴出 `dart analyze` 的完整输出 | 指出包名应为 `lecture3` 而非 `dart_oo`，改 import 前缀即可 | 改成 `package:lecture3/...` 后复跑，76 个问题归零 |
| 8 | 三个独立研究模块的骨架 | "分别写 mixin 线性化、集合不可变、== 与 hashCode 的实验脚本，要能 dart run 并打印实测结论" | `research/` 下三个文件初稿 | **逐条核对过官方文档**（dart.dev 的 mixins / collections / classes 页）；把 AI 给的结论句全部改成自己实跑出来再写的结论；例如"`growable: false` 的元素仍可修改"这一条，是我实际跑出来看到没抛错才写进结论的 |

**说明**：所有 AI 生成的代码都经过实跑验证，验证手段是
`dart analyze`（0 告警）+ `dart test`（22 个用例）+ `dart run` 的实测输出，
而不是只看代码"像是对的"。独立研究部分的结论以我自己的实测输出为准，
其中"mixin 的 `on` 约束在编译期报错"这一条，是我另外写了一个临时文件
实际跑 `dart analyze` 拿到报错码 `mixin_application_not_implemented_interface`
之后才写进结论的（临时文件已删除）。

---

## 八、证据截图

截图文件都在仓库 `images/` 目录下，是把命令的**真实输出**原样渲染成的终端截图。

| 图 | 文件 | 说明 |
| --- | --- | --- |
| 01 | `images/01-检查点-dart-run-统计输出.png` | `dart run bin/dart_oo.dart` 的完整输出：上面是封装与校验、mixin 类型链与 `format()` 文本框，最下面是成绩册统计报告的开头。证明检查点"统计输出正确" |
| 02 | `images/02-集合统计链与边界情况.png` | 同一命令的后半段：按等级分档、按分数降序、以及统计链的 7 项结果；末尾是空成绩册的边界情况（人数 0、平均分 0，不抛异常） |
| 03 | `images/03-检查点-dart-test-全部通过.png` | `dart test` 的完整输出，22 个用例逐条列出，最后 `All tests passed!`。证明检查点"测试全部通过" |
| 04 | `images/04-检查点-dart-analyze-无告警.png` | `dart analyze` 输出 `No issues found!`、Dart SDK 版本 3.13.4、以及 `dart format` 复检 0 changed。证明静态检查与格式规范都过关 |
| 05 | `images/05-独立研究一-mixin线性化.png` | `dart run research/mixin_linearization.dart`：`Base with M1, M2` 输出 `M2(M1(Base))`，调换顺序输出 `M1(M2(Base))`；随后是 `on` 约束的编译期报错记录 |
| 06 | `images/06-独立研究二-集合不可变.png` | `dart run research/immutable_collections.dart`：对三种只读容器分别尝试改长度/改元素，记录各自抛出的异常类型；`growable: false` 那一行显示改元素"没有报错"，这就是它的差异所在 |
| 07 | `images/07-独立研究三-equals与hashCode.png` | `dart run research/equality_hashcode.dart`：只重写 `==` 的类，`List.contains(c)` 返回 `true` 而 `Set.contains(c)` 返回 `false`；以及改掉可变字段后对象从 `Set` 中消失 |
| 08 | `images/08-问题与调试-真实类型错误.png` | 第六节问题 1 的完整复现：`dart analyze` 只报了一条无关提示，`dart run` 抛出 `type 'int' is not a subtype of type 'double'` 并附调用栈 |
| 09 | `images/09-Git提交记录.png` | `git log --oneline --decorate` 的 6 次提交，以及 `git ls-files` 的 12 个受控文件。证明"3 次以上提交"与提交规范 |

---

## 九、自评

对照指南 6.1–6.3 逐项自查：

### 6.1 案例复现（15 + 检查点 5 + Git 规范 5 + 报告记录 5）

| 项 | 要求 | 完成情况 | 自评 |
| --- | --- | --- | --- |
| 步骤一 建模 | `Student`（命名构造 fromJson、getter、校验 setter）+ `GradeBook`（内部 List） | 都已实现，另加 `Student.fresh` 命名构造 | 完成 |
| 步骤二 统计 | average / maxBy / countPassed / groupByGrade，禁止手写 for | 全部实现，另加 minBy / failedNames / byId / sortedByScoreDesc / advancedReport；**全项目 0 处手写 for 循环** | 完成 |
| 步骤三 mixin + 测试 | Logger 混入 GradeBook；test 下至少 2 个用例 | Logger 与 Validated 两个 mixin；22 个用例（要求 2 个） | 超额完成 |
| 检查点 | 统计输出正确；测试全部通过 | 手算比对 + 22 用例全绿 + analyze 0 告警 | 完成 |
| Git 规范 | 每步一次提交 | 6 次提交，前三次提交信息与指南给的完全一致 | 完成 |
| 报告记录 | 按十节模板填写 | 本报告 | 完成 |

### 6.2 自主实践基本要求

| 序 | 任务 | 完成情况 | 自评 |
| --- | --- | --- | --- |
| 1 | 类设计合理性 | `id`/`name` 用 `final`、`_score` 私有、三个构造函数、setter 带范围校验、派生 getter 不存字段 | 完成 |
| 2 | mixin 改造替代一层继承 | 抽出 `mixin Formattable` 替代原来的继承；改造理由写在代码注释与第四节 | 完成 |
| 3 | 集合统计链 ≥5 个方法 | `advancedReport()` 串联 7 个：where → map → where → fold → any → every → firstWhere | 超额完成 |
| 4 | test 包 ≥2 用例含异常 | 22 个用例，其中 6 个专打异常路径（负数/101/1000/120/构造非法初值/fromJson 越界） | 超额完成 |
| 5 | AI 使用标注 | 第七节逐条记录用途、指令摘要、输出、验证方式 | 完成 |

### 6.3 独立研究任务（选做）

| 序 | 任务 | 完成情况 | 自评 |
| --- | --- | --- | --- |
| 1 | mixin 线性化实验 | 两个含同名方法的 mixin × 两种 with 顺序，实测得到 `M2(M1(Base))` 与 `M1(M2(Base))`；另外用 `dart analyze` 验证了 `on` 约束在编译期报错 | 完成 |
| 2 | 集合不可变实践 | 对 `const` 列表 `add` 实测抛 `UnsupportedError`；另外对比了 `List.unmodifiable` 与 `growable: false` 的差异，总结了三种"不可变"各自能挡什么、以及浅拷贝陷阱 | 完成 |
| 3 | `==` 与 `hashCode` 重写 | 实测了只重写 `==` 时 `List.contains` 与 `Set.contains` 结论相反、`Map` 查不到、`remove` 删不掉；以及可变字段进 `hashCode` 后对象从 `Set` 中消失 | 完成 |

### 我认为还做得不够的地方

- **独立研究三的 `Set` 去重表现在测试里**：目前那三条实验结论是在
  `research/` 脚本里跑出来肉眼确认的，没有落成 `test/` 里的断言。
  更严谨的做法是把它们也固化成单元测试，这样以后改代码能自动发现问题。
  下次课之前想补上。
- **`GradeBook.empty()` 与 `maxBy` 的矛盾**：空成绩册调用 `maxBy` 会抛 `StateError`，
  因为 `reduce` 需要一个初始元素。我实测确认过：`dart run` 得到
  `StateError -> Bad state: No element`。目前 `average` 做了空判断，但 `maxBy`/`minBy` 没做。
  这在当前用法下没问题（有数据才会去算最高分），但接口上不够稳，
  更合适的做法是返回 `Student?` 并用 `fold` 实现。
- **混入的 `Logger.logTag` 用的是 `runtimeType.toString()`**，
  子类会打印出 `DetailedGradeBook` 这种长名字，日志里略显啰嗦，
  可以考虑给每个类一个短标签。

---

## 十、一句话收获与下一步计划

**一句话收获**：Dart 里"复用代码"有三种手段，选哪种取决于关系——
要复用**实现**用 `extends`，要统一**契约**用 `implements`/`abstract`，
要叠加**横切能力**用 `mixin with`；而 `with` 的顺序不是随便写的，
它决定了线性化链上谁覆盖谁、`super` 会落到哪里，
我这次是把两种顺序都跑了一遍才真正记住的。

**遗留问题**：
1. 独立研究三的三条结论还没固化成 `test/` 里的断言（见第九节）。
2. `maxBy` / `minBy` 在空成绩册上会抛 `StateError`，接口健壮性待改进。
3. 三个独立研究模块目前各自独立，没有和主工程的统计逻辑产生关联，
   想再补一个"用 `==`/`hashCode` 给成绩册做去重"的实用例子。

**下次课预习要点**：下一课进入 Flutter 界面部分，提前要看的点是——
Widget 本身就是类（正好接上本次的类与构造），
界面数据是集合（接上本次的 List/Map/Set 与链式处理），
以及"不可变"在 Widget 里的地位（`const` 构造函数、`StatelessWidget` 为什么强调不可变），
这几点应该和本次的独立研究二直接相关。
