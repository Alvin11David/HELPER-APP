# Complete Referral Bonus System Implementation

## Overview

This document describes the complete implementation of the referral bonus system for the Helper App. The system allows existing users to share their referral codes with new users, and both parties receive bonuses when the new user completes sign-up with OTP verification.

---

## System Architecture

### User Flow

```
1. NEW USER (Sign Up Flow)
   ├─ ReferralCodeScreen
   │  ├─ User enters referral code (10-digit code like "UG789EC598")
   │  ├─ System validates code exists in Sign Up.referralCode
   │  ├─ System returns code to PhoneNumberEmailAddressScreen
   │  └─ User pops with referral code
   │
   ├─ PhoneNumberEmailAddressScreen
   │  ├─ User enters phone/email and full name
   │  ├─ Referral code is stored in _referralCode state
   │  ├─ User receives and enters OTP
   │  └─ Navigation to OTPVerificationScreen with referralCode parameter
   │
   └─ OTPVerificationScreen
      ├─ OTP verified ✓
      ├─ User profile created in Sign Up collection with referralCode
      ├─ applyReferralRewards() Cloud Function is called
      │  ├─ Finds referrer by referralCode
      │  ├─ Reads dynamic bonuses from System Settings.default
      │  ├─ Increments referrer balance: +referrerBonus (600)
      │  ├─ Increments referred user balance: +referralBonusUG (500)
      │  └─ Creates Referred Users/{referredUserId} entry with full details
      └─ Navigation to next screen (RoleSelectionScreen/RegistrationPaymentScreen)
```

---

## Database Collections

### 1. **Sign Up Collection**

```firestore
Sign Up/{userId}
├── uid: string (user ID)
├── email: string
├── phoneNumber: string
├── fullName: string
├── referralCode: string (10-digit code, e.g., "UG789EC598")
├── amount: number (balance)
├── provider: string ("email" | "phone")
├── verified: boolean (true)
├── createdAt: timestamp
├── updatedAt: timestamp
└── ... other fields
```

### 2. **System Settings Collection**

```firestore
System Settings/default
├── referralBonusUG: number (500) ← Amount for newly referred user
├── referrerBonus: number (600)   ← Amount for user who shared code
└── ... other settings
```

### 3. **Referred Users Collection** (Created by Cloud Function)

```firestore
Referred Users/{referredUserId}
├── referredUserId: string (UID of new user)
├── referrerUserId: string (UID of existing user who shared code)
├── referralCode: string (the code used)
├── referredPhone: string (new user's phone)
├── referredEmail: string (new user's email)
├── referredFullName: string (new user's full name)
├── referrerPhone: string (existing user's phone)
├── referrerEmail: string (existing user's email)
├── referrerFullName: string (existing user's full name)
├── referrerReward: number (amount given to referrer)
├── referredReward: number (amount given to referred user)
├── rewarded: boolean (true = rewards applied)
└── rewardedAt: timestamp
```

---

## Cloud Functions Implementation

### `applyReferralRewards` (Callable Function)

**Location:** `helper/functions/src/index.ts`

**Parameters:**

```typescript
{
  referredUserId: string; // UID of new user completing signup
  referralCode: string; // Code entered by new user
}
```

**Response:**

```typescript
{
  success: boolean;
  message: string;
  referrerBonus?: number;
  referredBonus?: number;
}
```

**Logic Flow:**

1. ✅ Validate inputs (referredUserId, referralCode not empty)
2. ✅ Check if referral already rewarded (prevent duplicate rewards)
3. ✅ Read dynamic bonus amounts from `System Settings.default`
   - `referralBonusUG` → amount for referred user
   - `referrerBonus` → amount for referrer
4. ✅ Query `Sign Up` collection for user with matching referralCode
5. ✅ Verify referrer exists and referralCode is valid
6. ✅ Prevent self-referrals (referrer ≠ referred user)
7. ✅ Use Firestore **transaction** to atomically:
   - Increment referrer's `Sign Up.amount` by referrerBonus
   - Increment referred user's `Sign Up.amount` by referredBonus
   - Create `Referred Users/{referredUserId}` entry with full details
8. ✅ Log success with amounts awarded
9. ✅ Return success response with amounts

**Key Features:**

- **Atomic Transactions:** All operations succeed or all fail (no partial updates)
- **Duplicate Prevention:** Checks if reward already applied
- **Dynamic Amounts:** Reads from System Settings collection
- **Error Handling:** Proper error messages for invalid codes, duplicates, self-referrals

---

## Flutter Implementation

### 1. **Amount.dart Service**

**File:** `helper/lib/Amount.dart`

**New Method:**

