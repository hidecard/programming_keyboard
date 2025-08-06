import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../models/statistics.dart';
import '../models/achievement.dart';
import 'package:flutter/services.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  String _selectedLanguage = 'HTML';
  int _selectedLesson = 1;
  String _targetCode = '';
  final TextEditingController _typingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
  List<bool> _charStatus = []; // true = correct, false = incorrect

  final Map<String, Map<int, String>> _lessonSnippets = {
    'HTML': {
      1: '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Website</title>
</head>
<body>
    <header>
        <h1>Welcome to My Site</h1>
        <nav>
            <ul>
                <li><a href="#home">Home</a></li>
                <li><a href="#about">About</a></li>
                <li><a href="#contact">Contact</a></li>
            </ul>
        </nav>
    </header>
    <main>
        <section id="home">
            <h2>Home</h2>
            <p>This is the home section.</p>
        </section>
    </main>
    <footer>
        <p>&copy; 2024 My Website</p>
    </footer>
</body>
</html>''',
      2: '''<nav class="main-nav">
    <ul class="nav-list">
        <li class="nav-item">
            <a href="/" class="nav-link">Home</a>
        </li>
        <li class="nav-item">
            <a href="/products" class="nav-link">Products</a>
        </li>
        <li class="nav-item">
            <a href="/services" class="nav-link">Services</a>
        </li>
        <li class="nav-item">
            <a href="/contact" class="nav-link">Contact</a>
        </li>
    </ul>
</nav>''',
      3: '''<form class="contact-form" action="/submit" method="POST">
    <div class="form-group">
        <label for="name">Full Name:</label>
        <input type="text" id="name" name="name" required>
    </div>
    <div class="form-group">
        <label for="email">Email Address:</label>
        <input type="email" id="email" name="email" required>
    </div>
    <div class="form-group">
        <label for="message">Message:</label>
        <textarea id="message" name="message" rows="5" required></textarea>
    </div>
    <button type="submit" class="submit-btn">Send Message</button>
</form>''',
    },
    'CSS': {
      4: '''/* Reset and base styles */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Arial', sans-serif;
    line-height: 1.6;
    color: #333;
    background-color: #f4f4f4;
}

/* Header styles */
header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1rem 0;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
}''',
      5: '''/* Flexbox Layout */
.container {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 20px;
    padding: 20px;
}

.card {
    flex: 1;
    min-width: 300px;
    background: white;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    padding: 20px;
    transition: transform 0.3s ease;
}

