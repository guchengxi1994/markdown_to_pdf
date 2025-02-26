// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:screenshot/screenshot.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Markdown to PDF')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final rawMarkdown = """
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
""";

              final pdf = await convertMarkdownToPdf(rawMarkdown);
              final bytes = await pdf.save();

              // Save to file
              final file = File('output.pdf');
              await file.writeAsBytes(bytes);

              print('PDF saved to ${file.absolute.path}');
            },
            child: Text('Generate PDF'),
          ),
        ),
      ),
    );
  }
}

Future<pw.Document> convertMarkdownToPdf(String markdownText) async {
  final document = pw.Document();

  // Parse Markdown to AST
  final nodes = md.Document().parse(markdownText);

  // Build PDF content
  final widgets = <pw.Widget>[];
  for (final node in nodes) {
    widgets.addAll(await _buildPdfWidgets(node));
  }

  document.addPage(
    pw.Page(
      build:
          (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: widgets,
          ),
    ),
  );

  return document;
}

Future<List<pw.Widget>> _buildPdfWidgets(md.Node node) async {
  final widgets = <pw.Widget>[];

  if (node is md.Element) {
    switch (node.tag) {
      case 'h1':
        widgets.add(
          pw.Text(
            node.textContent,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        );
        break;
      case 'h2':
        widgets.add(
          pw.Text(
            node.textContent,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        );
        break;
      case 'h3':
        widgets.add(
          pw.Text(
            node.textContent,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        );
        break;
      case 'ul':
        widgets.add(await _buildList(node));
        break;
      case 'p':
        widgets.add(await _buildParagraph(node));
        break;
      case 'pre':
        widgets.add(
          pw.Text(
            node.textContent,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
        );
        break;
      default:
        widgets.add(pw.Text(node.textContent));
    }
  } else if (node is md.Text) {
    widgets.add(await _parseInlineContent(node.text));
  }

  return widgets;
}

Future<pw.Widget> _buildList(md.Element node) async {
  final items = <pw.Widget>[];
  for (final child in node.children ?? []) {
    if (child is md.Element && child.tag == 'li') {
      items.add(
        pw.Text('• ${child.textContent}', style: pw.TextStyle(fontSize: 12)),
      );
    }
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: items,
  );
}

Future<pw.Widget> _buildParagraph(md.Element node) async {
  final widgets = <pw.Widget>[];
  for (final child in node.children ?? []) {
    if (child is md.Text) {
      widgets.add(await _parseInlineContent(child.text));
    } else if (child is md.Element) {
      if (child.tag == "li") {
        widgets.add(
          pw.Text(
            child.textContent,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        );
      }
      widgets.add(
        pw.Text(child.textContent, style: pw.TextStyle(fontSize: 12)),
      );
    }
  }
  return pw.Row(children: widgets);
}

Future<pw.Widget> _parseInlineContent(String text) async {
  final regex = RegExp(r'\$(.*?)\$'); // Match inline LaTeX, e.g., $E=mc^2$
  final parts = text.split(regex);
  final widgets = <pw.Widget>[];

  for (int i = 0; i < parts.length; i++) {
    if (i % 2 == 1) {
      // Render LaTeX as an image
      final latex = parts[i];
      final image = await _latexToImage(latex);
      widgets.add(pw.Image(image));
    } else {
      widgets.add(pw.Text(parts[i], style: pw.TextStyle(fontSize: 12)));
    }
  }

  return pw.Row(children: widgets);
}

final ScreenshotController screenshotController = ScreenshotController();

Future<pw.MemoryImage> _latexToImage(String latex) async {
  try {
    // Use flutter_math to render LaTeX as SVG
    final svg = Math.tex(
      latex,
      mathStyle: MathStyle.display,
      textStyle: TextStyle(fontSize: 20),
    );
    final data = await screenshotController.captureFromWidget(
      svg,
      delay: Duration(milliseconds: 300),
    );
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (e) {
    return pw.MemoryImage(Uint8List(0)); // Fallback for errors
  }
}
