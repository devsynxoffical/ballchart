# HoopStar Backend Plan V2: Admin 4 Screens (Plus Role Alignment)

This is Version 2 of backend planning, focused on **Admin module deep mapping**:
- Admin Dashboard
- Admin Teams
- Admin Staff
- Admin Profile

It also aligns these with existing role flows (`coach`, `assistant_coach`, `player`) so implementation remains consistent with V1.

Related document:
- `BACKEND_IMPLEMENTATION_PLAN_HOME_PROFILE_AUTH.md` (V1)

---

## 1) Backend Objectives for V2

1. Make Admin module production-ready with complete API coverage.
2. Support all admin UI functions currently present in frontend.
3. Ensure staff permissions are first-class and enforced server-side.
4. Keep contracts reusable for coach/assistant/player dashboards.
5. Standardize error handling and permission-denied responses.

---

## 2) Current Admin Frontend Functional Map

From `AcademyDashboardScreen`, `StaffListScreen`, `TeamDetailScreen`, and dialogs:

### 2.1 Admin Home (Dashboard tab)
- Load academy overview (`loadAdminOverview`)
- Show academy KPIs (teams/staff/players)
- Show top performer card
- Show active squads carousel
- Open team details
- Quick actions:
  - create team
  - invite staff
- Pull-to-refresh
- Receive live socket updates

### 2.2 Admin Teams tab
- List all teams
- Open team detail
- Show each team age group and players count

### 2.3 Team Details (nested from teams/home)
- Read full team profile
- Read roster players
- Open player details
- Add player
- Update team leads (coach + assistant)
- View battle log snippets

### 2.4 Admin Staff tab
- View staff hierarchy list
- Select staff and inspect details
- Edit staff identity:
  - name
  - email
  - password
  - profile picture URL
- Toggle permissions with dependency logic:
  - manage requires create for strategy/battle
- Add new staff with initial permissions

### 2.5 Admin Profile tab
- Academy-focused profile cards:
  - owner name/email/experience
  - academy name/logo
  - counts (teams/staff)
- Edit profile (name/email/experience/profile image)
- Edit academy details
- Upload image

---

## 3) Required Domain Model (Backend)

## 3.1 Collections / Tables
- `users`
- `academies`
- `teams`
- `players` (or user subtype if single-table)
- `staff` (or user subtype if single-table)
- `battles`
- `strategies` (for permission scaffolding and future use)
- `audit_logs` (recommended)

## 3.2 Core Entities

### User
- `_id`
- `username`
- `email` (unique)
- `passwordHash`
- `role`: admin | head_coach | coach | assistant_coach | player
- `academyId`
- `profileCompleted`
- `permissions` (effective or assigned)
- profile fields:
  - `experienceLevel`, `sports[]`, `achievements[]`, `additionalInfo`
  - `profileImageUrl`
  - player fields: `height`, `weight`, `wingspan`, `position`, `jerseyNumber`, `classYear`, `scoutingNotes`, `ageRange`

### Academy
- `_id`
- `academyName`
- `logoUrl`
- `ownerUserId`

### Team
- `_id`
- `academyId`
- `name`
- `ageGroup`
- `colorValue`
- `logoPath`
- `coachStaffId`
- `assistantCoachStaffId`

### Player Assignment
- `teamId`
- `playerUserId`

### Staff Assignment
- `assignedTeamIds[]`

---

## 4) RBAC + Permission Enforcement

## 4.1 Role Rules
- `admin`: full academy control
- `head_coach`: broad read/manage based on policy
- `coach`: assigned-team control
- `assistant_coach`: restricted operations
- `player`: own profile + own dashboard

## 4.2 Permission Keys (must exist)
- `createPlayer`, `readPlayer`, `updatePlayer`, `deletePlayer`
- `createTeam`, `manageStaff`
- `createBattle`, `manageBattle`
- `createStrategy`, `manageStrategy`

## 4.3 Critical Constraints
- Permission toggles validated by backend:
  - if `manageStrategy=true` then `createStrategy=true`
  - if `manageBattle=true` then `createBattle=true`
- Staff cannot escalate beyond actor’s authority.
- Cross-academy access forbidden (`403`).

---

## 5) API Contract Plan (Admin 4 Screens)

## 5.1 Admin Home APIs

