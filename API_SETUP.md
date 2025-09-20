# API Setup Instructions for PennApps 2025 Prize Features

## Auth0 Setup (Authentication) - REQUIRED ⚠️

### Step 1: Create Auth0 Account
1. Go to https://auth0.com/
2. Sign up for a free account
3. Create a new tenant (choose your region)

### Step 2: Create Application
1. In Auth0 dashboard, go to "Applications"
2. Click "Create Application"
3. Name: "Menu Optimizer Pro"
4. Type: "Native" (for mobile apps)
5. Click "Create"

### Step 3: Configure Application
1. In your application settings, add these URLs:

**Allowed Callback URLs:**
```
com.example.pennapps_2025://dev-mup2ksku6p7ra6tr.us.auth0.com/ios/com.example.pennapps_2025/callback
```

**Allowed Logout URLs:**
```
com.example.pennapps_2025://dev-mup2ksku6p7ra6tr.us.auth0.com/ios/com.example.pennapps_2025/logout
```

Replace `YOUR_AUTH0_DOMAIN` with your actual Auth0 domain (e.g., `dev-xxxxx.us.auth0.com`)

### Step 4: Get Credentials
1. Copy your **Domain** (e.g., `dev-xxxxx.us.auth0.com`)
2. Copy your **Client ID**

### Step 5: Update Your Code
Replace in `/lib/data/datasources/auth0_datasource.dart` lines 8-9:
```dart
static const String _domain = 'YOUR_AUTH0_DOMAIN'; // e.g., 'dev-xxxxx.us.auth0.com'
static const String _clientId = 'YOUR_AUTH0_CLIENT_ID'; // Your actual client ID
```

### Step 6: Enable Social Logins (Optional)
1. Go to "Authentication" → "Social"
2. Enable Google, GitHub, etc.
3. Configure with your app credentials

### Step 7: Platform Configuration (Already Done)
✅ Android: Manifest placeholders added to `build.gradle.kts`
✅ iOS: URL scheme added to `Info.plist`
✅ Auth0 handles callback URLs automatically

**You still need to:**
1. Replace `YOUR_AUTH0_DOMAIN` in `android/app/build.gradle.kts` line 33
2. Replace `YOUR_AUTH0_DOMAIN` and `YOUR_AUTH0_CLIENT_ID` in `auth0_datasource.dart`

## MongoDB Atlas Setup (Data Storage) - REQUIRED ⚠️

### Step 1: Create MongoDB Atlas Account
1. Go to https://cloud.mongodb.com/
2. Create a free account
3. Create a new cluster (M0 Sandbox - FREE)

### Step 2: Setup Database Access
1. **Database User**: In Atlas dashboard, go to "Database Access"
   - Click "Add New Database User"
   - Choose "Password" authentication
   - Username: `pennapps_user` (or your choice)
   - Password: Generate a secure password
   - Database User Privileges: "Read and write to any database"

2. **Network Access**: Go to "Network Access"
   - Click "Add IP Address"
   - Add `0.0.0.0/0` (allows access from anywhere - for hackathon only!)

### Step 3: Get Connection String
1. In Atlas dashboard, click "Connect" on your cluster
2. Choose "Connect your application"
3. Copy the connection string (looks like):
   ```
   mongodb+srv://pennapps_user:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```

### Step 4: Update Your Code
Replace in `/lib/data/datasources/mongodb_datasource.dart` line 11-12:
```dart
static const String _connectionString =
    'mongodb+srv://pennapps_user:YOUR_ACTUAL_PASSWORD@cluster0.xxxxx.mongodb.net/menu_optimizer?retryWrites=true&w=majority';
```

### Step 5: Database Collections (Auto-Created)
The app automatically creates these collections:
- `community_menus` - Shared menu data
- `users` - User authentication
- `user_sessions` - Optimization history
- `restaurants` - Restaurant metadata

## Gemini API Setup (Prize Feature)

1. **Get Gemini API Key**
   - Go to https://ai.google.dev/
   - Sign in with Google account
   - Go to "Get API Key"
   - Create a new API key

2. **Add API Key**
   - Replace in `/lib/data/datasources/gemini_vision_datasource.dart` line 11:
   ```dart
   static const String _apiKey = 'YOUR_ACTUAL_GEMINI_API_KEY';
   ```

## Prize Features Implemented

### MongoDB Atlas Prize Features ✅
- **Community Shared Database**: Users contribute processed menu data
- **User Authentication**: MongoDB-based user sessions
- **Analytics Dashboard**: Community insights and popular items
- **Smart Caching**: Check community database before processing
- **Real-time Sharing**: Menu data shared across all users

### Gemini AI Prize Features ✅
- **Vision OCR**: Camera-based menu scanning
- **AI Menu Analysis**: Superior text extraction from images
- **Smart Menu Conversation**: Ask questions about menus
- **Enhanced Descriptions**: AI-generated item descriptions
- **Fallback Parsing**: Robust error handling

## Testing the Features

1. **Test MongoDB Integration**:
   ```dart
   final mongoDataSource = MongoDBDataSource();
   await mongoDataSource.initialize();
   final userId = await mongoDataSource.authenticateUser(null);
   ```

2. **Test Gemini Vision**:
   ```dart
   final geminiDataSource = GeminiVisionDataSource();
   geminiDataSource.initialize();
   final items = await geminiDataSource.extractMenuFromFile('menu.jpg');
   ```

## Architecture Highlights

- **Clean Architecture**: Domain/Data/Presentation separation
- **Dependency Injection**: Provider-based service management
- **Repository Pattern**: Business logic abstraction
- **Community Intelligence**: Shared learning system

## Hackathon Demo Points

1. **Show Community Database**: Multiple users benefit from shared data
2. **Demo Camera OCR**: Live menu scanning with Gemini Vision
3. **Analytics Dashboard**: Community insights and popular items
4. **Performance**: Instant results from cached community data
5. **AI Integration**: Superior OCR vs traditional methods