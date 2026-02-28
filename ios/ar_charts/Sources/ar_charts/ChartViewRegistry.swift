import Foundation

enum ChartViewRegistry {
    private static let lock = NSLock()
    private static var lineCharts: [Int64: LineChartPlatformView] = [:]
    private static var barCharts: [Int64: BarChartPlatformView] = [:]

    static func registerLineChart(viewId: Int64, view: LineChartPlatformView) {
        lock.lock()
        defer { lock.unlock() }
        lineCharts[viewId] = view
    }

    static func unregisterLineChart(viewId: Int64) {
        lock.lock()
        defer { lock.unlock() }
        lineCharts.removeValue(forKey: viewId)
    }

    static func getLineChart(viewId: Int64) -> LineChartPlatformView? {
        lock.lock()
        defer { lock.unlock() }
        return lineCharts[viewId]
    }

    static func registerBarChart(viewId: Int64, view: BarChartPlatformView) {
        lock.lock()
        defer { lock.unlock() }
        barCharts[viewId] = view
    }

    static func unregisterBarChart(viewId: Int64) {
        lock.lock()
        defer { lock.unlock() }
        barCharts.removeValue(forKey: viewId)
    }

    static func getBarChart(viewId: Int64) -> BarChartPlatformView? {
        lock.lock()
        defer { lock.unlock() }
        return barCharts[viewId]
    }
}
