# lecture3 — Dart 语言基础二：面向对象与集合

移动应用软件开发实训 课堂作业三（第 5 周）独立项目仓库。

用类建模"课程成绩册"，完成统计功能；用集合链式方法替代手写循环；
用 mixin 替代一层继承；并用 `test` 包为核心逻辑写单元测试。

- 姓名：容磊
- 学号：20251060108
- 仓库地址：https://github.com/R6808/lecture3
- 运行环境：Dart SDK 3.13.4（Windows）
- 对应实践指南：《学生实践指南三　Dart 语言基础二：面向对象与集合》
- 对应案例：`dart_oo`（课堂案例复现）

---

## 一、快速开始

```bash
dart pub get          # 拉依赖
dart analyze          # 静态检查，期望输出 No issues found!
dart run bin/dart_oo.dart   # 运行案例复现，查看统计输出
dart test             # 跑单元测试，期望 All tests passed!
```

三个独立研究模块可以单独运行：

```bash
dart run research/mixin_linearization.dart     # mixin 线性化实验
dart run research/immutable_collections.dart   # 集合不可变实践
dart run research/equality_hashcode.dart       # == 与 hashCode 重写
```

---

## 二、目录结构

```
lecture3/
├── bin/
│   └── dart_oo.dart              案例复现统一入口（5 个演示段落）
├── lib/
│   ├── student.dart              Student 类：封装、命名构造、校验 setter
│   ├── logger.dart               Logger / Validated 两个能力 mixin
│   └── gradebook.dart            GradeBook 统计 + Formattable mixin + 显示宽度工具
├── test/
│   └── gradebook_test.dart       22 个用例，覆盖正常路径与异常路径
├── research/
│   ├── mixin_linearization.dart   独立研究一：mixin 线性化顺序
│   ├── immutable_collections.dart 独立研究二：集合的不可变
│   └── equality_hashcode.dart     独立研究三：== 与 hashCode 重写
├── progress.md                   进度报告三（十节全文）
└── README.md                     本文件
```

---

## 三、任务对照表

### 3.1 案例复现 `dart_oo`

| 指南要求 | 本项目实现 | 验证方式 |
| --- | --- | --- |
| 步骤一：建模 | `lib/student.dart` + `lib/gradebook.dart` | `dart run bin/dart_oo.dart` |
| 步骤二：统计功能，禁止手写 for 循环 | `gradebook.dart` 全部用 `where`/`map`/`fold`/`reduce` | `dart analyze` 无告警；全项目仅 1 处 `for`，且是 `byId()` 里的集合 `for` 生成器（指南 4.2 节教的集合字面量写法），无命令式循环 |
| 步骤三：mixin 与测试 | `lib/logger.dart` 的 `Logger` 混入 `GradeBook`；`test/` 下 22 个用例 | `dart test` 全绿 |
| 检查点：统计输出正确 | `dart run` 输出人数/平均分/最高分/最低分/及格人数/分档/降序 | 见 `progress.md` 第五节截图 |
| 检查点：测试全部通过 | 22 passed | `dart test` |

### 3.2 自主实践基本要求

| 序 | 任务 | 实现位置 | 说明 |
| --- | --- | --- | --- |
| 1 | 类设计合理性（字段、构造、封装） | `lib/student.dart` | `id`/`name` 为 `final`，`_score` 私有；主构造 + `fromJson` + `fresh` 三个构造函数；`score` 的 setter 带范围校验，越界抛 `ArgumentError`；`passed`/`grade` 用派生 getter 而不是存字段 |
| 2 | mixin 改造：用混入替代一层继承 | `lib/gradebook.dart` | 原本 `class DetailedGradeBook extends GradeBook` 只为拿到格式化能力，占掉了唯一的 `extends` 位；改为抽出 `mixin Formattable`，写成 `extends GradeBook with Formattable`。理由见文件内注释与 `progress.md` 第四节 |
| 3 | 集合统计链（至少 5 个链式方法） | `GradeBook.advancedReport()` | 连续使用 **7 个**：`where → map → where → fold → any → every → firstWhere` |
| 4 | test 包单元测试（至少 2 个用例，覆盖正常与异常） | `test/gradebook_test.dart` | 22 个用例分 4 组：统计正确性、异常分支、构造函数与 mixin、显示宽度 |
| 5 | AI 使用标注 | `progress.md` 第七节 | 逐条列出用途、指令摘要、输出、本人验证方式 |

