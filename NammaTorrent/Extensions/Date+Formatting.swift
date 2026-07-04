// Date+Formatting.swift
import Foundation

public extension Date {
    var shortFormatted: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    var timeAgo: String {
        Formatters.relativeDate(self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}
