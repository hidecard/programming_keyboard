import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> with TickerProviderStateMixin {
  String _selectedLanguage = 'HTML';
  int _selectedLesson = 1;
  String _targetCode = '';
  final TextEditingController _typingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _targetScrollController = ScrollController();
  final ScrollController _typingScrollController = ScrollController();
  bool _isManualScrolling = false;
  Timer? _scrollDebounceTimer;
  Timer? _textChangeDebounceTimer;

  // State variables
  String? _currentKey;
  bool _showHomeRow = true;
  bool _isStarted = false;
  bool _isCompleted = false;
  int _startTime = 0;
  int _currentTime = 0;
  int _totalCharacters = 0;
  int _correctCharacters = 0;
  double _wpm = 0.0;
  double _accuracy = 0.0;
  int _errors = 0;
  int _currentPosition = 0;
  int _currentCharIndex = 0;
  List<bool> _charStatus = [];
  List<TextSpan>? _cachedSpans;
  int? _lastPosition;
  List<bool>? _lastCharStatus;

  @override
  void initState() {
    super.initState();
    _typingController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);

    FocusManager.instance.primaryFocus?.unfocus();
    RawKeyboard.instance.addListener(_onRawKey);

    _targetScrollController.addListener(() {
      if (_targetScrollController.position.isScrollingNotifier.value) {
        _isManualScrolling = true;
      } else {
        _isManualScrolling = false;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _selectedLanguage = args['language'] ?? 'HTML';
          _selectedLesson = args['lesson'] ?? 1;
          _targetCode = args['typingText'] ?? '';
          _totalCharacters = _targetCode.length;
          _charStatus = List.filled(_totalCharacters, false);
        });
      }
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _autoScrollToCurrentPosition();
    }
  }

  @override
  void dispose() {
    _textChangeDebounceTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    RawKeyboard.instance.removeListener(_onRawKey);
    _typingController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _typingController.dispose();
    _focusNode.dispose();
    _targetScrollController.dispose();
    _typingScrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _textChangeDebounceTimer?.cancel();
    _textChangeDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_isStarted && _targetCode.isNotEmpty) {
        _startTimer();
      }

      final typedText = _typingController.text;
      _correctCharacters = 0;
      _errors = 0;
      _currentPosition = typedText.length;
      _currentCharIndex = typedText.length;

      for (int i = 0; i < typedText.length && i < _targetCode.length; i++) {
        bool isCorrect = typedText[i] == _targetCode[i];
        _charStatus[i] = isCorrect;
        if (isCorrect) {
          _correctCharacters++;
        } else {
          _errors++;
        }
      }

      _calculateMetrics();
      _autoScrollToCurrentPosition();

      if (typedText.length >= _targetCode.length && _targetCode.isNotEmpty) {
        _completePractice();
      }

      setState(() {});
    });
  }

  void _startTimer() {
    setState(() {
      _isStarted = true;
      _startTime = DateTime.now().millisecondsSinceEpoch;
    });
    _updateTimer();
  }

  void _updateTimer() {
    if (!_isStarted || _isCompleted || !mounted) return;

    final newTime = DateTime.now().millisecondsSinceEpoch - _startTime;
    if ((newTime - _currentTime).abs() > 100) {
      setState(() {
        _currentTime = newTime;
      });
      _calculateMetrics();
    }
    Future.delayed(const Duration(milliseconds: 100), _updateTimer);
  }

  void _calculateMetrics() {
    final elapsedMinutes = _currentTime / 60000;
    final typedWords = _typingController.text.split(' ').length;

    setState(() {
      _wpm = elapsedMinutes > 0 ? typedWords / elapsedMinutes : 0;
      _accuracy = _totalCharacters > 0
          ? (_correctCharacters / _totalCharacters) * 100
          : 0;
    });
  }

  void _autoScrollToCurrentPosition() {
    if (_isManualScrolling || _isCompleted || _targetCode.isEmpty) return;

    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      final textBeforeCursor = _typingController.text.substring(0, _currentPosition);
      final textSpan = TextSpan(
        text: textBeforeCursor,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 16,
          height: 1.5,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout(maxWidth: MediaQuery.of(context).size.width / 2);

      final caretOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: _currentPosition),
        Rect.zero,
      );

      final targetOffset = caretOffset.dy - (MediaQuery.of(context).size.height / 4);

      if (_targetScrollController.hasClients) {
        _targetScrollController.animateTo(
          targetOffset.clamp(0.0, _targetScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }

      if (_typingScrollController.hasClients) {
        _typingScrollController.animateTo(
          targetOffset.clamp(0.0, _typingScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _completePractice() {
    setState(() {
      _isCompleted = true;
    });

    final session = PracticeSession(
      language: _selectedLanguage,
      lessonId: _selectedLesson,
      wpm: _wpm,
      accuracy: _accuracy,
      duration: _currentTime ~/ 1000,
      errors: _errors,
      completedAt: DateTime.now(),
      isPerfect: _accuracy == 100.0,
    );

    StatisticsService.updateStatistics(session);
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text('Lesson Completed! 🎉'),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Performance Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildResultRow('WPM', '${_wpm.toStringAsFixed(1)}', Icons.speed),
                    _buildResultRow('Accuracy', '${_accuracy.toStringAsFixed(1)}%', Icons.track_changes),
                    _buildResultRow('Time', _formatTime(_currentTime), Icons.access_time),
                    _buildResultRow('Errors', '$_errors', Icons.error_outline),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '100% Complete',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
              if (_accuracy == 100.0)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.purple, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Perfect Lesson!',
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Lessons'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _resetPractice();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _resetPractice() {
    setState(() {
      _isStarted = false;
      _isCompleted = false;
      _startTime = 0;
      _currentTime = 0;
      _correctCharacters = 0;
      _wpm = 0.0;
      _accuracy = 0.0;
      _errors = 0;
      _currentPosition = 0;
      _currentCharIndex = 0;
      _charStatus = List.filled(_totalCharacters, false);
      _isManualScrolling = false;
      _cachedSpans = null;
      _lastPosition = null;
      _lastCharStatus = null;
    });
    _typingController.clear();
    _targetScrollController.jumpTo(0);
    _typingScrollController.jumpTo(0);
    _focusNode.requestFocus();
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<TextSpan> _buildColoredText() {
    if (_cachedSpans != null && _lastPosition == _currentPosition && _lastCharStatus == _charStatus) {
      return _cachedSpans!;
    }

    List<TextSpan> spans = [];
    for (int i = 0; i < _targetCode.length; i++) {
      Color textColor;
      Color backgroundColor;

      if (i < _currentPosition) {
        if (_charStatus[i]) {
          textColor = Colors.green[700]!;
          backgroundColor = Colors.green[50]!;
        } else {
          textColor = Colors.red[700]!;
          backgroundColor = Colors.red[50]!;
        }
      } else if (i == _currentPosition) {
        textColor = Colors.white;
        backgroundColor = Theme.of(context).colorScheme.primary;
      } else {
        textColor = Colors.grey[600]!;
        backgroundColor = Colors.transparent;
      }

      spans.add(
        TextSpan(
          text: _targetCode[i],
          style: TextStyle(
            color: textColor,
            backgroundColor: backgroundColor,
            fontWeight: i == _currentPosition ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    _cachedSpans = spans;
    _lastPosition = _currentPosition;
    _lastCharStatus = List.from(_charStatus);
    return spans;
  }

  void _onRawKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      setState(() {
        _currentKey = _mapLogicalKeyToChar(event.logicalKey);
      });
    } else if (event is RawKeyUpEvent) {
      setState(() {
        _currentKey = null;
      });
    }
  }

  String? _mapLogicalKeyToChar(LogicalKeyboardKey key) {
    final keyLabel = key.keyLabel?.toLowerCase() ?? '';
    const symbolMap = {
      'semicolon': ';',
      'equal': '=',
      'comma': ',',
      'minus': '-',
      'period': '.',
      'slash': '/',
      'backslash': '\\',
      'quote': '\'',
      'backquote': '`',
      'open bracket': '[',
      'close bracket': ']',
      'less than': '<',
      'greater than': '>',
      'vertical line': '|',
      'space': ' ',
      'tab': 'tab',
      'shift left': 'shift',
      'shift right': 'shift',
      '1': '1',
      '2': '2',
      '3': '3',
      '4': '4',
      '5': '5',
      '6': '6',
      '7': '7',
      '8': '8',
      '9': '9',
      '0': '0',
    };
    return symbolMap[keyLabel] ?? keyLabel;
  }

  Widget _buildVirtualKeyboard() {
    final rows = [
      ['tab', '`', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '|'],
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\'],
      ['shift', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '<', '>'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'],
      ['space'],
    ];

    List<String> nextKeys = [];
    bool needsShift = false;

    if (_currentPosition < _targetCode.length) {
      final nextChar = _targetCode[_currentPosition];
      final mappedKey = _mapCharToKeyboardKey(nextChar);
      nextKeys.add(mappedKey);
      if (nextChar.toUpperCase() != nextChar.toLowerCase() && nextChar == nextChar.toUpperCase() ||
          const ['!', '@', '#', '\$', '%', '^', '&', '*', '(', ')', '_', '+', '<', '>', ':', '"', '{', '}', '?', '~', '|'].contains(nextChar)) {
        needsShift = true;
        nextKeys.add('shift');
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              final isHome = ['shift', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '<', '>'].contains(key);
              final isActive = _currentKey == key;
              final isNext = nextKeys.contains(key) && !isActive;
              final isSpace = key == 'space';
              final isShift = key == 'shift';
              final isTab = key == 'tab';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: isSpace ? 40 : (isShift || isTab) ? 20 : 12,
                  vertical: isSpace ? 8 : 10,
                ),
                decoration: BoxDecoration(
                color: isActive
                    ? Colors.orange[600]
                    : isNext
                        ? Colors.blue[400]
                        : isHome && _showHomeRow
                            ? Colors.orange[100]
                            : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? Colors.orange[800]!
                      : isNext
                          ? Colors.blue[800]!
                          : isHome && _showHomeRow
                              ? Colors.orange[400]!
                              : Colors.grey[300]!,
                  width: isActive || isNext ? 3 : 1,
                ),
                boxShadow: isNext
                    ? [
                        BoxShadow(
                          color: Colors.blue[600]!.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : isActive
                        ? [
                            BoxShadow(
                              color: Colors.orange[600]!.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
              ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: isNext ? 1.08 : 1.0).animate(
                    CurvedAnimation(
                      parent: AnimationController(
                        duration: const Duration(milliseconds: 500),
                        vsync: this,
                      )..repeat(reverse: true),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Text(
                    isSpace
                        ? 'Space'
                        : isShift
                            ? 'Shift'
                            : isTab
                                ? 'Tab'
                                : key.toUpperCase(),
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : isNext
                              ? Colors.white
                              : isHome && _showHomeRow
                                  ? Colors.orange[800]
                                  : Colors.grey[800],
                      fontWeight: isActive || isNext ? FontWeight.bold : FontWeight.normal,
                      fontSize: isSpace ? 16 : (isShift || isTab) ? 14 : 18,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  String _mapCharToKeyboardKey(String char) {
    const charToKeyMap = {
      ' ': 'space',
      ';': 'semicolon',
      '=': 'equal',
      ',': 'comma',
      '-': 'minus',
      '.': 'period',
      '/': 'slash',
      '\\': 'backslash',
      '\'': 'quote',
      '`': 'backquote',
      '[': 'open bracket',
      ']': 'close bracket',
      '<': 'less than',
      '>': 'greater than',
      '|': 'vertical line',
      '\t': 'tab',
      '!': '1',
      '@': '2',
      '#': '3',
      '\$': '4',
      '%': '5',
      '^': '6',
      '&': '7',
      '*': '8',
      '(': '9',
      ')': '0',
      '_': 'minus',
      '+': 'equal',
      ':': 'semicolon',
      '"': 'quote',
      '{': 'open bracket',
      '}': 'close bracket',
      '?': 'slash',
      '~': 'backquote',
      'A': 'a',
      'B': 'b',
      'C': 'c',
      'D': 'd',
      'E': 'e',
      'F': 'f',
      'G': 'g',
      'H': 'h',
      'I': 'i',
      'J': 'j',
      'K': 'k',
      'L': 'l',
      'M': 'm',
      'N': 'n',
      'O': 'o',
      'P': 'p',
      'Q': 'q',
      'R': 'r',
      'S': 's',
      'T': 't',
      'U': 'u',
      'V': 'v',
      'W': 'w',
      'X': 'x',
      'Y': 'y',
      'Z': 'z',
    };

    return charToKeyMap[char] ?? char.toLowerCase();
  }

  void _startPractice() {
    setState(() {
      _isStarted = true;
      _isCompleted = false;
      _startTime = DateTime.now().millisecondsSinceEpoch;
      _currentTime = 0;
      _correctCharacters = 0;
      _wpm = 0.0;
      _accuracy = 0.0;
      _errors = 0;
      _currentPosition = 0;
      _currentCharIndex = 0;
      _charStatus = List.filled(_totalCharacters, false);
      _isManualScrolling = false;
      _cachedSpans = null;
      _lastPosition = null;
      _lastCharStatus = null;
    });
    _typingController.clear();
    _targetScrollController.jumpTo(0);
    _typingScrollController.jumpTo(0);
    _focusNode.requestFocus();
    _updateTimer();
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  String _getLanguageString() {
    switch (_selectedLanguage) {
      case 'HTML':
        return 'html';
      case 'CSS':
        return 'css';
      case 'JavaScript':
        return 'javascript';
      default:
        return 'html';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPractice,
            tooltip: 'Reset Practice',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lesson $_selectedLesson - $_selectedLanguage',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                            fontSize: 22,
                          ),
                    ),
                    Text(
                      '${_currentPosition}/$_totalCharacters',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _totalCharacters > 0 ? _currentPosition / _totalCharacters : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.orange[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('Time', _formatTime(_currentTime), Icons.access_time),
                _buildMetric('WPM', _wpm.toStringAsFixed(1), Icons.speed),
                _buildMetric('Accuracy', '${_accuracy.toStringAsFixed(1)}%', Icons.track_changes),
                _buildMetric('Errors', '$_errors', Icons.error_outline),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.orange[100]!,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.code, size: 18, color: Colors.orange[800]),
                                const SizedBox(width: 8),
                                Text(
                                  'Target Code',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$_currentPosition/$_totalCharacters',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _targetScrollController,
                              padding: const EdgeInsets.all(16),
                              child: SelectableText.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                  children: _buildColoredText(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18, color: Colors.orange[800]),
                              const SizedBox(width: 8),
                              Text(
                                'Your Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Position: $_currentPosition',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _typingScrollController,
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _typingController,
                              focusNode: _focusNode,
                              maxLines: null,
                              style: const TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 16,
                                height: 1.5,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Start typing here...',
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildVirtualKeyboard(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startPractice,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Practice'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// Placeholder for PracticeSession and StatisticsService
class PracticeSession {
  final String language;
  final int lessonId;
  final double wpm;
  final double accuracy;
  final int duration;
  final int errors;
  final DateTime completedAt;
  final bool isPerfect;

  PracticeSession({
    required this.language,
    required this.lessonId,
    required this.wpm,
    required this.accuracy,
    required this.duration,
    required this.errors,
    required this.completedAt,
    required this.isPerfect,
  });
}

class StatisticsService {
  static void updateStatistics(PracticeSession session) {
    // Implement statistics update logic
  }
}