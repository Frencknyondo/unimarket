# Push Notifications Setup Guide

## Overview

The push notification system has been implemented with the following components:

1. **Client-side (Flutter)**:
   - `push_notifications_service.dart` - Handles FCM setup and token management
   - `fcm_push_service.dart` - Queues push notifications to be sent
   - `notifications_service.dart` - Creates notifications and triggers push delivery

2. **Server-side (Firebase Cloud Functions)**:
   - `functions/src/push-notifications.ts` - Cloud Function that sends actual FCM payloads

## Flow Diagram

```
1. User enables push notifications in app
   ↓
2. PushNotificationService requests permission (iOS) and retrieves FCM token
   ↓
3. FCM token stored in Firestore: unimarket_db/{userId}/fcmToken
   ↓
4. When notification is created via NotificationsService.createNotification():
   - Notification document created in 'notifications' collection
   - Push delivery queued via FCMPushService.sendPushToUser()
   ↓
5. FCMPushService creates document in 'push_queue' collection with:
   - userId, fcmToken, title, message, data payload
   ↓
6. Cloud Function listens to push_queue and sends FCM payload
   ↓
7. FCM delivers notification to device
   ↓
8. Cloud Function marks push_queue document as 'sent' with timestamp
```

## Setup Instructions

### Step 1: Deploy Cloud Function

1. Navigate to your Firebase project's functions directory (or create it):
   ```bash
   cd unimarket/functions
   npm install firebase-functions firebase-admin
   ```

2. Copy the content from `functions/src/push-notifications.ts` and ensure it's in your functions/src directory.

3. Update `functions/tsconfig.json` to include TypeScript support if needed.

4. Deploy the function:
   ```bash
   firebase deploy --only functions
   ```

   Expected output:
   ```
   ✔  Deploy complete!

   Function URL: https://REGION-PROJECT_ID.cloudfunctions.net/sendPushNotification
   ```

### Step 2: Configure Firestore Security Rules

Update your `firestore.rules` to allow the Cloud Function to update push_queue documents:

```firestore
match /push_queue/{document=**} {
  // Only the Cloud Function (via service account) can write to push_queue
  allow read, write: if request.auth == null && request.auth.uid == 'CLOUD_FUNCTION_UID';
  // Or use a simpler approach: allow Cloud Functions (authenticated via service account)
  allow write: if request.auth == null;
}
```

Alternatively, you can set the security rules to allow writing from the backend service:

```firestore
match /push_queue/{document=**} {
  // Allow creation from the app
  allow create: if request.auth != null;
  // Allow Cloud Functions to manage these documents
  allow read, update: if request.auth == null;
}
```

### Step 3: Enable Cloud Messaging API

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to APIs & Services or Cloud Messaging
4. Ensure "Firebase Cloud Messaging API" is enabled

### Step 4: Configure Notification Channels (Android)

In Android, notification channels control how notifications are displayed. This is already handled in the Flutter app via FirebaseMessaging configuration.

### Step 5: Test the Flow

#### Test from Dart App:

```dart
import 'package:unimarket/services/notifications_service.dart';

final notificationsService = NotificationsService();

// Create a test notification
await notificationsService.createNotification(
  userId: 'test-user-id',
  title: 'Test Push',
  message: 'This is a test push notification',
  type: 'test',
  orderId: '',
);

// The push will be automatically sent if the user has notifications enabled
// and has a saved FCM token
```

#### Test from Firebase Console:

1. Go to Cloud Functions in Firebase Console
2. Find `sendPushNotification` function
3. Click on Testing tab
4. Manually trigger with sample data:

```json
{
  "userId": "test-user-id",
  "fcmToken": "your_fcm_token_here",
  "title": "Test Title",
  "message": "Test Message",
  "data": {
    "type": "test",
    "orderId": "order-123"
  }
}
```

## File Structure

```
unimarket/
├── lib/
│   ├── services/
│   │   ├── push_notifications_service.dart      # FCM setup
│   │   ├── fcm_push_service.dart               # Push queueing
│   │   └── notifications_service.dart          # Notification CRUD + push trigger
│   ├── main.dart                                # FCM foreground handler
│   └── profile.dart                             # Push notification toggle
├── functions/
│   ├── src/
│   │   └── push-notifications.ts               # Cloud Functions
│   ├── package.json
│   ├── tsconfig.json
│   └── .eslintrc.js
└── firestore.rules                              # Firestore security rules
```

## Firestore Collections

### `push_queue` Collection

Documents created when a push notification needs to be sent:

```json
{
  "userId": "user-id",
  "fcmToken": "device-fcm-token",
  "title": "Order Confirmation",
  "message": "Your order has been confirmed",
  "data": {
    "type": "order",
    "orderId": "order-123"
  },
  "createdAt": "2024-01-01T12:00:00Z",
  "sent": false,
  "sentAt": null,
  "error": null,
  "response": null
}
```

After successful sending:

```json
{
  // ... same as above, but:
  "sent": true,
  "sentAt": "2024-01-01T12:00:05Z",
  "response": "message-id-from-fcm",
  "error": null
}
```

### `notifications` Collection

In-app notifications (separate from push notifications):

```json
{
  "userId": "user-id",
  "title": "Order Update",
  "message": "Your order is being prepared",
  "type": "order",
  "orderId": "order-123",
  "isRead": false,
  "createdAt": "2024-01-01T12:00:00Z"
}
```

### `unimarket_db/{userId}` Document Fields (for push)

```json
{
  "fcmToken": "device-fcm-token-string",
  "notificationsEnabled": true,
  "lastFcmTokenUpdate": "2024-01-01T12:00:00Z"
}
```

## Troubleshooting

### Cloud Function Not Triggering

- Check Firebase Console → Cloud Functions → Logs for errors
- Ensure `push_queue` collection has write permissions from the app
- Verify Cloud Messaging API is enabled

### FCM Tokens Not Being Saved

- Check PushNotificationService in profile.dart - ensure permission was granted
- Verify Firestore write permissions for `unimarket_db` collection
- Check browser console (web) or logcat (Android) for permission errors

### Push Notifications Not Received

- Ensure user has `notificationsEnabled == true` in Firestore
- Verify FCM token exists and hasn't expired (tokens can expire after ~60 days)
- Check Cloud Function logs for delivery errors
- For Android: Ensure notification channel is configured properly

### Testing Without Real Device

- Use Firebase Console to send test messages
- Use Flutter web for testing in browser DevTools
- Android emulator can receive FCM if Google Play Services are installed

## Security Considerations

1. **Data Validation**: Cloud Function validates all fields before sending
2. **Token Verification**: Only sends to tokens saved by the user
3. **Rate Limiting**: Implement rate limiting in production
4. **User Opt-out**: Respects `notificationsEnabled` flag
5. **Error Logging**: Failed pushes are logged in Firestore for debugging

## Performance Optimization

The current implementation:
- Queues pushes asynchronously (doesn't block notification creation)
- Batches notifications for multiple users
- Includes automatic retry for failed pushes (via Cloud Function)
- Cleans up old push_queue documents after 7 days

## Next Steps

1. Deploy Cloud Functions
2. Test push delivery end-to-end
3. Monitor Cloud Function logs for issues
4. Set up alerts for high error rates
5. Implement push notification analytics

## References

- [Firebase Messaging Documentation](https://firebase.google.com/docs/messaging)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging)
