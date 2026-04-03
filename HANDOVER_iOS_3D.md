# In-Sight 3D iOS — Handover Document

**Date:** 2026-04-04
**From:** Windows dev machine (Claude Code session)
**To:** MacBook (Claude Code session)

---

## Context: What Is This Project?

In-Sight is a retail shelf scanning SDK. Field reps walk into stores, scan shelves with their phone, and the system identifies products, counts facings, measures share of shelf, and captures pricing. The data flows to a portal for brand owners to see how their products are performing in-store.

### Two Versions

1. **2D version** (Android, working): Snapshot-based. User frames a bay, holds steady, taps capture. Products detected in a single hi-res frame. Built as a Flutter app with Kotlin native SDK. **This is the production version.**

2. **3D version** (iOS, this project): Continuous spatial scanning. User walks along the shelf. ARKit tracks their movement. Products are detected per-frame and placed in 3D world space. No "capture bay" button needed — products accumulate as the user moves. Handles narrow aisles, pillars, and obstructed views.

---

## Repositories

| Repo | URL | Description |
|------|-----|-------------|
| 3D iOS SDK (foundation) | `https://github.com/DTexDDC/3Dcamera-sdk-IOS.git` | Existing iOS 3D SDK — needs major rework |
| 2D Pipeline Test App | `https://github.com/GrahamNi/insightpipeline.git` | Working Android pipeline — the reference implementation |
| In-Sight Portal | (ask Graham) | Node.js portal with model management, task management |

---

## The 2D Pipeline (Reference — What the 3D Version Must Match)

The 2D pipeline is the **classification engine** that the 3D version reuses. It runs as:

### Detection Cascade
1. **Infrastructure detector** (infra_v5.tflite, 640x640) — detects shelves, price labels, bay dividers
2. **Generic product detector** (product_detector_v3.tflite, 640x640) — detects product bounding boxes
3. **Brand logo detector** (brand_logo_v3_nano.tflite) — identifies brand logos on products
4. **Brand classifier** (hs_brand_classifier_v3.tflite) — classifies which brand a product is
5. **DINOv2 embedder** (hs_embedder_v1.tflite) + prototype matrix — SKU-level identification via cosine similarity
6. **NV SKU classifier** (nv_sku_classifier_v2.tflite) — target brand specific identification
7. **OCR** (ML Kit on Android, Vision framework on iOS) — reads price labels

### Key Processing Steps
- Bay dividers define scan scope (products outside dividers are excluded)
- Shelf numbering: S1 = floor (bottom-to-top)
- Base facings only (stacked products count as 1)
- Products tracked across frames via IoU, deduplicated
- Hi-res frame captured for cropping (detection on analysis stream, crops from capture stream)
- Cascade runs on crops at bay capture time (not per-frame)

### Model Hierarchy
- **Universal** (bundle in app): infra detector, product detector, OCR
- **Regional** (download per market): brand logo detector (Ireland ≠ Australia)
- **Category + market specific** (download per assignment): brand classifier, embedder, SKU classifier

### Current Model Status
- **Ireland**: Full pipeline (logo 108 brands, HS brand classifier 22 brands, NV embedder 21 SKUs)
- **Australia**: No classifiers yet (training data exists, not built yet)
- **Fallback**: If no classifier, run infra + product + logo only → group crops by brand → send to server for training data

---

## The 3D iOS SDK — Current State

### Location
`3Dcamera-sdk-IOS/MyDetectObject/`

### What Exists (6 key files)

| File | Lines | Purpose |
|------|-------|---------|
| `ARViewContainer.swift` | 1,600 | ARKit world tracking, 4K frame capture, YUV→BGRA→RGB conversion, camera movement detection |
| `ObjectDetectionHelper.swift` | 928 | TFLite YOLO inference (640x640, 8400 anchors), NMS (IoU 0.6), confidence filtering |
| `ObjectDetectState.swift` | 33 | Data model: 2D bbox + 3D world position + shelf/bay/facing indices |
| `sdkSendData.swift` | 102 | Groups detections by shelf/bay, assigns facing indices, builds JSON payload |
| `ContentView.swift` | 327 | SwiftUI UI: start/pause/clear, detection list, movement warning |
| `ImageProcessor.swift` | 40 | CGImage→CVPixelBuffer utility (unused) |

### What Works
- ARKit world tracking + vertical plane detection
- TFLite YOLO inference (same architecture as 2D pipeline)
- 2D-to-3D raycasting via ARKit
- Movement gating (pause detection when camera moving)
- Basic product grouping by shelf/bay

