import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meal_ver2/model/Verse.dart';
import 'package:meal_ver2/model/Note.dart';
import 'package:meal_ver2/model/Highlight.dart';
import 'package:meal_ver2/viewmodel/MainViewModel.dart';
import 'package:provider/provider.dart';
import 'package:meal_ver2/view/SelectBibleView.dart';
import 'package:meal_ver2/view/NoteEditorView.dart';
import 'package:meal_ver2/view/NotesCalendarView.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../util/CustomTheme.dart';
import 'OptionView.dart'; // 성경 선택 화면을 import
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class MobileMeal2View extends StatefulWidget {
  @override
  _MobileMeal2ViewState createState() => _MobileMeal2ViewState();
}
enum _LayoutMode { list, split }


class _MobileMeal2ViewState extends State<MobileMeal2View> {
  bool isLoading = true;
  String errorMessage = '';
  DateTime? selectedDate;
  late MainViewModel viewModel;
  bool _syncingScroll = false;
  late final LinkedScrollControllerGroup _linkedGroup;
  final List<ScrollController> _bibleScrollControllers = [];
  _LayoutMode _layoutMode = _LayoutMode.list;
  // Selection mode variables
  bool isSelectionMode = false;
  Set<String> selectedVerseIds = {};
  List<VerseReference> selectedVerses = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _linkedGroup = LinkedScrollControllerGroup();

