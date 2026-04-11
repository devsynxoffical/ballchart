# HoopStar Backend Implementation Plan

This document maps frontend behavior to backend requirements so API work can start immediately.

Scope in this version:
- Auth: `Login`, `Signup`, `Logout`, profile-completion dependency
- Home + Profile screens for:
  - `coach`
  - `assistant_coach`
  - `player`
- Role/permission handling required for these flows

Out of scope for this version:
- Full admin 4-screen deep API breakdown (home/teams/staff/profile) - planned next document version
- Full battle/strategy authoring contracts

---

## 1) Current Frontend Function Inventory

### 1.1 Auth / Session

From frontend:
- `AuthRepository.login()` tries endpoints in order:
  - `/auth/admin/login`
  - `/auth/coach/login`
  - `/auth/player/login`
- On success, token is stored and `/auth/profile` is fetched for hydrated session
- `AuthRepository.signup()` routes by role:
  - admin -> `/auth/admin/signup`
  - coach/head/assistant -> `/auth/coach/signup`
  - player -> `/auth/player/signup`
- `AuthViewmodel.login()` routes user:
  - admin -> academy dashboard
  - non-admin + profile completed -> main app
  - non-admin + profile incomplete -> complete-profile flow
- `AuthViewmodel.logout()` clears token and returns to login

### 1.2 Home Screens

#### Coach + Assistant Coach Home
Main data loader:
- `AcademyProvider.loadCoachDashboard()` -> `GET /auth/dashboard/coach`

Used by screens:
- `CoachHomeScreen` (tabs)
- `TeamsTab` consumes:
  - assigned teams list
  - team leads info
  - staff context
  - team/player details

#### Player Home
Main data loader:
- `AcademyProvider.loadPlayerDashboard()` -> `GET /auth/dashboard/player`

Used by screens:
- `PlayerStatsTab`
- `HomeScreen`-style widgets (stats/team/staff/teammates)
- profile detail blocks fallback to this payload

### 1.3 Profile Screens

Shared profile loader:
- `ProfileRepository.getUserProfile()` -> `GET /auth/profile`

Shared profile updater:
- `ProfileRepository.completeProfile(profileData)` -> `PUT /auth/profile`

Profile usage by role:
- coach/assistant:
  - edit experience/sports/achievements/additionalInfo
- player:
  - profile tab opens `PlayerDetailScreen` (editable for self only)
  - editable biometrics + credentials + picture + notes
  - quick field updates (height/weight/wingspan)
- admin:
  - academy-focused profile cards
  - owner name/email/experience/profile image

---

## 2) Role and Permission Model (Required Backend Source of Truth)

Roles currently used:
- `admin`
- `head_coach`
- `coach`
- `assistant_coach`
- `player`

Permission keys currently used in app:
- `createPlayer`, `readPlayer`, `updatePlayer`, `deletePlayer`
- `createTeam`, `manageStaff`
- `createBattle`, `manageBattle`
- `createStrategy`, `manageStrategy`

Minimum backend requirement:
- include role and effective permission map in auth/profile payload
- enforce permissions server-side (never trust client toggles)

---

## 3) API Contracts Needed (Auth + 6 Screen Scope)

## 3.1 Auth APIs

### POST `/auth/admin/signup`
Body:
```json
{
  "username": "Admin Name",
  "email": "admin@academy.com",
  "password": "secret123",
  "academyName": "Elite Academy"
}
```
Response:
```json
{
  "_id": "userId",
  "username": "Admin Name",
  "email": "admin@academy.com",
  "role": "admin",
  "token": "jwt",
  "profileCompleted": true
}
```

### POST `/auth/coach/signup`
Used for `coach`, `assistant_coach`, `head_coach` creation path.
Body minimum:
```json
{
  "username": "Coach Name",
  "email": "coach@academy.com",
  "password": "secret123"
}
```

