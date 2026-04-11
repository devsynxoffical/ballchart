# BallChart - Complete Screen Documentation

## Overview
BallChart is a comprehensive basketball academy management system built with Flutter. The application features role-based navigation, real-time data synchronization, and a modern dark-themed UI with golden accents.

## Architecture & Navigation
- **Role-Based Navigation**: Different user experiences for Admin, Coach, Player, and Staff roles
- **Main Navigator**: `AppNavigator` handles role-specific screen routing
- **Authentication Flow**: Centralized login/registration with profile completion
- **Real-Time Updates**: Live data synchronization across all screens

---

## 🎯 Authentication Screens

### 1. Splash Screen (`SplashScreen`)
**Location**: `lib/features/splash/view/splash_screen.dart`
**Purpose**: App initialization and authentication routing
**Key Features**:
- 3-second branded loading experience
- Automatic session validation
- Role-based navigation routing
- Background image with gradient overlay
**Functions**:
- `_checkAuth()` - Validates user session and routes accordingly
- Routes to: Academy Dashboard (admin), Main App (completed profiles), Profile Completion, or Login

### 2. Login Screen (`LoginScreen`)
**Location**: `lib/features/login/view/login_screen.dart`
**Purpose**: User authentication with role-specific access
**Key Features**:
- Email/password authentication
- Social login integration (Google, Apple)
- Forgot password functionality
- Role-based login context
**Functions**:
- Email validation and authentication
- Password visibility toggle
- Navigation to registration
- Social login placeholders

### 3. Registration Screen (`AuthScreen`)
**Location**: `lib/features/auth/view/auth_screen.dart`
**Purpose**: Academy administrator registration
**Key Features**:
- Admin account creation
- Academy name registration
- Form validation with real-time feedback
- Professional branding
**Functions**:
- Form validation (email, password strength)
- Academy registration with admin account
- Navigation to login after success

### 4. Registration Success Screen (`RegistrationSuccessScreen`)
**Location**: `lib/features/auth/view/registration_success_screen.dart`
**Purpose**: Confirmation and onboarding after successful registration
**Key Features**:
- Success confirmation with statistics
- Academy status display
- Navigation to dashboard
**Functions**:
- Display registration success
- Show initial academy stats
- Route to login screen

### 5. Profile Completion - Coach (`CompleteProfileScreenCoach`)
**Location**: `lib/features/auth/completeyourprofile/coach/view/profile_coach_screen.dart`
**Purpose**: Coach-specific profile setup
**Key Features**:
- Experience level selection
- Sports categories selection
- Achievement selection
- Custom achievement input
**Functions**:
- Experience level dropdown (1-3, 4-7, 8+ years)
- Multi-select sports categories
- Achievement toggles
- Custom text input for additional achievements

### 6. Profile Completion - Player (`CompleteProfilePlayerScreen`)
**Location**: `lib/features/auth/completeyourprofile/player/view/profile_player_screen.dart`
**Purpose**: Player-specific profile setup
**Key Features**:
- Position selection
- Age range selection
- Experience level selector
- Goals selection
**Functions**:
- Position dropdown (Forward, Guard, Mid-fielder)
- Age range selection (10-15, 15-20, 20+)
- Interactive experience selector
- Multi-select goals with custom input

### 7. Forgot Password - Email (`EnterEmailScreen`)
**Location**: `lib/features/auth/forgotpassword/view/enter_email_screen.dart`
**Purpose**: Password reset initiation
**Key Features**:
- Email input for password reset
- Professional design with security focus
**Functions**:
- Email validation
- Send reset link functionality
- Navigation to OTP screen

### 8. Forgot Password - OTP (`EnterOtpScreen`)
**Location**: `lib/features/auth/forgotpassword/view/enter_OTP_screen.dart`
**Purpose**: OTP verification for password reset
**Key Features**:
- 6-digit OTP input
- Resend code functionality
**Functions**:
- OTP verification
- Code resend capability
- Navigation to new password screen

---

## 🏢 Admin/Management Screens