.card:hover {
    transform: translateY(-5px);
}''',
    },
    'JavaScript': {
      6: '''// Utility functions
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// DOM manipulation
document.addEventListener('DOMContentLoaded', function() {
    const header = document.querySelector('header');
    const navLinks = document.querySelectorAll('nav a');
    
    // Smooth scrolling for navigation links
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href').substring(1);
            const targetSection = document.getElementById(targetId);
            
            if (targetSection) {
                targetSection.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
});''',
    },
  };

  @override
  void initState() {
    super.initState();
    _typingController.addListener(_onTextChanged);

    // Keyboard event listener
    FocusManager.instance.primaryFocus?.unfocus();
    RawKeyboard.instance.addListener(_onRawKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onRawKey);
    _typingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isStarted) {
      _startTimer();
    }

    final typedText = _typingController.text;
    _correctCharacters = 0;
    _errors = 0;
    _currentPosition = typedText.length;
    _currentCharIndex = typedText.length;

    // Update character status for real-time tracking
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

    if (typedText.length >= _targetCode.length) {
      _completePractice();
    }
  }

  void _startTimer() {
    setState(() {
      _isStarted = true;
      _startTime = DateTime.now().millisecondsSinceEpoch;
    });
    _updateTimer();
  }

  void _updateTimer() {
    if (!_isStarted || _isCompleted) return;
    if (!mounted) return;
    setState(() {
      _currentTime = DateTime.now().millisecondsSinceEpoch - _startTime;
    });
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

  void _completePractice() {
    setState(() {
      _isCompleted = true;
    });

    // Create practice session and update statistics
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

    // Show enhanced completion dialog
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
              // Performance Summary
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
                    _buildResultRow(
                      'WPM',
                      '${_wpm.toStringAsFixed(1)}',
                      Icons.speed,
                    ),
                    _buildResultRow(
                      'Accuracy',
                      '${_accuracy.toStringAsFixed(1)}%',
                      Icons.track_changes,
                    ),
                    _buildResultRow(
                      'Time',
                      _formatTime(_currentTime),
                      Icons.access_time,
                    ),
                    _buildResultRow('Errors', '$_errors', Icons.error_outline),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Progress Bar
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

              // Achievement Notification
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
    });
    _typingController.clear();
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<TextSpan> _buildColoredText() {
    List<TextSpan> spans = [];

    for (int i = 0; i < _targetCode.length; i++) {
      Color textColor;
      Color backgroundColor;

      if (i < _currentPosition) {
        // Already typed
        if (_charStatus[i]) {
          // Correct character
          textColor = Colors.green[700]!;
          backgroundColor = Colors.green[50]!;
        } else {
          // Incorrect character
          textColor = Colors.red[700]!;
          backgroundColor = Colors.red[50]!;
        }
      } else if (i == _currentPosition) {
        // Current position (cursor)
        textColor = Colors.white;
        backgroundColor = Theme.of(context).colorScheme.primary;
      } else {
        // Not yet typed
        textColor = Colors.grey[600]!;
        backgroundColor = Colors.transparent;
      }

      spans.add(
        TextSpan(
          text: _targetCode[i],
          style: TextStyle(
            color: textColor,
            backgroundColor: backgroundColor,
            fontWeight: i == _currentPosition
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      );
    }

    return spans;
  }

  // Keyboard event handler
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

  // Map logical keys to characters, including additional symbols
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

  // Virtual Keyboard Widget
  Widget _buildVirtualKeyboard() {
    // Define keyboard rows including numbers, symbols, shift, and tab
    final rows = [
      // Number row
      [
        'tab',
        '`',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '0',
        '-',
        '=',
        '|',
      ],
      // Top row
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\\'],
      // Home row
      [
        'shift',
        'a',
        's',
        'd',
        'f',
        'g',
        'h',
        'j',
        'k',
        'l',
        ';',
        '\'',
        '<',
        '>',
      ],
      // Bottom row
      ['z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/'],
      // Space bar
      ['space'],
    ];

    // Determine the next keys to highlight (including Shift for uppercase and symbols)
    List<String> nextKeys = [];
    if (_currentPosition < _targetCode.length) {
      final nextChar = _targetCode[_currentPosition];
      final mappedKey = _mapCharToKeyboardKey(nextChar);
      nextKeys.add(mappedKey);
      // If the next character is uppercase or a Shift-modified symbol, also highlight Shift
      if ((nextChar.toUpperCase() != nextChar.toLowerCase() &&
              nextChar == nextChar.toUpperCase()) ||
          const [
            '!',
            '<',
            '>',
            '.',
            '/',
            '.',
            ',',
            ';',
            ':',
            '\'',
            '[',
            ']',
            '\'',
            '=',
            '-',
            '0',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '(',
            ')',
            '_',
            '+',
            ':',
            '"',
            '{',
            '}',
            '?',
            '!',
            '@',
            '#'
          ].contains(nextChar)) {
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
              final isHome = ['shift','a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '<', '>'].contains(key);
              final isActive = _currentKey == key;
              final isNext = nextKeys.contains(key) && !isActive;
              final isSpace = key == 'space';
              final isShift = key == 'shift';
              final isTab = key == 'tab';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: isSpace
                      ? 40
                      : (isShift || isTab)
                      ? 20
                      : 12,
                  vertical: isSpace ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.orange
                      : isNext
                      ? Colors.blue[100]
                      : isHome && _showHomeRow
                      ? Colors.orange[100]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? Colors.orange[700]!
                        : isNext
                        ? Colors.blue[700]!
                        : isHome && _showHomeRow
                        ? Colors.orange
                        : Colors.grey[300]!,
                    width: isActive || isNext ? 2 : 1,
                  ),
                  boxShadow: isActive || isNext
                      ? [
                          BoxShadow(
                            color: (isActive ? Colors.orange : Colors.blue)
                                .withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  isSpace
                      ? 'Space'
                      : (isShift
                            ? 'Shift'
                            : (isTab ? 'Tab' : key.toUpperCase())),
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : isNext
                        ? Colors.blue[800]
                        : isHome && _showHomeRow
                        ? Colors.orange[800]
                        : Colors.grey[800],
                    fontWeight: isActive || isNext
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: isSpace
                        ? 16
                        : (isShift || isTab)
                        ? 14
                        : 18,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // Map target character to keyboard key
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
      '!': '1', // Shift + 1
      '@': '2', // Shift + 2
      '#': '3', // Shift + 3
      '%': '5', // Shift + 5
      '^': '6', // Shift + 6
      '&': '7', // Shift + 7
      '*': '8', // Shift + 8
      '(': '9', // Shift + 9
      ')': '0', // Shift + 0
      '_': 'minus', // Shift + -
      '+': 'equal', // Shift + =
      ':': 'semicolon', // Shift + ;
      '"': 'quote', // Shift + '
      '{': 'open bracket', // Shift + [
      '}': 'close bracket', // Shift + ]
      '?': 'slash', // Shift + /
    };
    // For uppercase letters, return the lowercase key
    if (char.toUpperCase() != char.toLowerCase() &&
        char == char.toUpperCase()) {
      return char.toLowerCase();
    }
    return charToKeyMap[char] ?? char.toLowerCase();
  }

  void _startPractice() {
    // Reset state and start timer
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
    });
    _typingController.clear();
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
            Icon(
              Icons.keyboard_alt_rounded,
              color: Colors.orange[700],
              size: 32,
            ),
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
          // Progress Bar
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
                      '${_currentPosition}/${_totalCharacters}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: _totalCharacters > 0
                      ? _currentPosition / _totalCharacters
                      : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Metrics Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.orange[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  'Time',
                  _formatTime(_currentTime),
                  Icons.access_time,
                ),
                _buildMetric('WPM', _wpm.toStringAsFixed(1), Icons.speed),
                _buildMetric(
                  'Accuracy',
                  '${_accuracy.toStringAsFixed(1)}%',
                  Icons.track_changes,
                ),
                _buildMetric('Errors', '$_errors', Icons.error_outline),
              ],
            ),
          ),

          // Main Content
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
                  // Target Code Display
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
                                Icon(
                                  Icons.code,
                                  size: 18,
                                  color: Colors.orange,
                                ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
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
                              padding: const EdgeInsets.all(16),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 18,
                                    color: Colors.black,
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
                  // Typing Area
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
                              Icon(Icons.edit, size: 18, color: Colors.orange),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _typingController,
                              focusNode: _focusNode,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Start typing here...',
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

          // Virtual Keyboard Overlay
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
