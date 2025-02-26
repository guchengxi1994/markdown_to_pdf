// ignore_for_file: avoid_print

import 'package:markdown/markdown.dart';

void main() {
  // Markdown 文本
  String markdownText = '''
# 这是一个标题

这是一些文本，包含**加粗文本**和*斜体文本*。

- 列表项 1
- 列表项 2

sss
  ''';

  // 解析 Markdown 并生成语法树
  var nodes = parseMarkdown(markdownText);

  // 打印语法树
  for (var node in nodes) {
    if (node is Element) {
      print("tag:${node.tag}");
      for (Node child in node.children ?? []) {
        if (child is Element) {
          print("    tag:${child.tag}");
        }
        print("    child:${child.textContent}  }");
      }
      print("attr:${node.attributes}");
      print("|||||||||||||||||||||||||||||||||||||");
    }
  }
}

// 自定义函数来解析 Markdown
List<Node> parseMarkdown(String markdown) {
  // 使用 markdown 库解析
  return Document().parseLines(markdown.split('\n'));
}
