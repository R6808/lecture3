/// logger.dart — 日志能力 mixin
///
/// 对应实践指南三第三部分（mixin：跨类复用）与课堂案例 dart_oo 步骤三。
library;

/// 日志能力
///
/// 为什么用 mixin 而不是继承：日志是**横切能力**，与"是不是成绩册"无关。
/// 如果用 `class GradeBook extends Loggable` 来获得日志，
/// 就等于宣称"成绩册是一种日志器"，继承关系被污染，
/// 而且一个类只能 extends 一个父类，这唯一的继承位会被日志这种小事占掉。
/// 用 mixin 则可以让任意类按需混入，且能混入多个。
mixin Logger {
  /// 日志前缀：默认用运行时类型名，子类可覆写
  String get logTag => runtimeType.toString();

  /// 打印一条日志
  ///
  /// 支持多行：把每一行都加上前缀，避免只有第一行带标签、后面几行
  /// 看起来像"没人认领"的裸输出。
  void log(String msg) {
    final prefix = '[$logTag] ';
    print(msg.split('\n').map((line) => '$prefix$line').join('\n'));
  }

  /// 打印带分隔线的标题
  void logTitle(String title) {
    log('===== $title =====');
  }
}

/// 校验能力 mixin
///
/// 演示混入的约定：mixin 可以声明抽象 getter，要求宿主类自己实现。
mixin Validated {
  /// 宿主必须实现：是否通过校验
  bool get isValid;

  /// 校验失败就抛错
  void check() {
    if (!isValid) {
      throw StateError('$runtimeType 校验未通过');
    }
  }
}
