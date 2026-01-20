# Detailed Xcode Project Setup Instructions

## Part 1: Create the Xcode Project (10 minutes)

### Step 1: Launch Xcode
1. Open **Spotlight** (Cmd + Space)
2. Type "Xcode" and press Enter
3. Wait for Xcode to launch

### Step 2: Create New Project
1. You'll see the Xcode welcome screen
2. Click **"Create New Project"** (big blue button)
   - OR use menu: **File → New → Project** (Shift + Cmd + N)

### Step 3: Choose Template
1. In the template chooser window:
   - **Top tabs**: Click **"iOS"** (should be selected by default)
   - **Template options**: Scroll and click **"App"** (blue icon with squares)
2. Click **"Next"** button (bottom right)

### Step 4: Configure Project Settings

**IMPORTANT: Fill these in EXACTLY:**

```
Product Name:                AIDrawing
Team:                        [Select your Apple Developer team]
Organization Identifier:     com.yourname (or use your existing identifier)
Bundle Identifier:           [Auto-fills as com.yourname.AIDrawing]
Interface:                   SwiftUI ⚠️ MUST be SwiftUI, not Storyboard
Language:                    Swift ⚠️ MUST be Swift
Storage:                     None (leave unchecked)
Include Tests:               ☑️ Checked (optional but recommended)
```

3. Click **"Next"** button

### Step 5: Choose Save Location

**CRITICAL - This is where errors happen:**

1. In the file browser that appears:
   - Navigate to: `/Users/ryan/ai-drawing`
   - **DO NOT go into the AIDrawing subfolder**
   - You should see: README.md, AIDrawing folder, .git folder
2. **UNCHECK** "Create Git repository on my Mac" (we already have one)
3. Click **"Create"** button

