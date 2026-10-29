# BallChart — App Store upload

Current app version in `pubspec.yaml`: **1.1.2+12**  
Bundle ID: `com.devsynx.ballchart`  
Xcode team: **DEVSYNX ( PRIVATE ) LIMITED** (`T42TML879N`)  
Display name: **BallChart**

You need a Mac, Xcode, an [Apple Developer](https://developer.apple.com) account ($99/year), and [App Store Connect](https://appstoreconnect.apple.com).

---

## After transferring the app to a new team (important)

If BallChart was moved from **Syed Hassan Ali**’s team to **Wassim Mohsen**’s team, Xcode errors like these are normal until the **new** team is set up:

- *“Your team has no devices from which to generate a provisioning profile”*
- *“No profiles for 'com.devsynx.courtiq' were found”*
- *“Communication with Apple failed”*

### A. Finish the transfer in Apple’s portals

1. **Old owner (Hassan):** App Store Connect → app → **App Information** → **Transfer App** → complete transfer to Wassim’s team.
2. **New owner (Wassim):** Accept the transfer email / notification in App Store Connect.
3. **Wassim:** Sign in to [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles**:
   - **Identifiers** → confirm `com.devsynx.courtiq` exists (it should move with the app).
   - If it is **missing**, click **+** → App IDs → register `com.devsynx.courtiq` (same bundle ID as before).

### B. Fix signing in Xcode (Wassim’s Mac)

1. **Xcode → Settings → Accounts** → add Wassim’s Apple ID → select team **Wassim Mohsen**.
2. Select the team row → **Manage Certificates** → **+** → create **Apple Distribution** (for App Store upload).
3. Open `ios/Runner.xcworkspace` → **Runner** target → **Signing & Capabilities**:
   - Team: **Wassim Mohsen**
   - Bundle Identifier: `com.devsynx.courtiq`
   - **Automatically manage signing**: ON
4. Plug in an iPhone (or any iOS device) with USB → unlock → tap **Trust** → in Xcode pick the device once. That registers it and fixes the “no devices” development profile error.
5. Back in **Accounts**, select Wassim’s team → **Download Manual Profiles** (or click **Try Again** on the signing error).
6. **Product → Clean Build Folder**, then archive again.

### C. Upload build (preferred after team change)

From the project root on Wassim’s Mac:

```bash
cd /Users/hassan/Downloads/HassanShabir/ballchart
flutter clean && flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release
```

Upload `build/ios/ipa/*.ipa` with **Transporter** (Mac App Store app).  
You do **not** need a development profile on a phone for this—only a valid **Distribution** cert on Wassim’s team.

### D. If it still fails

| Problem | Fix |
|--------|-----|
| Bundle ID owned by old team | Transfer must be **completed**; old team cannot keep the same App Store app + bundle on two teams. |
| Wrong Apple ID in Xcode | Only Wassim (or a user with **Admin** on his team) should sign. |
| “No profiles found” | Developer portal → Profiles → **+** → **App Store** → app `com.devsynx.courtiq` → select Distribution cert. Or let Xcode auto-manage after step B.4. |
| App not visible in Connect | Log into App Store Connect with Wassim’s account; app should appear under **Apps** after transfer acceptance. |

**Do not** change the bundle ID after transfer unless you intend to publish a **new** App Store listing.

---

## 1. One-time Apple setup

1. Open [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App**.
2. Fill:
   - Platform: iOS
   - Name: BallChart
   - Primary language: English
   - Bundle ID: `com.devsynx.courtiq` (create it first in [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) if missing)
   - SKU: `ballchart` (any unique string; cannot change later)
3. In Xcode: **Xcode → Settings → Accounts** → add Wassim’s Apple ID → select team **Wassim Mohsen** (`Y5F8D447P5`).
4. Open `ios/Runner.xcworkspace` (not `.xcodeproj`) → select **Runner** → **Signing & Capabilities**:
   - Team: your team
   - Bundle Identifier: `com.devsynx.courtiq`
   - Automatically manage signing: on

---

## 2. Bump version before each upload

Edit `pubspec.yaml`:

```yaml
version: 1.1.1+11
```

- `1.1.1` = user-facing version (must be **higher** than the last App Store version).
- `11` = build number (`+` value). Must be **higher** than any build already uploaded, including TestFlight.

Then:

```bash
cd /Users/hassan/Downloads/HassanShabir/ballchart
flutter clean
flutter pub get
cd ios && pod install && cd ..
```

---

## 3. Build the IPA

From the project root:

```bash
flutter build ipa --release
```

Output:

`build/ios/ipa/ballchart.ipa`  
(or `BallChart.ipa` depending on Flutter)

If signing fails, open `ios/Runner.xcworkspace` in Xcode, pick a real iPhone or **Any iOS Device (arm64)**, Product → Archive, and upload from Organizer (step 4b).

---

## 4. Upload to App Store Connect

### Option A — Transporter (simplest)

1. Install **Transporter** from the Mac App Store.
2. Sign in with the same Apple ID.
3. Drag `build/ios/ipa/*.ipa` into Transporter → **Deliver**.

### Option B — Xcode Organizer

```bash
open ios/Runner.xcworkspace
```

1. Product → Destination → **Any iOS Device (arm64)**
2. Product → **Archive**
3. When Organizer opens: **Distribute App** → **App Store Connect** → **Upload**
4. Keep default options (upload symbols, manage version automatically).

Wait 5–15 minutes. Email: “Finished processing”.

---

## 5. Submit for review

In [App Store Connect](https://appstoreconnect.apple.com) → BallChart:

1. **TestFlight** (optional): add internal testers, install via TestFlight app.
2. **App Store** tab → this version (1.1.1):
   - Select the build you just uploaded (`1.1.1 (11)`)
   - Screenshots (6.7" iPhone required; plus 6.5"/iPad if you support iPad)
   - Description, keywords, support URL, privacy policy URL
   - Age rating
   - **App Privacy**: declare data (account, photos, mic, etc.)
   - Contact info for Apple review
3. **Add for Review** → **Submit to App Store**

Review usually takes 24–48 hours.

Encryption question: BallChart only uses HTTPS. Answer **No** to “uses non-exempt encryption” if Apple asks, or add `ITSAppUsesNonExemptEncryption = false` later if you want to skip that prompt.

---

## 6. What Apple reviewers will try

Prepare a **demo login** in Review Notes, for example:

- Admin / coach / player emails + passwords
- Note that the backend is live: `https://ballchart-production.up.railway.app`
- Camera / mic / photos: used for profile pictures, voice notes, and tactics

If login is blocked, the app will be rejected.

---

## Checklist

- [ ] `pubspec.yaml` version higher than last live build
- [ ] `flutter build ipa --release` succeeds
- [ ] IPA uploaded (Transporter or Xcode)
- [ ] Build appears in App Store Connect → TestFlight
- [ ] Screenshots + privacy policy + demo account
- [ ] Submit for review