### 1. Academy Dashboard (`AcademyDashboardScreen`)
**Location**: `lib/features/management/view/academy_dashboard_screen.dart`
**Purpose**: Main admin control center with comprehensive academy overview
**Key Features**:
- Real-time academy statistics
- Team management carousel
- Top performer highlights
- Tactical action buttons
- Multi-tab navigation (Dashboard, Teams, Staff, Profile)
**Functions**:
- `_loadDataWithRetry()` - Robust data loading with retry logic
- `_showCreateTeamDialog()` - Team creation workflow
- `_showInviteStaffDialog()` - Staff invitation workflow
- Real-time data synchronization with error handling
- Performance metrics display

### 2. Management Screen (`ManagementScreen`)
**Location**: `lib/features/management/view/management_screen.dart`
**Purpose**: Simplified management interface for basic operations
**Key Features**:
- Quick action cards for teams and staff
- Direct creation dialogs
- Clean, focused interface
**Functions**:
- `_showCreateTeam()` - Launch team creation dialog
- `_showCreateStaff()` - Launch staff creation dialog
- Management card navigation

---

## 👨‍🏫 Coach Screens

### 1. Coach Home Screen (`CoachHomeScreen`)
**Location**: `lib/features/coach/home/view/coach_home_screen.dart`
**Purpose**: Coach's main navigation hub
**Key Features**:
- Personalized header with user info
- Role-based navigation tabs
- Status indicators
- Team management integration
**Functions**:
- `_buildEnhancedHeader()` - Dynamic user header
- Tab navigation (Teams, Battle, Strategy, Profile)
- Real-time profile integration

---

## 👤 Player Screens

### 1. Player Home Screen (`PlayerHomeScreen`)
**Location**: `lib/features/player/view/player_home_screen.dart`
**Purpose**: Player's main navigation hub
**Key Features**:
- Personalized player header
- Performance-focused navigation
- Stats integration
- Battle and strategy access
**Functions**:
- `_buildEnhancedHeader()` - Player-specific header
- Tab navigation (Stats, Battle, Strategy, Profile)
- Performance metrics display

---

## 🎮 Battle/Game Screens

### 1. Battle Screen (`BattleScreen`)
**Location**: `lib/features/battle/view/battle_screen.dart`
**Purpose**: Game management and live battle tracking
**Key Features**:
- Live battle scoring display
- Battle repository with scheduling
- Strategic profiles and scouting
- Real-time updates
**Functions**:
- `_loadDataWithRetry()` - Battle data loading
- `_showCreateBattleDialog()` - Battle scheduling
- Live score updates
- Team analysis and scouting intelligence
- Battle history tracking

---

## 🧠 Strategy Screens

### 1. Enhanced Strategy Screen (`EnhancedStrategyScreen`)
**Location**: `lib/features/strategy/view/enhanced_strategy_screen.dart`
**Purpose**: Tactical strategy management and video playbook
**Key Features**:
- Video strategy library
- Grid/List/Analytics view modes
- Category filtering and search
- Video player integration
- Like and view tracking
**Functions**:
- `_loadDataWithRetry()` - Strategy data loading
- `_showCreateStrategyDialog()` - Strategy creation
- Video playback with controls
- Analytics dashboard
- Permission-based access control

---

## 👤 Profile & Settings

### 1. Profile Screen (`ProfileScreen`)
**Location**: `lib/features/profile/view/profile_screen.dart`
**Purpose**: User profile management and settings
**Key Features**:
- Identity display with avatar
- Academy partnership information
- Bento grid for user stats
- System settings and logout
**Functions**:
- `_buildIdentityHeader()` - User identity display
- `_buildAcademyPartnership()` - Academy info management
- `_showEditAcademyDialog()` - Academy editing
- Profile refresh and logout

---

## 👥 Staff Management

### 1. Staff List Screen (`StaffListScreen`)
**Location**: `lib/features/staff/view/staff_list_screen.dart`
**Purpose**: Comprehensive staff management and permissions
**Key Features**:
- Hierarchical staff tree view
- Staff detail editing
- Live permission management
- Active profiles carousel
**Functions**:
- `_buildHierarchyTree()` - Organizational chart
- `_buildStaffDetailCard()` - Staff member editing
- `_buildPermissionsCard()` - Permission management
- Real-time permission updates
- Staff creation and onboarding

