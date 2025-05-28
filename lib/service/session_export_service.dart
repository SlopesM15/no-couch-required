import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:no_couch_needed/models/therapy_sessions.dart';
import 'package:no_couch_needed/models/transcript_line.dart';
import 'package:no_couch_needed/pages/pdf_viewer_page.dart';

class SessionExportService {
  static Future<void> exportSessionAsPDF({
    required TherapySession session,
    required BuildContext context,
  }) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: LoadingAnimationWidget.newtonCradle(
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      // Generate PDF
      final pdf = pw.Document();

      // Format dates
      final sessionDate = DateFormat('MMMM dd, yyyy').format(session.createdAt);
      final sessionTime = DateFormat('h:mm a').format(session.createdAt);

      // Calculate duration
      final duration =
          session.transcript.isNotEmpty
              ? session.transcript.last.timestamp
                  .difference(session.createdAt)
                  .inMinutes
              : 0;

      // Add metadata
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Therapy Session Transcript',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Therapist: ${session.therapistAgent.isNotEmpty ? session.therapistAgent : "Unknown"}',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Date: $sessionDate at $sessionTime',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Duration: $duration minutes | Messages: ${session.transcript.length}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Mood Summary if available
              if (session.moodEntries.isNotEmpty) ...[
                pw.Text(
                  'Mood Journey',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children:
                        session.moodEntries.map((entry) {
                          final moodTime = entry.sessionTime ~/ 60;
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Text(
                              '${moodTime}m - ${entry.mood}',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Transcript Header
              pw.Text(
                'Conversation Transcript',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Transcript Messages
              ...session.transcript.map((line) {
                final messageTime = DateFormat('h:mm a').format(line.timestamp);
                final isUser = line.role.toLowerCase() == 'user';

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Speaker and time
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            isUser
                                ? 'You'
                                : (session.therapistAgent.isNotEmpty
                                    ? session.therapistAgent.split(' ').first
                                    : 'Therapist'),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color:
                                  isUser
                                      ? PdfColors.blue700
                                      : PdfColors.green700,
                            ),
                          ),
                          pw.Text(
                            messageTime,
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      // Message content
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: isUser ? PdfColors.blue50 : PdfColors.green50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(
                            color:
                                isUser ? PdfColors.blue200 : PdfColors.green200,
                          ),
                        ),
                        child: pw.Text(
                          line.text,
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Footer
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on ${DateFormat('MMMM dd, yyyy at h:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'This transcript is confidential and for personal use only.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final fileName =
          'therapy_session_${DateFormat('yyyyMMdd_HHmmss').format(session.createdAt)}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to PDF viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  PDFViewerPage(pdfFile: file, title: 'Session - $sessionDate'),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Export Failed',
                style: TextStyle(color: Colors.white),
              ),
              content: Text(
                'Failed to export session: ${e.toString()}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK', style: TextStyle(color: Colors.cyanAccent)),
                ),
              ],
            ),
      );
    }
  }
}
