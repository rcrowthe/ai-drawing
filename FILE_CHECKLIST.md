# Quick File Addition Checklist

Use this checklist when adding files to Xcode. Check off each file as you add it.

## Source File Locations

All files are in: `/Users/ryan/ai-drawing/AIDrawing/AIDrawing/`

## Files to Add (35 total)

### App (1 file)
- [ ] AIDrawingApp.swift

### Core/Models (4 files)
- [ ] Stroke.swift
- [ ] DrawingSession.swift
- [ ] AIState.swift
- [ ] UserProfile.swift

### Core/Services (1 file)
- [ ] PersistenceService.swift

### Configuration (1 file)
- [ ] AIConfiguration.swift

### AI/StateMachine (1 file)
- [ ] AIStateMachine.swift

### AI/Lenses (5 files)
- [ ] LensProtocol.swift
- [ ] MusicianLens.swift
- [ ] PainterLens.swift
- [ ] PhysicistLens.swift
- [ ] LensAggregator.swift

### AI/MoveGenerators (6 files)
- [ ] EchoGenerator.swift
- [ ] TextureGenerator.swift
- [ ] StructuralGenerator.swift
- [ ] ContrastGenerator.swift
- [ ] PredictiveGenerator.swift
- [ ] SurpriseGenerator.swift

### AI/DecisionEngine (4 files)
- [ ] AIMove.swift
- [ ] AIDecisionEngine.swift
- [ ] SafetyValidator.swift
- [ ] MoveSelector.swift

### AI/Learning (3 files)
- [ ] BehaviorTracker.swift
- [ ] MotifDetector.swift
- [ ] ProfileAdapter.swift

### AI/CoreML (2 files)
- [ ] FeatureExtractor.swift
- [ ] MLModelManager.swift

### Drawing/Canvas (1 file)
- [ ] DrawingCanvasView.swift

### Drawing/ViewModels (2 files)
- [ ] DrawingViewModel.swift
- [ ] ControlPanelViewModel.swift

### Drawing/History (1 file)
- [ ] HistoryManager.swift

### UI/Screens (2 files)
- [ ] DrawingScreen.swift
- [ ] ControlPanelView.swift

### UI/Components (1 file)
- [ ] AIActivityIndicator.swift

---

## Total Files by Category

| Category | Count |
|----------|-------|
| App | 1 |
| Core | 5 |
| Configuration | 1 |
| AI | 21 |
| Drawing | 4 |
| UI | 3 |
| **TOTAL** | **35** |

---

## Quick Add All Files Script

If you want to speed up the process, you can select multiple files at once when adding:

1. Right-click on a group → "Add Files to 'AIDrawing'..."
2. Navigate to the corresponding source folder
3. **Cmd + Click** to select multiple files
4. Click "Add"

Example: For AI/MoveGenerators, select all 6 generator files at once.

---

## File Dependencies (Import Order)

If you want to minimize build errors, add files in this order:

1. **First**: Core models (Stroke, DrawingSession, AIState, UserProfile)
2. **Second**: Configuration (AIConfiguration)
3. **Third**: Core services (PersistenceService)
4. **Fourth**: AI infrastructure (StateMachine, Lenses, DecisionEngine)
5. **Fifth**: AI features (MoveGenerators, Learning, CoreML)
6. **Sixth**: Drawing components (Canvas, ViewModels, History)
7. **Last**: UI (Screens, Components)
8. **Final**: App entry point (AIDrawingApp)

This order reduces circular dependency errors during initial compilation.
