# ar_charts

A Flutter charts library for **Android** and **iOS** with line and bar charts, configurable axes, legends, and interactions. Uses native chart engines for smooth, platform-consistent rendering.

## Features

- **Line charts** — Single or multiple series, optional cubic curves, markers, viewport/zoom
- **Bar charts** — Single or grouped bars, custom colors and widths
- **Axes** — Configurable X, left Y, and right Y axes; min/max, label count, grid lines
- **Value formats** — Compact (1K, 1.5M), decimal, or percent for axis labels
- **Legend** — Position (top/bottom/left/right) and alignment
- **Interactions** — Zoom, drag, and highlight (tap) on supported platforms
- **Animation** — Optional entrance animation with configurable duration and easing
- **Markers** — Optional value popover on tap with customizable format

## Platform support

| Platform | Engine |
|----------|--------|
| **Android** | [MPAndroidChart](https://github.com/PhilJay/MPAndroidChart) |
| **iOS** | [Charts](https://github.com/ChartsOrg/Charts) (ChartsOrg/Charts) |

Other platforms (web, desktop) are not supported; the chart widgets render an empty area.

---

## Installation

### Android: add JitPack repository (required)

The Android chart engine ([MPAndroidChart](https://github.com/PhilJay/MPAndroidChart)) is published on JitPack. **Before** adding the package, add the JitPack repository to your Android project.

**If your Android project uses Kotlin DSL** (`build.gradle.kts` in the project root, e.g. `android/build.gradle.kts` or `android/settings.gradle.kts`), add:

```kotlin
repositories {
    google()
    mavenCentral()
    maven("https://jitpack.io")
}
```

**If your Android project uses Groovy** (`build.gradle`), add:

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://jitpack.io" }
    }
}
```

Put this in the same place where you already have `google()` and `mavenCentral()` (e.g. in `allprojects { repositories { ... } }` in the root `build.gradle`, or in `pluginManagement { repositories { ... } }` / root `repositories { ... }` in `settings.gradle` / `settings.gradle.kts`).

### Add the package

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ar_charts: ^0.1.0
```

Or from Git:

```yaml
dependencies:
  ar_charts:
    git:
      url: https://github.com/anisrehman/ar_charts.git
      ref: main
```

Then run:

```bash
flutter pub get
```

---

## Quick start

### Line chart

```dart
import 'package:ar_charts/ar_charts.dart';

LineChart(
  series: [
    LineSeries(
      id: 'price',
      label: 'Price',
      points: [
        LinePoint(x: 0, y: 100),
        LinePoint(x: 1, y: 150),
        LinePoint(x: 2, y: 120),
        LinePoint(x: 3, y: 180),
      ],
    ),
  ],
  height: 280,
  xAxis: const AxisConfig(min: 0, max: 4),
  leftAxis: const AxisConfig(formatType: AxisValueFormatCompact()),
  legend: const LegendConfig(
    enabled: true,
    position: LegendPosition.bottom,
    alignment: LegendAlignment.center,
  ),
  defaultLineStyle: const LineStyle(
    lineColor: Colors.blue,
    lineWidth: 2,
    drawCircles: true,
    cubic: true,
  ),
)
```

### Bar chart

```dart
BarChart(
  series: [
    BarSeries(
      id: 'sales',
      label: 'Sales',
      points: [
        BarPoint(x: 1, y: 5, label: 'Mon'),
        BarPoint(x: 2, y: 3, label: 'Tue'),
        BarPoint(x: 3, y: 7, label: 'Wed'),
      ],
    ),
  ],
  height: 280,
  xAxis: const AxisConfig(min: 0, max: 4),
  legend: const LegendConfig(enabled: true, position: LegendPosition.bottom),
  defaultBarStyle: const BarStyle(
    barColor: Colors.orange,
    barWidth: 0.6,
    drawValues: true,
  ),
)
```

### Grouped bar chart

Use multiple `BarSeries` and enable `BarGroupConfig`:

```dart
BarChart(
  series: [
    BarSeries(id: 'storeA', label: 'Store A', points: [...]),
    BarSeries(id: 'storeB', label: 'Store B', points: [...]),
  ],
  barGroup: const BarGroupConfig(
    enabled: true,
    groupSpace: 0.2,
    barSpace: 0.05,
  ),
  defaultBarStyle: const BarStyle(barColor: Colors.blue, barWidth: 0.35),
  perSeriesStyle: const {
    'storeA': BarStyle(barColor: Colors.teal, barWidth: 0.35),
    'storeB': BarStyle(barColor: Colors.indigo, barWidth: 0.35),
  },
)
```

---

## API overview

### Widgets

| Widget | Description |
|--------|-------------|
| `LineChart` | Renders one or more line series with optional axes, legend, interaction, viewport, marker, and animation. |
| `BarChart` | Renders one or more bar series; supports grouped bars via `BarGroupConfig`. |

### Data types

| Type | Description |
|------|-------------|
| `LineSeries` | `id`, `label`, and list of `LinePoint` (x, y). |
| `LinePoint` | `x` (double), `y` (double). |
| `BarSeries` | `id`, `label`, and list of `BarPoint` (x, y, optional label). |
| `BarPoint` | `x`, `y`, and optional `label` for axis/tooltip. |

### Configuration

| Config | Used by | Description |
|--------|--------|-------------|
| `AxisConfig` | Both | Axis visibility, label, min/max, label count, grid/axis lines, `formatType`. |
| `AxisValueFormat` | AxisConfig | `AxisValueFormatNone`, `AxisValueFormatCompact`, `AxisValueFormatDecimal(decimals)`, `AxisValueFormatPercent(decimals)`. |
| `LineStyle` | LineChart | Line color/width, circles (on/off, color, radius), draw values, cubic curve. |
| `BarStyle` | BarChart | Bar color, width, draw values. |
| `BarGroupConfig` | BarChart | Grouped bars: enabled, groupSpace, barSpace, fromX, centerAxisLabels, label. |
| `LegendConfig` | Both | enabled, position (top/bottom/left/right), alignment (start/center/end). |
| `InteractionConfig` | Both | zoomEnabled, dragEnabled, highlightEnabled. |
| `ViewportConfig` | LineChart | visibleXRangeMin/Max, initialX, viewPortOffsets. |
| `MarkerConfig` | Both | enabled; tooltip shows x on first line, then each series at that x with colored bullet and y. |
| `AnimationConfig` | Both | enabled, durationMs, easing (easeInOut, linear). |

### LineChart-only

- **Right axis**: `rightAxis` (default: disabled). Use for a second Y scale.
- **Viewport**: `viewport` for visible X range and offsets (useful with zoom/drag).
- **Per-series style**: `perSeriesStyle` map from series `id` to `LineStyle`.

### BarChart-only

- **Bar groups**: `barGroup` with `BarGroupConfig` for multiple series side-by-side.
- **Per-series style**: `perSeriesStyle` map from series `id` to `BarStyle`.

---

## Examples

The **example** app in this repo includes:

1. **Line chart** — Many points, compact Y-axis format, drag, marker, cubic line.
2. **Bar chart** — Single series with labels and values on bars.
3. **Grouped bar chart** — Two series with `BarGroupConfig` and per-series colors.

Run the example:

```bash
cd example && flutter run
```

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for the full text.
