import Foundation

// 업계·직종의 대분류와 소분류. 고른 소분류 이름을 그대로 저장하고 서버에 보낸다
// 초안이다. 항목은 사용자와 다시 검토한다 (TASK.md)
struct ChoiceCategory: Identifiable, Hashable, Sendable {
  let name: String
  let items: [String]

  var id: String { name }
}

enum ChoiceCatalog {
  static let industries = [
    ChoiceCategory(
      name: "メーカー",
      items: [
        "自動車・輸送機器", "電機・電子部品", "機械・精密機器", "食品・飲料", "化学・素材", "医薬品・医療機器",
        "化粧品・日用品", "アパレル・繊維", "住宅・建材・インテリア",
      ]),
    ChoiceCategory(name: "商社", items: ["総合商社", "専門商社"]),
    ChoiceCategory(
      name: "小売", items: ["百貨店・スーパー", "コンビニ", "ドラッグストア", "専門店", "通信販売・EC"]),
    ChoiceCategory(name: "金融", items: ["銀行・信用金庫", "証券・投資", "生命保険・損害保険", "クレジット・リース"]),
    ChoiceCategory(
      name: "サービス・インフラ",
      items: [
        "不動産", "建設", "運輸・物流", "電力・ガス・エネルギー", "旅行・ホテル", "飲食", "医療", "福祉・介護", "教育・保育",
        "美容・理容", "人材サービス", "コンサルティング", "レジャー・アミューズメント",
      ]),
    ChoiceCategory(name: "ソフトウェア・通信", items: ["ソフトウェア・情報処理", "インターネット・Web", "通信", "ゲーム"]),
    ChoiceCategory(name: "広告・出版・マスコミ", items: ["放送", "新聞・出版", "広告"]),
    ChoiceCategory(name: "官公庁・公社・団体", items: ["国家公務員", "地方公務員", "警察・消防・自衛隊", "公社・団体"]),
  ]

  static let jobTitles = [
    ChoiceCategory(name: "営業", items: ["法人営業", "個人営業", "ルート営業", "営業企画"]),
    ChoiceCategory(name: "事務・管理", items: ["一般事務", "営業事務", "経理・財務", "人事・労務", "総務・法務"]),
    ChoiceCategory(name: "企画・マーケティング", items: ["商品企画", "マーケティング", "広報・PR"]),
    ChoiceCategory(
      name: "販売・サービス", items: ["販売・接客", "店長・店舗運営", "ホテル・旅行", "飲食・調理", "コールセンター"]),
    ChoiceCategory(name: "IT・エンジニア", items: ["システムエンジニア", "プログラマー", "インフラエンジニア", "データ分析"]),
    ChoiceCategory(name: "技術・研究", items: ["研究・開発", "機械・電気設計", "生産・品質管理", "建築・土木"]),
    ChoiceCategory(name: "クリエイティブ", items: ["デザイナー", "編集・ライター", "映像・音響"]),
    ChoiceCategory(name: "専門職", items: ["コンサルタント", "金融専門職", "士業"]),
    ChoiceCategory(name: "医療・福祉", items: ["看護師", "介護職", "相談員", "医療事務", "薬剤師", "リハビリ職"]),
    ChoiceCategory(name: "教育・保育", items: ["教員", "講師", "保育士"]),
    ChoiceCategory(name: "美容", items: ["美容師", "理容師", "エステ・ネイル"]),
    ChoiceCategory(name: "製造・物流・運転", items: ["製造・組立", "倉庫・物流", "ドライバー・配達"]),
    ChoiceCategory(name: "公務員", items: ["行政職", "公安職（警察・消防）", "技術職"]),
  ]

  // 대분류 이름이 맞으면 그 소분류를 모두, 아니면 이름이 맞는 소분류만 남긴다.
  // 히라가나·가타카나, 전각·반각, 대소문자를 구분하지 않는다
  static func filter(_ categories: [ChoiceCategory], query: String) -> [ChoiceCategory] {
    let key = normalized(query)
    guard !key.isEmpty else { return categories }
    return categories.compactMap { category in
      if normalized(category.name).contains(key) { return category }
      let items = category.items.filter { normalized($0).contains(key) }
      return items.isEmpty ? nil : ChoiceCategory(name: category.name, items: items)
    }
  }

  static func category(containing item: String, in categories: [ChoiceCategory]) -> ChoiceCategory?
  {
    categories.first { $0.items.contains(item) }
  }

  private static func normalized(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    let katakana = trimmed.applyingTransform(.hiraganaToKatakana, reverse: false) ?? trimmed
    let halfwidth = katakana.applyingTransform(.fullwidthToHalfwidth, reverse: false) ?? katakana
    return halfwidth.lowercased()
  }
}
