import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';

class SessionCreationScreen extends ConsumerStatefulWidget {
  final Session? editSession;

  const SessionCreationScreen({super.key, this.editSession});

  @override
  ConsumerState<SessionCreationScreen> createState() =>
      _SessionCreationScreenState();
}

class _SessionCreationScreenState extends ConsumerState<SessionCreationScreen> {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final List<SessionItem> _items = [];
  final List<TextEditingController> _itemControllers = [];
  final List<FocusNode> _itemFocusNodes = [];
  final ScrollController _scrollController = ScrollController();
  Set<int> _emptyTaskErrors = {};
  String? _titleError;

  bool get _isEditing => widget.editSession != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.editSession!.title;
      _items.addAll(widget.editSession!.items);
      for (final item in _items) {
        _itemControllers.add(TextEditingController(text: item.name));
        _itemFocusNodes.add(FocusNode());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _scrollController.dispose();
    for (final c in _itemControllers) {
      c.dispose();
    }
    for (final f in _itemFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _addTask() {
    setState(() {
      _items.add(const SessionItem(
        name: '',
        durationSeconds: 5 * 60,
        type: SessionItemType.task,
      ));
      _itemControllers.add(TextEditingController());
      _itemFocusNodes.add(FocusNode());
    });
    _scrollToBottom();
  }

  void _addBreak() {
    setState(() {
      _items.add(const SessionItem(
        name: 'Break',
        durationSeconds: 5 * 60,
        type: SessionItemType.break_,
      ));
      _itemControllers.add(TextEditingController(text: 'Break'));
      _itemFocusNodes.add(FocusNode());
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final current = _scrollController.offset;
        _scrollController.animateTo(
          current + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);
      _itemFocusNodes[index].dispose();
      _itemFocusNodes.removeAt(index);
      _items.removeAt(index);
      _emptyTaskErrors.remove(index);
      _emptyTaskErrors = _emptyTaskErrors.map((i) => i > index ? i - 1 : i).toSet();
    });
  }

  void _updateItemName(int index, String name) {
    setState(() {
      _items[index] = _items[index].copyWith(name: name);
    });
  }

  void _updateItemDuration(int index, int seconds) {
    setState(() {
      _items[index] = _items[index].copyWith(durationSeconds: seconds);
    });
  }

  Future<void> _saveSession() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a session title.');
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one task to your session.')),
      );
      return;
    }

