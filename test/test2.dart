import 'package:markdown/markdown.dart';

const testStr = """
## ChatGPT Response

----

Welcome to ChatGPT! Below is an example of a response with Markdown and LaTeX code:

### Markdown Example

You can use Markdown to format text easily. Here are some examples:

- **Bold Text**: **This text is bold**
- *Italic Text*: *This text is italicized*
- [Link](https://www.example.com): [This is a link](https://www.example.com)
- Lists:
  1. Item 1
  2. Item 2
  3. Item 3

### LaTeX Example

You can also use LaTeX for mathematical expressions. Here's an example:

- **Equation**: \( f(x) = x^2 + 2x + 1 \)
- **Integral**: \( \int_{0}^{1} x^2 \, dx \)
- **Matrix**:

\[
\begin{bmatrix}
1 & 2 & 3 \\
4 & 5 & 6 \\
7 & 8 & 9
\end{bmatrix}
\]

## Image Example

![image](./a.png)

![](data:image/png;base64,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)


### Conclusion

Markdown and LaTeX can be powerful tools for formatting text and mathematical expressions in your Flutter app. If you have any questions or need further assistance, feel free to ask!

""";

void main() {
  // 解析 Markdown 并生成语法树
  var nodes = parseMarkdown(testStr);

  // 打印语法树
  for (var node in nodes) {
    printNode(node);
    print("\n");
  }
}

void printNode(Node n) {
  if (n is Element) {
    if (n.children == null || n.children!.length == 1) {
      print("element tag:${n.tag} text: ${n.textContent}");
    } else {
      for (Node child in n.children ?? []) {
        printNode(child);
      }
    }
  } else if (n is Text) {
    print("text: ${n.textContent}");
  }
}

// 自定义函数来解析 Markdown
List<Node> parseMarkdown(String markdown) {
  // 使用 markdown 库解析
  return Document().parseLines(markdown.split('\n'));
}