---

## 🧭 Navigation Architecture

### App Navigator (`AppNavigator`)
**Location**: `lib/features/AppNavigator/app_navigator.dart`
**Purpose**: Central navigation controller with role-based routing
**Key Features**:
- Dynamic screen building based on user role
- Profile-driven role resolution
- Memoized screen optimization
- Exit dialog handling
**Functions**:
- `_buildScreens()` - Role-specific screen assembly
- Profile-based role updating
- Navigation state management

### Role-Based Screen Access:
- **Admin**: Academy Dashboard → Management → Teams/Staff → Battle → Strategy → Profile
- **Coach**: Coach Home → Teams → Battle → Strategy → Profile  
- **Player**: Player Home → Stats → Battle → Strategy → Profile
- **Staff**: Limited access based on permissions

---

## 🎨 Design System

### Color Palette:
- **Primary**: `#FFD900` (Golden Yellow)
- **Background**: `#131313` (Dark)
- **Surface High**: `#2A2A2A` (Elevated surfaces)
- **Surface Container**: `#201F1F` (Card backgrounds)
- **Outline**: `#9D8F79` (Borders and accents)

### Typography:
- **Space Grotesk** font family for headings
- **Font Weights**: 300, 500, 700, 900
- **Letter Spacing**: Emphasis on military/technical aesthetic

### UI Patterns:
- **Bento Grid Layouts**: Information density with visual hierarchy
- **Gradient Overlays**: Depth and visual interest
- **Status Indicators**: Live data visualization
- **Permission Wrappers**: Role-based UI elements

---

## 🔄 Data Flow & State Management

### Provider Architecture:
- **AuthViewmodel**: Authentication state
- **ProfileViewmodel**: User profile data
- **AcademyProvider**: Academy management data
- **BattleViewmodel**: Battle/game data
- **StrategyViewmodel**: Strategy content

### Real-Time Features:
- Live battle score updates
- Real-time permission changes
- Profile synchronization
- Error handling with retry logic

### Error Handling:
- Graceful degradation
- User-friendly error messages
- Retry mechanisms
- Loading states

---

## 📱 Responsive Design

### Mobile-First Approach:
- Optimized for mobile devices
- Touch-friendly interactions
- Adaptive layouts
- Gesture support

### Accessibility:
- Semantic labeling
- High contrast ratios
- Focus management
- Screen reader support

---

## 🔐 Security Features

### Authentication:
- JWT token management
- Session validation
- Secure password handling
- Role-based access control

### Data Protection:
- Permission-based UI rendering
- Secure API communication
- Input validation and sanitization

---

## 🚀 Performance Optimizations

### Memory Management:
- Screen memoization
- Efficient state management
- Image caching
- Lazy loading

### Network Optimization:
- Retry mechanisms
- Error boundary handling
- Efficient data fetching
- Offline support considerations

---

## 📊 Analytics & Tracking

### User Engagement:
- Screen view tracking
- Feature usage metrics
- Performance monitoring
- Error tracking

### Business Intelligence:
- Academy growth metrics
- User activity patterns
- Content engagement
- Retention analytics

---

## 🔮 Future Enhancements

### Planned Features:
- Advanced analytics dashboard
- Video analysis tools
- Performance tracking
- Communication system
- Mobile app extensions

### Technical Improvements:
- Enhanced offline capabilities
- Advanced security features
- Performance optimizations
- UI/UX refinements

---

## 📝 Development Notes

### Code Organization:
- Feature-based folder structure
- Separation of concerns
- Reusable widget components
- Consistent naming conventions

### Best Practices:
- Error handling patterns
- State management principles
- Testing strategies
- Documentation standards

---

This documentation provides a comprehensive overview of all screens and their functions within the BallChart application. Each screen is designed with specific user roles in mind, featuring modern UI patterns and robust functionality for basketball academy management.
