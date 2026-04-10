import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:bayan/core/models/diwan_report.dart';

/// Converts a [DiwanReport] into a professionally branded PDF byte buffer.
///
/// The generated PDF is self-contained (no external fonts required at runtime)
/// and can be written to disk, shared via Share.shareXFiles, or uploaded to
/// Supabase Storage.
class PdfReportService {
  // -------------------------------------------------------------------------
  // Brand palette (matches BayanColors.*)
  // -------------------------------------------------------------------------

  static const _brandGold = PdfColor.fromInt(0xFFD4A94C);
  static const _brandDark = PdfColor.fromInt(0xFF1A1A2E);
  static const _brandAccent = PdfColor.fromInt(0xFF6C63FF);
  static const _textDark = PdfColor.fromInt(0xFF1C1C1E);
  static const _textLight = PdfColor.fromInt(0xFFF5F5F5);
  static const _divider = PdfColor.fromInt(0xFFE0E0E0);
  static const _cardBg = PdfColor.fromInt(0xFFFAFAFA);

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Generates a branded PDF for [report] and returns the raw bytes.
  Future<Uint8List> generate(DiwanReport report) async {
    final doc = pw.Document(
      title: 'تقرير ديوان — ${report.title}',
      author: 'منصة بيان',
      creator: 'Bayan Mobile v1.8',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        header: (ctx) => _buildHeader(ctx, report),
        footer: (ctx) => _buildFooter(ctx, report),
        build: (ctx) => [
          _sectionTitle('ملخص الجلسة'),
          _sessionSection(report.session),
          pw.SizedBox(height: 20),
          _sectionTitle('إحصاءات الجمهور'),
          _audienceSection(report.audience),
          pw.SizedBox(height: 20),
          _sectionTitle('الاقتصاد'),
          _economySection(report.economy),
          pw.SizedBox(height: 20),
          _sectionTitle('التفاعل'),
          _engagementSection(report.engagement),
          pw.SizedBox(height: 20),
          _sectionTitle('رؤى الذكاء الاصطناعي'),
          _aiInsightsSection(report.aiInsights),
        ],
      ),
    );

    return doc.save();
  }

  // -------------------------------------------------------------------------
  // Header / Footer
  // -------------------------------------------------------------------------

  pw.Widget _buildHeader(pw.Context ctx, DiwanReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _brandGold, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'بيان',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandGold,
                ),
              ),
              pw.Text(
                'منصة المحتوى العربي المتميز',
                style: const pw.TextStyle(fontSize: 9, color: _brandAccent),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                report.title,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              pw.Text(
                'تقرير الديوان',
                style: const pw.TextStyle(fontSize: 10, color: _brandAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx, DiwanReport report) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _divider, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _brandAccent),
          ),
          pw.Text(
            'تاريخ التقرير: ${fmt.format(report.generatedAt)}',
            style: const pw.TextStyle(fontSize: 8, color: _brandAccent),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section helpers
  // -------------------------------------------------------------------------

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _brandDark,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: _textLight,
        ),
      ),
    );
  }

  pw.Widget _card({required List<pw.Widget> children}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _divider, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  pw.Widget _statRow(String label, String value, {bool highlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: _textDark),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlight ? _brandGold : _textDark,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _dividerWidget() =>
      pw.Divider(color: _divider, thickness: 0.5, height: 8);

  // -------------------------------------------------------------------------
  // Content sections
  // -------------------------------------------------------------------------

  pw.Widget _sessionSection(DiwanReportSession session) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');
    return _card(
      children: [
        _statRow('مدة الجلسة', session.totalDurationFormatted, highlight: true),
        _dividerWidget(),
        if (session.startedAt != null)
          _statRow('بدأت في', fmt.format(session.startedAt!)),
        if (session.endedAt != null)
          _statRow('انتهت في', fmt.format(session.endedAt!)),
      ],
    );
  }

  pw.Widget _audienceSection(DiwanReportAudience audience) {
    return _card(
      children: [
        _statRow(
          'أعلى عدد مستمعين',
          '${audience.peakListeners}',
          highlight: true,
        ),
        _dividerWidget(),
        _statRow('المستمعون الفريدون', '${audience.uniqueListeners}'),
      ],
    );
  }

  pw.Widget _economySection(DiwanReportEconomy economy) {
    return _card(
      children: [
        _statRow(
          'إجمالي الإيرادات',
          '${economy.totalRevenue} رمز',
          highlight: true,
        ),
        _dividerWidget(),
        _statRow('إيرادات التذاكر', '${economy.ticketRevenue} رمز'),
        _statRow('التذاكر المباعة', '${economy.ticketsSold}'),
        _statRow('قيمة الهدايا', '${economy.totalGiftsValue} رمز'),
      ],
    );
  }

  pw.Widget _engagementSection(DiwanReportEngagement engagement) {
    return _card(
      children: [
        _statRow(
          'أصوات الاستطلاعات',
          '${engagement.totalPollVotes}',
          highlight: true,
        ),
        _dividerWidget(),
        _statRow('استطلاعات أُجريت', '${engagement.pollsConducted}'),
        _statRow('أسئلة طُرحت', '${engagement.totalQuestions}'),
        _statRow('أسئلة أُجيب عنها', '${engagement.questionsAnswered}'),
      ],
    );
  }

  pw.Widget _aiInsightsSection(DiwanReportAiInsights insights) {
    return _card(
      children: [
        pw.Text(
          'الملخص',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _brandAccent,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          insights.summary.isEmpty ? '—' : insights.summary,
          style: const pw.TextStyle(fontSize: 10, color: _textDark),
        ),
        if (insights.keyPoints.isNotEmpty) ...[
          _dividerWidget(),
          pw.Text(
            'النقاط الرئيسية',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _brandAccent,
            ),
          ),
          pw.SizedBox(height: 4),
          ...insights.keyPoints.map(
            (pt) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(
                      color: _brandGold,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(pt, style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