### 3.3 独立研究任务（选做）

| 序 | 任务 | 文件 | 主要结论 |
| --- | --- | --- | --- |
| 1 | mixin 线性化实验 | `research/mixin_linearization.dart` | `Base with M1, M2` 得到 `M2(M1(Base))`，把 `with` 顺序调换整条调用链倒过来；`on` 约束在**编译期**报 `mixin_application_not_implemented_interface` |
| 2 | 集合不可变实践 | `research/immutable_collections.dart` | 对 `const` 列表 `add` 抛 `UnsupportedError`；`List.unmodifiable` 长度与元素都拦，`growable: false` 只拦长度、元素仍可改；不可变是**浅层**的，元素自身要靠 setter 校验 |
| 3 | `==` 与 `hashCode` 重写 | `research/equality_hashcode.dart` | 只重写 `==` 时 `List.contains(c)` 为 `true` 而 `Set.contains(c)` 为 `false`，同一份数据换个容器结论相反；可变字段进 `hashCode` 后对象会"从 Set 里消失" |

---

## 四、关键设计说明

### 4.1 为什么 `Student` 不重写 `==` / `hashCode`

`Student` 有一个可变的 `_score`。如果按"内容"重写 `==` 并让它参与
`hashCode`，那么改分之后对象的哈希值就变了，它一旦进过 `Set` 或当过 `Map` 的键
就再也捞不出来（`research/equality_hashcode.dart` 实验四复现了这一点）。
所以这里刻意保留默认的**身份相等**语义；需要按学号找学生时走
`GradeBook.byId()` 返回的 `Map<String, Student>`。
详见 `lib/student.dart` 顶部注释与独立研究三。

### 4.2 为什么用 `mixin` 而不是 `extends`

日志和格式化都是**横切能力**，与"是不是成绩册"无关。
用 `extends` 获取它们等于宣称"成绩册是一种日志器"，语义不成立，
还会占掉唯一的继承位。改成 `mixin` 后：

```dart
class GradeBook with Logger { ... }                       // 日志能力
class DetailedGradeBook extends GradeBook with Formattable { ... }  // 继承位留给真正的 is-a
```

两种能力叠加互不冲突，`extends` 位还留给了真正需要复用的父类。

### 4.3 显示宽度对齐

`Formattable.format()` 生成的文本框按**显示宽度**而不是字符个数对齐：
中文在等宽终端里占两列，直接用 `String.padRight` 排出来的框会左右错位。
`displayWidth` / `padToWidth` 用 `runes` 遍历并按 East Asian Width 的宽字符区间
加权，`test/` 里有一条断言专门检查"每一行显示宽度完全一致"。

---

## 五、检查点证据

| 检查点 | 命令 | 结果 |
| --- | --- | --- |
| 静态检查 | `dart analyze` | `No issues found!` |
| 统计输出正确 | `dart run bin/dart_oo.dart` | 人数 7 / 平均分 67.71 / 最高分 孙悦 100 / 最低分 赵磊 0 / 及格 5 人 |
| 测试全部通过 | `dart test` | `All tests passed!`（22 个用例） |

截图见 `progress.md` 第八节与仓库 `images/` 目录。

---

## 六、Git 提交记录

按实践指南第五部分"每步一次提交"执行，提交信息与指南一致：

```
feat: Student & GradeBook models
feat: gradebook stats via collection chains
feat: Logger mixin & unit tests
```

之后为独立研究模块与进度报告追加提交。