### What's Broken
- **Infinite loop bug** in `sdkSendData.send()` lines 42-48 and 61-63 — `while true` loops can hang
- Threading safety issues throughout
- ~40% dead/commented code
- Debug code saving images to Photos album on every inference
- No depth sensing (despite "3D" name — only uses plane detection + raycasting)
- No tests

### ARKit APIs Currently Used
- `ARWorldTrackingConfiguration` with `.vertical` plane detection
- `ARSCNView` + `ARSCNViewDelegate` for rendering
- `ARFrame` for camera images + camera transform
- `ARPlaneAnchor` detection (partially commented out)
- 4K video format, 30 FPS, HDR, auto-focus

### TFLite Configuration
- Input: 640x640 RGB
- Output: 8400 × 35 (31 classes + 4 bbox coords)
- 7 threads (too many — should be 2-4)
- NMS IoU threshold: 0.6
- Model loaded from `DetectObjectSDK.shared.modelPath`

---

## What Needs to Happen — 3D iOS Rebuild

### The Goal
Replace the snapshot-based scanning with continuous spatial mapping:

1. User taps "Start Scan"
2. ARKit session begins, tracks device position in 3D space
3. User walks along the shelf naturally
4. Products detected per-frame, placed in 3D world coordinates
5. 3D deduplication: same product seen from different angles = 1 product
6. Bay dividers detected → define spatial boundaries
7. User taps "Finish"
8. Best crop for each product extracted (sharpest, most centred frame)
9. Cascade classification runs on crops
10. Results screen: share of shelf, facings by brand, pricing

### Architecture Plan

```
┌─────────────────────────────────────────────────────────┐
│  ARKit Session (ARWorldTrackingConfiguration)            │
│  - 4K camera frames + device pose (position/rotation)    │
│  - Vertical plane detection (for shelf/bay geometry)     │
│  - Optional: depth (LiDAR on Pro models)                 │
└───────────────┬─────────────────────────────────────────┘
                │ ARFrame (every 3rd frame)
                ▼
┌─────────────────────────────────────────────────────────┐
│  Detection Layer (reuse from 2D pipeline)                │
│  - Infra detector: shelves, price labels, bay dividers   │
│  - Product detector: generic product bounding boxes      │
└───────────────┬─────────────────────────────────────────┘
                │ 2D detections + camera pose
                ▼
┌─────────────────────────────────────────────────────────┐
│  3D Placement (raycast 2D → 3D world space)              │
│  - Use ARKit hitTest/raycast on detected vertical planes │
│  - Each product gets a world coordinate (x, y, z metres) │
│  - Bay dividers get world coordinates too                 │
└───────────────┬─────────────────────────────────────────┘
                │ 3D positioned detections
                ▼
┌─────────────────────────────────────────────────────────┐
│  3D Tracker (replaces 2D IoU tracker)                    │
│  - Products within ~5cm in 3D = same product             │
│  - Merge detections from multiple viewing angles         │
│  - Track confidence: more sightings = higher confidence  │
│  - Store best frame reference per product                │
└───────────────┬─────────────────────────────────────────┘
                │ accumulated product map
                ▼
┌─────────────────────────────────────────────────────────┐
│  On "Finish" — Crop + Classify                           │
│  - Extract best crop per product from stored frames      │
│  - Run cascade: logo → brand → embedder → OCR            │
│  - Assign shelf/bay/facing using 3D positions            │
│  - Build results                                         │
└───────────────┬─────────────────────────────────────────┘
                │ classified products
                ▼
┌─────────────────────────────────────────────────────────┐
│  Results Screen (same data as 2D)                        │
│  - Share of shelf %, facings by brand                    │
│  - Price cards, compliance checks                        │
│  - Grouped by shelf, sorted by position                  │
└─────────────────────────────────────────────────────────┘
```

### What to Reuse from Existing SDK
- ARKit session setup (`ARViewContainer.swift` — clean up, remove dead code)
- TFLite inference wrapper (`ObjectDetectionHelper.swift` — refactor, reduce threads to 4)
- Data model (`ObjectDetectState.swift` — extend with tracking metadata)
- Frame capture + YUV conversion (the pixel buffer code works)

### What to Build New
1. **3D Tracker** — replaces sdkSendData.swift. Products in 3D space with merge/dedup logic.
2. **Frame Store** — keep N recent hi-res frames for crop extraction at finish time.
3. **Cascade Classification** — port the brand logo / brand classifier / embedder / OCR pipeline from the Android 2D version to iOS (CoreML or TFLite, Vision framework for OCR).
4. **Results Screen** — SwiftUI screen matching the 2D pipeline's results output.
5. **Spatial Bay Scoping** — use 3D bay divider positions to define scan boundaries.
6. **UI Overlay** — show product count, shelf lines, detected products as lightweight markers projected from 3D to screen space.

