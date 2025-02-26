import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:markdown/markdown.dart' as md;

const double normalFontSize = 12.0;
const double h1FontSize = 24.0;
const double h2FontSize = 18.0;
const double h3FontSize = 16.0;

class Converter {
  Converter._();

  static pw.Font? regularFont;
  static pw.Font? boldFont;
  static pw.Font? italicFont;

  static Future<void> loadFont(String path, Function(pw.Font) setter) async {
    final fontBytes = await File(path).readAsBytes();
    setter(pw.Font.ttf(ByteData.view(fontBytes.buffer)));
  }

  static void loadFontFromBytes(ByteData bytes, Function(pw.Font) setter) {
    setter(pw.Font.ttf(bytes));
  }

  static Future<pw.Document> convert(String markdown) async {
    return _convertMarkdownToPdf(markdown);
  }
}

Future<pw.Document> _convertMarkdownToPdf(String markdownText) async {
  final doc = pw.Document();
  final nodes = md.Document().parseLines(markdownText.split('\n'));

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
          int level = int.parse(node.tag.substring(1));
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                node.textContent,
                style: _defaultTextStyle().copyWith(
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
                  node.children!.map((li) => _convertListItem(li)).toList(),
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
                      style: _defaultTextStyle(),
                    );
                  }).toList(),
            ),
          );
          break;
        case 'img':
          final imageWidget = _convertImage(node.attributes['src']);
          if (imageWidget != null) widgets.add(imageWidget);
          break;
      }
    } else if (node is md.Text) {
      widgets.add(pw.Text(node.text, style: _defaultTextStyle()));
    }
  }
  return widgets;
}

pw.Widget _buildStyledText(md.Element element) {
  return pw.RichText(
    text: pw.TextSpan(children: _parseMarkdownText(element.children!)),
  );
}

List<pw.InlineSpan> _parseMarkdownText(List<md.Node> nodes) {
  return nodes.map((node) {
    if (node is md.Text) {
      return pw.TextSpan(text: node.text, style: _defaultTextStyle());
    } else if (node is md.Element) {
      var style = _defaultTextStyle();
      if (node.tag == 'strong') {
        style = style.copyWith(fontWeight: pw.FontWeight.bold);
      } else if (node.tag == 'em') {
        style = style.copyWith(fontStyle: pw.FontStyle.italic);
      }
      return pw.TextSpan(text: node.textContent, style: style);
    }
    return const pw.TextSpan(text: '');
  }).toList();
}

pw.Widget _convertListItem(md.Node node) {
  if (node is md.Element && node.tag == 'li') {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("• ", style: _defaultTextStyle()),
        pw.Expanded(child: _buildStyledText(node)),
      ],
    );
  }
  return pw.Container();
}

pw.Widget? _convertImage(String? src) {
  if (src == null) return null;
  try {
    pw.MemoryImage? image;
    if (src.startsWith('data:image')) {
      final base64Data = src.split(',')[1];
      image = pw.MemoryImage(base64Decode(base64Data));
    } else {
      final file = File(src);
      if (file.existsSync()) {
        image = pw.MemoryImage(file.readAsBytesSync());
      }
    }
    return image != null
        ? pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Image(image),
        )
        : null;
  } catch (_) {
    return pw.Text('[Invalid Image]', style: _defaultTextStyle());
  }
}

pw.TextStyle _defaultTextStyle() {
  return pw.TextStyle(
    font: Converter.regularFont,
    fontNormal: Converter.regularFont,
    fontBold: Converter.boldFont,
    fontItalic: Converter.italicFont,
    fontSize: normalFontSize,
    fontFallback:
        [
          Converter.regularFont,
          Converter.boldFont,
          Converter.italicFont,
        ].where((font) => font != null).cast<pw.Font>().toList(),
  );
}
