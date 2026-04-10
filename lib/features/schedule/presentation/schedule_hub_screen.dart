import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bayan/core/theme/theme.dart';
import 'package:bayan/core/widgets/glassmorphic_container.dart';
import 'package:bayan/core/widgets/haptic_button.dart';
import 'package:bayan/core/widgets/pulsing_dot.dart';

class _ScheduledDiwan {
  final String id;
  final String title;
  final String host;
  final String date;
  final String time;
  final IconData icon;
  final Color accentColor;
  final bool isToday;
  final bool isLive;

  const _ScheduledDiwan({
    required this.id,
    required this.title,
    required this.host,
    required this.date,
    required this.time,
    required this.icon,
    required this.accentColor,
    this.isToday = false,
    this.isLive = false,
  });
}

const _upcomingDiwans = [
  _ScheduledDiwan(
    id: 'sd-1',
    title: 'ديوان الشعر الحديث',
    host: 'عبدالله المطيري',
    date: 'اليوم',
    time: '٩:٠٠ م',
    icon: Icons.auto_stories_rounded,
    accentColor: BayanColors.accent,
    isToday: true,
    isLive: true,
  ),
  _ScheduledDiwan(
    id: 'sd-2',
    title: 'نقاشات تقنية',
    host: 'سارة الفهد',
    date: 'اليوم',
    time: '١٠:٣٠ م',
    icon: Icons.memory_rounded,
    accentColor: Color(0xFF6C3FA0),
    isToday: true,
  ),
  _ScheduledDiwan(
    id: 'sd-3',
    title: 'مجلس الأدب الكويتي',
    host: 'فهد العنزي',
    date: 'غداً',
    time: '٨:٠٠ م',
    icon: Icons.menu_book_rounded,
    accentColor: Color(0xFF2A6F97),
  ),
  _ScheduledDiwan(
    id: 'sd-4',
    title: 'صالون الفكر العربي',
    host: 'نورة الصباح',
    date: 'الخميس ١٢ أبريل',
    time: '٩:٣٠ م',
    icon: Icons.psychology_rounded,
    accentColor: Color(0xFF8B5E3C),
  ),
  _ScheduledDiwan(
    id: 'sd-5',
    title: 'ريادة الأعمال',
    host: 'محمد الراشد',
    date: 'الجمعة ١٣ أبريل',
    time: '٧:٠٠ م',
    icon: Icons.rocket_launch_rounded,
    accentColor: Color(0xFFD4AF37),
  ),
];

const _weekDays = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];

class ScheduleHubScreen extends StatefulWidget {
  const ScheduleHubScreen({super.key});

  @override
  State<ScheduleHubScreen> createState() => _ScheduleHubScreenState();
}

