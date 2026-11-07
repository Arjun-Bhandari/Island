import SwiftUI

/// A plain month grid with today highlighted and prev/next navigation — no
/// event-calendar integration (that wasn't part of the brief), just the
/// browse-the-month glance the reference design leans on.
struct CalendarGridView: View {
    private let calendar = Calendar.current
    private let today = Date.now
    @State private var monthOffset: Int = 0

    private var displayedMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: today) ?? today
    }

    private var monthDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else { return [] }

        let leadingBlanks = Array(repeating: Date?.none, count: firstWeekday - 1)
        let dayCount = calendar.component(.day, from: calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!)
        let days = (0..<dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: monthInterval.start) }
        return leadingBlanks + days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(Array(calendar.veryShortWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let isToday = calendar.isDateInToday(date)
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 10, weight: isToday ? .semibold : .regular))
                            .foregroundStyle(isToday ? .black : .white)
                            .frame(width: 18, height: 18)
                            .background(isToday ? Color.white : Color.clear, in: Circle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(width: 18, height: 18)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(displayedMonth, format: .dateTime.month(.wide).year())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button {
                monthOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            if monthOffset != 0 {
                Button("Today") { monthOffset = 0 }
                    .buttonStyle(.plain)
                    .font(.system(size: 9))
                    .foregroundStyle(.blue)
            }

            Button {
                monthOffset += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
