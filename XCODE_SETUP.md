# Xcode Project Setup - Avoiding Nested Folders

## The Problem
Xcode ALWAYS creates nested folders when you make a new project. We already have our source files organized, so we need to work around this.

## Solution: Create Project Elsewhere, Then Move It

### Step 1: Create Project in Temporary Location

1. Open Xcode
2. File → New → Project
3. Choose: iOS → App
4. Settings:
   - Product Name: `AIDrawing`
   - Interface: **SwiftUI**
   - Language: **Swift**
5. **Save Location**: Choose your **Desktop** (NOT ai-drawing folder)
6. Xcode creates `~/Desktop/AIDrawing/`

### Step 2: Move Only the .xcodeproj File

Open Terminal and run:
```bash
mv ~/Desktop/AIDrawing/AIDrawing.xcodeproj /Users/ryan/ai-drawing/
rm -rf ~/Desktop/AIDrawing
```

This moves just the project file and deletes the nested folders.

### Step 3: Open the Project

```bash
open /Users/ryan/ai-drawing/AIDrawing.xcodeproj
```

### Step 4: Configure Project Settings

In Xcode:
1. Click blue "AIDrawing" icon (top left)
2. Select "AIDrawing" under TARGETS
3. General tab:
   - Deployment Info → **iPad only** (uncheck iPhone)
   - Minimum Deployments → **iOS 17.0**
4. Signing & Capabilities:
   - Check "Automatically manage signing"
   - Select your Team

### Step 5: Delete Default Files

Xcode created some template files we don't need:
1. In Project Navigator, find these files (they'll show as red/missing):
   - ContentView.swift
   - AIDrawingApp.swift
2. If they appear, delete them (Remove Reference)

### Step 6: Add YOUR Source Files

1. In Project Navigator, right-click the blue "AIDrawing" icon
2. Choose "Add Files to 'AIDrawing'..."
3. Navigate to: `/Users/ryan/ai-drawing/`
4. **Select all these folders** (Cmd+Click each):
   - AI
   - App
   - Configuration
   - Core
   - Drawing
   - UI
5. **Important checkboxes**:
   - ☐ Copy items if needed - **UNCHECK**
   - ☑ Create groups - **CHECK**
   - ☑ Add to targets: AIDrawing - **CHECK**
6. Click "Add"

### Step 7: Build and Run

1. Select destination: iPad Pro simulator
2. Press ⌘B to build
3. Press ⌘R to run

## Final Structure

```
/Users/ryan/ai-drawing/
├── AIDrawing.xcodeproj    ← Xcode project (at root level)
├── AI/                     ← Your source files (at root level)
├── App/
├── Configuration/
├── Core/
├── Drawing/
├── UI/
└── README.md
```

**No nested AIDrawing folders!**
