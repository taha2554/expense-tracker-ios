# Expense Tracker (iOS)

![CI](https://github.com/taha2554/expense-tracker-ios/actions/workflows/ci.yml/badge.svg)

A personal expense tracker for iPhone built with **SwiftUI**, **SwiftData** and **Swift Charts**.

## Features

- Add, edit and delete expenses with amount, category, date and note
- List grouped by day with daily totals, search in notes, filter by category, swipe to delete
- Monthly summary: total, daily average, projection to the end of the month
- Optional monthly budget with a progress bar that turns orange at 80% and red when exceeded
- Donut chart and table of spending per category (Swift Charts)
- Browse previous months
- Export a month as a CSV file through the share sheet
- Currency selection (TRY / EUR / USD / GBP); amounts accept both `12,50` and `12.50`
- "Add sample data" button on the empty screen for a quick demo

## Project structure

```
Sources/ExpenseCore/     Swift package with the logic: categories, monthly summary,
                         grouping, amount parsing, CSV export (Foundation only)
Tests/ExpenseCoreTests/  XCTest unit tests for the package
App/                     SwiftUI app: SwiftData model, list, form, summary
project.yml              XcodeGen project definition
```

The calculations live in a separate Swift package and work on a small `ExpenseLike` protocol instead of the SwiftData class. That way they can be tested with plain structs, without a model container or simulator – `swift test` runs them in a second.

Some details:
- Money uses `Decimal`, never `Double`, so totals don't pick up floating-point errors.
- The category is stored as a raw string in SwiftData, so adding a new category later can't break existing data.
- Month boundaries respect the user's calendar and time zone (an expense at 00:00 on the 1st belongs to the new month – there's a test for it).

## Running

Requires Xcode 15+ (iOS 17 SDK) and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen                 # creates ExpenseTracker.xcodeproj
open ExpenseTracker.xcodeproj
```

Run the logic tests from the terminal:

```bash
swift test
```

## Next ideas

- Recurring expenses (rent, subscriptions)
- iCloud sync with a CloudKit-backed SwiftData container
- Home-screen widget showing the remaining budget

## License

MIT