```dart
static Future<Map<String, dynamic>> applyReferralRewards({
  required String referredUserId,
  required String referralCode,
})
```

**Purpose:**

- Calls the Cloud Function `applyReferralRewards`
- Returns success/failure with bonus amounts
- Silently fails if no referral code provided (doesn't break signup)

**Usage:**

```dart
final result = await AmountService.applyReferralRewards(
  referredUserId: user.uid,
  referralCode: referralCode,
);

if (result['success'] == true) {
  // Rewards applied
  print('Referrer bonus: ${result['referrerBonus']}');
  print('Referred bonus: ${result['referredBonus']}');
}
```

---

### 2. **Referral_Code_Screen.dart**

**File:** `helper/lib/Auth/Referral_Code_Screen.dart`

**Changes:**

1. Removed requirement for user to be logged in
2. Simplified validation to just check if code exists
3. Changed navigation from pushing next screen to popping with result

**Flow:**

```dart
void _onVerify() async {
  // 1. Validate code format
  // 2. Query Sign Up.referralCode to verify code exists
  // 3. Pop with code: Navigator.of(context).pop(code)
}

void _onSkip() {
  // Pop with empty string if user skips
  Navigator.of(context).pop('')
}
```

**Result Type:** `String` (the referral code or empty string)

---

### 3. **Phone*Number*&\_Email_Address_Screen.dart**

**File:** `helper/lib/Auth/Phone_Number_&_Email_Address_Screen.dart`

**Changes:**

1. Added `_referralCode` state variable to store code
2. Added `didChangeDependencies()` to capture code from route arguments (if needed)
3. Updated "Use Referral Code" button to:
   - Navigate to ReferralCodeScreen
   - Capture returned code
   - Update `_referralCode` state
   - Show confirmation message
4. Pass `_referralCode` to OTPVerificationScreen constructor

**Code Example:**

```dart
GestureDetector(
  onTap: () async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const ReferralCodeScreen(),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _referralCode = result);
      // Show confirmation
    }
  },
  child: Text('Use Referral Code'),
),
```

**Navigation to OTP:**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => OTPVerificationScreen(
      isPhoneVerification: true,
      emailOrPhone: phoneNumber,
      verificationId: '',
      fullName: fullName,
      password: password,
      referralCode: _referralCode, // ← Pass the code
    ),
  ),
);
```

---

### 4. **OTP_Verification_Screen.dart**

**File:** `helper/lib/Auth/OTP_Verification_Screen.dart`

**Changes:**

1. Added import: `import 'package:helper/Amount.dart';`
2. Added `_applyReferralRewards()` helper method
3. Call this method after `_writeUserProfileDoc()` succeeds

**\_applyReferralRewards Method:**

```dart
Future<void> _applyReferralRewards(
  String referredUserId,
  String referralCode,
) async {
  if (referralCode.isEmpty) return; // Skip if no code

  try {
    final result = await AmountService.applyReferralRewards(
      referredUserId: referredUserId,
      referralCode: referralCode,
    );

    if (result['success'] == true) {
      // Silently log - don't overwhelm UI with snackbars
      // User's balance will be updated automatically
    }
  } catch (e) {
    // Silently fail - referral rewards should not block signup
    // User signup still completes successfully
  }
}
```

**Integration Points (3 locations):**

1. **Custom OTP with Phone:**

```dart
await _writeUserProfileDoc(...);

// Apply referral rewards if code provided
if (widget.referralCode.isNotEmpty) {
  await _applyReferralRewards(user.uid, widget.referralCode);
}

await _cleanupOTPDoc(key);
```

2. **Firebase Auth with Phone:**

```dart
await _writeUserProfileDoc(...);

if (widget.referralCode.isNotEmpty) {
  await _applyReferralRewards(user.uid, widget.referralCode);
}
```

3. **Email Verification:**

```dart
await _writeUserProfileDoc(...);

if (widget.referralCode.isNotEmpty) {
  await _applyReferralRewards(user.uid, widget.referralCode);
}

