//
//  HistoryManager.swift
//  AIDrawing
//
//  Unified undo/redo system for both user and AI strokes
//

import Foundation
import Combine

/// Type of action that can be undone/redone
enum ActionType {
    case userStroke(Stroke)
    case aiStroke(Stroke)
    case removeStroke(UUID)
    case toggleVisibility(UUID, visible: Bool)
}

/// Record of an action with timestamp
struct ActionRecord {
    let id: UUID
    let timestamp: Date
    let action: ActionType

    init(action: ActionType) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
    }
}

/// Manages undo/redo history
class HistoryManager: ObservableObject {
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false

    private var undoStack: [ActionRecord] = []
    private var redoStack: [ActionRecord] = []
    private let maxHistorySize = 100

    /// Record a new action (clears redo stack)
    func record(_ action: ActionType) {
        let record = ActionRecord(action: action)
        undoStack.append(record)

        // Limit history size
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst()
        }

        // Clear redo stack when new action is recorded
        redoStack.removeAll()

        updateState()
    }

    /// Undo the last action
    func undo() -> ActionType? {
        guard let record = undoStack.popLast() else { return nil }

        redoStack.append(record)
        updateState()

        return record.action
    }

    /// Redo the last undone action
    func redo() -> ActionType? {
        guard let record = redoStack.popLast() else { return nil }

        undoStack.append(record)
        updateState()

        return record.action
    }

    /// Clear all history
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState()
    }

    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    /// Get recent actions (for debugging/visualization)
    func recentActions(count: Int = 10) -> [ActionRecord] {
        return Array(undoStack.suffix(count))
    }
}
