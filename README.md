# Programming Keyboard Trainer

A Flutter Windows Desktop Application that helps beginners practice typing and learn HTML, CSS, and JavaScript syntax.

## 🚀 Features

### HomePage
- **Language Selection**: Choose between HTML, CSS, and JavaScript
- **Dark Mode Toggle**: Switch between light and dark themes
- **Modern UI**: Clean, responsive design with Material Design
- **Start Practice Button**: Navigate to the practice session

### PracticePage
- **Syntax Highlighting**: Code snippets with proper syntax highlighting
- **Real-time Metrics**: 
  - Typing speed (WPM - Words Per Minute)
  - Accuracy percentage
  - Progress tracking
  - Timer
- **Split View**: Target code on the left, typing area on the right
- **Virtual Keyboard**: Visual keyboard representation (placeholder)
- **Reset Functionality**: Restart practice sessions

## 📋 Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- For Windows Desktop: Visual Studio with "Desktop development with C++" workload
- For Web: Chrome or Edge browser
- For Android: Android Studio and Android SDK

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd programming_keyboard_trainer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**

   **For Web (Recommended for quick testing):**
   ```bash
   flutter run -d chrome
   ```

   **For Windows Desktop:**
   ```bash
   flutter run -d windows
   ```

   **For Android:**
   ```bash
   flutter run -d android
   ```

## 📦 Dependencies

- `flutter_highlight: ^0.7.0` - For syntax highlighting
- `flutter_typeahead: ^5.2.0` - For typing analysis
- `provider: ^6.1.1` - For state management

## 🎯 How to Use

1. **Launch the Application**
   - The app opens to the HomePage with a beautiful gradient background
   - You'll see the app title and a dark mode toggle in the top-right corner

2. **Select a Language**
   - Use the dropdown to choose between HTML, CSS, or JavaScript
   - Each language has its own icon and color coding

3. **Start Practice**
   - Click the "Start Practice" button
   - You'll be taken to the PracticePage

4. **Practice Session**
   - The left panel shows the target code with syntax highlighting
   - The right panel is your typing area
   - Real-time metrics are displayed at the top
   - Type the code exactly as shown in the target

5. **Track Your Progress**
   - Monitor your WPM (Words Per Minute)
   - Check your accuracy percentage
   - See your progress (characters typed vs total)
   - Watch the timer

6. **Reset Practice**
   - Use the refresh button in the app bar to restart

## 🎨 UI Features

- **Responsive Design**: Works on different screen sizes
- **Material Design 3**: Modern UI components
- **Dark/Light Theme**: Toggle between themes
- **Gradient Backgrounds**: Beautiful visual appeal
- **Card-based Layout**: Clean and organized interface
- **Monospace Font**: For code readability

## 📊 Code Snippets Included

### HTML
- Complete HTML5 document structure
- Header with navigation
- Main content sections
- Footer

### CSS
- Reset and base styles
- Header styling with gradients
- Navigation styling
- Responsive layout
- Footer styling

### JavaScript
- Utility functions (debounce)
- DOM manipulation
- Event listeners
- Form validation
- Email validation
- Notification system

## 🔧 Troubleshooting

### Windows Desktop Issues
If you get "Unable to find suitable Visual Studio toolchain":
1. Install Visual Studio Community (free)
2. During installation, select "Desktop development with C++"
3. Include Windows 10/11 SDK and CMake tools

### Web Development
For web development, simply run:
```bash
flutter run -d chrome
```

### Android Development
For Android development:
1. Install Android Studio
2. Set up Android SDK
3. Create an Android emulator
4. Run: `flutter run -d android`

## 🚀 Future Enhancements

- [ ] More programming languages (Python, Java, C++)
- [ ] Custom code snippets
- [ ] User accounts and progress tracking
- [ ] Advanced virtual keyboard
- [ ] Sound effects for typing
- [ ] Export practice results
- [ ] Difficulty levels
- [ ] Multiplayer mode

## 📝 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you encounter any issues or have questions, please open an issue on the repository.

---

**Happy Coding! 🎉**
