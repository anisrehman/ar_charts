## 0.2.3

* Added selected-point emphasis for line charts via `LineStyle.selectedPoint`, so tapped points can stay hidden by default and still become clearly visible on selection.
* Applied the selected-point highlight behavior on both Android and iOS line chart renderers.
* Updated the line chart example to demonstrate selected-point emphasis with hidden normal circles.

## 0.2.2

* Fixed axis font color issue.
* Fixed tooltip position.

## 0.2.1

* Fixed line chart y-axis repeating the same label (e.g. "100") when using compact format with a narrow value range (e.g. 100–101).

## 0.2.0

* Structural changes in `BarChart` to better support grouped bar charts.

## 0.1.6

* Added axis grid-line styling options in `AxisConfig`: optional `gridLineColor` and `gridLineWidth`.
* Applied axis grid-line color/width customization on both Android and iOS platform implementations.
* Updated line chart example to demonstrate lighter, subtle grid lines.

## 0.1.5

* Markers now support optional auto-hide via `MarkerConfig.autoHideDurationSeconds` (seconds, default 3.5) on both line and bar charts; after a value is tapped, the marker automatically hides after the configured delay.
* Axes now support optional `gridLineColor` and `gridLineWidth` in `AxisConfig` to customize grid line appearance (for example, lighter/subtle grid lines).

## 0.1.4

* Line charts support solid and dashed line style via `LineDrawSolid` and `LineDrawDashed` on `LineStyle.lineDrawStyle`.
* Chart marker styling improved on Android and iOS (rounded corners, border, shadow).

## 0.1.3

* Charts update automatically when data changes.

## 0.1.2

* Fixed iOS build: updated podspec dependency from `Charts` to `DGCharts` to resolve "Unable to find module dependency: 'DGCharts'" when installing on iOS.

## 0.1.1

* Added line area fill support for line charts (`LineFillSolid`, `LineFillGradient`).
* Fixed Android gradient fill rendering to correctly apply `fillAlpha`.
* Android line area opacity now matches iOS behavior for gradient fills.

## 0.1.0

* First minor release.
* Line and bar charts with configurable axes, legends, and interactions.
* Markers with formatted text, multiline tooltips, and platform-specific layout fixes.
* Date formatter support on x-axis.
* Android and iOS native chart engines (MPAndroidChart, Charts).

## 0.0.5

* Marker shows formatted text.
* Fixed Android marker position.
* Date formatter support on x-axis.
* Marker position fixes.
* Multiline marker tooltip support.
* Padding adjustments for iOS marker.
* General marker fixes.

## 0.0.4

* Example updated for multiple lines.
* License info updated in README.

## 0.0.3

* Updated documentation.
* Separate page for each example in demo app.
* Example cleanup.
* API documentation section removed from README.

## 0.0.2

* Formatting for y-axis values.
* Updated package description.
* Updated homepage in pubspec.

## 0.0.1

* Initial release.
* Line and bar charts for Android (MPAndroidChart) and iOS (Charts).
* Configurable axes, legends, and interactions.
* Package namespace: `com.anisrehman.archarts`.
