# Referral System - Changes Summary

## Files Modified

### 1. **helper/functions/src/index.ts**

- ✅ Added `applyReferralRewards` Cloud Function (callable)
- Location: End of file, after `requestCardSession` function
- Function reads dynamic bonuses from `System Settings.default`
- Creates `Referred Users/{referredUserId}` entry with full user details
- Uses transactions for atomic balance updates

### 2. **helper/lib/Amount.dart**

- ✅ Added import: `import 'package:cloud_functions/cloud_functions.dart';`
- ✅ Added `FirebaseFunctions` instance variable
- ✅ Added `applyReferralRewards()` static method
  - Calls Cloud Function with referredUserId and referralCode
  - Returns result map with success status and bonus amounts
  - Handles errors silently if no referral code provided

### 3. **helper/lib/Auth/Referral_Code_Screen.dart**

- ✅ Simplified `_onVerify()` method:
  - Removed requirement for user to be logged in
  - Removed Firebase Auth check
  - Removed Referred Users document creation (moved to Cloud Function)
  - Now only validates code exists in Sign Up collection
  - Returns code on success: `Navigator.pop(code)`
- ✅ Updated `_onSkip()` method:
  - Returns empty string to allow normal signup
  - Changed from TODO to `Navigator.pop('')`

### 4. **helper/lib/Auth/Phone*Number*&\_Email_Address_Screen.dart**

- ✅ Added state variable: `String _referralCode = '';`
- ✅ Added `didChangeDependencies()` override to capture code from route arguments
- ✅ Updated "Use Referral Code" button tap handler:
  - Changed from simple push to `Navigator.push<String>` with result capture
  - Captures returned code and updates `_referralCode` state
  - Shows confirmation message to user
- ✅ Updated first OTP navigation (phone, custom OTP):
  - Changed `referralCode: ''` to `referralCode: _referralCode`
- ✅ Updated second OTP navigation (phone, Firebase Auth):
  - Already had this parameter, now passes actual value
- ✅ Updated third OTP navigation (email):
  - Changed `referralCode: ''` to `referralCode: _referralCode`

### 5. **helper/lib/Auth/OTP_Verification_Screen.dart**

- ✅ Added import: `import 'package:helper/Amount.dart';`
- ✅ Added `_applyReferralRewards()` helper method:
  - Calls `AmountService.applyReferralRewards()`
  - Silently handles success/failure
  - Doesn't block user navigation
  - Works with empty referral code (skips silently)
- ✅ Added calls to `_applyReferralRewards()` in 3 locations (after `_writeUserProfileDoc()`):
  1. Phone verification with custom OTP
  2. Phone verification with Firebase Auth
  3. Email verification
  - All check if `widget.referralCode.isNotEmpty` before calling

---

## Cloud Function Implementation Details

### applyReferralRewards Function Structure

```typescript
export const applyReferralRewards = onCall(
  { maxInstances: 5 },
  async (request) => {
    // 1. Validate inputs
    // 2. Check for duplicate rewards
    // 3. Read System Settings.default for:
    //    - referralBonusUG (default: 500)
    //    - referrerBonus (default: 600)
    // 4. Find referrer by referralCode
    // 5. Get referred user data
    // 6. Run transaction:
    //    - Increment referrer amount by referrerBonus
    //    - Increment referred amount by referralBonusUG
    //    - Create Referred Users/{referredUserId} entry
    // 7. Return success with amounts
  },
);
```

---

## Database Schema

### System Settings Collection Structure

```firestore
System Settings/default
├── referralBonusUG: 500 (number)
└── referrerBonus: 600 (number)
```

### Referred Users Collection (Created by Cloud Function)

```firestore
Referred Users/{referredUserId}
├── referredUserId: string
├── referrerUserId: string
├── referralCode: string
├── referredPhone: string
├── referredEmail: string
├── referredFullName: string
├── referrerPhone: string
├── referrerEmail: string
├── referrerFullName: string
├── referrerReward: number (600)
├── referredReward: number (500)
├── rewarded: boolean (true)
└── rewardedAt: timestamp
```

---

## Data Flow Summary

