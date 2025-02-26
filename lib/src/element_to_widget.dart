import 'dart:convert';
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:collection/collection.dart';
import 'package:markdown/markdown.dart' as md;

const double normalFontSize = 12.0;
const double h1FontSize = 24.0;
const double h2FontSize = 18.0;
const double h3FontSize = 16.0;

Future<pw.Document> convertMarkdownToPdf(String markdownText) async {
  final doc = pw.Document();

  final md.Document markdownDoc = md.Document();
  final nodes = markdownDoc.parseLines(markdownText.split('\n'));

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return _convertMarkdownAstToPdf(nodes);
      },
    ),
  );

  return doc;
}

// 解析 Markdown AST 并转换为 PDF 组件
List<pw.Widget> _convertMarkdownAstToPdf(List<md.Node> nodes) {
  List<pw.Widget> widgets = [];

  for (var node in nodes) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'p':
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: _buildStyledText(node),
            ),
          );
          break;
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          int level = int.parse(node.tag.substring(1));
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                node.textContent,
                style: pw.TextStyle(
                  fontSize: 24 - (level * 2),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );
          break;
        case 'ul':
          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  node.children!.mapIndexed((i, li) {
                    return _convertListItem(li, i);
                  }).toList(),
            ),
          );
          break;
        case 'ol':
          int index = 1;
          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children:
                  node.children!.map((li) {
                    return pw.Text("${index++}. ${li.textContent}");
                  }).toList(),
            ),
          );
          break;
        case 'img':
          String? src = node.attributes['src'];
          if (src != null) {
            pw.MemoryImage? image;
            if (src.startsWith('data:image')) {
              // 解析 Base64 图片
              final base64Data = src.split(',')[1];
              image = pw.MemoryImage(base64Decode(base64Data));
            } else {
              // 处理本地文件路径图片
              final file = File(src);
              if (file.existsSync()) {
                image = pw.MemoryImage(file.readAsBytesSync());
              }
            }
            if (image != null) {
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Image(image),
                ),
              );
            }
          }
          break;
      }
    } else if (node is md.Text) {
      widgets.add(pw.Text(node.text));
    }
  }

  return widgets;
}

// 处理嵌套样式文本
pw.Widget _buildStyledText(md.Element element) {
  return pw.RichText(
    text: pw.TextSpan(children: _parseMarkdownText(element.children!)),
  );
}

// 递归解析 Markdown 文本样式
List<pw.InlineSpan> _parseMarkdownText(List<md.Node> nodes) {
  List<pw.InlineSpan> spans = [];

  for (var node in nodes) {
    if (node is md.Text) {
      spans.add(pw.TextSpan(text: node.text));
    } else if (node is md.Element) {
      if (node.tag == 'img') {
        String? src = node.attributes['src'];
        if (src != null) {
          try {
            pw.MemoryImage? image;
            if (src.startsWith('data:image')) {
              // Base64 图片解析
              final base64Data = src.split(',')[1];
              image = pw.MemoryImage(base64Decode(base64Data));
            } else {
              // 处理本地图片
              final file = File(src);
              if (file.existsSync()) {
                image = pw.MemoryImage(file.readAsBytesSync());
              }
            }
            if (image != null) {
              spans.add(
                pw.WidgetSpan(
                  child: pw.Container(
                    width: 100, // 可根据需求调整图片尺寸
                    height: 100,
                    child: pw.Image(image),
                  ),
                ),
              );
            }
          } catch (e) {
            spans.add(pw.TextSpan(text: '[Invalid Image]'));
          }
        }
      } else {
        // 处理加粗、斜体等样式
        pw.TextStyle style = pw.TextStyle();

        if (node.tag == 'strong') {
          style = pw.TextStyle(fontWeight: pw.FontWeight.bold);
        } else if (node.tag == 'em') {
          style = pw.TextStyle(fontStyle: pw.FontStyle.italic);
        }

        spans.add(pw.TextSpan(text: node.textContent, style: style));
      }
    }
  }

  return spans;
}

pw.Widget _convertListItem(md.Node node, int index) {
  if (node is md.Element && node.tag == 'li') {
    List<pw.Widget> children = [];

    for (var child in node.children!) {
      if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
        // children.addAll(_convertMarkdownAstToPdf([child]));

        children.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children:
                child.children!.map((li) {
                  return pw.Text(li.textContent);
                }).toList(),
          ),
        );
      } else {
        if (child is md.Text) {
          children.add(pw.Text(child.textContent));
        } else {
          children.add(_buildStyledText(child as md.Element));
        }
      }
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [pw.Text("   ${index + 1}. "), ...children],
    );
  }
  return pw.Container();
}
