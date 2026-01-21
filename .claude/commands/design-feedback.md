# Human Interface Guidelines Compliance Review

Review Swift UI code for compliance with Apple's Human Interface Guidelines and suggest improvements.

**Usage**: `/design-feedback <file-path> [component-type]`

---

## 🚨 CRITICAL: Use Local Documentation Only

This command uses **LOCAL markdown files** stored in `documentation/human_interface_guidelines/`.

**DO NOT use WebFetch or attempt to access apple.com or any external websites.**

**ONLY use the Read tool to access local .md files in the documentation directory.**

---

## Before Execution - Pre-Flight Checklist

Before executing this command, verify:
- [ ] You will use **Read tool only** (NOT WebFetch)
- [ ] You will access files from `documentation/human_interface_guidelines/*.md`
- [ ] You will **NOT** attempt to access any websites
- [ ] All HIG references will point to local file paths, not URLs

---

## Description

Analyzes SwiftUI views, UIKit components, or AppKit views to identify potential Human Interface Guidelines violations and provides actionable recommendations based on Apple's official design guidelines stored locally in `documentation/human_interface_guidelines/`.

## Arguments

- `file-path`: Path to the Swift file containing UI code
- `component-type` (optional): Specific component to focus on (e.g., Button, TextField, NavigationView)

## Examples

```bash
/design-feedback KahloStudio/TabbedMainWindow.swift
/design-feedback KahloStudio/DeviceControlBar.swift Button
/design-feedback KahloStudio/MaterialEditorPanel.swift
```

## Implementation

### Step 1: Read and Analyze Swift File

1. Read the specified Swift file using the **Read tool**
2. Identify UI framework (SwiftUI, UIKit, or AppKit)
3. Extract all UI components:
   - Views and containers
   - Controls (buttons, text fields, pickers, etc.)
   - Navigation elements
   - Layout structures
   - Custom views and modifiers
4. Identify component properties:
   - Colors and visual styling
   - Typography and text
   - Spacing and sizing
   - Accessibility modifiers
   - Interaction patterns

### Step 2: Component Classification

Classify identified components into HIG categories:

**Layout & Organization**
- Navigation (NavigationView, TabView, Sidebar)
- Containers (VStack, HStack, ZStack, List, Form)
- Windows and panels

**Controls**
- Buttons and links
- Text input (TextField, TextEditor, SecureField)
- Selection controls (Picker, Toggle, Slider)
- Menus and context menus

**Content**
- Images and icons (SF Symbols compliance)
- Text and typography
- Colors and materials
- Icons and graphics

**User Interaction**
- Gestures and touch targets
- Keyboard shortcuts
- Accessibility features
- Feedback and animations

### Step 3: Load HIG Guidelines from Local Files

**Load guidelines from the local documentation directory:**
`documentation/human_interface_guidelines/`

**Directory Structure**:
- `UI-Components/Components.md` - Component-specific guidelines
- `UI-Foundations/Color.md` - Color usage guidelines (NOT found at UI-Foundations/Color.md in repo)
- `UI-Foundations/Typography.md` - Text and font guidelines (NOT found at UI-Foundations/Typography.md in repo)
- `UI-Foundations/Materials.md` - Materials and vibrancy (NOT found at UI-Foundations/Materials.md in repo)
- `Layout-and-Hierarchy/Layout.md` - Spacing and sizing
- `Platform-Guidelines/macOS/macOS.md` - macOS-specific patterns
- `Platform-Guidelines/iOS/iOS.md` - iOS-specific patterns
- `Design-Technologies/SFSymbols.md` - SF Symbols guidelines
- `Interaction-Inputs/Inputs.md` - Keyboard, gestures, accessibility
- `Design-Principles/Principles.md` - Core design principles

**Loading Strategy**:
1. **Use Read tool to load relevant HIG markdown files** (never use WebFetch)
2. Extract key guidelines and requirements from local documentation
3. Focus on "Best Practices" and "Avoid" sections
4. Note platform-specific considerations (macOS vs iOS)
5. Search for component-specific guidance in Components.md

**Note**: First check which files actually exist using Bash `ls` or similar, as not all theoretical files may be present. Adapt to the actual file structure.

### Step 4: Compliance Analysis

Compare the code against HIG guidelines from local documentation:

**Accessibility**
- [ ] Has meaningful accessibility labels
- [ ] Sufficient touch/click target sizes (44x44pt minimum for iOS, 28x28pt for macOS)
- [ ] Proper contrast ratios (4.5:1 for text, 3:1 for UI components)
- [ ] VoiceOver/Voice Control support
- [ ] Keyboard navigation support
- [ ] Dynamic Type support

**Visual Design**
- [ ] Uses system colors or semantic colors
- [ ] Follows spacing conventions (8pt grid)
- [ ] Uses SF Symbols for icons where appropriate
- [ ] Consistent with platform visual language
- [ ] Proper use of materials and vibrancy