    for (final item in _items) {
      if (item.durationSeconds <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All durations must be greater than 0.')),
        );
        return;
      }
    }

    _emptyTaskErrors.clear();
    bool hasEmptyTask = false;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isTask && _itemControllers[i].text.trim().isEmpty) {
        _emptyTaskErrors.add(i);
        hasEmptyTask = true;
      }
    }
    if (hasEmptyTask) {
      setState(() {});
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(name: _itemControllers[i].text);
    }

    try {
      if (_isEditing) {
        await ref.read(sessionServiceProvider).updateSession(
          uid: user.uid,
          sessionId: widget.editSession!.id,
          title: title,
          items: _items,
        );
      } else {
        await ref.read(sessionServiceProvider).addSession(
          uid: user.uid,
          title: title,
          items: _items,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}h ${m}min';
    if (m > 0 && s > 0) return '${m}min ${s}s';
    if (m > 0) return '$m min';
    if (s > 0) return '${s}s';
    return '0 min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
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
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        _buildTitleInput(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildAddButtons(),
                        if (_items.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _buildTimelineHeader(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_items.isNotEmpty)
                    Expanded(
                      child: _buildItemsList(),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSaveFooter(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorderLight),
        ),
      ),
      child: SizedBox(
        height: AppComponentSizes.headerHeight,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: AppIconSizes.header,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _isEditing ? 'Edit Session' : 'Create Session',
                style: AppTextStyles.headlineSm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Session Title',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.outline,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassWhite,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.glassBorderLight),
          ),
          child: TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            decoration: InputDecoration(
              hintText: 'Enter session title',
              errorText: _titleError,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.outlineVariant,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  '${_titleController.text.length}/30',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                maxHeight: 20,
              ),
            ),
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            onChanged: (value) {
              if (value.length > 30) {
                _titleController.text = value.substring(0, 30);
                _titleController.selection = TextSelection.fromPosition(
                  const TextPosition(offset: 30),
                );
              }
              setState(() {
                if (_titleError != null) _titleError = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _addTask,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg - 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: AppRadius.radiusPill,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: AppIconSizes.md,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Add Task',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GestureDetector(
            onTap: _addBreak,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg - 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: AppRadius.radiusPill,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.coffee_rounded,
                    size: AppIconSizes.md,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Add Break',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHeader() {
    final totalMinutes =
        _items.fold(0, (sum, item) => sum + item.durationSeconds) ~/ 60;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tasks',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.outline,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Total: $totalMinutes min',
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerPadding,
      ).copyWith(bottom: 100),
      child: PrimaryScrollController(
        controller: _scrollController,
        child: ReorderableListView.builder(
          itemCount: _items.length,
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.radiusMd,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAlpha(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          // ignore: deprecated_member_use
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            setState(() {
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
              final controller = _itemControllers.removeAt(oldIndex);
              _itemControllers.insert(newIndex, controller);
              final focusNode = _itemFocusNodes.removeAt(oldIndex);
              _itemFocusNodes.insert(newIndex, focusNode);
              if (_emptyTaskErrors.contains(oldIndex)) {
                _emptyTaskErrors.remove(oldIndex);
                _emptyTaskErrors.add(newIndex);
              }
            });
          },
          itemBuilder: (context, index) {
            final item = _items[index];
            return Padding(
              key: ValueKey('item_$index'),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _buildItemCard(item, index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(SessionItem item, int index) {
    final isBreak = item.isBreak;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: AppColors.glassBorderLight),
        boxShadow: [AppShadows.taskCard],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.drag_indicator_rounded,
            size: AppIconSizes.xl,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.isTask)
                  TextField(
                    controller: _itemControllers[index],
                    focusNode: _itemFocusNodes[index],
                    decoration: InputDecoration(
                      hintText: 'Add task name',
                      hintStyle: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.outlineVariant,
                        fontSize: 14,
                      ),
                      errorText: _emptyTaskErrors.contains(index)
                          ? 'Task must have a name'
                          : null,
                      errorStyle: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    onChanged: (value) {
                      if (value.length > 30) {
                        _itemControllers[index].text = value.substring(0, 30);
                        _itemControllers[index].selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: 30),
                        );
                      }
                      _updateItemName(index, _itemControllers[index].text);
                      setState(() {
                        _emptyTaskErrors.remove(index);
                      });
                    },
                  )
                else
                  Text(
                    'BREAK',
                    style: AppTextStyles.labelMd.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.onSurface,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.deferToChild,
                      onTap: () =>
                          _showDurationPicker(index, item.durationSeconds),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: AppRadius.radiusSm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBreak
                                  ? Icons.coffee_rounded
                                  : Icons.schedule_rounded,
                              size: AppIconSizes.xs,
                              color: AppColors.onPrimary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _formatDuration(item.durationSeconds),
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_itemControllers[index].text.length}/30',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: () => _removeItem(index),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: AppIconSizes.md,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDurationPicker(int index, int currentSeconds) async {
    final initH = currentSeconds ~/ 3600;
    final initM = (currentSeconds % 3600) ~/ 60;
    final initS = currentSeconds % 60;

    final result = await showDialog<int>(
      context: context,
      builder: (_) => _DurationPickerDialog(
        initialHours: initH,
        initialMinutes: initM,
        initialSeconds: initS,
      ),
    );

    if (result != null) {
      _updateItemDuration(index, result);
    }
  }

  Widget _buildSaveFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.containerPadding,
        AppSpacing.md,
        AppSpacing.containerPadding,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassMenuBg,
        border: Border(
          top: BorderSide(color: AppColors.glassBorderLight),
        ),
      ),
      child: SizedBox(
        height: AppComponentSizes.buttonHeight,
        child: FilledButton(
          onPressed: _saveSession,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.radiusPill,
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.save_rounded,
                size: AppIconSizes.xl,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _isEditing ? 'Save Changes' : 'Save Session',
                style: AppTextStyles.button.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationPickerDialog extends StatefulWidget {
  final int initialHours;
  final int initialMinutes;
  final int initialSeconds;

  const _DurationPickerDialog({
    required this.initialHours,
    required this.initialMinutes,
    required this.initialSeconds,
  });

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final TextEditingController _secondController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController(
      text: widget.initialHours > 0 ? widget.initialHours.toString() : '',
    );
    _minuteController = TextEditingController(
      text: widget.initialMinutes > 0 ? widget.initialMinutes.toString() : '',
    );
    _secondController = TextEditingController(
      text: widget.initialSeconds > 0 ? widget.initialSeconds.toString() : '',
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  void _onOk() {
    final h = int.tryParse(_hourController.text) ?? 0;
    final m = int.tryParse(_minuteController.text) ?? 0;
    final s = int.tryParse(_secondController.text) ?? 0;
    if (m > 59) {
      setState(() => _errorText = 'Minutes cannot exceed 59');
      return;
    }
    if (s > 59) {
      setState(() => _errorText = 'Seconds cannot exceed 59');
      return;
    }
    final total = h * 3600 + m * 60 + s;
    if (total > 0) {
      Navigator.pop(context, total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
      title: const Text('Enter time', style: AppTextStyles.bodyLg),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(controller: _hourController, label: 'Hour'),
              _buildSeparator(),
              _buildField(
                controller: _minuteController,
                label: 'Minute',
                hasError: _errorText != null,
              ),
              _buildSeparator(),
              _buildField(
                controller: _secondController,
                label: 'Second',
                hasError: _errorText != null,
              ),
            ],
          ),
          if (_errorText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorText!,
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: AppTextStyles.link),
        ),
        TextButton(
          onPressed: _onOk,
          child: const Text('OK', style: AppTextStyles.link),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          ':',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool hasError = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: AppTextStyles.headlineSm.copyWith(fontSize: 28),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: AppTextStyles.headlineSm.copyWith(
                fontSize: 28,
                color: AppColors.outlineVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusSm,
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusSm,
                borderSide: BorderSide(color: AppColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.radiusSm,
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.primaryDark,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
