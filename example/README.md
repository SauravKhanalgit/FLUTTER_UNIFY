# Flutter Unify Example App

A production-ready demo application showcasing all Flutter Unify features.

## Features Demonstrated

### 🤖 AI Integration
- Chat with AI models (OpenAI, Anthropic, Gemini)
- Streaming responses for real-time interaction
- Embeddings generation
- Provider switching (OpenAI ↔ Anthropic ↔ Local)

### 🔐 Authentication
- Email/password authentication
- OAuth providers (Google, Apple, GitHub)
- Anonymous authentication
- Biometric authentication (when available)
- Multi-factor authentication
- Account linking and management

### 📊 Developer Tools
- Real-time performance monitoring
- Event tracking and visualization
- System information display
- Dev dashboard web interface
- Error tracking and recovery

### 🌐 Networking
- HTTP requests with performance tracking
- Automatic retry and error handling
- Request/response monitoring
- Network statistics

### 💾 File System
- Cross-platform file operations
- Storage adapters (coming soon)

## Getting Started

### Prerequisites

1. **Flutter SDK** (3.10.0 or higher)
2. **Dart SDK** (3.0.0 or higher)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/flutter_unify.git
   cd flutter_unify/example
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up AI API Key** (optional for AI features):
   ```dart
   // In lib/main.dart, replace with your actual API key
   aiApiKey: 'your-openai-api-key-here',
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## App Structure

```
lib/
├── main.dart              # App entry point with Unify initialization
├── screens/
│   ├── home_screen.dart   # Main dashboard showing all features
│   ├── auth_screen.dart   # Authentication demo
│   ├── ai_screen.dart     # AI chat and features demo
│   └── dev_tools_screen.dart # Developer tools and monitoring
```

## Features Overview

### Home Screen
- **Status Check**: Shows if Flutter Unify is properly initialized
- **Module Status**: Displays available modules
- **Feature Cards**: Quick access to all features
- **Performance Stats**: Real-time performance metrics

### Authentication Screen
- **Email Auth**: Sign up/sign in with email and password
- **OAuth**: Google, Apple, GitHub integration
- **Anonymous**: Sign in without credentials
- **User Profile**: Display current user information
- **Sign Out**: Secure logout functionality

### AI Screen
- **Chat Interface**: Conversational AI interaction
- **Provider Selection**: Switch between AI providers
- **Streaming**: Real-time response streaming
- **Embeddings**: Generate text embeddings
- **Performance Tracking**: Monitor AI operation performance

### Dev Tools Screen
- **Dashboard Toggle**: Enable/disable dev dashboard
- **Performance Monitoring**: Real-time performance stats
- **Event Log**: View recorded events
- **System Info**: Device and system information
- **Web Dashboard**: Open browser-based dashboard

## API Usage Examples

### Auto-Initialization
```dart
// One-line setup for everything
final result = await Unify.autoInitialize(
  aiApiKey: 'your-api-key',
  aiProvider: AIProvider.openai,
);
```

### Authentication
```dart
// Email sign in
final result = await Unify.auth.signInWithEmailAndPassword(email, password);

// OAuth sign in
await Unify.auth.signInWithProvider(AuthProvider.google);

// Listen to auth changes
Unify.auth.onAuthStateChanged.listen((event) {
  if (event.user != null) {
    print('User signed in: ${event.user!.email}');
  }
});
```

### AI Integration
```dart
// Simple chat
final response = await Unify.ai.chat('Hello, how are you?');

// Streaming responses
await for (final chunk in Unify.ai.streamChat(message)) {
  print(chunk.choices.first.delta?.content ?? '');
}

// Generate embeddings
final embedding = await Unify.ai.embed('Flutter is amazing');
```

### Performance Monitoring
```dart
// Track any operation
final result = await Unify.performance.trackOperation(
  'api_call',
  () => fetchData(),
);

// Get statistics
final stats = Unify.performance.getStats();
print('Success rate: ${(stats.successRate * 100).round()}%');
```

### Dev Dashboard
```dart
// Enable dashboard
Unify.dev.enable();

// Record events
Unify.dev.recordEvent(DashboardEvent(
  type: EventType.network,
  title: 'API Request',
  data: {'url': '/api/users'},
));

// Open web dashboard
await Unify.dev.show(); // Opens http://localhost:8080
```

## Development

### Adding New Features

1. **Create a new screen** in `lib/screens/`
2. **Add navigation** in `main.dart`
3. **Implement the feature** using Flutter Unify APIs
4. **Add performance tracking** where appropriate
5. **Record dev events** for monitoring

### Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Run integration tests
flutter test integration_test/
```

### Building

```bash
# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Build for Web
flutter build web
```

## Troubleshooting

### AI Features Not Working
- Check that you have set a valid API key in `main.dart`
- Ensure you have internet connection
- Verify the API key has sufficient credits

### Authentication Not Working
- Some auth methods may require additional setup (Firebase, Supabase)
- Check the console for initialization errors
- Verify platform-specific configurations

### Dev Dashboard Not Opening
- Ensure the dashboard is enabled: `Unify.dev.enable()`
- Check that port 8080 is available
- Try a different port: `await Unify.dev.show(port: 3000)`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Submit a pull request

## License

This example app is part of Flutter Unify and follows the same license terms.

## Support

- 📚 **Documentation**: [flutter_unify_docs.com](https://flutter-unify-docs.com)
- 🐛 **Issues**: [GitHub Issues](https://github.com/flutter-unify/flutter_unify/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/flutter-unify/flutter_unify/discussions)
- 📧 **Email**: support@flutter-unify.com

---

**Built with ❤️ using Flutter Unify**

Showcase all the amazing features of Flutter Unify in this production-ready demo app!