**What Xcode will do:**
- Creates `AIDrawing.xcodeproj` inside `/Users/ryan/ai-drawing/AIDrawing/`
- Creates default files (we'll delete these and add ours)

### Step 6: Verify Project Created

After clicking Create, Xcode will open the project. You should see:
- Left side: **Project Navigator** with "AIDrawing" folder
- Center: Project settings with General/Signing/etc tabs
- Right side: Inspector panel

**Location verification:**
The project is at: `/Users/ryan/ai-drawing/AIDrawing/AIDrawing.xcodeproj`

---

## Part 2: Configure Project Settings (5 minutes)

### Step 1: Select the Project
1. In **Project Navigator** (left panel), click the **blue "AIDrawing" icon** at the very top
2. In the center, you'll see two items under TARGETS: "AIDrawing" and "AIDrawingTests"
3. Click **"AIDrawing"** (the first target, not the test one)

### Step 2: General Tab Settings

Make sure the **"General"** tab is selected (top of center panel), then set:

```
Display Name:                AIDrawing
Bundle Identifier:           com.yourname.AIDrawing

Deployment Info:
  ☐ iPhone                   [UNCHECK]
  ☑️ iPad                     [CHECK - this is iPad only]
  Minimum Deployments:       iOS 17.0

Supported Destinations:
  Orientation:               All (check all 4: Portrait, Upside Down, Landscape Left, Right)

App Category:               Creativity
```

### Step 3: Signing & Capabilities

1. Click **"Signing & Capabilities"** tab (next to General)
2. Under "Signing":
   - ☑️ Check **"Automatically manage signing"**
   - **Team**: Select your Apple Developer team
   - You should see "Signing Certificate: Apple Development"

**If you see signing errors:**
- Make sure you're logged into Xcode with your Apple ID (Xcode → Settings → Accounts)
- Change Bundle Identifier to something unique like: `com.yourname.AIDrawing.test`

---

## Part 3: Delete Default Files (2 minutes)

Xcode created some default files we don't need. Let's remove them:

### Step 1: Delete Default Swift Files
In the **Project Navigator** (left panel), you'll see a folder structure. Locate and DELETE these files:

1. Right-click on **"ContentView.swift"** → **Delete**
   - In the popup: Click **"Move to Trash"** (not just Remove Reference)

2. Right-click on **"AIDrawingApp.swift"** → **Delete** → **"Move to Trash"**
   - We have our own version to add

3. Right-click on **"Assets.xcassets"** → Keep this one (DON'T delete)

4. Right-click on **"Preview Content"** folder → **Delete** → **"Move to Trash"**

**After deleting, you should only see:**
- ▸ AIDrawing (folder)
  - Assets.xcassets
  - (maybe Info.plist or AIDrawing.entitlements - keep these)

---

## Part 4: Add All Source Files (15 minutes)

Now we'll add all 35 Swift files I created. **This is the most important part.**

### Method 1: Add Files While Maintaining Structure (RECOMMENDED)

#### Step 1: Create Group Structure in Xcode

We need to recreate the folder structure inside Xcode:

1. Right-click on **"AIDrawing"** folder in Project Navigator
2. Select **"New Group"**
3. Name it: **"App"**
4. Repeat to create these groups (as children of AIDrawing):
   - Core
   - AI
   - Drawing
   - UI
   - Configuration

5. Right-click on **"Core"** → **"New Group"** → Name: **"Models"**
6. Right-click on **"Core"** → **"New Group"** → Name: **"Services"**
7. Right-click on **"AI"** → Create these groups:
   - StateMachine
   - Lenses
   - MoveGenerators
   - DecisionEngine
   - Learning
   - CoreML
8. Right-click on **"Drawing"** → Create:
   - Canvas
   - ViewModels
   - History
9. Right-click on **"UI"** → Create:
   - Screens
   - Components

**Your structure should now look like:**
```
▸ AIDrawing
  ▸ App
  ▸ Core
    ▸ Models
    ▸ Services
  ▸ AI
    ▸ StateMachine
    ▸ Lenses
    ▸ MoveGenerators
    ▸ DecisionEngine
    ▸ Learning
    ▸ CoreML
  ▸ Drawing
    ▸ Canvas
    ▸ ViewModels
    ▸ History
  ▸ UI
    ▸ Screens
    ▸ Components
  ▸ Configuration
  Assets.xcassets
```

#### Step 2: Add Files to Each Group

Now we'll add the actual Swift files to each group:

**For each group, do this:**

1. Right-click on the group (e.g., "App")
2. Select **"Add Files to 'AIDrawing'..."**
3. Navigate to: `/Users/ryan/ai-drawing/AIDrawing/AIDrawing/[corresponding folder]`
4. Select the Swift files for that group
5. **IMPORTANT - Check these options:**
   - ☑️ **"Copy items if needed"** - UNCHECK THIS
   - ☑️ **"Create groups"** - SELECT THIS (not "Create folder references")
   - ☑️ **Add to targets: AIDrawing** - CHECK THIS
6. Click **"Add"**

**Detailed file additions:**

**App group:**
- Add: `AIDrawingApp.swift`

**Core → Models:**
- Add: `Stroke.swift`, `DrawingSession.swift`, `AIState.swift`, `UserProfile.swift`

**Core → Services:**
- Add: `PersistenceService.swift`

**Configuration group:**
- Add: `AIConfiguration.swift`

**AI → StateMachine:**
- Add: `AIStateMachine.swift`

**AI → Lenses:**
- Add: `LensProtocol.swift`, `MusicianLens.swift`, `PainterLens.swift`, `PhysicistLens.swift`, `LensAggregator.swift`

**AI → MoveGenerators:**
- Add: `EchoGenerator.swift`, `TextureGenerator.swift`, `StructuralGenerator.swift`, `ContrastGenerator.swift`, `PredictiveGenerator.swift`, `SurpriseGenerator.swift`

**AI → DecisionEngine:**
- Add: `AIMove.swift`, `AIDecisionEngine.swift`, `SafetyValidator.swift`, `MoveSelector.swift`

**AI → Learning:**
- Add: `BehaviorTracker.swift`, `MotifDetector.swift`, `ProfileAdapter.swift`

**AI → CoreML:**
- Add: `FeatureExtractor.swift`, `MLModelManager.swift`

**Drawing → Canvas:**
- Add: `DrawingCanvasView.swift`

**Drawing → ViewModels:**
- Add: `DrawingViewModel.swift`, `ControlPanelViewModel.swift`

**Drawing → History:**
- Add: `HistoryManager.swift`

**UI → Screens:**
- Add: `DrawingScreen.swift`, `ControlPanelView.swift`

**UI → Components:**
- Add: `AIActivityIndicator.swift`

---

## Part 5: Verify and Build (5 minutes)

### Step 1: Check All Files Are Added

In Project Navigator, expand all folders. You should see **35 Swift files** organized in the structure.

Count them:
- App: 1 file
- Core/Models: 4 files
- Core/Services: 1 file
- Configuration: 1 file
- AI/StateMachine: 1 file
- AI/Lenses: 5 files
- AI/MoveGenerators: 6 files
- AI/DecisionEngine: 4 files
- AI/Learning: 3 files
- AI/CoreML: 2 files
- Drawing/Canvas: 1 file
- Drawing/ViewModels: 2 files
- Drawing/History: 1 file
- UI/Screens: 2 files
- UI/Components: 1 file

**Total: 35 files**

### Step 2: Set Entry Point

1. Click on **"AIDrawingApp.swift"** in Project Navigator
2. Make sure it has this at the top:
   ```swift
   @main
   struct AIDrawingApp: App {
   ```
   - The `@main` is crucial - it's the app entry point

### Step 3: Build the Project

1. Select destination: Click the device dropdown (top left of Xcode, next to Play button)
2. Choose **"iPad Pro (12.9-inch)"** or any iPad simulator
3. Click the **Play button** (▶️) or press **Cmd + R**

**Expected on first build:**
- You'll see LOTS of red errors saying "Cannot find type X in scope"
- **This is normal!** The Swift compiler needs to resolve all the types
- Let the build complete

4. Try building again: **Product → Build** (Cmd + B)
5. Errors should decrease each time
6. After 2-3 builds, most errors should resolve

**If errors persist:**
- Make sure ALL 35 files are in the target (check the file inspector on right side)
- Make sure you're building for iOS, not macOS
- Make sure deployment target is iOS 17.0+

### Step 4: Run the App

Once build succeeds:
1. Click **Play button** (▶️) or press **Cmd + R**
2. iPad simulator will launch
3. App should open with a blank drawing canvas

**First Run Test:**
- Try drawing on the canvas with your mouse/trackpad
- The AI won't respond yet (it needs Apple Pencil simulation)
- Check that the toolbar appears at the bottom with icons

---

## Part 6: Enable Apple Pencil Simulation (Optional)

To test the AI drawing features in the simulator:

1. With simulator running, go to simulator menu: **I/O → Input → Send Apple Pencil Events → Enable**
2. Hold **Shift** while drawing to simulate Apple Pencil
3. Now the AI should respond to your strokes!

---

## Troubleshooting

### "Cannot find type 'PKTool' in scope"
**Fix:** Add UIKit import
- Add `import UIKit` to DrawingCanvasView.swift

### "No such module 'Combine'"
**Fix:** Already imported, check deployment target
- Set deployment target to iOS 17.0+

### "Entry point not found"
**Fix:** Make sure AIDrawingApp.swift has `@main`

### Files appear red in Project Navigator
**Fix:** File references broken
- Delete the red file reference
- Re-add the file using "Add Files to AIDrawing..."

### Build succeeds but app crashes
**Fix:** Check console for error
- Look at debug console (bottom of Xcode)
- Usually missing required init or configuration

---

## Quick Reference: Keyboard Shortcuts

- **Build**: Cmd + B
- **Run**: Cmd + R
- **Stop**: Cmd + .
- **Clean Build**: Shift + Cmd + K
- **Add Files**: Cmd + Option + A
- **New Group**: Cmd + Option + N

---

## Success Checklist

- ☐ Xcode project created at `/Users/ryan/ai-drawing/AIDrawing/AIDrawing.xcodeproj`
- ☐ Project settings: iOS 17+, iPad only
- ☐ All 35 Swift files added to project
- ☐ Files organized in correct groups
- ☐ All files added to AIDrawing target (not test target)
- ☐ Build succeeds (Cmd + B)
- ☐ App runs in iPad simulator (Cmd + R)
- ☐ Drawing canvas appears
- ☐ Can draw on canvas
- ☐ AI responds to strokes (with Apple Pencil events enabled)

---

**Estimated Total Time: 35-40 minutes**

If you get stuck at any step, let me know exactly what you see and I can help troubleshoot!