### POST `/auth/player/signup`
Body minimum:
```json
{
  "username": "Player Name",
  "email": "player@academy.com",
  "password": "secret123"
}
```

### POST login endpoints
- `/auth/admin/login`
- `/auth/coach/login`
- `/auth/player/login`

Common body:
```json
{ "email": "x@y.com", "password": "secret123" }
```

Common response:
```json
{
  "_id": "userId",
  "username": "Name",
  "email": "x@y.com",
  "role": "coach",
  "token": "jwt",
  "profileCompleted": true
}
```

### GET `/auth/profile`
Must return role-specific profile fields:
```json
{
  "_id": "userId",
  "username": "Name",
  "email": "x@y.com",
  "role": "coach",
  "profileCompleted": true,
  "academy": { "_id": "academyId", "academyName": "Elite Academy" },
  "permissions": {
    "createPlayer": true,
    "readPlayer": true
  },
  "experienceLevel": "Advanced",
  "sports": ["Basketball"],
  "achievements": ["State title"],
  "additionalInfo": "..."
}
```

### PUT `/auth/profile`
Single endpoint for role-aware self updates.

Supported keys by role:
- admin: `username`, `email`, `experienceLevel`, `profileImageUrl`
- coach/assistant/head: `username`, `email`, `experienceLevel`, `sports`, `achievements`, `additionalInfo`, `profileImageUrl`
- player: `height`, `weight`, `wingspan`, `position`, `jerseyNumber`, `classYear`, `scoutingNotes`, `profileImageUrl`, `email`, `password`

Backend must:
- validate per-role allowed fields
- hash password if provided
- reject forbidden fields with clear message

---

## 3.2 Home APIs

### GET `/auth/dashboard/coach`
For `coach`, `assistant_coach`, `head_coach` role.

Response contract:
```json
{
  "coach": {
    "_id": "coachId",
    "username": "Coach Name",
    "role": "assistant_coach"
  },
  "teams": [
    {
      "_id": "teamId",
      "name": "U19 Elite",
      "ageGroup": "U19",
      "colorValue": 4294961415,
      "coachStaffId": "staffA",
      "assistantCoachStaffId": "staffB",
      "players": [
        {
          "_id": "playerId",
          "username": "Player Name",
          "email": "player@x.com",
          "position": "PG",
          "height": "182 cm",
          "weight": "77 kg",
          "wingspan": "189 cm",
          "classYear": "2026",
          "tempPassword": "******",
          "profileImageUrl": "https://..."
        }
      ]
    }
  ],
  "upcomingBattles": [],
  "strategySummary": {}
}
```

Rules:
- coach sees assigned teams
- assistant_coach sees assigned teams
- head_coach may see all academy teams (configurable)

### GET `/auth/dashboard/player`
For player home + player detail.

Response contract:
```json
{
  "player": {
    "_id": "playerId",
    "username": "Player Name",
    "email": "player@x.com",
    "position": "PG",
    "ageRange": "18",
    "height": "182 cm",
    "weight": "77 kg",
    "wingspan": "189 cm",
    "jerseyNumber": "12",
    "classYear": "2026",
    "scoutingNotes": "High IQ guard",
    "profileImageUrl": "https://...",
    "stats": {
      "matchesPlayed": 12,
      "wins": 8,
      "points": 214,
      "ppg": 17.8,
      "apg": 4.9,
      "rpg": 6.1
    },
    "battleStats": {
      "totalBattles": 12,
      "wins": 8,
      "totalPoints": 214,
      "recentBattles": []
    }
  },
  "team": {
    "_id": "teamId",
    "name": "U19 Elite",
    "category": "Elite",
    "division": "North",
    "memberCount": 12
  },
  "coachingStaff": [],
  "teammates": []
}
```

---

## 4) Function-by-Function Backend Mapping (Requested Core)

## 4.1 Login Screen Functions

