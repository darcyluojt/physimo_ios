# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Physimo is an iOS SwiftUI application for human pose analysis and joint angle measurement. The app uses multiple computer vision frameworks to detect and analyze human poses from images, calculating joint angles using both Apple's Vision framework and Google's MediaPipe. The application focuses on knee flexion analysis for physiotherapy and movement assessment.

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
- `ImageProcessor`: Main orchestrator that processes images through multiple pose detection systems (Services/ImageProcessor.swift:13)
- `Vision2DProcessor` & `Vision3DProcessor`: Apple Vision framework processors (Processor/ directory)
- `MediapipeProcessor`: Google MediaPipe pose detection service (Processor/MediapipeProcessor.swift:5)

**Data Models:**
- `Metric`: Individual joint angle measurements with accuracy scores (Models/Metric.swift:2)
- `BodyDetectionResult`: Unified representation of pose landmarks from all sources (Models/BodyDetectionResult.swift:55)
- `MetricConfiguration`: Defines which joints to analyze and angle calculation logic (Models/MetricConfiguration.swift:13)

**Image Analysis & Visualization:**
- `ImageAnalyser`: Handles overlay rendering and coordinate transformations (Services/ImageAnalyser.swift:54)
- `ImageDisplayMetrics`: Manages image scaling and coordinate mapping for UI display (Services/ImageAnalyser.swift:8)

### Current Architecture Changes (Recent)

**Unified Data Model Approach:**
- Replaced separate archetype-based system with unified `BodyDetectionResult` and `MetricConfiguration`
- All pose detection sources now convert to the same `BodyLandmark` format with both 2D and 3D coordinates
- Centralized angle calculation through `Joint` and `Bone` structures

**Pose Detection Sources:**
1. **Apple 2D Pose** (`HumanBodyPoseObservation`) - Vision2DProcessor.swift:6
2. **Apple 3D Pose** (`HumanBodyPose3DObservation`) - Vision3DProcessor.swift:5
3. **MediaPipe 2D** (`MediaPipePoseLandmarks`) - MediapipeProcessor.swift:93
4. **MediaPipe 3D** (`MediaPipePoseWorldLandmarks`) - MediapipeProcessor.swift:93

### Key Dependencies

- **MediaPipeTasksVision**: Google's pose detection framework (installed via CocoaPods)
- **Vision**: Apple's computer vision framework
- **SwiftUI**: UI framework with PhotosPicker integration
- **simd**: SIMD math operations for 3D calculations

### Project Structure

```
physimo/
├── Models/              # Data models and configurations
│   ├── BodyDetectionResult.swift    # Unified pose landmark representation
│   ├── Metric.swift                 # Joint angle measurements
│   ├── MetricConfiguration.swift    # Angle calculation configurations
│   └── pose_landmarker_heavy.task   # MediaPipe model file
├── Views/               # SwiftUI views organized by feature
│   ├── ImageAnalysisView.swift      # Main image list view
│   ├── ImageDetailsView.swift       # Image display with overlays
│   ├── MainView.swift              # Tab-based navigation
│   └── Uploads/                    # Upload-related views
├── Services/            # Business logic
│   ├── ImageProcessor.swift        # Main processing orchestrator
│   └── ImageAnalyser.swift         # Overlay rendering and coordinate mapping
├── Processor/           # Pose detection processors
│   ├── MediapipeProcessor.swift    # MediaPipe integration
│   ├── Vision2DProcessor.swift     # Apple 2D pose detection
│   └── Vision3DProcessor.swift     # Apple 3D pose detection
├── ViewModels/          # View state management
│   ├── UploadViewModel.swift       # Photo picker and processing logic
├── Extensions/          # Swift extensions
│   └── ImagePropertyOrientation.swift
└── Assets.xcassets/     # App resources and icons
```

### MediaPipe Integration

- Model file: `pose_landmarker_heavy.task` (bundled in app bundle)
- Service class: `MediapipeProcessor` provides pose detection API
- Confidence thresholds: 0.5 for detection, presence, and tracking
- Returns both 2D normalized landmarks and 3D world coordinates via `MediaPipePoseResult`

### Joint Angle Calculation

**Current Implementation:**
- Uses unified `BodyDetectionResult.angle(of: Joint)` method
- Calculates angles using SIMD vector math with dot product and arc cosine
- Supports both 2D and 3D coordinate systems with SIMD3<Float> representation
- Maps between different landmark indexing systems via enum extensions

**Coordinate System Mapping:**
- All landmarks converted to unified `BodyPart` enum system

### UI and Visualization

**Image Display:**
- `ImageDetailsView` shows images with pose overlay visualizations
- Canvas-based rendering with coordinate transformation for proper overlay positioning
- Supports both MediaPipe (red) and Apple Vision (blue) overlay visualization

**Metrics Display:**
- Grid-based metrics comparison across all pose detection sources
- Shows left/right knee flexion angles with accuracy scores when available

### Current Limitations & Areas for Development

1. **Metrics Scope**: Currently only supports knee flexion analysis
2. **UI Integration**: Image analysis view needs integration with upload processing
3. **Error Handling**: Limited error recovery in pose detection pipeline
4. **Performance**: No caching or optimization for repeated processing

## Important Notes

- Always use the workspace file (`physimo.xcworkspace`) when opening in Xcode
- MediaPipe model files are large (~50MB) - ensure they're properly bundled in the app target
- The app requires camera and photo library permissions for full functionality
- All coordinate systems are normalized to [0,1] range for consistency across frameworks
- Recent architecture focuses on client-side processing with unified data models
