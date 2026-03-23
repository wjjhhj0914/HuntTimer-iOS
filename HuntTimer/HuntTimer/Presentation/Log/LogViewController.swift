import UIKit

/// 기록 화면 ViewController — 캘린더 상태 관리 및 델리게이트 처리 담당
final class LogViewController: BaseViewController {

    // MARK: - View
    private let contentView = LogView()

    // MARK: - State
    private var selectedDay: Int?  = 19
    private let activityDays: Set<Int> = [1, 3, 5, 8, 10, 12, 15, 17, 19, 20, 22, 24, 25, 26]
    private let dayImageURLs: [String] = [
        "https://images.unsplash.com/photo-1744710835733-936ab49ee0b4?w=80",
        "https://images.unsplash.com/photo-1716487621020-462aa91a6af6?w=80",
        "https://images.unsplash.com/photo-1691351943492-cfee023e9cbf?w=80",
        "https://images.unsplash.com/photo-1702914954859-f037fc75b760?w=80",
    ]

    // MARK: - loadView
    override func loadView() {
        view = contentView
    }

    // MARK: - BaseViewController
    override func setupBind() {
        contentView.calendarCollectionView.dataSource = self
        contentView.calendarCollectionView.delegate   = self
        contentView.calendarButton.addTarget(self, action: #selector(calendarTapped), for: .touchUpInside)
        contentView.listButton.addTarget(self, action: #selector(listTapped), for: .touchUpInside)
        contentView.prevMonthButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        contentView.nextMonthButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func calendarTapped() {
        contentView.setToggleState(isCalendar: true)
        UIView.animate(withDuration: 0.25) {
            self.contentView.calendarContainer.isHidden     = false
            self.contentView.calendarContainer.alpha        = 1
            self.contentView.summaryCardContainer.isHidden  = false
            self.contentView.summaryCardContainer.alpha     = 1
        }
    }

    @objc private func listTapped() {
        contentView.setToggleState(isCalendar: false)
        UIView.animate(withDuration: 0.25) {
            self.contentView.calendarContainer.isHidden     = true
            self.contentView.calendarContainer.alpha        = 0
            self.contentView.summaryCardContainer.isHidden  = true
            self.contentView.summaryCardContainer.alpha     = 0
        }
    }

    @objc private func prevMonth() {}
    @objc private func nextMonth() {}
}

// MARK: - UICollectionViewDataSource / Delegate
extension LogViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        contentView.buildCalendarCells().count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell  = cv.dequeueReusableCell(withReuseIdentifier: DayCell.id, for: indexPath) as! DayCell
        let cells = contentView.buildCalendarCells()
        let day   = cells[indexPath.item]
        let hasActivity = day.map { activityDays.contains($0) } ?? false
        let imgURL = hasActivity ? dayImageURLs[indexPath.item % dayImageURLs.count] : nil
        cell.configure(day: day, isSelected: day == selectedDay, isToday: day == 19,
                       hasActivity: hasActivity, imageURL: imgURL)
        return cell
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cells = contentView.buildCalendarCells()
        guard let day = cells[indexPath.item] else { return }
        selectedDay = day
        cv.reloadData()
    }
}
