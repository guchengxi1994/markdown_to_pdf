// ignore_for_file: avoid_init_to_null

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:collection/collection.dart';
import 'package:markdown/markdown.dart' as md;

const double normalFontSize = 12.0;
const double h1FontSize = 24.0;
const double h2FontSize = 18.0;
const double h3FontSize = 16.0;

class Converter {
  Converter._();
  static pw.Font? regularFont = null;
  static Future<void> loadRegularFont(String path) async {
    final fontBytes = await File(path).readAsBytes();
    final font = pw.Font.ttf(ByteData.view(fontBytes.buffer));
    regularFont = font;
  }

  static void loadRegularFontFromBytes(ByteData bytes) {
    final font = pw.Font.ttf(bytes);
    regularFont = font;
  }

  static pw.Font? boldFont = null;
  static Future<void> loadBoldFont(String path) async {
    final fontBytes = await File(path).readAsBytes();
    final font = pw.Font.ttf(ByteData.view(fontBytes.buffer));
    boldFont = font;
  }

  static void loadBoldFontFromBytes(ByteData bytes) {
    final font = pw.Font.ttf(bytes);
    boldFont = font;
  }

  static pw.Font? italicFont = null;
  static Future<void> loadItalicFont(String path) async {
    final fontBytes = await File(path).readAsBytes();
    final font = pw.Font.ttf(ByteData.view(fontBytes.buffer));
    italicFont = font;
  }

  static void loadItalicFontFromBytes(ByteData bytes) {
    final font = pw.Font.ttf(bytes);
    italicFont = font;
  }

  static Future<pw.Document> convert(String markdown) async {
    return _convertMarkdownToPdf(markdown, {
      "regular": regularFont,
      "bold": boldFont,
      "italic": italicFont,
    });
  }
}

Future<pw.Document> _convertMarkdownToPdf(
  String markdownText,
  Map<String, pw.Font?> fonts,
) async {
  final doc = pw.Document();

  final md.Document markdownDoc = md.Document();
  final nodes = markdownDoc.parseLines(markdownText.split('\n'));

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return _convertMarkdownAstToPdf(nodes, fonts);
      },
    ),
  );

  return doc;
}

// 解析 Markdown AST 并转换为 PDF 组件
List<pw.Widget> _convertMarkdownAstToPdf(
  List<md.Node> nodes,
  Map<String, pw.Font?>? fonts,
) {
  List<pw.Widget> widgets = [];

  for (var node in nodes) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'p':
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: _buildStyledText(node, fonts),
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
                  font: fonts?["regular"],
                  fontNormal: fonts?["regular"],
                  fontBold: fonts?["bold"],
                  fontItalic: fonts?["italic"],
                  fontBoldItalic: fonts?["italic"],
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
                    return _convertListItem(li, i, fonts);
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
                    return pw.Text(
                      "${index++}. ${li.textContent}",
                      style: pw.TextStyle(
                        font: fonts?["regular"],
                        fontNormal: fonts?["regular"],
                        fontBold: fonts?["bold"],
                        fontItalic: fonts?["italic"],
                        fontBoldItalic: fonts?["italic"],
                      ),
                    );
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
      widgets.add(
        pw.Text(
          node.text,
          style: pw.TextStyle(
            fontNormal: fonts?["regular"],
            font: fonts?["regular"],
            fontBold: fonts?["bold"],
            fontItalic: fonts?["italic"],
            fontBoldItalic: fonts?["italic"],
          ),
        ),
      );
    }
  }

  return widgets;
}

// 处理嵌套样式文本
pw.Widget _buildStyledText(md.Element element, Map<String, pw.Font?>? fonts) {
  return pw.RichText(
    text: pw.TextSpan(children: _parseMarkdownText(element.children!, fonts)),
  );
}

// 递归解析 Markdown 文本样式
List<pw.InlineSpan> _parseMarkdownText(
  List<md.Node> nodes,
  Map<String, pw.Font?>? fonts,
) {
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
          style = pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            font: fonts?["regular"],
            fontNormal: fonts?["regular"],
            fontBold: fonts?["bold"],
            fontItalic: fonts?["italic"],
            fontBoldItalic: fonts?["italic"],
          );
        } else if (node.tag == 'em') {
          style = pw.TextStyle(
            fontStyle: pw.FontStyle.italic,
            font: fonts?["regular"],
            fontNormal: fonts?["regular"],
            fontBold: fonts?["bold"],
            fontItalic: fonts?["italic"],
            fontBoldItalic: fonts?["italic"],
          );
        }

        spans.add(pw.TextSpan(text: node.textContent, style: style));
      }
    }
  }

  return spans;
}

pw.Widget _convertListItem(
  md.Node node,
  int index,
  Map<String, pw.Font?>? fonts,
) {
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
                  return pw.Text(
                    li.textContent,
                    style: pw.TextStyle(
                      font: fonts?["regular"],
                      fontNormal: fonts?["regular"],
                      fontBold: fonts?["bold"],
                      fontItalic: fonts?["italic"],
                      fontBoldItalic: fonts?["italic"],
                    ),
                  );
                }).toList(),
          ),
        );
      } else {
        if (child is md.Text) {
          children.add(
            pw.Text(
              child.textContent,
              style: pw.TextStyle(
                font: fonts?["regular"],
                fontNormal: fonts?["regular"],
                fontBold: fonts?["bold"],
                fontItalic: fonts?["italic"],
                fontBoldItalic: fonts?["italic"],
              ),
            ),
          );
        } else {
          children.add(_buildStyledText(child as md.Element, fonts));
        }
      }
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "   ${index + 1}. ",
          style: pw.TextStyle(
            font: fonts?["regular"],
            fontNormal: fonts?["regular"],
            fontBold: fonts?["bold"],
            fontItalic: fonts?["italic"],
            fontBoldItalic: fonts?["italic"],
          ),
        ),
        ...children,
      ],
    );
  }
  return pw.Container();
}
