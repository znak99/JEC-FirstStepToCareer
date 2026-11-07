import Testing

@testable import FirstStepToCareer

struct ChoiceCatalogTests {
  private let catalogs = [ChoiceCatalog.industries, ChoiceCatalog.jobTitles]

  @Test func itemsAreUniqueAndFitTheServerLimit() {
    for catalog in catalogs {
      let items = catalog.flatMap(\.items)
      #expect(Set(items).count == items.count)
      #expect(Set(catalog.map(\.name)).count == catalog.count)
      #expect(items.allSatisfy { $0.count <= InterviewDraft.choiceLimit })
      #expect(catalog.allSatisfy { !$0.items.isEmpty })
    }
  }

  @Test(arguments: ["", "   "])
  func blankQueryKeepsEverything(_ query: String) {
    #expect(
      ChoiceCatalog.filter(ChoiceCatalog.industries, query: query) == ChoiceCatalog.industries)
  }

  @Test func categoryNameMatchKeepsAllItems() throws {
    let result = ChoiceCatalog.filter(ChoiceCatalog.industries, query: "金融")
    let finance = try #require(result.first { $0.name == "金融" })
    #expect(finance.items.count == 4)
  }

  @Test func itemMatchKeepsOnlyMatchingItems() {
    // 「営業」은 소분류만 맞고, 「企画・マーケティング」은 대분류 이름이 맞는다
    let result = ChoiceCatalog.filter(ChoiceCatalog.jobTitles, query: "企画")
    #expect(result.map(\.name) == ["営業", "企画・マーケティング"])
    #expect(result.first?.items == ["営業企画"])
    #expect(result.last?.items.count == 3)
  }

  @Test func ignoresKanaWidthAndCase() {
    #expect(ChoiceCatalog.filter(ChoiceCatalog.jobTitles, query: "えんじにあ").count == 1)
    #expect(ChoiceCatalog.filter(ChoiceCatalog.jobTitles, query: "ｴﾝｼﾞﾆｱ").count == 1)
    #expect(
      ChoiceCatalog.filter(ChoiceCatalog.industries, query: "ｗｅｂ").first?.items == ["インターネット・Web"])
    #expect(ChoiceCatalog.filter(ChoiceCatalog.jobTitles, query: "it").first?.name == "IT・エンジニア")
  }

  @Test(arguments: ["存在しない業界", "<script>", "%"])
  func unknownQueryFindsNothing(_ query: String) {
    #expect(ChoiceCatalog.filter(ChoiceCatalog.industries, query: query).isEmpty)
  }

  @Test func findsCategoryOfItem() {
    #expect(
      ChoiceCatalog.category(containing: "看護師", in: ChoiceCatalog.jobTitles)?.name == "医療・福祉")
    #expect(ChoiceCatalog.category(containing: "IT", in: ChoiceCatalog.industries) == nil)
  }
}
