import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:io' as io;
import 'dart:ui';
import '../utils/lesson_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  Map<String, List<Map<String, dynamic>>> _lessonMap = {};
  String _selectedLanguage = 'HTML';
  int _selectedLessonId = 1;
  bool _loading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final loaded = await LessonStorage.loadLessons();
    setState(() {
      _lessonMap = loaded.map(
        (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)),
      );
      _tabController?.dispose(); // Dispose any existing controller
      _tabController = TabController(
        length: _lessonMap.keys.length > 0 ? _lessonMap.keys.length : 1,
        vsync: this,
        initialIndex: _lessonMap.keys.isNotEmpty
            ? _lessonMap.keys.toList().indexOf(_selectedLanguage) >= 0
                ? _lessonMap.keys.toList().indexOf(_selectedLanguage)
                : 0
            : 0,
      );
      _tabController!.addListener(_handleTabChange);
      _loading = false;
    });
  }

  void _handleTabChange() {
    if (_tabController!.indexIsChanging || !mounted) return;
    setState(() {
      _selectedLanguage = _lessonMap.keys.toList()[_tabController!.index];
      _selectedLessonId = 1;
    });
  }

  Future<void> _saveLessons() async {
    await LessonStorage.saveLessons(_lessonMap);
  }

  void _startPractice() {
    if (_lessonMap[_selectedLanguage]!.isEmpty) return;
    final lesson = _lessonMap[_selectedLanguage]!.firstWhere(
      (l) => l['id'] == _selectedLessonId,
      orElse: () => _lessonMap[_selectedLanguage]!.first,
    );
    Navigator.pushNamed(
      context,
      '/practice',
      arguments: {
        'language': _selectedLanguage,
        'lesson': lesson['id'],
        'typingText': lesson['typingText'] ?? '',
      },
    );
  }

  void _addLesson() async {
    String selectedCategory = _selectedLanguage;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        String title = '';
        String description = '';
        String typingText = '';
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.library_add, color: Colors.orange, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Add New Lesson',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _lessonMap.keys
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (v) => selectedCategory = v ?? selectedCategory,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => description = v,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Typing Text',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 5,
                    onChanged: (v) => typingText = v,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onPressed: () {
                          if (title.isNotEmpty && typingText.isNotEmpty) {
                            Navigator.pop(context, {
                              'category': selectedCategory,
                              'title': title,
                              'description': description,
                              'typingText': typingText,
                            });
                          }
                        },
                        label: const Text('Add Lesson'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result != null && result['title'] != null && result['typingText'] != null) {
      setState(() {
        final lessons = _lessonMap[result['category']]!;
        lessons.add({
          'id': lessons.length + 1,
          'title': result['title']!,
          'description': result['description'] ?? '',
          'typingText': result['typingText']!,
        });
        _selectedLanguage = result['category']!;
        _selectedLessonId = lessons.length;
        _updateTabController();
      });
      await _saveLessons();
    }
  }

  void _addCategory() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        String category = '';
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.create_new_folder, color: Colors.orange, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Add New Category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => category = v,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 18),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: () {
                        if (category.trim().isNotEmpty && !_lessonMap.containsKey(category.trim())) {
                          Navigator.pop(context, category.trim());
                        }
                      },
                      label: const Text('Add Category'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null && !_lessonMap.containsKey(result)) {
      setState(() {
        _lessonMap[result] = [];
        _selectedLanguage = result;
        _selectedLessonId = 1;
        _updateTabController();
      });
      await _saveLessons();
    }
  }

  void _updateTabController() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _tabController = TabController(
      length: _lessonMap.keys.length > 0 ? _lessonMap.keys.length : 1,
      vsync: this,
      initialIndex: _lessonMap.keys.isNotEmpty
          ? _lessonMap.keys.toList().indexOf(_selectedLanguage) >= 0
              ? _lessonMap.keys.toList().indexOf(_selectedLanguage)
              : 0
          : 0,
    );
    _tabController!.addListener(_handleTabChange);
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_box, color: Colors.orange),
                title: const Text('Add Category'),
                onTap: () {
                  Navigator.pop(context);
                  _addCategory();
                },
              ),
              ListTile(
                leading: const Icon(Icons.add, color: Colors.orange),
                title: const Text('Add Lesson'),
                onTap: () {
                  Navigator.pop(context);
                  _addLesson();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_upload, color: Colors.orange),
                title: const Text('Import Lessons'),
                onTap: () {
                  Navigator.pop(context);
                  _importLessons();
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download, color: Colors.orange),
                title: const Text('Export Lessons'),
                onTap: () {
                  Navigator.pop(context);
                  _exportLessons();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _importLessons() async {
    try {
      if (kIsWeb) {
        html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
        uploadInput.accept = '.json';
        uploadInput.click();
        await uploadInput.onChange.first;
        final file = uploadInput.files?.first;
        if (file != null) {
          final reader = html.FileReader();
          reader.readAsText(file);
          await reader.onLoadEnd.first;
          final content = reader.result as String;
          final imported = json.decode(content) as Map<String, dynamic>;
          setState(() {
            _lessonMap = imported.map(
              (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)),
            );
            _selectedLanguage = _lessonMap.keys.isNotEmpty ? _lessonMap.keys.first : 'HTML';
            _selectedLessonId = 1;
            _updateTabController();
          });
          await _saveLessons();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lessons imported!')));
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (result != null && result.files.single.path != null) {
          final file = io.File(result.files.single.path!);
          final content = await file.readAsString();
          final imported = json.decode(content) as Map<String, dynamic>;
          setState(() {
            _lessonMap = imported.map(
              (k, v) => MapEntry(k, List<Map<String, dynamic>>.from(v)),
            );
            _selectedLanguage = _lessonMap.keys.isNotEmpty ? _lessonMap.keys.first : 'HTML';
            _selectedLessonId = 1;
            _updateTabController();
          });
          await _saveLessons();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lessons imported!')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _exportLessons() async {
    try {
      final jsonString = json.encode(_lessonMap);
      if (kIsWeb) {
        final bytes = utf8.encode(jsonString);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'lessons_export.json')
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lessons exported!')));
      } else {
        String? output = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Lessons As',
          fileName: 'lessons_export.json',
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (output != null) {
          final file = io.File(output);
          await file.writeAsString(jsonString);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lessons exported!')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final lessons = _lessonMap[_selectedLanguage] ?? [];

    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        backgroundColor: Colors.orange[50],
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 36),
            const SizedBox(width: 10),
            Text(
              'YHA Computer',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            height: 64,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.orange[200]!, width: 1.2),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.deepOrange[300]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.orange[700],
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    tabs: _lessonMap.keys
                        .map(
                          (lang) => Tab(
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.folder_special_rounded,
                                    size: 18,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(lang),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.orange),
            tooltip: 'Settings',
            onPressed: _showSettingsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                _buildStatCard('WPM', '45', Icons.speed, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Accuracy', '92%', Icons.track_changes, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard('Lessons', '${lessons.length}', Icons.school, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: Colors.orange[400]),
                            const SizedBox(width: 8),
                            Text(
                              'Lessons ($_selectedLanguage)',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${lessons.length} total',
                            style: TextStyle(
                              color: Colors.orange[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: lessons.isEmpty
                        ? Center(
                            child: Text(
                              'No lessons yet.\nAdd your first lesson from Settings!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              final isSelected = _selectedLessonId == lesson['id'];
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange[50] : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? Colors.orange : Colors.orange[100]!,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.12),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    setState(() {
                                      _selectedLessonId = lesson['id'];
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.code,
                                          color: Colors.orange,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lesson['title'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.orange[800] : Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lesson['description'],
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: lessons.isEmpty ? null : _startPractice,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  lessons.isEmpty ? 'No Lesson' : 'Start Lesson $_selectedLessonId',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.orange[700], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}