### What to Delete
- `sdkSendData.swift` — infinite loop bugs, wrong approach. Replace with 3D tracker.
- `ImageProcessor.swift` — unused.
- All `DetectObjectSDK.shared` references — this was an external SDK wrapper. Build it native.
- All `UIImageWriteToSavedPhotosAlbum` debug code.
- ~40% commented-out code throughout.

---

## Key Design Decisions Already Made

1. **S1 = floor** — shelf numbering always starts from the bottom. Ground level = Shelf 1.
2. **Base facings only** — stacked products count as 1 facing. Only count the front row at shelf level.
3. **Bay-scoped** — products outside bay dividers are excluded from counts.
4. **No autonomous decisions** — present plan to user, get approval, then execute. This is a commercial product.
5. **Never lose data** — crops are expensive to capture. Never recycle or discard prematurely.
6. **Flutter overlay for rendering** — project 3D coordinates to 2D screen space. No SceneKit/RealityKit rendering needed for product boxes. Simple, maintainable, consistent with 2D version's look.

---

## Model Files

The 2D pipeline models are in the pipeline test app repo (`insightpipeline`). For the iOS 3D version, these need to be converted or bundled:

| Model | Format | Input | Output | Notes |
|-------|--------|-------|--------|-------|
| infra_v5 | .tflite | 640x640 RGB | shelves, price labels, dividers | Universal |
| product_detector_v3 | .tflite | 640x640 RGB | product bboxes | Universal |
| brand_logo_v3_nano | .tflite | varies | brand logo detections | Regional (Ireland) |
| hs_brand_classifier_v3 | .tflite | 224x224 RGB | brand classification | Category+market |
| hs_embedder_v1 | .tflite | 224x224 RGB | 384-dim embedding | Category+market |
| nv_prototype_matrix | .bin | N/A | prototype embeddings | Category+market |
| nv_sku_classifier_v2 | .tflite | 224x224 RGB | SKU classification | Brand+market |

TFLite runs on iOS via the TensorFlow Lite Swift/ObjC API (already used in the existing SDK). No need to convert to CoreML unless there's a performance reason.

---

## Preprocessing Requirements (Critical — Must Match Training)

These MUST match exactly or classification will fail:

- **Detection models** (infra, product, logo): 640x640, letterbox resize, /255.0 normalisation
- **Classification models** (brand, SKU): 224x224, bilinear stretch (NOT letterbox), /127.5 - 1.0 normalisation
- **Embedder**: 224x224, bilinear stretch, /127.5 - 1.0 normalisation
- **Prototype matching**: cosine similarity, threshold 0.60, separation margin 0.015

---

## Performance Targets (from 2D Pipeline)

- Detection: ~6 Hz on product detector, ~2 Hz on infra (throttled)
- Classification: batch at finish time only, not per-frame
- Threads: 2-4 (not 7 as in current iOS SDK)
- XNNPACK delegate for TFLite acceleration
- Reusable inference buffers (avoid allocation per frame)

---

## Portal & Backend

- Portal API: `https://portal-api-411626849747.australia-southeast1.run.app`
- Model manifest: `GET /api/models/manifest?market=AU`
- Firebase auth (token-based)
- Dual ID matching: Firebase UID or database UUID
- PostgreSQL on Google Cloud SQL (australia-southeast1)

---

## Priority Order for iOS 3D Build

1. **Clean up existing SDK** — remove dead code, fix threading, delete debug artifacts
2. **Verify ARKit tracking works** — walk along shelf, confirm device pose is stable
3. **Wire infra + product detectors** — detect products per-frame during walk
4. **Build 3D tracker** — place products in world space, deduplicate by proximity
5. **Add frame store** — keep recent hi-res frames for crop extraction
6. **Wire cascade classification** — logo → brand → embedder at finish time
7. **Build results screen** — share of shelf, facings, pricing
8. **Add OCR** — Vision framework for price label reading
9. **Polish UX** — smooth overlay, product count, scan progress indicators

---

## Questions That Will Come Up

- **SwiftUI or UIKit?** The existing SDK uses SwiftUI + ARSCNView (UIKit wrapper). This is fine. Keep SwiftUI for UI, UIKit wrapper for AR.
- **Flutter?** The iOS 3D version is native Swift, NOT Flutter. The 2D Flutter app is Android-only for now.
- **CoreML vs TFLite?** Use TFLite — already works in the existing SDK, models are .tflite format, avoids conversion issues.
- **LiDAR?** Nice to have but not required. ARKit plane detection + raycasting works on all ARKit-capable devices. LiDAR (iPhone 12 Pro+) would give better depth but narrows the device audience.
