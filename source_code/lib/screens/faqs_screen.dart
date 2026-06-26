import 'package:flutter/material.dart';

import '../constants.dart';
import '../widgets/glass_card.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  int? _expandedIndex;

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'What is this app about?',
      answer:
          'This is a productivity app that helps you manage your tasks, set reminders, and organize work sessions. You can create custom lists, categorize tasks, and track your progress over time.',
    ),
    _FaqItem(
      question: 'What are sessions and how do they work?',
      answer:
          'Sessions are focused work timers. You can design a session with multiple tasks, and add breaks, each with a set duration. When you start a session, a countdown timer runs for each task followed by optional breaks. This helps you stay focused using structured time blocks, very helpful for gym workout sessions or study sessions, sessions make sure that you meet a defined timeline or only spend a certain amount of time on a task without getting distracted by other things ',
    ),
    _FaqItem(
      question: 'How do I create a session?',
      answer:
          'Go to the Sessions tab from the bottom navigation bar, now tap "Create New Session" button on top of the screen. Give your session a title, then add tasks and/or breaks with their respective durations. You can reorder tasks, edit them, or remove them before saving, you can edit this session anytime later.',
    ),
    _FaqItem(
      question: 'What are custom lists and how do I create one?',
      answer:
          'Custom lists let you group tasks and categorize them for better management,. Go to the Profile tab and tap "My Lists", now click "Add List" button, Give you list a name, and choose a unique icon for it as a marker, then click create.',
    ),
    _FaqItem(
      question: 'How can I add tasks into a specific list?',
      answer:
          'On Home screen, click on the downward arrow in the top right corner, this will show all the available lists, including any of the custom lists you have added, select any list of your choice, now all the tasks you add will be added to the selected list alongside the ALL Tasks list, you can switch between lists anytime.',
    ),
    _FaqItem(
      question: 'What do the task categories mean?',
      answer:
          'Categories help you organize tasks by type. The available categories are Important, Study, Work, and Home. Each category has a distinct color so you can quickly identify task types at a glance.',
    ),
    _FaqItem(
      question: 'How do reminders work?',
      answer:
          'Remainder notifications are genrated on three occasions 1: When a task is due in 12 hours, 2: when a task is due in 2 hours, 3: when you miss the deadline for a task. You can tap on any reminder to go directly to that task, also you get a rescedule button on the remainder notification to set new due date for missed tasks.',
    ),
    _FaqItem(
      question: 'Is my data safe and synced?',
      answer:
          'Yes. Your data is stored securely om cloud storage. It syncs across your devices in real time and is tied to your account. You can access your tasks and sessions from anywhere by logging in.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.containerPadding,
                      right: AppSpacing.containerPadding,
                      top: AppSpacing.xl,
                      bottom: 100,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _faqs.length; i++) ...[
                            _buildFaqTile(i),
                            if (i < _faqs.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.10,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border(bottom: BorderSide(color: AppColors.glassBorderLight)),
      ),
      child: SizedBox(
        height: AppComponentSizes.headerHeight,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_rounded,
                size: AppIconSizes.header,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.quiz_rounded,
              size: AppIconSizes.header,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'FAQs',
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(int index) {
    final faq = _faqs[index];
    final isExpanded = _expandedIndex == index;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey(index),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedIndex = expanded ? index : null;
          });
        },
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        iconColor: AppColors.primaryDark,
        collapsedIconColor: AppColors.outline,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isExpanded
                ? AppColors.primaryDark.withValues(alpha: 0.12)
                : AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: AppTextStyles.labelSm.copyWith(
                color: isExpanded ? AppColors.primaryDark : AppColors.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        title: Text(
          faq.question,
          style: AppTextStyles.bodyLg.copyWith(
            color: AppColors.onSurface,
            fontSize: 15,
          ),
        ),
        children: [
          Text(
            faq.answer,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
