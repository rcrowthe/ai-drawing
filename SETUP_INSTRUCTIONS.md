# AI Drawing App - Setup Instructions

## For Non-Developers: How to Run on Your iPad

### Step 1: Open the Project
1. Open `AIDrawing.xcodeproj` in Xcode
2. Wait for Xcode to finish indexing (progress bar at top)

### Step 2: Fix the Account Error
1. Go to **Xcode menu** → **Settings** (or **Preferences** on older Xcode)
2. Click the **Accounts** tab
3. Click the **+** button at bottom left
4. Select **Apple ID**
5. Sign in with your Apple ID (the one you use for iCloud/App Store)
6. Close the Settings window

### Step 3: Fix the Bundle Identifier
1. In the left sidebar, click on **AIDrawing** (the blue project icon at the top)
2. In the main area, select the **aidrawing** target (under TARGETS)
3. Click the **Signing & Capabilities** tab at the top
4. You'll see two errors - we're fixing them now:

   **For "No Accounts" error:**
   - Under **Team**, select your Apple ID from the dropdown

   **For "No profiles" error:**
   - Change the **Bundle Identifier** field
   - Replace `com.ryan.aidrawing.1768867551` with something like:
     - `com.yourname.aidrawing` (replace `yourname` with your actual name, no spaces)
     - Example: `com.john.aidrawing`

5. Check the box **Automatically manage signing** (should already be checked)

### Step 4: Connect Your iPad
1. Connect your iPad to your Mac with a USB cable
2. Unlock your iPad
3. If prompted on iPad, tap **Trust This Computer**
4. In Xcode, at the top near the Play button, you'll see a device selector
5. Click it and select your iPad from the list (it will show the iPad name)

### Step 5: Build and Run
1. Click the Play button (▶︎) at the top left of Xcode
2. Xcode will build the app (this takes 1-2 minutes the first time)
3. The app will install and launch on your iPad automatically

### Step 6: Trust the Developer Certificate (First Time Only)
When you first run the app, your iPad will show an error: "Untrusted Developer"

**To fix this:**
1. On your iPad, go to **Settings** → **General** → **VPN & Device Management**
2. Find your Apple ID under "Developer App"
3. Tap it
4. Tap **Trust "[Your Apple ID]"**
5. Tap **Trust** in the popup
6. Go back to the app and run it again from Xcode

### Step 7: Use the App
The app should now be running on your iPad\! You can:
- Draw with Apple Pencil
- Tap the gear icon ⚙️ to adjust AI settings
- Change colors in settings
- Use the eraser tool
- Toggle AI strokes on/off with the eye icon 👁️

### Troubleshooting

**"Build Failed" errors:**
- Make sure you completed Step 3 (Bundle Identifier changed)
- Make sure your iPad is unlocked
- Try disconnecting and reconnecting the iPad

**App crashes immediately:**
- Check Step 6 - you need to trust the developer certificate
- Try running from Xcode again after trusting

**"No iPad detected":**
- Check USB cable connection
- Unlock your iPad
- Try a different USB port
- Make sure iPad shows "Trust This Computer" popup

**App expires after 7 days:**
- Free Apple IDs can only run apps for 7 days
- After 7 days, just connect iPad and run from Xcode again
- OR: Get an Apple Developer account ($99/year) for 1-year certificates

### Notes
- The app will stay on your iPad for 7 days (free Apple ID) or 1 year (paid developer account)
- After expiration, just rebuild from Xcode to extend
- You don't need to keep Xcode open after the app is installed
- Changes you make to settings/drawings will persist

---

If you still have issues, send a screenshot of the error to Ryan\!
