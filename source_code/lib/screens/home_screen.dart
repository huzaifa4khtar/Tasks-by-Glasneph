import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/services_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/slide_route.dart';
import '../widgets/task_category_menu.dart';
import '../widgets/top_notch_bar.dart';
import 'sessions_list_screen.dart';
import 'login_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

enum _SortOrder { oldestFirst, newestFirst, dueSoonest, dueFarthest }

// ───── Home Screen Widget ─────

class HomeScreen extends ConsumerStatefulWidget {
  final String? email;
  final String? loginMessageName;
  final String? highlightTaskId;
  final bool openEditSheet;

  const HomeScreen({
    super.key,
    this.email,
    this.loginMessageName,
    this.highlightTaskId,
    this.openEditSheet = false,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// ───── State ─────

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // Controllers & animation
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _taskFocusNode = FocusNode();
  late final AnimationController _sheetController;
  late final Animation<double> _sheetAnimation;
  late final AnimationController _bounceCheckController;
  late final AnimationController _bounceStarController;
  late final Animation<double> _bounceCheck;
  late final Animation<double> _bounceStar;

  // Sheet state
  DateTime? _selectedDueDate;
  TimeOfDay? _selectedDueTime;
  bool _isSheetOpen = false;
  String? _dueDateError;
  String? _titleError;

  // Category & sort state
  String _selectedCategory = 'All Tasks';
  bool _isMenuExpanded = false;
  _SortOrder _sortOrder = _SortOrder.newestFirst;
  bool _isSortExpanded = false;
  final LayerLink _sortLink = LayerLink();

  // Navigation
  int _selectedNavIndex = 2;

  // Back-button / keyboard fallback
  bool _wasKeyboardOpen = false;

  // Stream cache (avoids loading flash on setState)
  Stream<QuerySnapshot<Map<String, dynamic>>>? _cachedStream;

  // Custom lists state
  Map<String, Map<String, dynamic>> _rawLists = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _listsSub;

  // Highlight state
  String? _highlightedTaskId;
  final GlobalKey _highlightedCardKey = GlobalKey();

  // Edit mode state
  String? _editingDocId;
  String? _editingUserUid;

  // ───── Lifecycle ─────

  @override
  void initState() {
    super.initState();
    _initSheetAnimation();
    _initBounceAnimations();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    _showLoginSnackbarIfNeeded();
    _initListsSubscription();
    _initHighlight();
    _rescheduleRemindersOnLaunch();
  }

  void _initHighlight() {
    if (widget.highlightTaskId != null) {
      _highlightedTaskId = widget.highlightTaskId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToHighlightedTask();
          if (widget.openEditSheet) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _openEditSheetForHighlighted();
            });
          }
        }
      });
    }
  }

  void _rescheduleRemindersOnLaunch() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    ref.read(taskServiceProvider).rescheduleAllReminders(user.uid);
  }

  void _scrollToHighlightedTask() {
    if (_highlightedTaskId == null) return;
    final context = _highlightedCardKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  void _openEditSheetForHighlighted() {
    if (_highlightedTaskId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final taskService = ref.read(taskServiceProvider);
    taskService.tasksStream(user.uid).first.then((snapshot) {
      if (!mounted) return;
      final doc = snapshot.docs.where((d) => d.id == _highlightedTaskId).firstOrNull;
      if (doc == null) return;

      final data = doc.data();
      _showEditTaskSheet(
        docId: doc.id,
        userUid: user.uid,
        currentTitle: (data['title'] as String?) ?? '',
        currentDueAt: (data['dueAt'] as Timestamp?)?.toDate(),
        currentHasDueTime: (data['hasDueTime'] as bool?) ?? false,
      );
    });
  }

  void _initListsSubscription() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _listsSub = ref
        .read(taskServiceProvider)
        .listsStream(user.uid)
        .listen((snapshot) {
      if (!mounted) return;
      final data = snapshot.data();
      final raw = (data?['customLists'] as Map<String, dynamic>?) ?? {};
      setState(() => _rawLists = raw.map((k, v) {
        return MapEntry(k, (v as Map<String, dynamic>?) ?? {});
      }));
    });
  }

  @override
  void dispose() {
    _listsSub?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    WidgetsBinding.instance.removeObserver(this);
    _sheetController.dispose();
    _bounceCheckController.dispose();
    _bounceStarController.dispose();
    _taskController.dispose();
    _taskFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final keyboardOpen = View.of(context).viewInsets.bottom > 0;
    if (_wasKeyboardOpen && !keyboardOpen && _isSheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isSheetOpen) _hideSheet();
      });
    }
    _wasKeyboardOpen = keyboardOpen;
  }

  // ───── Animation setup ─────

  void _initSheetAnimation() {
    _sheetController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _sheetAnimation = CurvedAnimation(
      parent: _sheetController,
      curve: Curves.easeOutBack,
    );
  }

  void _initBounceAnimations() {
    _bounceCheckController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceCheck = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _bounceCheckController, curve: Curves.easeOut),
    );
    _bounceCheckController.repeat(reverse: true);

    _bounceStarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceStar = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _bounceStarController, curve: Curves.easeOut),
    );
    _bounceStarController.value = 1.0;
    _bounceStarController.repeat(reverse: true);
  }

  void _showLoginSnackbarIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fullName = widget.loginMessageName?.trim();
      if (fullName == null || fullName.isEmpty) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logged in as $fullName')));
    });
  }

  // ───── Back-button handler ─────

  bool _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.goBack &&
        _isSheetOpen &&
        mounted) {
      _taskFocusNode.unfocus();
      _hideSheet();
      return true;
    }
    return false;
  }

  // ───── Date helpers ─────

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]}, ${dt.year}';

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${_months[dt.month - 1]}, ${dt.year} \u00b7 $hour:$minute $period';
  }

  Future<void> _pickDueDate() async {
    _wasKeyboardOpen = false;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDueDate = picked;
        _selectedDueTime = null;
        _dueDateError = null;
      });
    }
  }

  Future<void> _pickDueTime() async {
    _wasKeyboardOpen = false;
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedDueTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDueTime = picked);
    }
  }

  DateTime? _selectedDueDateTime() {
    if (_selectedDueDate == null) return null;
    if (_selectedDueTime == null) {
      return DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
      );
    }
    return DateTime(
      _selectedDueDate!.year,
      _selectedDueDate!.month,
      _selectedDueDate!.day,
      _selectedDueTime!.hour,
      _selectedDueTime!.minute,
    );
  }

  // ───── Sort helpers ─────

  String _sortLabel() {
    switch (_sortOrder) {
      case _SortOrder.oldestFirst:
        return 'Oldest First';
      case _SortOrder.newestFirst:
        return 'Newest First';
      case _SortOrder.dueSoonest:
        return 'Due Date Soonest';
      case _SortOrder.dueFarthest:
        return 'Due Date Farthest';
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);

    DateTime? createdAt(QueryDocumentSnapshot<Map<String, dynamic>> d) {
      final value = d.data()['createdAt'];
      if (value is Timestamp) return value.toDate();
      return null;
    }

    DateTime? dueAt(QueryDocumentSnapshot<Map<String, dynamic>> d) {
      final value = d.data()['dueAt'];
      if (value is Timestamp) return value.toDate();
      return null;
    }

    switch (_sortOrder) {
      case _SortOrder.oldestFirst:
        list.sort((a, b) {
          final da = createdAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = createdAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
        });
      case _SortOrder.newestFirst:
        list.sort((a, b) {
          final da = createdAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = createdAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
      case _SortOrder.dueSoonest:
        list.sort((a, b) {
          final da = dueAt(a);
          final db = dueAt(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
      case _SortOrder.dueFarthest:
        list.sort((a, b) {
          final da = dueAt(a);
          final db = dueAt(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
    }
    return list;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterByCategory(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    switch (_selectedCategory) {
      case 'All Tasks':
        return docs;
      case 'Important':
        return docs.where((d) =>
          (d.data()['isImportant'] as bool?) == true,
        ).toList();
      case 'Study Tasks':
        return docs.where((d) =>
          (d.data()['category'] as String?) == 'Study',
        ).toList();
      case 'Work Tasks':
        return docs.where((d) =>
          (d.data()['category'] as String?) == 'Work',
        ).toList();
      case 'Home Tasks':
        return docs.where((d) =>
          (d.data()['category'] as String?) == 'Home',
        ).toList();
      default:
        return docs.where((d) =>
          (d.data()['category'] as String?) == _selectedCategory,
        ).toList();
    }
  }

  // ───── Bottom navigation ─────

  void _onNavTapped(int index) {
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(AppDurations.normal, () {
        if (!mounted) return;
        Widget screen = const SizedBox.shrink();
        switch (index) {
          case 0: screen = const RemindersScreen();
          case 1: screen = const SessionsListScreen();
          case 3: screen = const SettingsScreen();
          case 4: screen = const ProfileScreen();
        }
        Navigator.push(
          context,
          fadeRoute(screen),
        ).then((_) {
          if (mounted) setState(() => _selectedNavIndex = 2);
        });
      });
    });
  }

  // ───── Add-task sheet logic ─────

  void _showAddTaskSheet() {
    setState(() {
      _isSheetOpen = true;
      _dueDateError = null;
      _titleError = null;
    });
    _sheetController.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNode.requestFocus();
    });
  }

  void _hideSheet() {
    setState(() {
      _isSheetOpen = false;
      _editingDocId = null;
      _editingUserUid = null;
    });
  }

  void _addTaskFromSheet() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _taskController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Please enter a task.');
      return;
    }

    final isEditing = _editingDocId != null;
    final dueAt = _selectedDueDateTime();
    final hasDueTime = _selectedDueTime != null;

    if (isEditing) {
      final docId = _editingDocId!;
      final userUid = _editingUserUid!;
      _cancelEdit();

      ref.read(taskServiceProvider).updateTask(
        uid: userUid,
        taskId: docId,
        title: title,
        dueAt: dueAt,
        hasDueTime: hasDueTime,
      ).catchError((Object e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(authServiceProvider).readableDataError(e)),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    } else {
      _hideSheet();

      final autoStar = _selectedCategory == 'Important';
      String? autoCategory;
      if (_selectedCategory == 'Study Tasks') {
        autoCategory = 'Study';
      } else if (_selectedCategory == 'Work Tasks') {
        autoCategory = 'Work';
      } else if (_selectedCategory == 'Home Tasks') {
        autoCategory = 'Home';
      } else if (_selectedCategory != 'All Tasks' && !autoStar) {
        autoCategory = _selectedCategory;
      }

      ref.read(taskServiceProvider).addTask(
        uid: user.uid,
        title: title,
        dueAt: dueAt,
        hasDueTime: hasDueTime,
        isImportant: autoStar,
        category: autoCategory,
      ).then((_) {
        if (mounted) {
          setState(() {
            _taskController.clear();
            _selectedDueDate = null;
            _selectedDueTime = null;
          });
        }
      }).catchError((Object e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(authServiceProvider).readableDataError(e)),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  // ───── Edit-task sheet ─────

  void _showEditTaskSheet({
    required String docId,
    required String userUid,
    required String currentTitle,
    required DateTime? currentDueAt,
    required bool currentHasDueTime,
  }) {
    _taskController.text = currentTitle;
    _selectedDueDate = currentDueAt;
    _selectedDueTime = currentHasDueTime && currentDueAt != null
        ? TimeOfDay.fromDateTime(currentDueAt)
        : null;
    setState(() {
      _editingDocId = docId;
      _editingUserUid = userUid;
      _isSheetOpen = true;
      _dueDateError = null;
      _titleError = null;
    });
    _sheetController.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskFocusNode.requestFocus();
      _taskController.selection = TextSelection.fromPosition(
        TextPosition(offset: _taskController.text.length),
      );
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingDocId = null;
      _editingUserUid = null;
      _taskController.clear();
      _selectedDueDate = null;
      _selectedDueTime = null;
      _isSheetOpen = false;
    });
  }

  // ───── Shared widgets ─────

  // ───── Build ─────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cachedStream ??= ref
            .read(taskServiceProvider)
            .tasksStream(user.uid),
        builder: (context, snapshot) {
          final allDocs = snapshot.data?.docs ?? [];
          final totalCount = allDocs.length;
          final importantCount =
              allDocs.where((d) => (d.data()['isImportant'] as bool?) == true).length;
          final studyCount =
              allDocs.where((d) => (d.data()['category'] as String?) == 'Study').length;
          final workCount =
              allDocs.where((d) => (d.data()['category'] as String?) == 'Work').length;
          final homeCount =
              allDocs.where((d) => (d.data()['category'] as String?) == 'Home').length;

          final customLists = _rawLists.entries.map((entry) {
            final data = entry.value;
            final name = (data['name'] as String?) ?? '';
            final iconCodePoint = (data['iconCodePoint'] as int?) ?? Icons.folder_rounded.codePoint;
            final colorValue = (data['colorValue'] as int?) ?? AppColors.primaryDark.toARGB32();
            final activeCount = allDocs.where((d) {
              final taskData = d.data();
              return (taskData['category'] as String?) == name &&
                  (taskData['isDone'] as bool?) != true;
            }).length;
            return CustomListInfo(
              name: name,
              // ignore: non_const_argument_for_const_parameter
              icon: IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
              color: Color(colorValue),
              activeCount: activeCount,
            );
          }).toList();

          return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background gradient
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
                  const TopNotchBar(),
                  // Header + sort + task list
                  SafeArea(
                    child: Column(
                      children: [
                        TaskCategoryMenu(
                          selectedCategory: _selectedCategory,
                          isExpanded: _isMenuExpanded,
                          onCategorySelected: (cat) => setState(() {
                            _selectedCategory = cat;
                            _isMenuExpanded = false;
                          }),
                          onToggleExpanded: () => setState(() => _isMenuExpanded = !_isMenuExpanded),
                          totalCount: totalCount,
                          importantCount: importantCount,
                          studyCount: studyCount,
                          workCount: workCount,
                          homeCount: homeCount,
                          customLists: customLists,
                        ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.containerPadding, AppSpacing.containerPadding, AppSpacing.containerPadding, 0),
                      child: _buildSortBar(),
                    ),
                    Expanded(child: _buildBody(snapshot)),
                  ],
                ),
              ),
              // Bottom navigation
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom,
                child: BottomNavBar(
                  currentIndex: _selectedNavIndex,
                  onItemTapped: _onNavTapped,
                ),
              ),
              // FAB
              Positioned(
                right: AppSpacing.containerPadding,
                bottom: 120,
                child: _buildFab(),
              ),
              // Add-task sheet (animated)
              if (_isSheetOpen)
                Positioned(
                  left: AppSpacing.containerPadding,
                  right: AppSpacing.containerPadding,
                  bottom: 130 + MediaQuery.of(context).viewInsets.bottom,
                  child: ScaleTransition(
                    scale: _sheetAnimation,
                    child: Material(
                      color: Colors.transparent,
                      child: _buildSheetTaskInput(),
                    ),
                  ),
                ),
              // Sort dropdown (overlays everything)
              if (_isSortExpanded)
                CompositedTransformFollower(
                  link: _sortLink,
                  targetAnchor: Alignment.bottomRight,
                  followerAnchor: Alignment.topRight,
                  offset: const Offset(0, 6),
                  child: _buildSortDropdown(),
                ),
            ],
          );
        },
      ),
    );
}

  // ───── UI: Empty state ─────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.glassWhite,
                    boxShadow: [AppShadows.emptyStateCircle],
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    size: AppIconSizes.emptyState,
                    color: AppColors.primaryAlpha(0.30),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 6,
                  child: AnimatedBuilder(
                    animation: _bounceCheck,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _bounceCheck.value),
                      child: child,
                    ),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassWhite,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Icon(
                        Icons.done_all_rounded,
                        size: AppIconSizes.lg,
                        color: AppColors.dueTeal,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 4,
                  child: AnimatedBuilder(
                    animation: _bounceStar,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _bounceStar.value),
                      child: child,
                    ),
                    child: Container(
                      width: AppComponentSizes.expandButtonSize,
                      height: AppComponentSizes.expandButtonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.glassWhite,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        size: AppIconSizes.md,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Get Things Done',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(
              'No tasks yet. Add your first task! Take the first step towards a more organized day.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ───── UI: Body (scroll view wrapper) ─────

  Widget _buildBody(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildTaskList(snapshot),
        ],
      ),
    );
  }

  // ───── UI: Sort bar ─────

  Widget _buildSortBar() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CompositedTransformTarget(
              link: _sortLink,
              child: GestureDetector(
                onTap: () =>
                    setState(() => _isSortExpanded = !_isSortExpanded),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.radiusPill,
                    boxShadow: [AppShadows.sortBar],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sort_rounded, size: AppIconSizes.sm, color: AppColors.primaryDark),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _sortLabel(),
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        _isSortExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: AppIconSizes.sm,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───── UI: Sort dropdown ─────

  Widget _buildSortDropdown() {
    const options = <_SortOrder, String>{
      _SortOrder.oldestFirst: 'Oldest First',
      _SortOrder.newestFirst: 'Newest First',
      _SortOrder.dueSoonest: 'Due Date Soonest',
      _SortOrder.dueFarthest: 'Due Date Farthest',
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusMd,
        boxShadow: [AppShadows.sortDropdown],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.entries.map((entry) {
          final isSelected = _sortOrder == entry.key;
          return GestureDetector(
            onTap: () => setState(() {
              _sortOrder = entry.key;
              _isSortExpanded = false;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: AppIconSizes.sm,
                    color: isSelected ? AppColors.primaryDark : AppColors.outlineVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.value,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primaryDark : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───── UI: Add-task sheet input ─────

  Widget _buildSheetTaskInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusXl,
        boxShadow: [AppShadows.glassCard],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: AppComponentSizes.sheetMaxTextFieldHeight),
            child: TextField(
              controller: _taskController,
              focusNode: _taskFocusNode,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              onChanged: (_) {
                if (_titleError != null) {
                  setState(() => _titleError = null);
                }
              },
              decoration: InputDecoration(
                hintText: _editingDocId != null ? 'Edit task' : 'Enter a new task',
                hintStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outlineVariant,
                ),
                border: InputBorder.none,
                filled: true,
                fillColor: AppColors.primaryAlpha(0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMd,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMd,
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTextStyles.bodyLg,
            ),
          ),
          if (_titleError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                _titleError!,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateChip(),
                      const SizedBox(width: AppSpacing.sm),
                      _buildTimeChip(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (_editingDocId != null) ...[
                GestureDetector(
                  onTap: _cancelEdit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusPill,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: AppIconSizes.md,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              GestureDetector(
                onTap: _addTaskFromSheet,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: AppRadius.radiusPill,
                  ),
                  child: Icon(
                    _editingDocId != null
                        ? Icons.check_rounded
                        : Icons.arrow_upward_rounded,
                    size: AppIconSizes.md,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (_dueDateError != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                _dueDateError!,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateChip() {
    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedDueDate != null
              ? AppColors.primaryAlpha(0.08)
              : AppColors.onSurfaceVariantVeryLow,
          borderRadius: AppRadius.radiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: AppIconSizes.xs,
              color: _selectedDueDate != null
                  ? AppColors.primaryDark
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              _selectedDueDate != null
                  ? _formatDate(_selectedDueDate!)
                  : 'Due date',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _selectedDueDate != null
                    ? AppColors.primaryDark
                    : AppColors.onSurfaceVariant,
              ),
            ),
            if (_selectedDueDate != null) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedDueDate = null;
                  _selectedDueTime = null;
                }),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip() {
    return GestureDetector(
      onTap: _selectedDueDate == null
          ? () => setState(() {
                _dueDateError =
                    'Select a due date before adding a time.';
              })
          : _pickDueTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedDueTime != null
              ? AppColors.primaryAlpha(0.08)
              : AppColors.onSurfaceVariantVeryLow,
          borderRadius: AppRadius.radiusPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: AppIconSizes.xs,
              color: _selectedDueTime != null
                  ? AppColors.primaryDark
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              _selectedDueTime != null
                  ? _selectedDueTime!.format(context)
                  : 'Due time',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _selectedDueTime != null
                    ? AppColors.primaryDark
                    : AppColors.onSurfaceVariant,
              ),
            ),
            if (_selectedDueTime != null) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: () => setState(() => _selectedDueTime = null),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───── UI: Task list ─────

  Widget _buildTaskList(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            ref.read(authServiceProvider).readableDataError(snapshot.error),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.errorContainer),
          ),
        ),
      );
    }

    final docs = snapshot.data?.docs ?? [];
    final filtered = _filterByCategory(docs);
    final sorted = _sortedDocs(filtered);

    if (sorted.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: sorted.map((doc) {
        final data = doc.data();
        final title = (data['title'] as String?) ?? 'Untitled task';
        final isDone = (data['isDone'] as bool?) ?? false;
        final isImportant = (data['isImportant'] as bool?) ?? false;
        final hasDueTime = (data['hasDueTime'] as bool?) ?? false;
        final dueAt = (data['dueAt'] as Timestamp?)?.toDate();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTaskCard(
            title: title,
            isDone: isDone,
            isImportant: isImportant,
            hasDueTime: hasDueTime,
            dueAt: dueAt,
            docId: doc.id,
            userUid: user.uid,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required bool isDone,
    required bool isImportant,
    required bool hasDueTime,
    required DateTime? dueAt,
    required String docId,
    required String userUid,
  }) {
    final isHighlighted = _highlightedTaskId == docId;

    return Container(
      key: isHighlighted ? _highlightedCardKey : null,
      padding: EdgeInsets.symmetric(horizontal: isHighlighted ? 12 : 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusLg,
        boxShadow: [AppShadows.taskCard],
        border: isHighlighted
            ? Border.all(color: AppColors.primaryDark, width: 2)
            : null,
      ),
      child: Opacity(
        opacity: isDone ? 0.5 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconButton(
              onTap: () => ref.read(taskServiceProvider).toggleTask(
                  uid: userUid, taskId: docId, isDone: isDone),
              icon: isDone
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              color: isDone ? AppColors.primaryDark : AppColors.outlineVariant,
              size: AppIconSizes.xxl,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? AppColors.onSurfaceVariant : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (dueAt != null)
                        Text(
                          'Due: ${hasDueTime ? _formatDateTime(dueAt) : _formatDate(dueAt)}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      const Spacer(),
                      _buildIconButton(
                        onTap: () => ref
                            .read(taskServiceProvider)
                            .toggleImportant(
                                uid: userUid, taskId: docId, isImportant: isImportant),
                        icon: isImportant
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isImportant
                            ? AppColors.categoryImportant
                            : AppColors.outlineVariant,
                        size: AppIconSizes.xl,
                      ),
                      _buildIconButton(
                        onTap: () => _showEditTaskSheet(
                          docId: docId,
                          userUid: userUid,
                          currentTitle: title,
                          currentDueAt: dueAt,
                          currentHasDueTime: hasDueTime,
                        ),
                        icon: Icons.edit_rounded,
                        color: AppColors.outlineVariant,
                        size: AppIconSizes.xl,
                      ),
                      _buildIconButton(
                        onTap: () =>
                            ref.read(taskServiceProvider).deleteTask(
                                uid: userUid, taskId: docId),
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.outlineVariant,
                        size: AppIconSizes.xl,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required double size,
    double leftPad = AppSpacing.xs,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(left: leftPad),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  // ───── UI: FAB ─────

  Widget _buildFab() {
    return GestureDetector(
      onTap: _showAddTaskSheet,
      child: Container(
        width: AppComponentSizes.fabSize,
        height: AppComponentSizes.fabSize,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.radiusPill,
          boxShadow: [AppShadows.fab],
        ),
        child: const Icon(
          Icons.add,
          size: AppIconSizes.fab,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