### GET `/auth/admin/overview`
Purpose:
- source for dashboard cards, teams carousel, staff list, battle summary.

Response example:
```json
{
  "admin": {
    "_id": "u_admin",
    "username": "Owner",
    "email": "owner@academy.com",
    "academyName": "Elite Academy",
    "logoUrl": "https://..."
  },
  "teams": [
    {
      "_id": "t1",
      "name": "U19 Elite",
      "ageGroup": "U19",
      "colorValue": 4294959321,
      "logoPath": "https://...",
      "coachStaffId": "s1",
      "assistantCoachStaffId": "s2",
      "players": []
    }
  ],
  "staff": [
    {
      "_id": "s1",
      "username": "Sana",
      "email": "sana@x.com",
      "role": "coach",
      "assignedTeams": ["t1"],
      "permissions": { "createPlayer": true }
    }
  ],
  "battles": []
}
```

### Socket Events (already used by frontend)
- `STAFF_CREATED`, `STAFF_UPDATED`, `STAFF_DELETED`
- `TEAM_CREATED`, `TEAM_UPDATED`, `TEAM_DELETED`
- `TEAM_LEADS_UPDATED`
- `PLAYER_CREATED`, `PLAYER_UPDATED`, `PLAYER_DELETED`
- `BATTLE_CREATED`

Emit payload minimum:
```json
{ "academyId": "a1", "entityId": "..." }
```

---

## 5.2 Teams APIs

### POST `/auth/team/create`
Body:
```json
{
  "name": "U17 Falcons",
  "ageGroup": "U17",
  "colorValue": 4294959321,
  "logoPath": "data:image/png;base64,...",
  "coachStaffId": "s1",
  "assistantCoachStaffId": "s2"
}
```

### PUT `/auth/team/:teamId`
Body:
```json
{
  "name": "U17 Falcons A",
  "ageGroup": "U17",
  "colorValue": 4294959321,
  "logoPath": "https://..."
}
```

### DELETE `/auth/team/:teamId`
Expected:
- remove team
- detach from staff `assignedTeamIds`
- enforce safe cascade policy for players

### PUT `/auth/team/:teamId/leads`
Body:
```json
{
  "coachStaffId": "s1",
  "assistantCoachStaffId": "s2"
}
```

Validation:
- staff IDs belong to same academy
- roles allowed for lead slots

---

## 5.3 Team Detail APIs

### GET `/auth/team/:teamId/details`
Optional but recommended for stable deep view.
Return:
- full team
- roster
- lead staff profiles
- recent battles for this team

### POST `/auth/player/create`
Body currently used:
```json
{
  "username": "Player Name",
  "email": "p@x.com",
  "password": "temp123",
  "teamId": "t1",
  "position": "Guard",
  "ageRange": "17"
}
```

### PUT `/auth/player/:playerId`
Body may include:
`username`, `email`, `password`, `position`, `ageRange`, biometric fields

### DELETE `/auth/player/:playerId`
Removes player and team assignment.

---

## 5.4 Staff APIs

### POST `/auth/staff/create`
Body:
```json
{
  "username": "Hassan",
  "email": "hassan@x.com",
  "password": "secret123",
  "role": "assistant_coach",
  "customRoleName": null,
  "assignedTeamIds": ["t1"],
  "permissions": {
    "createPlayer": true,
    "readPlayer": true,
    "updatePlayer": false,
    "deletePlayer": false,
    "createTeam": false,
    "manageStaff": false,
    "createBattle": false,
    "manageBattle": false,
    "createStrategy": false,
    "manageStrategy": false
  }
}
```

### PUT `/auth/staff/:staffId`
Supports updates:
- `username`, `email`, `password`
- `role`, `customRoleName`
- `assignedTeamIds`
- `permissions`

Must enforce:
- actor cannot grant unauthorized capabilities
- dependency rules for strategy/battle create/manage

### GET `/auth/staff/credentials`
Used for duplicate email checks on create dialog.
Can be replaced with safer endpoint:
- `GET /auth/staff/check-email?email=...`

---

## 5.5 Admin Profile APIs

### PUT `/auth/admin/profile`
Body:
```json
{
  "academyName": "Elite Academy",
  "logoUrl": "https://...",
  "ownerName": "Owner Name",
  "ownerEmail": "owner@academy.com",
  "newPassword": "optional"
}
```

