# BallChart Feature Usage Guide (Video Script Base)

This document explains each major BallChart feature in practical, user-focused steps so you can record a detailed walkthrough video for every module.

---

## 1) Roles and Access

BallChart has three main role experiences:

- `Admin` (academy owner/manager)
- `Coach` / `Head Coach` / `Assistant Coach`
- `Player`

### How role routing works

After login, BallChart routes users automatically:

- Admin -> Academy Dashboard
- Coach roles -> Coach Home shell
- Player -> Player Home shell

If profile setup is incomplete, users are first sent to profile completion screens.

---

## 2) App Entry and Authentication

### 2.1 Splash and Session Restore

What to show in video:

1. Launch app
2. Show splash screen
3. Explain auto-session check:
   - Existing valid session -> auto-login
   - No session -> login screen

### 2.2 Registration (Academy/Admin)

Steps:

1. Open `Register Your Academy`
2. Fill required fields
3. Submit registration
4. Show success screen and onboarding guidance

Key points:

- Validation happens before submit
- Common errors are shown in clear dialogs/snackbars

### 2.3 Login

Steps:

1. Enter email/password
2. Tap sign-in
3. App routes by role

### 2.4 Forgot Password

Flow:

1. Enter email
2. OTP/verification step
3. New password
4. Success confirmation

---

## 3) Global Navigation and Back Behavior

### Expected back behavior (important for demo)

- From deeper pages -> go back to previous page
- From root tabs:
  - If user is not on first tab, back returns to first tab
  - If user is already on first tab, app shows **Exit App** popup

### iPhone gesture behavior

- Left-edge swipe/back gesture follows the same logic above

---

## 4) Admin Features

## 4.1 Academy Dashboard

Purpose:

- Central management for teams, staff, and academy operations

Typical flow:

1. Open dashboard
2. Review academy summary/cards
3. Navigate by tabs and action cards

### 4.2 Team Management

Includes:

- Create team
- Edit team details
- Team lead assignment
- Add/remove players

Demo steps:

1. Create team
2. Open team detail
3. Assign head/assistant lead
4. Add players

### 4.3 Staff Management

Includes:

- Create staff members
- Assign permissions
- Update roles/capabilities

### 4.4 Academy Profile Management

Includes:

- Edit academy details
- Update logo/photo

---

## 5) Coach Features

## 5.1 Coach Home

Main coach shell:

- Teams
- Battle/Games
- Strategy
- Profile

### 5.2 Teams Tab

Coach can:

- View assigned teams
- Open team details
- Start training assignment workflows

### 5.3 Team Details

Shows:

- Team identity
- Roster
- Coaching assignments
- Team activity context

---

## 6) Player Features

## 6.1 Player Home

Main player shell:

- Stats/overview
- Games
- Strategy
- Profile

### 6.2 Player Profile

Includes:

- Personal details
- Performance summaries
- Editable profile fields

---

## 7) Messaging Features

## 7.1 Conversations List

User can:

- View direct conversations
- View team group chats (if available for roster/team)
- See unread badges

### 7.2 Start New Chat

Steps:

1. Tap new-message action
2. Select contact
3. Open conversation

### 7.3 Chat Screen Features

Supported message types:

- Text
- Voice note
- File/PDF

Additional features:

- Reply-to message
- Read receipts
- Participant profile access

### 7.4 Team Group Chat

If team conversations are enabled by backend:

- Group threads appear in conversations list
- Messages notify team participants

---

## 8) Player Development Features

## 8.1 Coach Training Assignment

Coach can:

- Select player
- Select development area/drill
- Set schedule/points/notes
- Assign training

### 8.2 Monthly Performance Report (Coach)

Coach workflow:

1. Open monthly report screen
2. Select player + month/year
3. Edit ratings/insights/goals in editor
4. Save report
5. Generate/share PDF
6. Publish/send to player chat

### 8.3 Player Development (Player View)

Player can:

- View assigned training
- Mark assignments complete
- View points/progress
- View coach report when published
- Manage personal goals

---

## 9) Strategy Features

## 9.1 Strategy Library

Coach/player can browse strategy content.

Coach capabilities include:

- Create strategy
- Edit/update metadata
- Open strategy detail

### 9.2 Strategy Detail

Includes:

- Diagram/tactical breakdown
- Notes/content
- Optional voice clips
- Share/export actions

---

## 10) Tactical Lab and Voice Commands

## 10.1 Tactical Lab Core

Purpose:

- Build and animate tactical sequences
- Use typed or voice command input

### 10.2 Voice Command Workflow

Steps:

1. Tap mic
2. (First use) download local Whisper model
3. Speak command
4. Stop recording
5. Convert speech -> text
6. Parse command into tactical steps
7. Run animation

Key UX states to mention:

- Recording in progress
- Converting speech to text
- Success/failure hint messages

### 10.3 Save Tactic

Coach can save tactic/sequence as strategy content for reuse.

---

## 11) Battle/Games Features

## 11.1 Battle List and Status

Game statuses supported:

- Scheduled/pending
- Live/in-progress
- Finished

### 11.2 Create/Edit Battle

Includes:

- Game title
- Date/time
- Location
- Format/settings

### 11.3 Battle Hub

Provides:

- Quick game details
- Related actions
- Tactical lab shortcuts

---

## 12) Profile, Security, and Account Actions

Across roles:

- Edit profile
- Change password
- Logout
- Delete account flow (if allowed)

---

## 13) Feature Dependencies and Requirements

Use this section in videos to set expectations.

## 13.1 Internet-dependent features

- Login/auth APIs
- Messaging sync
- Team/player/staff management
- Report save/fetch/PDF APIs

## 13.2 Device permissions

- Microphone (voice commands, voice notes)
- Camera/photos (profile/team/player media)

## 13.3 One-time model download

- Tactical voice transcription may need initial local model download before first use.

---

## 14) Common Error Cases (and What to Say in Videos)

## 14.1 Authentication/session

- Invalid credentials
- Expired session token

## 14.2 Messaging

- Network interruption
- Conversation not found or stale conversation state

## 14.3 Reports

- Report not saved yet (PDF unavailable)
- Timeout/network errors during save

## 14.4 Tactical voice

- Permission denied
- Model download interrupted
- No speech detected

---

## 15) Suggested Video Recording Order

To make a clean training series, record in this sequence:

1. App overview + roles
2. Auth (signup/login/forgot)
3. Admin dashboard + team/staff management
4. Coach home + teams + assignments
5. Player home + development tracking
6. Messaging (DM + team group)
7. Reports (edit, save, PDF, publish to chat)
8. Strategy module
9. Tactical lab + voice workflow
10. Battle/games workflows
11. Profile/security settings

---

## 16) Short Role-Based Demo Checklists

## Admin checklist

- Login as admin
- Create team
- Add/assign staff
- Open team detail
- Add players
- Verify notifications/messages access

## Coach checklist

- Login as coach
- Open assigned teams
- Assign training
- Fill monthly report
- Send report in chat
- Use tactical lab voice command

## Player checklist

- Login as player
- View assignments
- Mark complete
- Open coach feedback report
- Open strategy/battle tabs
- Reply in messages

---

## 17) Notes for Production Support Videos

- Always mention role constraints (some buttons are permission-based)
- Mention when a feature is backend-dependent
- Show both success and failure examples for critical workflows:
  - report save
  - voice command parse
  - file/message send

---

If you want, next I can create:

1. `Video Script Version` (voice-over lines per screen), and  
2. `Shot List Version` (exact taps + expected output for screen recording).
