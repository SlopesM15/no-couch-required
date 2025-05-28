import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class PDFViewerPage extends StatefulWidget {
  final File pdfFile;
  final String title;

  const PDFViewerPage({Key? key, required this.pdfFile, required this.title})
    : super(key: key);

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';
  PDFViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF414345),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share PDF',
            onPressed: _sharePDF,
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfFile.path,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              debugPrint(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              debugPrint('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              controller = pdfViewController;
            },
            onLinkHandler: (String? uri) {
              debugPrint('goto uri: $uri');
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
                  ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.cyanAccent),
                          const SizedBox(height: 16),
                          Text(
                            'Loading PDF...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                  : Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Page ${currentPage! + 1} of $pages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
              : Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sharePDF,
        backgroundColor: Colors.cyanAccent,
        tooltip: 'Share PDF',
        child: const Icon(Icons.share_rounded, color: Colors.black),
      ),
    );
  }

  void _sharePDF() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.pdfFile.path)],
        subject: widget.title,
        text: 'Therapy session transcript',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
