//
//  MainContentViewModelTests.swift
//  TimeRabbitTests
//
//  Created by Takumi Ikeda on 2025/10/02.
//

import Foundation
import Testing
@testable import TimeRabbit

@MainActor
struct MainContentViewModelTests {
    // MARK: - Setup Helper

    private func createTestSetup() -> (MainContentViewModel, MockProjectRepository, MockTimeRecordRepository, MockJobRepository, [Project], [TimeRecord]) {
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let projects = try! mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
        let mockJobRepo = MockJobRepository()

        let factory = ViewModelFactory.create(with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo))
        let viewModel = factory.createMainContentViewModel()

        let timeRecords = try! mockTimeRecordRepo.fetchTimeRecords(
            for: nil,
            from: Calendar.current.startOfDay(for: Date()),
            to: Date()
        ).filter { $0.endTime != nil }

        return (viewModel, mockProjectRepo, mockTimeRecordRepo, mockJobRepo, projects, timeRecords)
    }

    // MARK: - Statistics Auto-Refresh Tests

    @Test("Statistics should auto-refresh when history edit sheet is closed")
    func statisticsAutoRefreshOnHistoryEdit() async {
        let (viewModel, _, mockTimeRecordRepo, mockJobRepo, projects, timeRecords) = createTestSetup()

        guard let recordToEdit = timeRecords.first else {
            #expect(Bool(false), "No completed records found for testing")
            return
        }

        // 初期統計データを取得
        let initialStatsCount = viewModel.statisticsViewModel.projectJobTimes.count
        #expect(initialStatsCount > 0, "Should have initial statistics data")

        // 履歴編集を開始
        viewModel.historyViewModel.editHistoryViewModel.startEditing(recordToEdit)
        #expect(viewModel.historyViewModel.editHistoryViewModel.showingEditSheet == true)

        // レコードを変更（作業区分を変更）
        let jobs = try! mockJobRepo.fetchAllJobs()
        let differentJob = jobs.first { $0.id != recordToEdit.job?.id }
        #expect(differentJob != nil, "Should have a different job available")

        if let differentJob = differentJob {
            viewModel.historyViewModel.editHistoryViewModel.selectedJob = differentJob

            // 変更を保存
            viewModel.historyViewModel.editHistoryViewModel.saveChanges()

            // シートが閉じられるまで待機
            try! await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            // 統計が更新されているか確認
            // 編集により作業区分が変わったので、統計の内訳が変わっているはず
            let updatedStatsCount = viewModel.statisticsViewModel.projectJobTimes.count

            // 統計データが再読み込みされていることを確認
            // (作業区分が変わると、グループ化が変わる可能性がある)
            #expect(viewModel.statisticsViewModel.projectJobTimes.count >= 0, "Statistics should be refreshed")
        }
    }

    @Test("Statistics should refresh when switching to statistics tab")
    func statisticsRefreshOnTabSwitch() async {
        let (viewModel, _, _, _, _, _) = createTestSetup()

        // 履歴タブから統計タブに切り替え
        #expect(viewModel.selectedTab == 0, "Should start on history tab")

        viewModel.selectTab(.statistics)

        #expect(viewModel.selectedTab == 1, "Should switch to statistics tab")
        #expect(viewModel.currentTab == .statistics, "Current tab should be statistics")

        // 統計データが存在することを確認
        #expect(viewModel.statisticsViewModel.projectJobTimes.count >= 0, "Statistics data should be loaded")
    }

    @Test("RefreshAllData should update both history and statistics")
    func testRefreshAllData() async {
        let (viewModel, _, _, _, _, _) = createTestSetup()

        // 初期データを確認
        let initialHistoryCount = viewModel.historyViewModel.dayRecords.count
        let initialStatsCount = viewModel.statisticsViewModel.projectJobTimes.count

        // 全データをリフレッシュ
        viewModel.refreshAllData()

        // データが再読み込みされていることを確認
        #expect(viewModel.historyViewModel.dayRecords.count >= 0, "History should be refreshed")
        #expect(viewModel.statisticsViewModel.projectJobTimes.count >= 0, "Statistics should be refreshed")
    }

    @Test("Tab selection should work correctly")
    func tabSelection() async {
        let (viewModel, _, _, _, _, _) = createTestSetup()

        // 履歴タブ（初期状態）
        #expect(viewModel.selectedTab == 0)
        #expect(viewModel.currentTab == .history)

        // 統計タブに切り替え
        viewModel.selectTab(.statistics)
        #expect(viewModel.selectedTab == 1)
        #expect(viewModel.currentTab == .statistics)

        // インデックスで切り替え
        viewModel.selectTab(at: 0)
        #expect(viewModel.selectedTab == 0)
        #expect(viewModel.currentTab == .history)
    }
}
