Realtime Database rules for presence status

Apply these rules in Firebase Console > Realtime Database > Rules, or deploy with Firebase CLI.

Rules (only allow authenticated users to read/write their own status):

```
{
  "rules": {
    "status": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

Notes:
- This allows any authenticated user to read all `status/$uid` nodes. If you want to restrict reads to only participants, you need a more advanced rule that checks chat membership in Firestore or another mapping.
- `onDisconnect()` behavior will still work with these rules.

Enable Realtime Database:
1. Open Firebase Console: https://console.firebase.google.com
2. Select your project
3. In the left menu choose "Realtime Database"
4. Click "Create Database" and choose the location
5. Choose START IN LOCKED MODE (recommended) or Test mode during development
6. In the Rules tab, paste the rules above and publish

Deploy with Firebase CLI (optional):
1. Install CLI: `npm install -g firebase-tools`
2. Login and init in your project folder:

```bash
firebase login
firebase init database
```

3. Put the rules in `database.rules.json` and deploy:

```bash
firebase deploy --only database
```

Security tip:
- Consider restricting `.read` to authenticated users only if you want presence visible only to logged-in clients, or implement server-side checks to limit who can read whose status.
