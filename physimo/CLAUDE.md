# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Physimo is an iOS SwiftUI application for human pose analysis and joint angle measurement. The app uses multiple computer vision frameworks to detect and analyze human poses from images, calculating joint angles using both Apple's Vision framework and Google's MediaPipe.

## Development Commands

### Building and Running
- Open `physimo.xcworkspace` in Xcode (not the .xcodeproj file)
- Use Xcode's build (⌘+B) and run (⌘+R) commands
- Run `pod install` from the parent directory if dependencies need updating

### Testing
- Run unit tests: use Xcode Test Navigator or ⌘+U
- Test targets: `physimoTests` and `physimoUITests`

## Architecture Overview

### Core Components

**Pose Detection Pipeline:**
- `ImageProcessor`: Main orchestrator that processes images through multiple pose detection systems
- `Vision2DProcessor` & `Vision3DProcessor`: Apple Vision framework processors
- `PoseLandmarkerService` (MediapipeProcessor.swift): Google MediaPipe pose detection service

**Data Models:**
- `Upload`: Represents an analyzed image with associated metrics
- `Metric`: Individual joint angle measurements with accuracy scores
- `Archetype`: Defines which joints to analyze (left/right knee, etc.)

**Metrics Calculation:**
- `MetricsCalculator`: Converts pose landmarks to joint angle measurements
- `AngleCalculationHelper`: Mathematical calculations for 2D/3D angles
- Supports both Apple Vision and MediaPipe landmark formats

### Key Dependencies

- **MediaPipeTasksVision**: Google's pose detection framework (installed via CocoaPods)
- **Vision**: Apple's computer vision framework
- **SwiftUI**: UI framework

### Project Structure

```
physimo/
├── Models/           # Data models (Upload, Metric, Archetype, etc.)
├── Views/           # SwiftUI views organized by feature
├── Services/        # Business logic (ImageProcessor, MetricsCalculator, UploadStore)
├── Processor/       # Pose detection processors (Vision, MediaPipe)
├── Helpers/         # Utility functions (angle calculations, extensions)
├── ViewModels/      # View state management
└── Assets.xcassets/ # App resources
```

### Pose Detection Sources

The app processes images through multiple pose detection systems:

1. **Apple 2D Pose** (`HumanBodyPoseObservation`)
2. **Apple 3D Pose** (`HumanBodyPose3DObservation`) 
3. **MediaPipe 2D** (`MediaPipePoseLandmarks`)
4. **MediaPipe 3D** (`MediaPipePoseWorldLandmarks`)

Each source produces `Metric` objects with calculated joint angles and confidence scores.

### MediaPipe Integration

- Model file: `pose_landmarker_heavy.task` (bundled in app)
- Service class: `PoseLandmarkerService` provides pose detection API
- Confidence thresholds: 0.5 for detection, presence, and tracking
- Returns both 2D normalized landmarks and 3D world coordinates

### Joint Angle Calculation

- Supports both 2D (CGPoint) and 3D (SIMD3<Float>) coordinate systems
- Calculates angles using dot product and arc cosine
- Maps between different landmark indexing systems (Apple vs MediaPipe)
- Includes confidence/accuracy scoring for each measurement

## Important Notes

- Always use the workspace file (`physimo.xcworkspace`) when opening in Xcode
- MediaPipe model files are large - ensure they're properly bundled
- The app requires camera and photo library permissions for full functionality
- Pose detection requires clear visibility of relevant body joints
- Joint angle calculations assume specific body positioning and may need calibration for different use cases