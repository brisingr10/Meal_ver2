# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application called "Meal_ver2" - a Bible reading app that provides daily scripture verses with note-taking functionality. The app is built with Flutter SDK 3.5.1+ and integrates with Firebase for backend services.

## Development Commands

### Flutter Commands
```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Build for Android
flutter build apk
flutter build appbundle

# Build for iOS
flutter build ios

# Build for Web
flutter build web

# Run tests
flutter test

# Analyze code
flutter analyze

# Generate JSON serialization code
flutter pub run build_runner build --delete-conflicting-outputs

# Generate native splash screens
flutter pub run flutter_native_splash:create
```

### Code Generation
The project uses `json_serializable` for JSON serialization. Run the build_runner when modifying models with `@JsonSerializable`:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture

### Directory Structure
- **lib/** - Main application code
  - **model/** - Data models (PlanData, Verse, Bible with JSON serialization)
  - **view/** - UI screens (MainView, SelectBibleView, OptionView)
  - **viewmodel/** - ViewModels using Provider pattern (MainViewModel, CustomThemeMode)
  - **network/** - API and Firebase integration (FirebaseFunction, MealApi, Plan)
  - **util/** - Utilities (CustomTheme, Globals, PreferenceUtil)

- **bib_json/** - Bible translation JSON files (개역개정, 새번역, 공동번역, NASB, NIV, ESV, ISV)
- **font/** - Custom fonts (LINESeed, MaruBuri, Pretendard, RIDIBatang)
- **성경구절 전처리/** - Python scripts for Bible verse data preprocessing

### Key Technologies
- **State Management**: Provider pattern with ChangeNotifier
- **Backend**: Firebase (Auth, Firestore, Analytics, Storage)
- **Persistence**: SharedPreferences for local storage
- **Internationalization**: flutter_localizations (Korean/English support)
- **Navigation**: MaterialApp with custom theming
- **HTTP**: http package for API calls

### Core Components

1. **MainViewModel** - Central state management
   - Manages Bible data loading
   - Handles date selection and navigation
   - Controls theme mode (light/dark)
   - Manages font size and spacing preferences
   - Integrates with Firebase functions

2. **Bible Data Models**
   - Uses `json_annotation` and `json_serializable` for parsing
   - Bible model with generated `.g.dart` files
   - Plan model for daily reading plans
   - Verse model for scripture text

3. **Firebase Integration**
   - Anonymous authentication
   - Firestore for data storage
   - Firebase Analytics for tracking
   - Configured via `firebase_options.dart`

### Platform-Specific Configurations
- **Android**: Configured with Firebase (`google-services.json`), custom splash screens
- **iOS**: Configured with AppDelegate.swift, custom app icons
- **Web**: PWA support with manifest.json

## Important Notes

- The app uses custom fonts defined in pubspec.yaml (Mealfont, Settingfont, Biblefont)
- Native splash screen is configured via `flutter_native_splash.yaml`
- Theme supports both light and dark modes via CustomThemeData
- Text scaling is disabled to maintain consistent UI (`textScaleFactor: 1.0`)
- Korean locale is the primary language with date formatting support

## Bible Notes Feature

### Overview
The app includes a comprehensive note-taking system that allows users to create notes linked to specific Bible verses and dates.

### Key Components

1. **Note Data Model** (`lib/model/Note.dart`)
   - Stores notes with title, content, date, and linked verses
   - VerseReference class for verse identification
   - Color coding support for categorization

2. **Selection Mode in MainView**
   - Long press any verse to enter selection mode
   - Checkboxes appear for multi-verse selection
   - "노트 만들기" floating button appears when verses are selected
   - Exit selection mode with X button or back gesture

3. **Note Editor** (`lib/view/NoteEditorView.dart`)
   - Create/edit notes with title and content
   - Shows selected verses at the top
   - Color picker for note categorization
   - Auto-saves to SharedPreferences

4. **Notes List** (`lib/view/NotesListView.dart`)
   - View all notes for current date
   - Date navigation (swipe or arrow buttons)
   - Edit/delete notes with swipe or menu
   - Empty state with instructions

5. **MainViewModel Updates**
   - Notes stored in Map<String, List<Note>> by date
   - Full CRUD operations (addNote, updateNote, deleteNote, getNotesForDate)
   - Persistence using SharedPreferences
   - hasNoteForVerse() checks for note indicators

### User Flow
1. View daily verses → Long press any verse
2. Selection mode activated → Select multiple verses with checkboxes
3. Tap "노트 만들기" → Write note in editor
4. Save → Returns to MainView with note indicators
5. Tap notes icon in header → View all notes for that date

### Testing Notes Feature
```bash
# After Flutter installation
flutter pub get
flutter run

# Test workflow:
# 1. Long press a verse to enter selection mode
# 2. Select multiple verses
# 3. Tap "노트 만들기" button
# 4. Create and save a note
# 5. Check note indicator appears on verses
# 6. Access notes list from header icon
```