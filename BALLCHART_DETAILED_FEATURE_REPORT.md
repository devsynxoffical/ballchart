# BallChart — Detailed Feature Report

**Document type:** End-to-end feature reference  
**Audience:** Academy admins, coaches, players, trainers, and support staff  
**Purpose:** Explain every major BallChart feature with full procedures, role access, expected results, and operational notes  

This report is intentionally detailed. Use it as a training manual, onboarding handbook, or video-script source.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Roles, Permissions & Access Model](#2-roles-permissions--access-model)
3. [App Launch, Splash & Session Restore](#3-app-launch-splash--session-restore)
4. [Authentication & Account Security](#4-authentication--account-security)
5. [Profile Completion (First Login)](#5-profile-completion-first-login)
6. [Global Navigation & Exit Behavior](#6-global-navigation--exit-behavior)
7. [Admin — Academy Dashboard](#7-admin--academy-dashboard)
8. [Admin — Team Management](#8-admin--team-management)
9. [Admin — Staff Management](#9-admin--staff-management)
10. [Admin — Player Enrollment](#10-admin--player-enrollment)
11. [Coach — Home & Teams](#11-coach--home--teams)
12. [Team Detail & Hierarchy](#12-team-detail--hierarchy)
13. [Player — Home & Stats](#13-player--home--stats)
14. [Player Detail / Athlete Dossier](#14-player-detail--athlete-dossier)
15. [Games / Battles Module](#15-games--battles-module)
16. [Battle Hub](#16-battle-hub)
17. [Strategy / Playbook Module](#17-strategy--playbook-module)
18. [Strategy Detail](#18-strategy-detail)
19. [Strategy KPIs](#19-strategy-kpis)
20. [Tactical Lab](#20-tactical-lab)
21. [Player Development — Assign Training](#21-player-development--assign-training)
22. [Player Development — My Development](#22-player-development--my-development)
23. [Coach Monthly / Period Reports](#23-coach-monthly--period-reports)
24. [PDF Reports & In-App Viewer](#24-pdf-reports--in-app-viewer)
25. [Messaging & Conversations](#25-messaging--conversations)
26. [Chat Screen (Text, Voice, Files)](#26-chat-screen-text-voice-files)
27. [Notifications](#27-notifications)
28. [Profile, Password, Logout & Delete Account](#28-profile-password-logout--delete-account)
29. [Device Permissions & Dependencies](#29-device-permissions--dependencies)
30. [Troubleshooting Playbook](#30-troubleshooting-playbook)
31. [Academy Setup Checklist](#31-academy-setup-checklist)

---

## 1. Product Overview

### What BallChart is

BallChart is a basketball academy operations platform. It connects academy management, coaching staff, and players in one app so an academy can:

- Create and manage **teams (squads)**, **staff**, and **players**
- Schedule and track **games (battles)**
- Build and share **strategies / playbooks**
- Design animated tactics in **Tactical Lab** (typed or voice commands)
- Assign **training**, track completion, and issue **performance reports**
- Communicate through **direct messages**, **team group chats**, **voice notes**, and **PDF report delivery**

### Who uses it

| Role | Primary job in BallChart |
|------|---------------------------|
| **Admin** | Own/manage the academy: teams, staff, players, branding, account security |
| **Head Coach** | Coach workflows plus broader organizational access (when Manage is available) |
| **Coach / Assistant Coach** | Teams, games, strategy, tactical lab, training assignments, reports, messaging |
| **Player** | View games/strategy, complete training, track progress, messaging, self profile |
| **Custom staff roles** | Access depends on permission toggles set by admin |

### How the app decides what you see

After login, BallChart routes by role:

1. **Admin** → Academy Dashboard (HOME · TEAMS · STAFF · PROFILE)
2. **Coach / Assistant / Head Coach** → Coach Home (HOME · GAMES · STRATEGY · PROFILE)
3. **Player** → Player Home (HOME · GAMES · STRATEGY · PROFILE)
4. If profile setup is incomplete → Profile completion screens first

Many buttons are also gated by **permissions** (for example `createTeam`, `createBattle`, `createStrategy`). If a button is missing, the account likely lacks that permission.

---

## 2. Roles, Permissions & Access Model

### 2.1 Explanation

Roles define the default shell and dashboard. Permissions fine-tune what staff can create or manage. An assistant coach without `createBattle` can still view games but cannot schedule new ones.

### 2.2 Permission matrix

| Permission | What it unlocks |
|------------|-----------------|
| `createTeam` | Create / register new squads |
| `manageStaff` | Invite staff, edit staff permissions |
| `createPlayer` | Create / enroll players onto teams |
| `updatePlayer` | Edit player dossier fields |
| `deletePlayer` | Remove players (where exposed) |
| `createBattle` | Schedule / edit games |
| `manageBattle` | Broader game management actions |
| `createStrategy` | Create playbook entries |
| `manageStrategy` | Manage / update playbooks |

### 2.3 Procedure — How an admin sets staff permissions

1. Log in as **Admin**.
2. Open the **STAFF** tab.
3. Tap the staff member you want to configure.
4. Review role (Head Coach, Coach, Assistant Coach, or custom).
5. Toggle each permission on or off according to responsibility.
6. Save changes.
7. Ask the staff member to refresh or re-login if UI does not update immediately.

**Expected result:** That staff member only sees create/manage actions matching enabled permissions.

---

## 3. App Launch, Splash & Session Restore

### 3.1 Explanation

When BallChart opens, the splash screen checks whether a valid login session already exists. This avoids forcing users to type credentials every time.

### 3.2 Procedure — Cold start with existing session

1. Tap the BallChart app icon.
2. Wait on the splash screen while session validation runs.
3. If the token/session is valid:
   - Admin opens Academy Dashboard
   - Coach opens Coach Home
   - Player opens Player Home
   - Incomplete profile opens profile completion

### 3.3 Procedure — Cold start with no session

1. Launch the app.
2. Splash finishes with no valid session.
3. App opens Login (or Auth/signup for new academy owners, depending on entry path).

### 3.4 Expected outcomes

| Condition | Destination |
|-----------|-------------|
| Valid admin session | Academy Dashboard |
| Valid coach session + completed profile | Coach Home |
| Valid player session + completed profile | Player Home |
| Valid session + incomplete profile | Profile completion |
| No / invalid session | Login / Auth |

---

## 4. Authentication & Account Security

### 4.1 Register an Academy (Admin Signup)

#### Explanation

Academy ownership starts with admin registration. This creates the admin user and the academy entity they will manage.

#### Procedure

1. Open BallChart and navigate to academy registration (**Register Your Academy** / Auth screen).
2. Enter required fields (typically full name, academy name, email, password).
3. Review and accept legal terms / privacy links if shown.
4. Tap **Create account** / submit.
5. Wait for success confirmation.
6. Open the optional **Academy Setup Guide** if offered (recommended for first-time owners).
7. Continue to Login or Dashboard as prompted.

#### What you should explain / verify

- Email must be unique and valid.
- Password must meet validation rules shown by the form.
- Role is fixed as **admin** for this signup path.
- After success, you should proceed to create the first team and invite staff.

#### Common issues

- Duplicate email → use another email or recover existing account.
- Validation errors → fix highlighted fields before resubmitting.

---

### 4.2 Login

#### Explanation

Login authenticates by role family (admin, coach, player). After success, routing sends the user to the correct shell.

#### Procedure

1. Open the Login screen.
2. Enter email and password.
3. Confirm you are using the correct account type if the UI asks for role context.
4. Tap **Sign In**.
5. Wait for authentication and routing.

#### Expected result

- Successful login → role dashboard or profile completion.
- Failed login → clear error (invalid credentials / network).

#### Best practice

Use the same email that was created by admin when the staff/player account was provisioned.

---

### 4.3 Forgot Password

#### Explanation

Password recovery is a multi-step flow: identify account by email → verify OTP → set a new password → confirm success.

#### Procedure

1. On Login, tap **Forgot Password**.
2. **Enter Email**
   - Type the account email.
   - Submit to request a verification code.
3. **Enter OTP**
   - Open the email inbox for the OTP.
   - Enter the code exactly as received.
   - Submit for verification.
4. **Enter New Password**
   - Type a new password.
   - Confirm password if asked.
   - Submit.
5. **Success screen**
   - Confirm reset completed.
   - Return to Login and sign in with the new password.

#### Notes

- OTP expires; request a new one if timed out.
- Keep the phone online during the full flow.
- After reset, old password no longer works.

---

### 4.4 Registration Success & Academy Setup Guide

#### Explanation

After admin signup, BallChart may show a success screen and an optional bottom-sheet guide. The guide walks through first operational steps so the academy is usable quickly.

#### Procedure — Use the setup guide

1. From registration success, tap **View Guide** (or equivalent).
2. Read each step carefully:
   - Sign in
   - Complete / update academy profile
   - Create first team
   - Invite staff
   - Enroll players
   - Schedule first game (optional early milestone)
3. Close the guide and go to Dashboard / Login.
4. Execute the steps in order (Sections 7–15 of this report).

---

## 5. Profile Completion (First Login)

### 5.1 Coach profile completion

#### Explanation

New coach accounts often require profile enrichment before the main shell unlocks. This gives the academy richer staff dossiers (experience, sports, achievements).

#### Procedure

1. Log in with a coach account that has incomplete profile.
2. App opens **Complete Profile (Coach)**.
3. Select experience level / years of experience.
4. Add sports / specialties relevant to basketball coaching.
5. Add achievements / additional information.
6. Save / submit.
7. App routes into Coach Home.

#### Expected result

`profileCompleted` becomes true; coach can access Teams, Games, Strategy, Profile.

---

### 5.2 Player profile completion

#### Explanation

Players provide position, age range, and goals so coaches can personalize training and reports.

#### Procedure

1. Log in as a player with incomplete profile.
2. Open **Complete Profile (Player)**.
3. Select primary position (e.g., Guard, Forward, Center — as listed in UI).
4. Select age range.
5. Enter goals / additional goals.
6. Save.
7. App routes into Player Home.

---

## 6. Global Navigation & Exit Behavior

### 6.1 Explanation

BallChart uses bottom tabs for major modules and header icons for Messages / Notifications. Back navigation is standardized so users do not accidentally leave the app.

### 6.2 Procedure — Switch modules

1. Tap a bottom tab (HOME, TEAMS/GAMES, STRATEGY/STAFF, PROFILE depending on role).
2. Content area switches without losing the session.
3. Use header icons for Messages or Notifications when available.

### 6.3 Procedure — Hardware / gesture back

1. From a pushed screen (team detail, chat, tactical lab): back returns to previous screen.
2. From a root tab that is **not** the first tab: back jumps to the first tab.
3. From the **first tab**: app shows an **Exit App** confirmation popup.
4. Confirm to leave, or cancel to stay.

### 6.4 iPhone note

Left-edge swipe-back follows the same logic as the system back button.

---

## 7. Admin — Academy Dashboard

### 7.1 Explanation

The Academy Dashboard is the admin control center. It summarizes academy health (teams, staff, players, activity) and provides shortcuts to create teams, invite staff, and inspect squads.

### 7.2 Procedure — Review academy overview

1. Log in as Admin.
2. Land on **HOME** (Academy Dashboard).
3. Review summary cards: team count, staff count, player count, activity metrics.
4. Scroll to squad carousel / top performer sections if shown.
5. Pull down to refresh data.
6. Tap **View All** (or equivalent) to jump into TEAMS when needed.

### 7.3 Procedure — Quick actions from HOME

1. Tap **Add Team** / create shortcut → Create Team dialog (Section 8).
2. Tap **Invite Staff** → Create Staff dialog (Section 9).
3. Tap a squad card → Team Detail (Section 12).

### 7.4 Expected result

Admin can understand academy size at a glance and jump into operational create flows without hunting menus.

---

## 8. Admin — Team Management

### 8.1 Explanation

Teams (also called squads) are the organizational unit for players, coaches, games context, and group messaging. Creating a team correctly (name, age group, coaches, branding) makes later roster and training work simpler.

### 8.2 Procedure — Create a team

1. As Admin, open **TEAMS** tab (or use Add Team from HOME).
2. Tap create / **Initialize New Team** / **Register New Squad**.
3. In **Create Team** dialog:
   - Upload team shield / logo (optional but recommended).
   - Enter **Squad Designation** (official team name).
   - Choose age group / category if available.
   - Pick team color if offered.
   - Assign **Head Coach** from staff list.
   - Assign **Assistant Coach** if available.
4. Tap **Initialize Squad** / Save.
5. Confirm the new team appears in the TEAMS list.

### 8.3 Procedure — Open and review a team

1. From TEAMS, tap a team card.
2. Review Team Detail:
   - Identity (name, logo, color)
   - Roster metrics
   - Active roster
   - Command staff / leads
   - Battle / activity log (if present)
3. Use FAB / Add Player to enroll athletes (Section 10 / 12).

### 8.4 Procedure — Edit team identity

1. Open Team Detail.
2. Use edit controls for name, photo, or other editable fields.
3. Save.
4. Refresh list to confirm updated branding.

### 8.5 Procedure — Assign team leads

1. Open Team Detail.
2. Open hierarchy / leads section.
3. Select Head Coach and/or Assistant Coach from staff.
4. Confirm assignment.
5. Verify leads appear under command staff.

**Expected result:** Team is visible to assigned coaches on Coach Home → Teams tab.

---

## 9. Admin — Staff Management

### 9.1 Explanation

Staff accounts are how coaches and assistants enter BallChart. Admin creates credentials, chooses role, and sets permissions. Without staff, teams have no coaches to assign training or run Tactical Lab.

### 9.2 Procedure — Invite / create staff

1. Open **STAFF** tab.
2. Tap Invite / Add Staff.
3. In **Create Staff** dialog fill:
   - Full name
   - Email (login identity)
   - Temporary password (share securely with the staff member)
   - Role (Head Coach / Coach / Assistant / custom)
   - Photo (optional)
   - Permission toggles
4. Save / Create.
5. Confirm staff appears in the org list.

### 9.3 Procedure — Share credentials safely

1. Copy email + temporary password.
2. Send privately (secure channel).
3. Instruct staff to:
   - Log in
   - Complete profile if prompted
   - Change password from Profile

### 9.4 Procedure — Edit staff

1. Open STAFF list.
2. Select staff member.
3. Update role, permissions, or profile fields.
4. Save.
5. Verify changes.

### 9.5 Expected result

Staff can log in, see coach shell features matching permissions, and appear in team lead selectors.

---

## 10. Admin — Player Enrollment

### 10.1 Explanation

Players need accounts linked to a team. Admin (or permitted staff) creates player credentials and assigns them to a squad so they appear in roster, development, messaging eligibility, and games.

### 10.2 Procedure — Create player from team

1. Open Team Detail.
2. Tap Add Player / FAB.
3. In **Create Player** dialog enter:
   - Name
   - Email
   - Password
   - Photo (optional)
   - Confirm team assignment
4. Save.
5. Confirm player appears in Active Roster.

### 10.3 Procedure — Enroll player from Admin Profile

1. Open Admin **PROFILE** tab.
2. Tap **Enroll Player** (or equivalent).
3. Enter name and assign team.
4. Complete required credential fields if prompted.
5. Save and verify on Team Detail roster.

### 10.4 Procedure — Player first login

1. Give player their email + temporary password.
2. Player opens BallChart → Login.
3. Completes Player Profile if required.
4. Lands on Player Home.

---

## 11. Coach — Home & Teams

### 11.1 Explanation

Coach Home is the daily operations shell for coaching staff. HOME focuses on assigned squads, training shortcuts, and intelligence/activity cards. Header icons open Messages and Notifications.

### 11.2 Procedure — Orient on Coach Home

1. Log in as coach.
2. Confirm header shows role and academy context.
3. Note bottom tabs: **HOME · GAMES · STRATEGY · PROFILE**.
4. Tap Messages icon (header) to open inbox.
5. Tap Notifications bell to open notification panel.

### 11.3 Procedure — Use Teams tab (HOME)

1. Stay on / open HOME.
2. Review **Active Squads**.
3. Tap a squad card → Team Detail.
4. Tap **Assign Training** shortcut → Training Assignment screen (Section 21).
5. If permitted, tap **Register New Squad** → Create Team dialog.

### 11.4 Procedure — Review top performer / feed

1. Scroll Teams tab content.
2. Review top performer card (if data exists).
3. Review intelligence / activity feed for recent academy signals.
4. Pull to refresh when data looks stale.

---

## 12. Team Detail & Hierarchy

### 12.1 Explanation

Team Detail is the operational page for one squad: who plays, who coaches, roster health, and quick actions to add players or manage hierarchy.

### 12.2 Procedure — Inspect roster

1. Open a team from Admin TEAMS or Coach HOME.
2. Review roster list (names, photos, positions if present).
3. Tap a player row → Player Detail dossier.
4. Return via back.

### 12.3 Procedure — Add a player (permitted staff)

1. On Team Detail, tap FAB / Add Player.
2. Complete Create Player dialog.
3. Save.
4. Confirm new athlete in Active Roster.

### 12.4 Procedure — Manage hierarchy (coaches)

1. Open Hierarchy Management section/widget.
2. Tap Select Coach / Add New as needed.
3. Choose staff for head or assistant slot.
4. Confirm.
5. Verify visual hierarchy updates (staff → players).

### 12.5 Expected result

Roster is current; assigned coaches see the team; players appear for training assignment selectors and messaging contacts.

---

## 13. Player — Home & Stats

### 13.1 Explanation

Player Home HOME tab is a personal performance dashboard: training status, points, recent games/battles, and shortcuts into My Development and PDF completion reports.

### 13.2 Procedure — Review personal stats

1. Log in as Player.
2. Open HOME tab.
3. Review:
   - Pending training count
   - Points / progress indicators
   - PPG / APG / RPG-style stats (when available)
   - Battle / recent games summary
4. Pull to refresh.

### 13.3 Procedure — Open My Training

1. Tap **OPEN MY TRAINING** / My Development entry.
2. Work assignments (Section 22).
3. Return to HOME to see updated pending/completed counts after completion.

### 13.4 Procedure — Open last completion PDF

1. If a completed assignment has a PDF available, tap View / Open completion PDF.
2. Review in-app PDF viewer.
3. Share externally only if needed.

---

## 14. Player Detail / Athlete Dossier

### 14.1 Explanation

Player Detail is the athlete dossier. Players can edit their own profile (when `canEdit` is true). Coaches/admins open it from roster to review biometrics, jersey info, scouting notes, and battle stats.

### 14.2 Procedure — Player edits own profile

1. Open PROFILE tab as Player (routes to Player Detail).
2. Update photo.
3. Edit full profile fields (name context, position, notes allowed by UI).
4. Quick-edit height / weight / wingspan if shown.
5. Save each section as prompted.
6. Confirm values persist after leaving and reopening.

### 14.3 Procedure — Coach reviews a player

1. From Team Detail roster, tap player.
2. Read biometrics, jersey, scouting notes, stats.
3. Edit only if you have `updatePlayer` permission.
4. Use dossier context when writing monthly reports.

---

## 15. Games / Battles Module

### 15.1 Explanation

The Games (Battle) module schedules and tracks academy contests and scrimmages. Status filters help staff focus on what is upcoming, live, paused, or finished. Creating a game requires `createBattle` permission.

### 15.2 Procedure — Browse games

1. Open **GAMES** tab (coach or player).
2. Choose a filter:
   - **ALL**
   - **SCHEDULED**
   - **LIVE**
   - **PAUSED**
   - **FINISHED**
3. Scroll the list.
4. Tap a game card to open Battle Hub (Section 16).

### 15.3 Procedure — Schedule a new game

1. Confirm your account has `createBattle`.
2. Tap FAB / Schedule Game.
3. In **Create Battle** sheet fill:
   - Title (e.g., Varsity vs East scrimmage)
   - Location (required — e.g., Main gym, Court 2)
   - Format: 5v5 / 3v3 / 1v1 / drills
   - Roster cap (max participants)
   - Date & time (picker or presets: +1h, +3h, Tonight 7p, +1 day)
   - Notes (opponent, focus, jerseys)
   - Tags
4. Tap **SCHEDULE GAME**.
5. Confirm the game appears under SCHEDULED.

**Validation tips**

- Location cannot be empty.
- Time should be in the future for new schedules.

### 15.4 Procedure — Edit a scheduled game

1. Open Games list.
2. Use edit action on a scheduled game (or reopen sheet from card actions).
3. Update fields.
4. Save changes.
5. Verify updated title/time/location on the list.

### 15.5 Procedure — Open Tactical Lab from games context

1. From Games list or Battle Hub, tap Tactical Lab shortcut if shown.
2. Build / review tactics for that game context (Section 20).

---

## 16. Battle Hub

### 16.1 Explanation

Battle Hub is the game control sheet. It combines roster/join actions with a play-by-play style status feed and shortcuts into tactical tools.

### 16.2 Procedure — Use GAME HUB

1. Tap a game from the list.
2. Review hub details (title, time, location, status).
3. Review roster / participants.
4. Tap **Join This Game** if eligible and joining is available.
5. Open tactical lab from hub when preparing plays.
6. Switch to **PLAY-BY-PLAY** section to review status events.

### 16.3 Expected result

Participants understand game logistics; eligible users can join; coaches can jump into tactical prep without leaving the games workflow.

### 16.4 Notes

Some lifecycle actions (leave / start / finish) may be partially implemented or reserved for future expansion. Prefer documented UI actions that are currently enabled on your build.

---

## 17. Strategy / Playbook Module

### 17.1 Explanation

Strategy is the academy playbook. Coaches author formations, film, diagrams, and text cues. Players browse assigned/available strategies to study before practice or games.

### 17.2 Procedure — Coach browse & search

1. Open **STRATEGY** tab as coach (`Enhanced Strategy` screen).
2. Use search box for strategy names/tags.
3. Apply filters / sort options.
4. Switch grid/list presentation if available.
5. Tap a card → Strategy Detail.

### 17.3 Procedure — Player browse playbook

1. Open **STRATEGY** as player.
2. Browse available strategies / media filters.
3. Review KPI % displays if shown.
4. Open a strategy for study.
5. Use shortcut to **My Development** when training is linked to playbook work.

### 17.4 Procedure — Create a strategy (coach)

1. Confirm `createStrategy` permission.
2. Tap create (+) on Strategy tab.
3. Choose creation mode from options sheet:
   - Full playbook
   - Video & film
   - Diagram
   - Text
   - External link
4. In Create Strategy dialog enter:
   - Name
   - Type / category
   - Media uploads as needed
   - Plays / cues list
   - Tags
5. Optionally tap **DESIGN IN LAB** to build animation in Tactical Lab.
6. Save.
7. Confirm new card appears in library.

### 17.5 Expected result

Playbook grows with reusable content; players can study; tactics can be linked from Lab.

---

## 18. Strategy Detail

### 18.1 Explanation

Strategy Detail is the deep view of one playbook entry: diagrams, video/text content, coach voice clips, tactical playback, and share/export.

### 18.2 Procedure — Study a strategy

1. Open a strategy card.
2. Review title, tags, and description.
3. Play video / view diagram / read text cues.
4. Open coach voice clips panel and replay instructions.
5. Open tactical playback / lab when available.
6. Share PDF report if export is offered.

### 18.3 Procedure — Coach voice clips on a strategy

1. On detail (or related lab panel), open voice clips section.
2. Play existing coach recordings.
3. As coach author, add new clips if UI provides record controls.
4. Confirm players can replay those clips in player mode.

---

## 19. Strategy KPIs

### 19.1 Explanation

Strategy KPIs let staff set academy targets such as formation engagement % and drill completion %. These targets guide development catalog expectations.

### 19.2 Procedure — Tune KPIs

1. From Strategy module, open **KPIs** sheet / action.
2. Review current targets.
3. Adjust formation engagement percentage.
4. Adjust drill completion percentage.
5. Save / apply.
6. Confirm values persist when reopening the sheet.

---

## 20. Tactical Lab

### 20.1 Explanation

Tactical Lab is BallChart’s half-court animation studio. Coaches type or speak flow commands, record sequences, drag players, attach voice notes, then save/publish as strategy and optionally assign to a team or player. Players can open Lab in playback / study mode.

### 20.2 Procedure — Open Tactical Lab

1. Enter from:
   - Strategy create → Design in Lab
   - Strategy detail playback
   - Games / Battle Hub shortcut
   - Direct tactical entry where exposed
2. Wait for court and player markers to load.
3. Confirm whether you are in coach-author mode or player-playback mode.

### 20.3 Procedure — Type a flow command

1. Tap the command text field.
2. Type a clear flow (example style: player movements / screens / cuts described in natural basketball language).
3. Tap **RECORD FLOW**.
4. Watch the animation execute on the court.
5. Adjust by dragging players if needed.
6. Re-run or refine the command text.

### 20.4 Procedure — Voice command (Whisper / on-device transcription)

1. Ensure microphone permission is granted.
2. Tap the mic.
3. On **first use**, wait for voice recognition model download / preparation dialog.
4. Speak the tactical flow clearly and close to the mic.
5. Stop recording.
6. Wait while speech converts to text.
7. Review transcribed command in the text field.
8. Tap **RECORD FLOW** to animate.
9. If transcription fails, read the error hint, retry, or type the command manually. Voice clip may still be kept when available.

### 20.5 Procedure — Record coach voice notes in Lab

1. Open **YOUR VOICE RECORDINGS** / coach voice notes panel.
2. Record instructional clips for the play.
3. Playback to verify clarity.
4. Keep clips attached when saving the flow.

### 20.6 Procedure — Save & publish / assign

1. After a usable recorded flow, tap Save / Publish.
2. In **Save & Assign Flow** dialog:
   - Enter tactic name (required), e.g. *Horns Red Pick & Roll*
   - Add player instructions
   - Optionally choose team/player assignment
3. Confirm save.
4. On success, find the tactic in Strategy / playbook library.

### 20.7 Expected results

| Action | Result |
|--------|--------|
| Typed command + RECORD FLOW | Court animation runs |
| Voice command success | Text filled + animation available |
| Voice permission denied | Prompt to enable microphone |
| Save without name | Validation error |
| Save success | Strategy/tactic stored; optional assignment created |

### 20.8 Best practices

- Prefer short, unambiguous spoken phrases.
- Use text fallback when gym noise is high.
- Name tactics consistently for searchable playbooks.
- Attach voice notes for player self-study.

---

## 21. Player Development — Assign Training

### 21.1 Explanation

Coaches assign focused work (drills, game prep, other tasks) to individual players with due dates and point values. Assignments feed the player’s My Development screen and completion PDFs.

### 21.2 Procedure — Assign training

1. From Coach HOME tap **Assign Training**, or enter from Strategy shortcuts.
2. On **Coach Training Assignment** screen:
   - Select player
   - Select focus area
   - Select drill from catalog
   - Choose type: training / game_prep / other
   - Set due date
   - Set points
   - Add notes if available
3. Tap **Assign training**.
4. Confirm the assignment appears in the existing assignments list.
5. Optionally open Monthly Report from related links.

### 21.3 Expected result

Player sees a new pending assignment in My Development; coach can track completion later.

---

## 22. Player Development — My Development

### 22.1 Explanation

My Development is the player’s training workspace: pending and completed assignments, personal goals, coach ratings/goals when published, and report access.

### 22.2 Procedure — Complete an assignment

1. Open My Development from Player HOME / Strategy shortcut.
2. Review **Pending** list.
3. Open an assignment.
4. Perform the real-world training.
5. Tap **Mark complete**.
6. Confirm it moves to completed.
7. Open completion PDF when generated.

### 22.3 Procedure — Save personal monthly goals

1. In My Development, find personal goals section.
2. Enter / edit goals for the period.
3. Tap **Save my goals**.
4. Confirm saved state (snackbar / persisted text).

### 22.4 Procedure — Review coach feedback

1. After coach publishes a period report, open the report section.
2. Read summary, area ratings, coach goals.
3. Open PDF report if offered.
4. Message coach from chat if clarification is needed.

---

## 23. Coach Monthly / Period Reports

### 23.1 Explanation

Coaches write structured performance evaluations by player and month/period: area ratings (1–5), insights, summary, and goals. Reports can be downloaded as PDF and published into the player’s BallChart messages for official delivery.

### 23.2 Procedure — Create / edit monthly report

1. Open **Coach Monthly Report** screen (from training assignment links or coach tools).
2. Select player.
3. Select month / year.
4. Open **Performance Report Editor**.
5. Rate each development area from 1–5.
6. Write insights / comments.
7. Write overall summary.
8. Enter coach goals for the player.
9. Save report.
10. Wait for success confirmation before leaving.

### 23.3 Procedure — Send report in BallChart messages

1. After a successful save, tap **Send report in BallChart messages** (in-app publish).
2. Confirm PDF/message delivery to player conversation.
3. Optionally open Messages to verify the PDF attachment appears in chat.
4. Use external share (WhatsApp/Email/Files) only when out-of-app delivery is required.

### 23.4 Expected result

- Report stored for that player/period
- PDF available for download/view
- Player can see published feedback in development + messages

### 23.5 Important rule

Always **save** the performance report before generating or sending PDF. Unsaved drafts may not produce a PDF.

---

## 24. PDF Reports & In-App Viewer

### 24.1 Explanation

BallChart generates PDFs for training completion and period reports. The in-app PDF viewer lets users read documents without leaving the app, with optional share actions.

### 24.2 Procedure — View a PDF in-app

1. From My Development, Monthly Report, or chat attachment, tap Open PDF.
2. Wait for document load in **In-App PDF Viewer**.
3. Scroll / pinch-zoom as supported.
4. Use share only if you need an external copy.
5. Close viewer to return.

### 24.3 PDF sources

| Source | Typical trigger |
|--------|-----------------|
| Assignment completion PDF | Player completes training |
| Period/monthly report PDF | Coach saves + generates report |
| Chat PDF attachment | Coach sends report in messages |

---

## 25. Messaging & Conversations

### 25.1 Explanation

Messaging connects admins, coaches, and players. Users see direct conversations and team group threads (when roster/team chat is available). Unread badges help prioritize replies. Eligible contacts are controlled by academy membership and backend rules.

### 25.2 Procedure — Open inbox

1. From Coach or Player shell header, tap **Messages**.
2. Review conversations list:
   - Direct chats
   - Team group chats
   - Unread badges
3. Pull to refresh if a new chat is missing.

### 25.3 Procedure — Start a new direct message

1. Tap **+** / New Message.
2. Browse eligible contacts.
3. Select a contact.
4. Conversation opens (new or existing).
5. Send first message (Section 26).

### 25.4 Procedure — Open team group chat

1. In conversations list, find the team group thread.
2. Open it.
3. Send announcements to all members of that team chat.
4. Confirm recipients receive notifications when online sync is working.

---

## 26. Chat Screen (Text, Voice, Files)

### 26.1 Explanation

Chat supports real-time academy communication: typed messages, hold-to-record voice notes, reply threads, read receipts, participant profiles, and PDF attachments (especially for reports).

### 26.2 Procedure — Send text

1. Open a conversation.
2. Type in the composer.
3. Tap send.
4. Confirm message appears in the thread with your alignment/style.
5. Watch read receipts (double-tick) when peer reads.

### 26.3 Procedure — Send a voice note

1. Ensure microphone permission is allowed.
2. Press and hold the mic control.
3. Speak the note.
4. Release to send (or follow on-screen cancel/send affordances).
5. Confirm voice bubble appears.
6. Recipient taps play on **Voice Note Bubble** to listen.

### 26.4 Procedure — Reply to a message

1. Long-press or use reply action on a bubble.
2. Confirm reply preview appears above composer.
3. Send text/voice reply.
4. Thread shows reply linkage.

### 26.5 Procedure — Open participant profile

1. Tap avatar / participant info.
2. Review profile sheet.
3. If peer is a player, open full Player Detail when offered.

### 26.6 Procedure — Receive / open PDF in chat

1. When a coach publishes a report, open the conversation.
2. Tap the PDF attachment bubble.
3. View in-app or share externally.

---

## 27. Notifications

### 27.1 Explanation

The notification panel aggregates academy events (messages, assignments, reports, system notices). Users can mark one or all as read and tap items to navigate to related screens when deep-links are available.

### 27.2 Procedure — Review notifications

1. Tap the notification bell in the header.
2. Scroll the list by type/time.
3. Tap an item to open related content when supported.
4. Mark a single notification as read, or mark all read.
5. Close panel.

### 27.3 Relationship to messaging

Opening a conversation and reading messages typically clears related unread message indicators. If badges linger, refresh inbox or reconnect network.

---

## 28. Profile, Password, Logout & Delete Account

### 28.1 Explanation

Profile is the account & identity center. Admins also manage academy partnership/branding and quick create actions. Coaches edit coaching details. Players are routed to their athlete dossier instead of the generic staff profile.

### 28.2 Procedure — Edit staff / coach profile

1. Open **PROFILE** tab.
2. Update avatar.
3. Edit name / coach details (experience, achievements, assigned teams display).
4. Save.
5. Confirm header/profile reflect changes.

### 28.3 Procedure — Edit academy (Admin)

1. Open Admin PROFILE.
2. Open **Edit Academy** dialog.
3. Update academy name / logo / related fields.
4. Save.
5. Confirm branding updates on dashboard.

### 28.4 Procedure — Change password

1. Open PROFILE.
2. Tap **Change Password**.
3. Enter current password.
4. Enter new password + confirmation.
5. Submit.
6. Re-login if the app requires it after password change.

### 28.5 Procedure — Notification preference toggle

1. In PROFILE operational settings, toggle notifications on/off if available.
2. Confirm preference persists after leaving the screen.

### 28.6 Procedure — Logout

1. Open PROFILE.
2. Tap Logout.
3. Confirm if prompted.
4. App returns to Login; session cleared.

### 28.7 Procedure — Delete account

1. Open PROFILE.
2. Tap Delete Account.
3. Read warning carefully (irreversible).
4. Confirm in **Delete Account** dialog.
5. Account removal request is submitted; access ends.

**Caution:** Delete account permanently removes access. Prefer logout or password change for temporary issues.

### 28.8 Legal links

Profile may expose Privacy Policy / Terms links. Open them in-browser or in-app viewer as provided.

---

## 29. Device Permissions & Dependencies

### 29.1 Explanation

Some features need OS permissions and a working network. Without them, UI may open but actions fail.

### 29.2 Required permissions

| Permission | Features that need it |
|------------|------------------------|
| **Microphone** | Chat voice notes, Tactical Lab voice commands, coach voice clips |
| **Camera / Photos** | Profile photos, team shields, player photos, strategy media |
| **Internet** | Login, messaging sync, CRUD for teams/staff/players, reports, PDFs, strategy sync |

### 29.3 First-time voice model download

Tactical Lab voice recognition may download an on-device speech model once. Do not background the app mid-download. After success, subsequent voice commands are faster.

### 29.4 Procedure — Grant microphone on iOS/Android

1. Trigger a mic feature (voice note or Lab mic).
2. When system prompt appears, allow access.
3. If previously denied:
   - Open device Settings → BallChart → enable Microphone
   - Return to app and retry

---

## 30. Troubleshooting Playbook

### 30.1 Cannot log in

**Checks**

1. Correct email/password for the role account.
2. Network connectivity.
3. Caps lock / autofill mistakes.
4. Account actually created by admin (for staff/players).

**Fix path:** Reset password → retry → contact academy admin to confirm credentials.

---

### 30.2 Missing create buttons (team/game/strategy)

**Cause:** Permission not granted.

**Fix path:** Admin opens STAFF → enable relevant permission → staff refreshes/relogs.

---

### 30.3 Report PDF unavailable

**Checks**

1. Was the period report saved successfully?
2. Is network stable?
3. Is the correct player/month selected?

**Fix path:** Re-open editor → Save → Generate/Send PDF again.

---

### 30.4 Voice command fails in Tactical Lab

**Checks**

1. Microphone permission on.
2. Model download finished.
3. Speech was clear / loud enough.
4. Network if any parse step requires it.

**Fix path:** Retry → type command manually → RECORD FLOW.

---

### 30.5 Message not sending

**Checks**

1. Internet connection.
2. Conversation still valid.
3. Attachment size/type supported.

**Fix path:** Reopen chat → retry send → check Notifications/Inbox after reconnect.

---

### 30.6 Player cannot see assignment

**Checks**

1. Coach assigned to correct player.
2. Player logged into correct account.
3. Pull-to-refresh on My Development.

**Fix path:** Coach re-open assignment list to confirm; re-assign if needed.

---

### 30.7 Session expired / unexpected login screen

**Cause:** Token expired or cleared.

**Fix path:** Log in again; avoid force-killing during critical saves.

---

## 31. Academy Setup Checklist

Use this after registering a new academy to confirm every feature path is live.

### Phase A — Foundation

- [ ] Admin account created and login verified
- [ ] Academy profile / logo updated
- [ ] At least one team created
- [ ] At least one coach/staff invited with permissions set
- [ ] At least one player enrolled on the team
- [ ] Coach can see the team on Coach Home
- [ ] Player can log in and complete profile

### Phase B — Operations

- [ ] Schedule a test game
- [ ] Open Battle Hub and join flow tested
- [ ] Create a strategy entry
- [ ] Run Tactical Lab typed flow and save
- [ ] Run Tactical Lab voice command (after mic + model setup)
- [ ] Assign training to player
- [ ] Player marks assignment complete
- [ ] Coach writes monthly report, saves, sends PDF in messages
- [ ] Player opens PDF in chat / development

### Phase C — Communication & account

- [ ] Direct message coach ↔ player works
- [ ] Team group chat visible (if enabled for roster)
- [ ] Voice note send/play works
- [ ] Notifications panel lists events
- [ ] Change password tested on a non-critical account
- [ ] Logout / re-login verified

---

## Appendix A — Role Quick Reference

### Admin daily path

Dashboard → Teams/Staff → Create assets → Profile/academy settings → Messages as needed

### Coach daily path

Teams → Assign training → Games → Strategy / Tactical Lab → Monthly reports → Messages

### Player daily path

HOME stats → My Development → Games → Strategy study → Messages → Profile dossier

---

## Appendix B — Feature-to-Screen Map (for trainers)

| Feature | Primary screen area |
|---------|---------------------|
| Splash / session | Splash |
| Admin signup | Auth |
| Login | Login |
| Forgot password | Email → OTP → New Password → Success |
| Coach profile setup | Complete Profile Coach |
| Player profile setup | Complete Profile Player |
| Admin home | Academy Dashboard |
| Teams list / create | TEAMS + Create Team dialog |
| Staff invite / permissions | STAFF + Create Staff dialog |
| Coach teams | Coach Home → Teams tab |
| Team operations | Team Detail |
| Player stats | Player Home → HOME |
| Athlete dossier | Player Detail |
| Games | Battle Screen |
| Schedule game | Create Battle sheet |
| Game hub | Battle Hub sheet |
| Playbook | Enhanced Strategy / Strategy screens |
| Strategy deep view | Strategy Detail |
| KPI targets | Strategy KPIs sheet |
| Animated tactics | Tactical Lab |
| Assign drills | Coach Training Assignment |
| Player training | My Development |
| Evaluations | Monthly Report + Period Editor |
| PDFs | In-App PDF Viewer |
| Inbox | Conversations List |
| Chat | Chat Screen |
| Alerts | Notification Panel |
| Account | Profile Screen |

---

## Appendix C — Recommended Training Order for Staff

1. Product overview + roles/permissions  
2. Admin signup, login, password recovery  
3. Create team → invite staff → enroll players  
4. Coach home + team detail + hierarchy  
5. Assign training + player completion  
6. Monthly report save + in-app PDF send  
7. Messaging (text, voice, team group)  
8. Strategy create + detail study  
9. Tactical Lab typed + voice workflows  
10. Games schedule + Battle Hub  
11. Profile security (password, logout)  
12. Troubleshooting drills from Section 30  

---

*End of BallChart Detailed Feature Report.*