    viewModel = Provider.of<MainViewModel>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      //await viewModel.loadPreferences(); // 초기화 작업을 한 번만 실행
      setState(() {
        isLoading = false; // 로딩 상태 종료
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      await viewModel.refreshVersesForDate(DateTime.now()); // 날짜에 맞게 데이터 새로고침
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error refreshing data : $e';
        isLoading = false;
      });
    }
  }

  void _changeDate(BuildContext context, bool isNextDay) {
    final viewModel = Provider.of<MainViewModel>(context, listen: false);
    final currentDate = viewModel.SelectedDate ?? DateTime.now();
    final newDate = isNextDay
        ? currentDate.add(Duration(days: 1))
        : currentDate.subtract(Duration(days: 1));

    // Exit selection mode when changing date
    if (isSelectionMode) {
      _exitSelectionMode();
    }

    viewModel.setSelectedDate(newDate);
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _enterSelectionMode() {
    setState(() {
      isSelectionMode = true;
      selectedVerseIds.clear();
      selectedVerses.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedVerseIds.clear();
      selectedVerses.clear();
    });
  }

  void _toggleVerseSelection(Verse verse, String bibleType) {
    final verseRef = VerseReference.fromVerse(verse, bibleType);
    final verseId = verseRef.verseId;

    setState(() {
      if (selectedVerseIds.contains(verseId)) {
        selectedVerseIds.remove(verseId);
        selectedVerses.removeWhere((v) => v.verseId == verseId);
      } else {
        selectedVerseIds.add(verseId);
        selectedVerses.add(verseRef);
      }
    });
  }

  void _createNoteFromSelection() async {
    if (selectedVerses.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorView(
          selectedVerses: List<VerseReference>.from(selectedVerses),
          date: viewModel.SelectedDate ?? DateTime.now(),
        ),
      ),
    );

    if (result == true) {
      // Note was created successfully
      _exitSelectionMode();
      // Refresh to show note indicators
      setState(() {});
    }
  }

  // Copy verses with reference format
  Future<void> _copyWithFormat(BuildContext context, String format) async {
    final selectedVerseObjects = viewModel.DataSource[0].where((verse) {
      final bibleType = viewModel.SelectedBibles.isNotEmpty
          ? viewModel.SelectedBibles[0]
          : '';
      final verseRef = VerseReference.fromVerse(verse, bibleType);
      return selectedVerseIds.contains(verseRef.verseId);
    }).toList();

    await viewModel.copyVersesWithReference(selectedVerseObjects);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('클립보드에 복사되었습니다')),
    );
    _exitSelectionMode();
  }

  // Apply highlight to selected verses
  void _applyHighlight(Color color) {
    for (final verseRef in selectedVerses) {
      // Check if verse already has a highlight
      final existingHighlight = viewModel.getHighlightForVerse(
        verseRef.book,
        verseRef.chapter,
        verseRef.verse,
      );

      if (existingHighlight != null) {
        // Remove highlight if it already exists
        viewModel.removeHighlight(
            verseRef.book, verseRef.chapter, verseRef.verse);
      } else {
        // Add new highlight
        viewModel.addHighlight(
            verseRef.book, verseRef.chapter, verseRef.verse, color);
      }
    }

    _exitSelectionMode();
  }
  
  void _syncScrollToOthers(ScrollController source) {
    if (_syncingScroll) return;
    _syncingScroll = true;
    final pos = source.hasClients ? source.position.pixels : 0.0;
    for (final c in _bibleScrollControllers) {
      if (c == source) continue;
      if (!c.hasClients) continue;
      final max = c.position.maxScrollExtent;
      c.jumpTo(pos.clamp(0.0, max));
    }
    _syncingScroll = false;
  }

  Widget _buildBibleColumn({
    required BuildContext context,
    required MainViewModel viewModel,
    required int bibleIndex,
    required ScrollController controller,
  }) {
    final verses = viewModel.DataSource[bibleIndex];
    final isFirstBible = bibleIndex == 0;
    final isSecondBible = bibleIndex == 1;
    final isThirdBible = bibleIndex == 2;
    final isFourthBible = bibleIndex == 3;

    final bibleType = (viewModel.SelectedBibles.isNotEmpty && bibleIndex < viewModel.SelectedBibles.length)
        ? viewModel.SelectedBibles[bibleIndex]
        : '';

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification && n.dragDetails != null) {
          _syncScrollToOthers(controller);
        }
        return false;
      },
      child: ListView.builder(
        controller: controller,
        itemCount: verses.length,
        itemBuilder: (context, index) {
          final verse = verses[index];
          final verseRef = VerseReference.fromVerse(verse, bibleType);
          final isSelected = selectedVerseIds.contains(verseRef.verseId);
          final hasNote = viewModel.hasNoteForVerse(viewModel.SelectedDate ?? DateTime.now(), verseRef);

          final highlight = viewModel.getHighlightForVerse(verse.book, verse.chapter, verse.verse);
          final hasHighlight = highlight != null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () {
                  if (!isSelectionMode) {
                    _enterSelectionMode();
                    _toggleVerseSelection(verse, bibleType);
                  }
                },
                onTap: () {
                  if (isSelectionMode) {
                    _toggleVerseSelection(verse, bibleType);
                  }
                },
                child: Container(
                  decoration: isSelected
                      ? BoxDecoration(
                    color: _selectionFill(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _selectionBorder(context), width: 1.1),
                  )
                      : null,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final textColor = Theme.of(context).textTheme.bodyLarge?.color;

                      final verseText = viewModel.DataSource.length > 1
                          ? '${verse.bibleType} ${verse.btext}'
                          : verse.btext;

                      final verseBodyColor = isFirstBible
                          ? textColor
                          : isSecondBible
                          ? Colors.blueGrey
                          : isThirdBible
                          ? Colors.brown
                          : Colors.deepPurple;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Opacity(
                            opacity: 1.0,
                            child: Container(
                              width: w * 0.10,
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${verse.verse}',
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'Biblefont',
                                  fontWeight: FontWeight.bold,
                                  fontSize: viewModel.fontSize * 0.8,
                                  height: viewModel.lineSpacing,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          SizedBox(width: w * 0.02),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: hasHighlight
                                        ? BoxDecoration(
                                      color: highlight!.color.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                        : null,
                                    child: Text(
                                      verseText,
                                      style: TextStyle(
                                        color: verseBodyColor,
                                        fontFamily: 'Biblefont',
                                        fontSize: viewModel.fontSize,
                                        height: viewModel.lineSpacing,
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasNote && !isSelectionMode)
                                  const SizedBox(width: 4),
                                if (hasNote && !isSelectionMode)
                                  Tooltip(
                                    message: '노트',
                                    child: Icon(
                                      Icons.description,
                                      size: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: viewModel.verseSpacing),
            ],
          );
        },
      ),
    );
  }

  void _ensureBibleControllers(int count) {
    while (_bibleScrollControllers.length < count) {
      _bibleScrollControllers.add(_linkedGroup.addAndGet());
    }
    while (_bibleScrollControllers.length > count) {
      _bibleScrollControllers.removeLast().dispose();
    }
  }
  _LayoutMode _calcLayoutMode(double width, int bibleCount) {
    const tabletWidth = 720.0; 
    if (width >= tabletWidth && bibleCount > 1) {
      return _LayoutMode.split;
    }
    return _LayoutMode.list;
  }

  void _updateLayoutModeIfNeeded(BuildContext context, double width, int bibleCount) {
    final desired = _calcLayoutMode(width, bibleCount);
    if (desired == _layoutMode) return;

    // build 중 setState 금지 → 프레임 끝나고 반영
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _layoutMode = desired;
      });
    });
  }
  // Build action button widget
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final isDark = MainViewModel.themeMode.value == ThemeMode.dark;
    final buttonColor = isDark ? Colors.white : Colors.deepPurple;

    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: buttonColor),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: buttonColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _bibleScrollControllers) {
      c.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          print('Building Meal2View...');
          return WillPopScope(
            onWillPop: () async {
              if (isSelectionMode) {
                _exitSelectionMode();
                return false;
              }
              return true;
            },
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (!isSelectionMode) {
                  if (details.primaryVelocity! < 0) {
                    _changeDate(context, true);
                  } else if (details.primaryVelocity! > 0) {
                    _changeDate(context, false);
                  }
                }
              },
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: MainViewModel.themeMode,
                builder: (context, themeMode, child) {
                  return MaterialApp(

                    themeMode: themeMode,
                    theme: ThemeData.light(),
                    darkTheme: ThemeData.dark(),
                    home: Scaffold(
                      endDrawer: Drawer(
                        child: ThemeAndBibleMenu(),
                      ),
                      body: SafeArea(
                        child: Consumer<MainViewModel>(
                          builder: (context, viewModel, child) {
                            if (viewModel.IsLoading) {
                              return Center(child: CircularProgressIndicator());
                            }

                            final bibleCount = viewModel.DataSource.length;
                            final desired = _calcLayoutMode(width, bibleCount);

                            if (desired != _layoutMode) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() {
                                  _layoutMode = desired;
                                });
                              });
                            }
                            
                            if (_layoutMode == _LayoutMode.split) {
                              _ensureBibleControllers(bibleCount);
                            }
                            
                            print('UI: Displaying data.');
                            return Container(
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .background,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Header(
                                      selectedDate: selectedDate,
                                      isSelectionMode: isSelectionMode,
                                      selectedCount: selectedVerseIds.length,
                                      onExitSelectionMode: _exitSelectionMode,
                                      onSelectDate: () async {
                                        final DateTime? pickedDate =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                          initialEntryMode:
                                          DatePickerEntryMode.calendarOnly,
                                        );
                                        if (pickedDate != null &&
                                            pickedDate != selectedDate) {
                                          setState(() {
                                            selectedDate = pickedDate;
                                          });
                                          viewModel.setSelectedDate(pickedDate);
                                        }
                                      },
                                    ),
                                    //SizedBox(height: 16.0), // 헤더와 본문 사이에 간격 추가

                                    Expanded(
                                      child: RefreshIndicator(
                                        onRefresh: _refreshData,
                                        child: _layoutMode == _LayoutMode.split
                                            ? (bibleCount == 4)
                                            ? GridView.count(
                                          crossAxisCount: 2,
                                          childAspectRatio: 1.0,
                                          children: List.generate(4, (i) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                              child: _buildBibleColumn(
                                                context: context,
                                                viewModel: viewModel,
                                                bibleIndex: i,
                                                controller: _bibleScrollControllers[i],
                                              ),
                                            );
                                          }),
                                        )
                                            : Row(
                                          children: List.generate(bibleCount, (i) {
                                            return Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(left: i == 0 ? 0 : 8.0),
                                                child: _buildBibleColumn(
                                                  context: context,
                                                  viewModel: viewModel,
                                                  bibleIndex: i,
                                                  controller: _bibleScrollControllers[i],
                                                ),
                                              ),
                                            );
                                          }),
                                        )
                                            : ListView.builder(
                                          controller: _scrollController,
                                          itemCount: viewModel.DataSource[0].length,
                                          itemBuilder: (context, index) {
                                            return Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                ...viewModel.DataSource
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  int bibleIndex = entry.key;
                                                  List<Verse> bibleVerses =
                                                      entry.value;

                                                  if (index < bibleVerses.length) {
                                                    Verse verse = bibleVerses[index];
                                                    bool isFirstBible =
                                                        bibleIndex == 0;
                                                    bool isSecondBible =
                                                        bibleIndex == 1;
                                                    bool isThirdBible =
                                                        bibleIndex == 2;
                                                    bool isFourthBible =
                                                        bibleIndex == 3;

                                                    final bibleType = viewModel
                                                        .SelectedBibles
                                                        .isNotEmpty &&
                                                        bibleIndex <
                                                            viewModel
                                                                .SelectedBibles
                                                                .length
                                                        ? viewModel.SelectedBibles[
                                                    bibleIndex]
                                                        : '';
                                                    final verseRef =
                                                    VerseReference.fromVerse(
                                                        verse, bibleType);
                                                    final isSelected =
                                                    selectedVerseIds.contains(
                                                        verseRef.verseId);
                                                    final hasNote =
                                                    viewModel.hasNoteForVerse(
                                                        viewModel.SelectedDate ??
                                                            DateTime.now(),
                                                        verseRef);
                                                    final highlight = viewModel
                                                        .getHighlightForVerse(
                                                        verse.book,
                                                        verse.chapter,
                                                        verse.verse);
                                                    final hasHighlight =
                                                        highlight != null;

                                                    return GestureDetector(
                                                      behavior: HitTestBehavior.opaque,
                                                      onLongPress: () {
                                                        if (!isSelectionMode) {
                                                          _enterSelectionMode();
                                                          _toggleVerseSelection(
                                                              verse, bibleType);
                                                        }
                                                      },
                                                      onTap: () {
                                                        if (isSelectionMode) {
                                                          _toggleVerseSelection(
                                                              verse, bibleType);
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration: isSelected
                                                            ? BoxDecoration(
                                                          color: _selectionFill(
                                                              context),
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(8),
                                                          border: Border.all(
                                                            color:
                                                            _selectionBorder(
                                                                context),
                                                            width: 1.1,
                                                          ),
                                                        )
                                                            : null,
                                                        child: LayoutBuilder(
                                                          builder:
                                                              (context, constraints) {
                                                            final w = constraints.maxWidth;
                                                            return Row(crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [Opacity(opacity: isFirstBible ? 1.0 : 0.1,
                                                                child: Container(width: w * 0.05,
                                                                  padding: EdgeInsets.only(top: 2),
                                                                  child: Text('${verse.verse} ',
                                                                    style: TextStyle(
                                                                      color: Theme
                                                                          .of(context)
                                                                          .textTheme
                                                                          .bodyLarge
                                                                          ?.color,
                                                                      fontFamily: 'Biblefont',
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: viewModel.fontSize * 0.8,
                                                                      height: viewModel.lineSpacing,
                                                                    ),
                                                                    textAlign: TextAlign.right,
                                                                  ),
                                                                ),
                                                              ),
                                                                SizedBox(
                                                                  width: w * 0.01,
                                                                ),
                                                                Expanded(
                                                                  child: Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child:
                                                                        Container(
                                                                          decoration:
                                                                          hasHighlight
                                                                              ? BoxDecoration(
                                                                            color: highlight.color.withOpacity(0.3),
                                                                            borderRadius: BorderRadius.circular(4),
                                                                          )
                                                                              : null,
                                                                          child: isSelectionMode
                                                                              ? Text(
                                                                            viewModel.DataSource.length > 1 // 성경이 여러 개인 경우 확인
                                                                                ? '${verse.bibleType} ${verse.btext}' // 여러 개일 경우 bibletype 포함
                                                                                : '${verse.btext}',
                                                                            // 하나일 경우 bibletype 없이 btext만 표시
                                                                            style:
                                                                            TextStyle(
                                                                              color: isFirstBible
                                                                                  ? Theme
                                                                                  .of(context)
                                                                                  .textTheme
                                                                                  .bodyLarge
                                                                                  ?.color
                                                                                  : isSecondBible
                                                                                  ? Colors.blueGrey
                                                                                  : isThirdBible
                                                                                  ? Colors.brown
                                                                                  : Colors.deepPurple,
                                                                              fontWeight: FontWeight.normal,
                                                                              fontFamily: 'Biblefont',
                                                                              fontSize: viewModel.fontSize,
                                                                              height: viewModel.lineSpacing,
                                                                            ),
                                                                          )
                                                                              : Text(
                                                                            viewModel.DataSource.length > 1 // 성경이 여러 개인 경우 확인
                                                                                ? '${verse.bibleType} ${verse.btext}' // 여러 개일 경우 bibletype 포함
                                                                                : '${verse.btext}',
                                                                            // 하나일 경우 bibletype 없이 btext만 표시
                                                                            style:
                                                                            TextStyle(
                                                                              color: isFirstBible
                                                                                  ? Theme
                                                                                  .of(context)
                                                                                  .textTheme
                                                                                  .bodyLarge
                                                                                  ?.color
                                                                                  : isSecondBible
                                                                                  ? Colors.blueGrey
                                                                                  : isThirdBible
                                                                                  ? Colors.brown
                                                                                  : Colors.deepPurple,
                                                                              fontWeight: FontWeight.normal,
                                                                              fontFamily: 'Biblefont',
                                                                              fontSize: viewModel.fontSize,
                                                                              height: viewModel.lineSpacing,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      if (hasNote &&
                                                                          !isSelectionMode)
                                                                        Padding(padding: EdgeInsets.only(left: 4),
                                                                          child: Tooltip(message: '노트',
                                                                            child: Icon(Icons.description,
                                                                              size: 16,
                                                                              color: Theme
                                                                                  .of(context)
                                                                                  .primaryColor,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return SizedBox.shrink();
                                                  }
                                                }).toList(),
                                                // 절간 간격 추가
                                                SizedBox(
                                                    height: viewModel.verseSpacing),
                                              ],
                                            );
                                            return const SizedBox.shrink();
                                          },

                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomNavigationBar: isSelectionMode &&
                          selectedVerseIds.isNotEmpty
                          ? Builder(
                        builder: (innerContext) {
                          return Container(
                            padding: EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionButton(
                                    context,
                                    icon: Icons.copy,
                                    label: '복사',
                                    onPressed: () =>
                                        _copyWithFormat(
                                            innerContext, 'reference'),
                                  ),
                                  _buildActionButton(
                                    context,
                                    icon: Icons.highlight,
                                    label: '형광펜',
                                    onPressed: () =>
                                        _applyHighlight(HighlightColor.yellow),
                                  ),
                                  _buildActionButton(
                                    context,
                                    icon: Icons.edit_note,
                                    label: '노트',
                                    onPressed: _createNoteFromSelection,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                          : null,
                    ),
                  );
                },
              ),
            ),
          );
        },
    );
  }
}

//SizedBox(height: viewModel.verseSpacing),
// 절간 간격 적용// 항목 사이 간격
class Header extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onSelectDate;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback? onExitSelectionMode;

  Header({
    this.selectedDate,
    required this.onSelectDate,
    this.isSelectionMode = false,
    this.selectedCount = 0,
    this.onExitSelectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);

    final today = DateTime.now();
    final todayString = DateFormat('yyy-MM-dd').format(today);

    // MainViewModel에서 SelectedDate를 가져옴
    final selectedDate = viewModel.SelectedDate;

    final displayDate = selectedDate != null
        ? DateFormat('MM/dd(E)', 'ko_KR').format(selectedDate)
        : DateFormat('MM/dd(E)', 'ko_KR').format(today);

    // 오늘의 계획 정보를 가져오기
    final todayPlanDescription = viewModel.TodayPlan != null
        ? '${viewModel.TodayPlan!.book} ${viewModel.TodayPlan!.fChap}:${viewModel.TodayPlan!.fVer} - ${viewModel.TodayPlan!.lChap}:${viewModel.TodayPlan!.lVer}'
        : '오늘의 계획이 없습니다';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 0.1, horizontal: 5),
      color: Colors.transparent,
      child:LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            return Row(
              children: [
                if (isSelectionMode)
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: onExitSelectionMode,
                  )
                else SizedBox(width: 10),
                Expanded(
                  child: isSelectionMode ? Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${selectedCount}개 선택됨',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Mealfont',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme
                            .of(context)
                            .brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  )
                      : GestureDetector(
                    // 터치 이벤트를 감지할 수 있도록 GestureDetector로 감싸기
                    onTap: () {onSelectDate();},
                    child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end,
                      children: [ConstrainedBox
                        (constraints: BoxConstraints(
                        maxWidth: w * 0.55,
                      ),
                        child:Text(
                          todayPlanDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Mealfont',
                            fontSize: (w * 0.04).clamp(14.0, 18.0),
                            fontWeight: FontWeight.bold,
                            color:
                            Theme
                                .of(context)
                                .brightness == Brightness.light
                                ? Colors.black // 라이트 테마일 때 회색
                                : Colors.white, // 다크 테마일 때 검은색
                          ),
                        ),
            ),
                        SizedBox(width: w * 0.05), // 날짜와 계획 사이 간격
                        Expanded(
                          //width: double.infinity,
                          //alignment: Alignment.bottomLeft,
                          child: Text(
                            displayDate,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'Mealfont',
                              fontSize: (w * 0.035).clamp(11.0, 14.0),
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context).brightness == Brightness.light ? Colors.black45 : Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isSelectionMode) ...[
                  SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.import_contacts),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotesCalendarView(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.article),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => SelectBibleView()),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.settings), // 메뉴 버튼
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer(); // Drawer 열기
                        },
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
      ),
    );
  }
}

class ThemeAndBibleMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context, listen: true);
    final List<double> values = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4];

    return Drawer(
      child: SafeArea(
        child:LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final isLandscape = w > h;

              return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        color: Theme.of(context).textTheme.bodyLarge?.backgroundColor,
                        padding: EdgeInsets.symmetric(
                        horizontal: w * 0.04,
                          vertical: h * 0.015,),
                        height: h * 0.08, // 원하는 높이 설정
                        child: Text(
                          '설정',
                          style: TextStyle(
                            fontFamily: 'Settingfont',
                            color: Theme.of(context).textTheme.bodyLarge?.color ??Colors.black,
                            fontSize: w * 0.045,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          MainViewModel.themeMode.value == ThemeMode.light? Icons.light_mode: Icons.dark_mode,
                          size: w * 0.06,
                        ),
                        title: Text(
                          '테마 변경',
                          style: TextStyle(
                            fontFamily: 'Settingfont',
                            color: Theme.of(context).textTheme.bodyLarge?.color ??Colors.black,
                              fontSize: w * 0.045,
                          ),
                        ),
                        onTap: () {
                          viewModel.toggleTheme(); // 테마 변경 로직 호출
                          Navigator.of(context).pop(); // Drawer 닫기
                        },
                      ),
                      Divider(),
                      Padding(
                        padding: EdgeInsets.all(w * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '글자 크기',
                              style: TextStyle(
                                fontFamily: 'Settingfont',
                                fontSize: w * 0.045,
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                              ),
                            ),
                            Slider(
                              value: viewModel.fontSize,
                              min: 12.0,
                              max: 36.0,
                              divisions: 12,
                              // 슬라이더 구간 나누기
                              label: viewModel.fontSize.toStringAsFixed(1),
                              onChanged: (value) {
                                viewModel.updateFontSize(value);
                              },
                            ),
                            SizedBox(height: h * 0.02),
                            Text(
                              '절간 간격',
                              style: TextStyle(
                                fontFamily: 'Settingfont',
                                fontSize: w * 0.045,
                                color: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color ??
                                    Colors.black,
                              ),
                            ),
                            Slider(
                              value: viewModel.verseSpacing,
                              min: 8.0,
                              max: 32.0,
                              divisions: 12,
                              // 슬라이더 구간 나누기
                              label: viewModel.verseSpacing.toStringAsFixed(1),
                              onChanged: (value) {
                                viewModel.updateVerseSpacing(value);
                              },
                            ),
                            SizedBox(height: h * 0.02),
                            Text(
                              '줄간 간격',
                              style: TextStyle(
                                fontFamily: 'Settingfont',
                                fontSize: w * 0.045,
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                              ),
                            ),
                            Slider(
                              value: viewModel.lineSpacing,
                              min: 1.0,
                              max: 3.0,
                              divisions: values.length - 1,
                              // 슬라이더 구간 나누기
                              label: viewModel.lineSpacing.toStringAsFixed(1),
                              onChanged: (value) {
                                viewModel.updateLineSpacing(value);
                              },
                            ),
                            SizedBox(height: h * 0.02),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                '끼니 알림',
                                style: TextStyle(
                                  fontFamily: 'Settingfont',
                                  fontSize: w * 0.045,
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                                ),
                              ),
                              value: viewModel.isDailyBibleAlarmEnabled,
                              onChanged: (enabled) async {
                                await viewModel.setDailyBibleAlarm(enabled);
                              },

                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: h * 0.2),
              Opacity(
                      opacity: 0.5, // 투명도 설정
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                        horizontal: w * 0.03,
              vertical: h * 0.012),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Originally created by InPyo Hong',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Mealfont',
                                fontSize: isLandscape? (w * 0.02).clamp(8.0, 10.0): (w * 0.028).clamp(9.0, 12.0),
                                color: Theme.of(context).textTheme.bodyLarge?.color ??Colors.black,
                              ),
                            ),
                            SizedBox(height: (h * 0.006).clamp(3.0, 8.0)), // 간격 추가
                            Text(
                              'Futher developed by TMTB',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Mealfont',
                                fontSize: isLandscape? (w * 0.02).clamp(8.0, 10.0): (w * 0.028).clamp(9.0, 12.0),
                                color: Theme.of(context).textTheme.bodyLarge?.color ??Colors.black,
                              ),
                            ),
                            SizedBox(height: (h * 0.006).clamp(3.0, 8.0)), // 간격 추가
                            Text(
                              'ⓒ 2024. 대한성서공회 all rights reserved.',
                              style: TextStyle(
                                fontFamily: 'Mealfont',
                                fontSize: isLandscape? (w * 0.02).clamp(8.0, 10.0): (w * 0.028).clamp(9.0, 12.0),
                                color: Theme.of(context).textTheme.bodyLarge?.color ??Colors.black,
                              ),
                            ),
                            SizedBox(height: (h * 0.006).clamp(3.0, 8.0)),
                            Text(
                              'New Americal Standard Bible Copyright ⓒ 1960, 1971, 1995, 2020 by The Lockman Foundation, La Habra, Calif. All rights reserved. For Permission to Quote Information visit www.lockman.org',
                              style: TextStyle(
                                fontFamily: 'Mealfont',
                                fontSize: isLandscape? (w * 0.02).clamp(8.0, 10.0): (w * 0.028).clamp(9.0, 12.0),
                                color: Theme.of(context).textTheme.bodyLarge?.color ??Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: (h * 0.008).clamp(4.0, 10.0)),
                            InkWell(
                              onTap: () async {
                                const url =
                                    'https://docs.google.com/forms/d/e/1FAIpQLScboAaHnboWAq8FJcDYStHRE6ZeqYAmY0AAuatoxeXO1X_WtA/viewform?usp=sharing';
                                if (await canLaunchUrl(Uri.parse(url))) {await launchUrl(Uri.parse(url),mode: LaunchMode.externalApplication);
                                } else {
                                  // URL을 열 수 없을 경우 처리
                                  print('Could not launch $url');
                                }
                                Navigator.of(context).pop(); // Drawer 닫기
                              },
                              child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: w * 0.02,
                                vertical: (h * 0.006).clamp(3.0, 8.0),
                              ),
                              child: Text(
                                textAlign: TextAlign.center,
                                'FeedBack',
                                style: TextStyle(
                                  fontFamily: 'Mealfont',
                                  color: Colors.blueAccent,
                                  // 라이트 테마일 때 회색// 다크 테마일 때 검은색
                                  fontSize: isLandscape? (w * 0.02).clamp(8.0, 10.0): (w * 0.028).clamp(9.0, 12.0),
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.blueAccent,
                                ),
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                    ),

                ],
              );
            },
      ),
      ),
    );
  }
}

Color _selectionFill(BuildContext context) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark) {
    return (Colors.grey[700] ?? theme.colorScheme.surfaceVariant)
        .withOpacity(0.5);
  }
  return theme.primaryColor.withOpacity(0.12);
}

Color _selectionBorder(BuildContext context) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark) {
    return (Colors.grey[400] ?? theme.colorScheme.onSurface).withOpacity(0.6);
  }
  return theme.primaryColor.withOpacity(0.4);
}