**Typography**
- [ ] Uses system fonts or approved custom fonts
- [ ] Text styles match HIG recommendations
- [ ] Appropriate font weights and sizes
- [ ] Supports Dynamic Type scaling

**Interaction**
- [ ] Clear visual feedback for interactive elements
- [ ] Appropriate animation and transitions
- [ ] Follows platform gesture conventions
- [ ] Proper keyboard shortcuts (macOS)
- [ ] Touch gesture support (iOS)

**Layout**
- [ ] Adapts to different screen sizes
- [ ] Proper safe area handling
- [ ] Appropriate spacing between elements
- [ ] Logical visual hierarchy
- [ ] Consistent margins and padding

### Step 5: Generate Feedback Report

Create a comprehensive report with:

```
🎨 HUMAN INTERFACE GUIDELINES REVIEW

📄 File: <file-path>
🔧 Framework: SwiftUI/UIKit/AppKit
📱 Platform: macOS/iOS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 COMPONENTS IDENTIFIED

✓ NavigationView (Line 45)
✓ Button (Lines 67, 89, 102)
✓ TextField (Line 78)
⚠ Custom View: MaterialCard (Line 120)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 COMPLIANCE FINDINGS

❌ CRITICAL ISSUES (Must Fix)

1. Accessibility Label Missing (Line 67)
   Component: Button("Save")
   Issue: No accessibility label provided
   HIG Reference: Interaction-Inputs/Inputs.md (Accessibility section)

   Current:
   Button("Save") { saveAction() }

   Recommended:
   Button("Save") { saveAction() }
       .accessibilityLabel("Save material changes")
       .accessibilityHint("Saves your changes to the material file")

2. Touch Target Too Small (Line 89)
   Component: Button with icon
   Issue: Button frame is 20x20pt (minimum is 44x44pt for iOS, 28x28pt for macOS)
   HIG Reference: UI-Components/Components.md (Buttons section)

   Current:
   Button(action: delete) {
       Image(systemName: "trash")
   }
   .frame(width: 20, height: 20)

   Recommended:
   Button(action: delete) {
       Image(systemName: "trash")
           .frame(width: 20, height: 20)
   }
   .frame(width: 44, height: 44) // Expand tappable area
   .contentShape(Rectangle())

⚠️  WARNINGS (Should Fix)

3. Non-Semantic Color Usage (Line 102)
   Component: Background color
   Issue: Hard-coded color instead of semantic color
   HIG Reference: [Local file with color guidelines]

   Current:
   .background(Color(red: 0.95, green: 0.95, blue: 0.95))

   Recommended:
   .background(Color(nsColor: .controlBackgroundColor))
   // or for cross-platform:
   .background(.background.secondary)

4. Missing Dynamic Type Support (Line 78)
   Component: TextField with fixed font
   Issue: Uses fixed font size, won't scale with user preferences
   HIG Reference: [Local file with typography guidelines]

   Current:
   TextField("Material Name", text: $name)
       .font(.system(size: 14))

   Recommended:
   TextField("Material Name", text: $name)
       .font(.body) // Uses system text style

💡 SUGGESTIONS (Nice to Have)

5. Consider Using SF Symbols (Line 120)
   Component: Custom icon image
   Issue: Custom asset could be replaced with SF Symbol
   HIG Reference: Design-Technologies/SFSymbols.md

   Current:
   Image("custom-save-icon")

   Recommended:
   Image(systemName: "arrow.down.doc")
   // Or if custom icon is essential, ensure it follows SF Symbols design principles

6. Add Keyboard Shortcut (Line 67)
   Component: Save button
   Issue: Primary action lacks keyboard shortcut (macOS convention)
   HIG Reference: Platform-Guidelines/macOS/macOS.md (Keyboard Shortcuts section)

   Recommended:
   Button("Save") { saveAction() }
       .keyboardShortcut("s", modifiers: .command)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📈 COMPLIANCE SCORE: 72/100

✓ Accessibility: 60% (3/5 checks passed)
✓ Visual Design: 80% (4/5 checks passed)
✓ Typography: 75% (3/4 checks passed)
✓ Interaction: 70% (7/10 checks passed)
✓ Layout: 85% (6/7 checks passed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 PRIORITY FIXES

1. Add accessibility labels to all interactive elements
2. Ensure minimum touch target sizes (44x44pt iOS, 28x28pt macOS)
3. Replace hard-coded colors with semantic colors
4. Add Dynamic Type support to all text

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 RELEVANT HIG DOCUMENTATION

Local Files Referenced:
• UI-Components/Components.md (Buttons, Text Fields, etc.)
• [Other local files that were actually referenced]
• Interaction-Inputs/Inputs.md (Accessibility, Keyboard)
• Platform-Guidelines/macOS/macOS.md (macOS Patterns)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ ADDITIONAL RECOMMENDATIONS

Platform-Specific:
• Consider using .controlSize() modifier for macOS buttons
• Use native macOS toolbar patterns for top-level actions
• Follow macOS window sizing and positioning guidelines

Accessibility:
• Test with VoiceOver enabled
• Verify all controls are keyboard-navigable
• Check color contrast in both light and dark modes

Performance:
• Consider lazy loading for long lists
• Use @State and @Binding appropriately to minimize redraws
```

