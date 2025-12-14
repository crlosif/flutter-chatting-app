# Flutter Chatting App

A modern, real-time chat application built with Flutter and Supabase. Features a beautiful dark theme UI with smooth animations and full real-time messaging support.

## Features

- 🔐 **Authentication** - Email/password signup and login with Supabase Auth
- 💬 **Real-time Messaging** - Instant message delivery using Supabase Realtime
- 👥 **Direct Messages** - Start private conversations with any user
- 👫 **Group Chats** - Create group conversations with multiple participants
- 🟢 **Online Status** - See who's currently online
- 🎨 **Beautiful UI** - Modern dark theme with smooth animations
- 📱 **Cross-platform** - Works on iOS, Android, Web, and Desktop

## Screenshots

The app features:
- Deep ocean blue gradient backgrounds
- Coral accent colors for interactive elements
- Animated message bubbles with read receipts
- Floating action buttons with glow effects
- Staggered list animations

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- A Supabase project

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd flutter_chatting_app
   ```

2. **Create a Supabase Project**
   - Go to [supabase.com](https://supabase.com) and create a new project
   - Wait for the project to be provisioned

3. **Set up the Database**
   - Navigate to SQL Editor in your Supabase dashboard
   - Copy and run the contents of `supabase/schema.sql`
   - This creates all required tables, indexes, and security policies

4. **Configure the App**
   - Open `lib/config/supabase_config.dart`
   - Replace the placeholder values with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'https://your-project.supabase.co';
   static const String supabaseAnonKey = 'your-anon-key';
   ```

5. **Install Dependencies**
   ```bash
   flutter pub get
   ```

6. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── config/
│   ├── supabase_config.dart    # Supabase credentials
│   └── theme.dart              # App theme and colors
├── models/
│   ├── user_profile.dart       # User data model
│   ├── chat_room.dart          # Chat room model
│   └── message.dart            # Message model
├── services/
│   ├── auth_service.dart       # Authentication logic
│   ├── chat_service.dart       # Chat and messaging
│   └── user_service.dart       # User management
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── chat/
│   │   ├── chat_list_screen.dart
│   │   ├── chat_room_screen.dart
│   │   ├── new_chat_screen.dart
│   │   └── widgets/
│   │       ├── message_bubble.dart
│   │       └── message_input.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── edit_profile_screen.dart
└── main.dart
```

## Database Schema

The app uses the following Supabase tables:

- **profiles** - User profiles extending Supabase Auth
- **chat_rooms** - Chat room metadata
- **chat_room_participants** - Many-to-many relationship for room members
- **messages** - Chat messages with real-time enabled

All tables have Row Level Security (RLS) enabled for proper data isolation.

## Dependencies

- `supabase_flutter` - Supabase client for Flutter
- `provider` - State management
- `intl` - Date/time formatting
- `timeago` - Relative time display
- `cached_network_image` - Image caching
- `image_picker` - Profile photo selection

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).