### GET `/auth/profile`
Must include admin fields for profile cards:
- username
- email
- role
- experienceLevel (if used)
- academyName

### PUT `/auth/profile`
For self profile edits from profile cards:
- `username`, `email`, `experienceLevel`, `profileImageUrl`

### POST `/upload/image`
Multipart form-data:
- file field: `image`
Return:
```json
{ "url": "https://cdn/.../image.png" }
```

---

## 6) Coach / Assistant / Player Alignment (for consistency)

Even though V2 is admin-focused, implement these in same release branch for contract stability:

### GET `/auth/dashboard/coach`
- consumed by coach + assistant home
- team visibility filtered by role + assignment

### GET `/auth/dashboard/player`
- consumed by player home + player detail/profile

### PUT `/auth/profile` role-aware allowlist
- coach fields
- assistant fields
- player fields

---

## 7) Function-to-Endpoint Matrix (Quick Reference)

| Frontend Function | Screen | Endpoint |
|---|---|---|
| `loadAdminOverview()` | Admin Home | `GET /auth/admin/overview` |
| `addTeamToBackend()` | Admin Home/Teams | `POST /auth/team/create` |
| `updateTeamInBackend()` | Team Detail | `PUT /auth/team/:teamId` |
| `deleteTeamInBackend()` | Teams/Detail | `DELETE /auth/team/:teamId` |
| `assignTeamLeadsInBackend()` | Team Detail | `PUT /auth/team/:teamId/leads` |
| `addPlayerToBackend()` | Team Detail/Admin Profile | `POST /auth/player/create` |
| `updatePlayer()` flow | Player Detail | `PUT /auth/player/:playerId` or `PUT /auth/profile` |
| `addStaffToBackend()` | Admin Home/Staff | `POST /auth/staff/create` |
| `updateStaffInBackend()` | Staff | `PUT /auth/staff/:staffId` |
| Permission toggles | Staff | `PUT /auth/staff/:staffId` |
| `updateAcademyProfileInBackend()` | Admin Profile | `PUT /auth/admin/profile` |
| Profile card edits | Admin/Coach/Player profile | `PUT /auth/profile` |
| Image upload | Profile dialogs | `POST /upload/image` |

---

## 8) Validation Rules Checklist

### General
- email normalized lowercase
- password min length and complexity policy
- string length limits
- sanitize HTML/script input

### Team
- unique team name per academy (or unique with ageGroup)
- valid color integer

### Staff
- unique email per academy (or globally)
- role must be in allowlist
- permissions map complete and boolean

### Player
- unique email
- valid assigned team
- ageRange parse-safe

### Profile
- user can edit self only
- admin profile updates constrained to admin scope

---

## 9) Error Contract (Strict)

All non-2xx responses:
```json
{
  "message": "Human-readable error",
  "code": "OPTIONAL_CODE",
  "details": {}
}
```

Use:
- `400` invalid payload
- `401` token invalid/missing
- `403` permission denied
- `404` entity not found
- `409` conflict (email/name duplicates)
- `422` semantic validation
- `500` unexpected

---

## 10) Implementation Sequence (Backend Team)

1. Middleware foundation
   - JWT auth
   - academy scoping
   - RBAC + permission guard
2. Admin overview endpoint
3. Team CRUD + leads update
4. Staff CRUD + permission update logic
5. Player create/update/delete linked to team
6. Admin profile + generic profile updates
7. File upload service (profile/team logos)
8. Socket event emission on all mutating endpoints
9. Integration tests for Admin module
10. Regression tests for coach/assistant/player dashboard endpoints

---

## 11) Definition of Done (Admin V2)

- Admin can fully operate Home/Teams/Staff/Profile without frontend hacks.
- Staff permission toggles persist correctly and obey dependency logic.
- Team detail actions (add player, assign leads) work with proper validation.
- Profile edits + image upload are stable.
- Socket updates refresh active clients correctly.
- No unauthorized cross-role or cross-academy data access.

---

## 12) Next Version (V3)

After V2 completion:
- Deep contracts for Battle + Strategy execution
- Event timeline model for AI-assisted play orchestration
- Advanced audit trails for admin/staff actions