class _ScheduleHubScreenState extends State<ScheduleHubScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDay = 2;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _showScheduleFlow() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ScheduleDiwanSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BayanColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildWeekStrip()),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildSectionTitle('المجالس القادمة')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final start = (index * 0.15).clamp(0.0, 0.6);
                  final end = (start + 0.4).clamp(0.0, 1.0);
                  final interval = CurveTween(
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  );
                  return AnimatedBuilder(
                    animation: _staggerController,
                    builder: (context, child) {
                      final v = interval.transform(
                        _staggerController.value.clamp(0.0, 1.0),
                      );
                      return Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - v)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ScheduleCard(diwan: _upcomingDiwans[index]),
                    ),
                  );
                }, childCount: _upcomingDiwans.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الجدول',
                  style: GoogleFonts.cairo(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: BayanColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أبريل ٢٠٢٦',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: BayanColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          HapticButton(
            hapticType: HapticFeedbackType.medium,
            onTap: _showScheduleFlow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: BayanColors.accent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: BayanColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    color: BayanColors.background,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'جدولة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BayanColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GlassmorphicContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: List.generate(7, (index) {
            final isSelected = index == _selectedDay;
            final dayNum = 7 + index;
            final hasEvent =
                index == 2 || index == 3 || index == 4 || index == 5;
            return Expanded(
              child: HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: () => setState(() => _selectedDay = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BayanColors.accent.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? Border.all(
                            color: BayanColors.accent.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weekDays[index],
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? BayanColors.accent
                              : BayanColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dayNum',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? BayanColors.accent
                              : BayanColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasEvent
                              ? BayanColors.accent
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 14),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: BayanColors.textPrimary,
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final _ScheduledDiwan diwan;
  const _ScheduleCard({required this.diwan});

  @override
  Widget build(BuildContext context) {
    return HapticButton(
      hapticType: HapticFeedbackType.selection,
      onTap: () => HapticFeedback.selectionClick(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: BayanColors.glassBackground,
              border: Border.all(
                color: diwan.isLive
                    ? diwan.accentColor.withValues(alpha: 0.25)
                    : BayanColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: diwan.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: diwan.accentColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(diwan.icon, color: diwan.accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diwan.title,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        diwan.host,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: BayanColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13,
                            color: diwan.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${diwan.date} · ${diwan.time}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: diwan.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (diwan.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: BayanColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PulsingDot(color: Colors.white, size: 5),
                        const SizedBox(width: 4),
                        Text(
                          'مباشر',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: BayanColors.background,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  HapticButton(
                    hapticType: HapticFeedbackType.medium,
                    onTap: () => HapticFeedback.mediumImpact(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: diwan.accentColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: diwan.accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: diwan.accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleDiwanSheet extends StatefulWidget {
  const _ScheduleDiwanSheet();

  @override
  State<_ScheduleDiwanSheet> createState() => _ScheduleDiwanSheetState();
}

class _ScheduleDiwanSheetState extends State<_ScheduleDiwanSheet> {
  final _titleController = TextEditingController();
  int _selectedHour = 9;
  int _selectedMinute = 0;
  bool _isPM = true;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: BayanColors.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: BayanColors.glassBorder.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BayanColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.add_circle_rounded,
                      color: BayanColors.accent,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'جدولة ديوان جديد',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: BayanColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: BayanColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اسم الديوان',
                    hintStyle: GoogleFonts.cairo(
                      color: BayanColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.edit_note_rounded,
                      color: BayanColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 20),
                _buildTimePicker(),
                const SizedBox(height: 28),
                HapticButton(
                  hapticType: HapticFeedbackType.heavy,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: BayanColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: BayanColors.accent.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'تأكيد الجدولة',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: BayanColors.background,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final dates = List.generate(
      7,
      (i) => DateTime.now().add(Duration(days: i)),
    );
    const dayNames = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التاريخ',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: BayanColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = date.day == _selectedDate.day;
              return HapticButton(
                hapticType: HapticFeedbackType.selection,
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 58,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BayanColors.accent.withValues(alpha: 0.15)
                        : BayanColors.glassBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? BayanColors.accent.withValues(alpha: 0.4)
                          : BayanColors.glassBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNames[date.weekday % 7],
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? BayanColors.accent
                              : BayanColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? BayanColors.accent
                              : BayanColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الوقت',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: BayanColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTimeWheel(
                value: _selectedHour,
                max: 12,
                min: 1,
                onChanged: (v) => setState(() => _selectedHour = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                ':',
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: BayanColors.accent,
                ),
              ),
            ),
            Expanded(
              child: _buildTimeWheel(
                value: _selectedMinute,
                max: 59,
                min: 0,
                step: 15,
                onChanged: (v) => setState(() => _selectedMinute = v),
              ),
            ),
            const SizedBox(width: 16),
            _buildAmPmToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeWheel({
    required int value,
    required int max,
    required int min,
    int step = 1,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: BayanColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: HapticButton(
              hapticType: HapticFeedbackType.selection,
              onTap: () {
                final next = value - step;
                onChanged(next < min ? max : next);
              },
              child: const Icon(
                Icons.remove_rounded,
                color: BayanColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: BayanColors.textPrimary,
            ),
          ),
          Expanded(
            child: HapticButton(
              hapticType: HapticFeedbackType.selection,
              onTap: () {
                final next = value + step;
                onChanged(next > max ? min : next);
              },
              child: const Icon(
                Icons.add_rounded,
                color: BayanColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmPmToggle() {
    return Container(
      decoration: BoxDecoration(
        color: BayanColors.glassBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BayanColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () => setState(() => _isPM = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !_isPM
                    ? BayanColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                ),
              ),
              child: Text(
                'ص',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: !_isPM
                      ? BayanColors.accent
                      : BayanColors.textSecondary,
                ),
              ),
            ),
          ),
          HapticButton(
            hapticType: HapticFeedbackType.selection,
            onTap: () => setState(() => _isPM = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isPM
                    ? BayanColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(13),
                ),
              ),
              child: Text(
                'م',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _isPM ? BayanColors.accent : BayanColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
