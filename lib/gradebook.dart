/// gradebook.dart — GradeBook 类
///
/// 对应实践指南三第五部分「课堂案例复现 dart_oo」步骤一：建模。
/// 本步骤只建立"成绩册能装下一批学生"这一最小能力，
/// 统计功能在步骤二实现。
library;

import 'student.dart';

/// 成绩册
class GradeBook {
  /// 内部用 List 承载（List 有序、可重复，符合"成绩册有一行行记录"的语义）
  final List<Student> students;

  /// 构造时接收列表；用 List.unmodifiable 包一层，
  /// 防止外部拿到引用后绕过本类直接改数据。
  GradeBook(List<Student> input) : students = List.unmodifiable(input);

  /// 空成绩册
  GradeBook.empty() : students = const [];

  /// 学生人数
  int get count => students.length;
}