Frontend behavior -> Backend requirement:
- submit email/password -> login endpoint must return role + token
- invalid credentials -> human-friendly message (`Invalid ... credentials`)
- on success -> `/auth/profile` must succeed for session hydration
- back press -> no backend requirement

## 4.2 Signup Screen Functions

- admin registration requires `academyName`
- email/password validation done on client; backend must revalidate
- duplicate email and weak password errors must be explicit

## 4.3 Coach Home Functions (includes assistant coach)

- initial load: `GET /auth/dashboard/coach`
- retry behavior: same endpoint idempotent
- team card open: must include enough team detail for team view
- assistant coach role behavior: filtered by assignment + permission restrictions

## 4.4 Assistant Coach Home Functions

Same endpoint as coach, but backend role guard:
- read access yes
- write operations in team/profile APIs controlled by permission map

## 4.5 Player Home Functions

- initial load: `GET /auth/dashboard/player`
- periodic refresh support (safe + performant)
- return complete aggregates for widgets (stats/team/staff/teammates)

## 4.6 Coach Profile Functions

- read self: `GET /auth/profile`
- update self: `PUT /auth/profile`
  - `experienceLevel`
  - `sports[]`
  - `achievements[]`
  - `additionalInfo`
  - `profileImageUrl`
  - optional `username`, `email`

## 4.7 Assistant Coach Profile Functions

Same endpoint as coach, but backend may restrict fields by policy.

## 4.8 Player Profile Functions (detailed profile page)

Must support:
- read current full profile + stats via dashboard/profile endpoints
- update single fields quickly:
  - `height`, `weight`, `wingspan`
- update full details:
  - `position`, `jerseyNumber`, `classYear`, `scoutingNotes`, `profileImageUrl`, `email`, `password`

Security requirements:
- player can only update own record
- coach viewing player profile is read-only from backend perspective unless permission allows dedicated staff endpoint

---

## 5) Validation, Errors, and Response Standards

For every endpoint:
- return JSON always
- error shape:
```json
{
  "message": "Human readable error",
  "code": "OPTIONAL_MACHINE_CODE"
}
```

Status conventions:
- `200/201` success
- `400` validation
- `401` unauthenticated
- `403` unauthorized (role/permission)
- `404` missing resource
- `409` email conflict
- `500` server error

---

## 6) Suggested DB Model Additions / Checks

Minimum entities:
- `User`
  - role, academy, managedBy, permissions, profileCompleted
  - coach fields: experience/sports/achievements/additionalInfo
  - player fields: biometric + basketball fields
- `Academy`
- `Team`
- `Battle`

Critical indexes:
- users by `email` unique
- teams by `academyId`
- team assignments by `staffId` and `playerId`

---

## 7) Implementation Order (Practical)

1. Auth foundation
   - signup/login/profile
   - JWT middleware
2. Role guard + permission middleware
3. Dashboard endpoints
   - `/auth/dashboard/coach`
   - `/auth/dashboard/player`
4. Profile update endpoint hardening
   - field allowlist by role
   - password hashing path
5. Response standardization + error contracts
6. Integration tests for 3 roles (`coach`, `assistant_coach`, `player`)

---

## 8) Test Checklist (Must Pass Before Frontend Integration)

Auth:
- admin signup/login
- coach login
- assistant coach login (via coach login endpoint)
- player login

Home:
- coach dashboard returns assigned teams
- assistant dashboard respects assignment + permissions
- player dashboard returns profile + team + staff + teammates

Profile:
- coach can update coach fields
- assistant can update allowed fields
- player can update biometrics and credentials
- unauthorized field update returns `403` or `400` with clear message

---

## 9) Next Document Version (after this scope)

Planned extension:
- Admin 4-screen full backend map:
  - Dashboard
  - Teams (including team detail deep view)
  - Staff (including permission toggle lifecycle)
  - Admin Profile (academy management)
- Battle and Strategy full contracts with command/event model