```
User selects "Use Referral Code"
    ↓
ReferralCodeScreen.dart
  ├─ User enters 10-digit code (e.g., "UG789EC598")
  ├─ Validates code exists in Sign Up.referralCode
  └─ Returns code via pop()
    ↓
Phone_Number_&_Email_Address_Screen.dart
  ├─ Captures returned code in _referralCode
  ├─ User enters phone/email and full name
  ├─ Sends OTP and receives code from user
  └─ Navigates to OTPVerificationScreen with referralCode
    ↓
OTP_Verification_Screen.dart
  ├─ OTP verified ✓
  ├─ User profile created in Sign Up collection
  ├─ Calls _applyReferralRewards(userId, referralCode)
  │  └─ Calls AmountService.applyReferralRewards()
  │     └─ Calls Cloud Function 'applyReferralRewards'
  └─ Navigates to RoleSelectionScreen/RegistrationPaymentScreen
    ↓
Cloud Function (applyReferralRewards)
  ├─ Finds referrer by looking up Sign Up.referralCode
  ├─ Reads System Settings.default for bonus amounts
  ├─ Uses transaction to atomically:
  │  ├─ Increment referrer Sign Up.amount by referrerBonus
  │  ├─ Increment referred Sign Up.amount by referralBonusUG
  │  └─ Create Referred Users document with full details
  └─ Returns success response
    ↓
Both users see updated balance in wallet
  ├─ Referrer: +600 UGX
  └─ Referred: +500 UGX
```

---

## Key Design Decisions

1. **No Client-Side Logic:** All balance updates done server-side only
2. **Non-Blocking Errors:** Referral failures don't prevent signup
3. **Dynamic Configuration:** Bonus amounts from System Settings (easily changeable)
4. **Transaction Safety:** Atomic operations prevent partial state
5. **Duplicate Prevention:** Check before applying reward
6. **Self-Referral Prevention:** UID comparison in Cloud Function
7. **Silent Success:** Don't overwhelm user with excessive notifications
8. **Full Traceability:** Referred Users collection stores all user details

---

## Environment Prerequisites

### Firestore Collections Required

- ✅ `Sign Up` (existing)
- ✅ `System Settings/default` (must create with bonuses)
- ✅ `Referred Users` (created automatically by Cloud Function)

### Cloud Function Deployment

```bash
cd helper/functions
npm install
firebase deploy --only functions:applyReferralRewards
```

---

## Testing Commands

### 1. Test Cloud Function Directly (Firebase Console)

```javascript
// Call with valid referral code
{
  "referredUserId": "test-user-123",
  "referralCode": "UG789EC598"
}

// Expected response
{
  "success": true,
  "message": "Referral rewards applied successfully",
  "referrerBonus": 600,
  "referredBonus": 500
}
```

### 2. Test Invalid Code

```javascript
{
  "referredUserId": "test-user-123",
  "referralCode": "INVALID"
}

// Expected response
{
  "success": false,
  "message": "Referral code \"INVALID\" not found"
}
```

### 3. Verify Database State

After successful reward:

- ✅ Check Sign Up/{referrerId}.amount increased by 600
- ✅ Check Sign Up/{referredId}.amount increased by 500
- ✅ Check Referred Users/{referredId} document created
- ✅ Check Referred Users/{referredId}.rewarded = true

---

## Rollback Plan

If issues occur:

1. **Cloud Function Error:**
   - Cloud Function will fail safely, user signup still completes
   - Admin can manually apply rewards later using same logic

2. **Balance Misalignment:**
   - Run `AmountService.recalcBalance()` to recalculate from Payment Data + Withdrawals + Referred Users

3. **Duplicate Rewards:**
   - Cloud Function prevents duplicates via `rewarded` flag
   - If flag is wrong, update Referred Users document directly

---

## Monitoring

### Logs to Watch

1. Cloud Function logs for `applyReferralRewards` success/failure
2. Firestore audit logs for Referred Users creation
3. User balance changes in Sign Up collection

### Metrics to Track

- New users signing up WITH referral code
- % of codes that successfully apply rewards
- Average reward amounts distributed
- Duplicate reward attempts blocked
