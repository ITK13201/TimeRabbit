//
//  TimeRabbitTests.swift
//  TimeRabbitTests
//
//  Created by Takumi Ikeda on 2025/07/31.
//

import Testing
import Foundation
@testable import TimeRabbit

struct TimeRabbitTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - systemId Tests

@Suite("Project and Job systemId Tests")
struct SystemIdTests {

  @Test("Project id (UUID) is automatically generated and unique")
  func testProjectSystemIdGeneration() throws {
    let repo = MockProjectRepository(withSampleData: false)

    let project1 = try repo.createProject(projectId: "P001", name: "Project 1", color: "blue")
    let project2 = try repo.createProject(projectId: "P002", name: "Project 2", color: "red")

    // id (UUID) が生成されている（UUIDのゼロ値ではない）
    let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    #expect(project1.id != zeroUUID)
    #expect(project2.id != zeroUUID)

    // id (UUID) が一意
    #expect(project1.id != project2.id)
  }

  @Test("Project id (UUID) remains unchanged when projectId is updated")
  func testProjectSystemIdImmutable() throws {
    let repo = MockProjectRepository(withSampleData: false)

    let project = try repo.createProject(projectId: "P001", name: "Project", color: "blue")
    let originalId = project.id

    try repo.updateProject(project, projectId: "P002", name: "Updated", color: "green")

    // id (UUID) は変更されない
    #expect(project.id == originalId)
  }

  @Test("Job id (UUID) is automatically generated and unique")
  func testJobSystemIdGeneration() throws {
    let repo = MockJobRepository()
    let jobs = try repo.fetchAllJobs()

    // 少なくとも2つのJobが存在することを確認
    #expect(jobs.count >= 2)

    let job1 = jobs[0]
    let job2 = jobs[1]

    // id (UUID) が生成されている（UUIDのゼロ値ではない）
    let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    #expect(job1.id != zeroUUID)
    #expect(job2.id != zeroUUID)

    // id (UUID) が一意
    #expect(job1.id != job2.id)
  }

  @Test("All predefined jobs have unique ids (UUID)")
  func testAllJobsHaveUniqueSystemIds() throws {
    let repo = MockJobRepository()
    let jobs = try repo.fetchAllJobs()

    // すべてのid (UUID) を収集
    let ids = jobs.map { $0.id }

    // 重複がないことを確認（SetのサイズがArrayと同じ）
    let uniqueIds = Set(ids)
    #expect(ids.count == uniqueIds.count)
  }
}