### Step 6: Provide Code Examples

For each issue, provide:
1. **Current code snippet** (what was found)
2. **Recommended code snippet** (how to fix it)
3. **HIG reference** (which local markdown file contains the guideline)
4. **Before/after comparison** (visual explanation if relevant)

### Step 7: Generate Diff/Patch (Optional)

If user requests, generate a complete diff that can be applied:

```swift
// File: KahloStudio/TabbedMainWindow.swift
// HIG Compliance Fixes

// Fix 1: Add accessibility labels
- Button("Save") { saveAction() }
+ Button("Save") { saveAction() }
+     .accessibilityLabel("Save material changes")
+     .accessibilityHint("Saves your changes to the material file")

// Fix 2: Ensure minimum touch targets
- Button(action: delete) {
-     Image(systemName: "trash")
- }
- .frame(width: 20, height: 20)
+ Button(action: delete) {
+     Image(systemName: "trash")
+         .frame(width: 20, height: 20)
+ }
+ .frame(width: 44, height: 44)
+ .contentShape(Rectangle())
```

## Advanced Features

### Component-Specific Deep Dive

If user specifies a component type, provide exhaustive analysis:

```bash
/design-feedback KahloStudio/DeviceControlBar.swift Button
```

This will:
1. Find all Button instances in the file
2. Load complete button guidelines from UI-Components/Components.md
3. Check every button-specific requirement
4. Provide button-specific best practices
5. Compare with Apple's own button implementations

### Cross-Platform Compliance

Detect platform and check appropriate guidelines from local files:
- **macOS (AppKit/SwiftUI)**: Platform-Guidelines/macOS/macOS.md
- **iOS (UIKit/SwiftUI)**: Platform-Guidelines/iOS/iOS.md
- **Cross-platform**: UI-Components/ and other local files

### Accessibility Audit Mode

```bash
/design-feedback KahloStudio/MaterialEditorPanel.swift --accessibility
```

Focus exclusively on accessibility compliance using Interaction-Inputs/Inputs.md:
- VoiceOver support
- Voice Control compatibility
- Keyboard navigation
- Color contrast
- Text sizing
- Focus management

## HIG Local Documentation Mapping

### Component Type → Local File Sections

All component guidelines are in `UI-Components/Components.md`:
- Buttons
- Text Fields
- Toggles
- Pickers
- Navigation Components
- Lists and Tables
- Alerts
- Menus
- Toolbars

### Foundations → Local Files

Check which of these actually exist:
- Accessibility: `Interaction-Inputs/Inputs.md`
- Layout: `Layout-and-Hierarchy/Layout.md`
- SF Symbols: `Design-Technologies/SFSymbols.md`
- Design Principles: `Design-Principles/Principles.md`

### Platform-Specific → Local Files

- macOS: `Platform-Guidelines/macOS/macOS.md`
- iOS: `Platform-Guidelines/iOS/iOS.md`
- iPadOS: `Platform-Guidelines/iPadOS/iPadOS.md`
- watchOS: `Platform-Guidelines/watchOS/watchOS.md`
- tvOS: `Platform-Guidelines/tvOS/tvOS.md`
- visionOS: `Platform-Guidelines/visionOS/visionOS.md`

## Output Formats

### Standard Report (default)
Comprehensive markdown report with all findings

### Summary Only
```bash
/design-feedback <file> --summary
```
Quick overview of critical issues only

### JSON Export
```bash
/design-feedback <file> --json
```
Machine-readable format for CI/CD integration

### Interactive Mode
```bash
/design-feedback <file> --interactive
```
Step through each issue with fix options

## Best Practices

1. **Run before code review**: Catch HIG issues early
2. **Focus on critical issues first**: Accessibility and usability
3. **Test in context**: Some guidelines are context-dependent
4. **Consider platform conventions**: macOS vs iOS differences
5. **User test**: HIG is a starting point, not a replacement for user feedback

## Requirements

- Swift file with UI code (SwiftUI, UIKit, or AppKit)
- Local HIG documentation in `documentation/human_interface_guidelines/`
- **Read tool only** for accessing local markdown files

## Limitations

- Cannot detect runtime behavior issues
- May not catch all context-dependent violations
- Custom components require manual interpretation
- Relies on local documentation being up-to-date

---

## Execute Now

**Final Reminder**: Use **Read tool ONLY**. Do NOT use WebFetch. Load all guidelines from local markdown files in `documentation/human_interface_guidelines/`.

Execute the design feedback review now.
