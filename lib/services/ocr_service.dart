// lib/services/ocr_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  // ═══════════════════════════════════════════════════════════════════
  // EXTRACT TEXT FROM IMAGE
  // ═══════════════════════════════════════════════════════════════════
  Future<String> extractText(File imageFile) async {
    try {
      debugPrint('📄 Starting OCR text extraction...');

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final text = recognizedText.text;

      debugPrint('✅ OCR extracted ${text.length} characters');
      debugPrint('📊 Found ${recognizedText.blocks.length} text blocks');

      return text;
    } catch (e) {
      debugPrint('❌ OCR error: $e');
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // EXTRACT STRUCTURED DATA (Lab Reports)
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> extractLabData(File imageFile) async {
    try {
      debugPrint('🔬 Extracting lab report data...');

      final text = await extractText(imageFile);

      if (text.isEmpty) {
        return {
          'raw_text': '',
          'parameters': {},
          'extracted_count': 0,
        };
      }

      // Parse common lab report patterns
      final Map<String, dynamic> parameters = {};
      final lines = text.split('\n');

      debugPrint('📋 Processing ${lines.length} lines...');

      for (var line in lines) {
        // Skip empty lines
        if (line.trim().isEmpty) continue;

        // Pattern 1: "Parameter: Value Unit (Range)"
        final pattern1 = RegExp(
          r'([A-Za-z\s]+)[:|\s]+(\d+\.?\d*)\s*([A-Za-z/%]*)',
          caseSensitive: false,
        );

        // Pattern 2: "Parameter Value Unit"
        final pattern2 = RegExp(
          r'([A-Za-z\s]{3,})\s+(\d+\.?\d*)\s*([A-Za-z/%]+)?',
          caseSensitive: false,
        );

        var match = pattern1.firstMatch(line) ?? pattern2.firstMatch(line);

        if (match != null) {
          final parameter = match.group(1)?.trim() ?? '';
          final value = match.group(2)?.trim() ?? '';
          final unit = match.group(3)?.trim() ?? '';

          // Filter out invalid parameters
          if (parameter.isNotEmpty &&
              value.isNotEmpty &&
              parameter.length > 2 &&
              parameter.length < 50) {
            parameters[parameter] = {
              'value': value,
              'unit': unit,
              'line': line.trim(),
            };

            debugPrint('✓ Found: $parameter = $value $unit');
          }
        }
      }

      debugPrint('✅ Extracted ${parameters.length} parameters');

      return {
        'raw_text': text,
        'parameters': parameters,
        'extracted_count': parameters.length,
        'line_count': lines.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Lab data extraction error: $e');
      debugPrint('Stack trace: $stackTrace');

      return {
        'raw_text': '',
        'parameters': {},
        'extracted_count': 0,
        'error': e.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // EXTRACT WITH CONFIDENCE SCORES
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> extractWithConfidence(File imageFile) async {
    try {
      debugPrint('🎯 Extracting text with confidence scores...');

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final List<Map<String, dynamic>> blocks = [];
      double totalConfidence = 0.0;
      int blockCount = 0;

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          blocks.add({
            'text': line.text,
            'confidence': 1.0, // ML Kit doesn't provide confidence, use 1.0
            'bounding_box': {
              'left': line.boundingBox.left,
              'top': line.boundingBox.top,
              'right': line.boundingBox.right,
              'bottom': line.boundingBox.bottom,
            },
          });

          totalConfidence += 1.0;
          blockCount++;
        }
      }

      final avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

      debugPrint('✅ Extracted ${blocks.length} text blocks');
      debugPrint(
          '📊 Average confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');

      return {
        'blocks': blocks,
        'block_count': blocks.length,
        'average_confidence': avgConfidence,
        'full_text': recognizedText.text,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error extracting with confidence: $e');
      return {
        'blocks': [],
        'block_count': 0,
        'average_confidence': 0.0,
        'error': e.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // EXTRACT SPECIFIC PATTERNS (e.g., dates, numbers)
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> extractPatterns(File imageFile) async {
    try {
      final text = await extractText(imageFile);

      // Date patterns
      final datePattern = RegExp(
        r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b',
      );
      final dates =
          datePattern.allMatches(text).map((m) => m.group(0)).toList();

      // Phone patterns
      final phonePattern = RegExp(
        r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b',
      );
      final phones =
          phonePattern.allMatches(text).map((m) => m.group(0)).toList();

      // Email patterns
      final emailPattern = RegExp(
        r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
      );
      final emails =
          emailPattern.allMatches(text).map((m) => m.group(0)).toList();

      // Numeric values
      final numberPattern = RegExp(r'\b\d+\.?\d*\b');
      final numbers =
          numberPattern.allMatches(text).map((m) => m.group(0)).toList();

      return {
        'dates': dates,
        'phones': phones,
        'emails': emails,
        'numbers': numbers,
        'patterns_found':
            dates.length + phones.length + emails.length + numbers.length,
      };
    } catch (e) {
      debugPrint('Error extracting patterns: $e');
      return {
        'dates': [],
        'phones': [],
        'emails': [],
        'numbers': [],
        'error': e.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DISPOSE RESOURCES
  // ═══════════════════════════════════════════════════════════════════
  void dispose() {
    debugPrint('🧹 Disposing OCRService...');
    _textRecognizer.close();
    debugPrint('✅ OCRService disposed');
  }
}