await _cleanupOTPDoc(email);
```

---

## Complete User Journey Example

### Scenario: Alice invites Bob

**Step 1: Bob visits Referral Code Screen**

- Sees input field for 10-digit referral code
- His friend Alice gives him her code: `UG789EC598`
- Bob enters code and clicks "Verify"
- System validates code exists in Sign Up.referralCode ✓
- Bob's screen pops with code returned

**Step 2: Bob enters Phone/Email**

- Returns to Phone*Number*&\_Email_Address_Screen
- Code `UG789EC598` is stored in `_referralCode` state
- Bob fills in: phone number, full name, email
- Receives OTP via SMS/Email
- Clicks "Continue" with referral code ready to pass

**Step 3: Bob verifies OTP**

- OTP validated ✓
- Sign Up document created with `referralCode: "UG789EC598"`
- Cloud Function `applyReferralRewards` is called:
  ```
  referredUserId: "bob_uid"
  referralCode: "UG789EC598"
  ```

**Step 4: Cloud Function Processes Reward**

- Finds Alice in Sign Up where `referralCode == "UG789EC598"`
- Reads System Settings.default:
  - `referrerBonus`: 600
  - `referralBonusUG`: 500
- Uses transaction to atomically:
  1. Increment Alice's amount: `+600` ← Alice is referrer
  2. Increment Bob's amount: `+500` ← Bob is referred user
  3. Create Referred Users/bob_uid:
     ```
     referredUserId: "bob_uid"
     referrerUserId: "alice_uid"
     referralCode: "UG789EC598"
     referredPhone: "+256 XXXXXXXXX" (Bob's phone)
     referredEmail: "bob@email.com"
     referredFullName: "Bob"
     referrerPhone: "+256 YYYYYYYYY" (Alice's phone)
     referrerEmail: "alice@email.com"
     referrerFullName: "Alice"
     referrerReward: 600
     referredReward: 500
     rewarded: true
     rewardedAt: <server timestamp>
     ```

**Step 5: Rewards Applied**

- ✅ Alice's wallet balance: `+600 UGX`
- ✅ Bob's wallet balance: `+500 UGX`
- Both users can see updated balance in their wallet

---

## Error Handling

### Referral Code Validation Errors

| Error                       | Cause                               | Resolution                   |
| --------------------------- | ----------------------------------- | ---------------------------- |
| "Invalid referral code"     | Code doesn't exist in Sign Up       | Ask user to verify code      |
| "Cannot refer yourself"     | Referrer ≠ Referred user (same UID) | Show in Cloud Function only  |
| "Referral already used"     | User already has referral reward    | Show in Cloud Function only  |
| "System Settings not found" | Missing System Settings.default     | Admin must create collection |

### Silent Failures (Don't Block Signup)

- Referral code passed but no match found
- Code is invalid
- Duplicate referral
- Cloud Function timeout

In these cases:

- User signup completes successfully
- User receives their own generated referral code
- Referral bonus is not applied (non-fatal)
- Errors logged server-side for debugging

---

## Data Consistency Guarantees

### Transaction Atomicity

The Cloud Function uses Firestore transactions to ensure:

- ✅ All operations succeed together OR all fail together
- ✅ No partial state updates
- ✅ Balance increments are safe and correct
- ✅ Referred Users entry is created with balance updates

### Duplicate Prevention

- ✅ Check if `Referred Users/{referredUserId}` already exists
- ✅ If exists and `rewarded == true`, reject duplicate
- ✅ Prevents multiple reward applications from network retries

---

## Configuration

### System Settings Document

Create in Firestore:

```firestore
System Settings
└── default
    ├── referralBonusUG: 500 (number)
    └── referrerBonus: 600 (number)
```

### Environment Variables (Cloud Functions)

No additional environment variables needed. Function reads from Firestore collections.

---

## Testing Checklist

- [ ] New user can enter valid referral code
- [ ] Invalid code shows error message
- [ ] Valid code is passed through sign-up flow
- [ ] OTP verification triggers applyReferralRewards
- [ ] Referrer receives 600 UGX bonus
- [ ] Referred user receives 500 UGX bonus
- [ ] Referred Users document is created with all fields
- [ ] Duplicate referral is rejected
- [ ] Self-referral is rejected
- [ ] Balance updates reflected in UI
- [ ] Skipping referral code allows normal signup
- [ ] Cloud Function handles network errors gracefully
- [ ] Transaction rollback works on error

---

## Important Notes

1. **Referral Code Generation:**
   - Existing users get auto-generated 10-character codes
   - Format: "UG" + 3 digits + 2 letters + 3 digits
   - Example: "UG789EC598"

2. **Timing of Rewards:**
   - Rewards applied only after OTP verification
   - Rewards applied before user completes full registration
   - This allows new user to see bonus immediately

3. **Server-Side Only:**
   - All balance updates handled by server (Cloud Functions + webhooks)
   - No client-side balance increment
   - User interface reads balance from Sign Up.amount field

4. **Error Resilience:**
   - Referral rewards should never block user signup
   - Non-critical failure is acceptable
   - Critical transactions (balance updates) use atomic operations

---

## Related Configurations

- **Payment Webhook** (`paymentWebhook`): Updates balance for deposits
- **Master Webhook** (`masterWebhook`): Handles deposit and withdrawal statuses
- **Amount Service** (`AmountService`): Centralized balance logic
- **Sign Up Collection**: User profiles with referral codes and balances
