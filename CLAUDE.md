# FitPulse - Claude Code Guide

## Project Overview
iOS fitness tracking app built with SwiftUI and HealthKit integration. Features on-device LLM (Llama 3.2 1B) for personalized coaching.

## Build Commands
- Build: `xcodebuild -project FitPulse.xcodeproj -scheme FitPulse -sdk iphonesimulator -configuration Debug build`
- Clean: `xcodebuild -project FitPulse.xcodeproj -scheme FitPulse clean`
- Run: `xcrun simctl boot "iPhone 17 Pro" && xcrun simctl install booted "$(xcodebuild -project FitPulse.xcodeproj -scheme FitPulse -sdk iphonesimulator -configuration Debug -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | xargs | cut -d= -f2 | xargs)/FitPulse.app" && xcrun simctl launch booted com.anderalvarez.fitpulse`

## Architecture
- MVVM pattern: Views -> ViewModels -> Services -> Models
- Key services: HealthKitService, LLMService, MealPlannerService, HydrationService, RecoveryAnalyzer

## Slash Commands
- `/build` - Build the app for simulator
- `/simulator` - Launch app on iOS simulator
- `/clean` - Clean build artifacts

## Prompting Strategies (Boris Cherny Tips)

### Bug Fixing (Zero Context Switching)
- Paste Slack bug thread and say "fix" (requires Slack MCP)
- "Go fix the Xcode build errors"
- "Check the simulator crash log and fix the issue"
- Point at logs: "Here's the build output: [paste]. Fix it."

### Code Quality & Review
- "Grill me on these changes - don't commit until I pass your review"
- "Prove this works by diffing behavior between main and this branch"
- "Review this like a senior iOS engineer. Be critical."

### Use Subagents For
- Large refactors: "Migrate all callbacks to async/await, use subagents"
- Multi-file changes: "Update all views to use the new design system, use subagents"
- Parallel exploration: "Investigate how HealthKit syncs data, use subagents"

### Learning Mode
- Run `/config` and enable "Explanatory" output style
- "Generate an HTML visualization explaining how HealthKit data flows"
- "Explain the SwiftUI view lifecycle for this component"

### Web Validation (Chrome MCP)
- "Use /chrome to validate the onboarding flow looks correct"
- "Screenshot the current simulator state and verify the UI"

## Session Evaluation
At the end of complex sessions, ask Claude:
"Rate this session 1-10 on: code quality, test coverage, architecture decisions, and learning value. What could be improved?"

## File Organization
- Views: `Sources/Views/`
- ViewModels: `Sources/ViewModels/`
- Services: `Sources/Services/`
- Models: `Sources/Models/`
- Components: `Sources/Components/`

## Common Patterns
- Adding a new feature: Start in Services, then ViewModel, then View
- HealthKit data: Use HealthKitService methods, never access HKHealthStore directly
- LLM features: Use LLMService for all AI interactions
