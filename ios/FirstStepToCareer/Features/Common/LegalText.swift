import SwiftUI

// 이용약관·개인정보 처리방침 본문. 실제 데이터 처리(DATA.md, ARCHITECTURE.md)에 맞춰 쓴 초안이다.
// 본문을 고치면 LegalDocument의 버전도 바꿔 다시 동의를 받는다
struct LegalSection {
  let title: LocalizedStringKey
  let paragraphs: [LocalizedStringKey]
}

extension LegalDocument {
  var effectiveDate: LocalizedStringKey { "2026年11月7日 制定" }

  var intro: LocalizedStringKey {
    switch self {
    case .terms:
      "この利用規約（以下「本規約」）は、就活一歩（以下「本アプリ」）の利用条件を定めるものです。本アプリを利用する方（以下「利用者」）は、本規約に同意したうえで本アプリを利用してください。"
    case .privacy:
      "就活一歩（以下「本アプリ」）の運営者は、利用者の情報を次のとおり取り扱います。"
    }
  }

  var sections: [LegalSection] {
    switch self {
    case .terms: Self.termsSections
    case .privacy: Self.privacySections
    }
  }

  private static var termsSections: [LegalSection] {
    [
      LegalSection(
        title: "第1条（本アプリについて）",
        paragraphs: [
          "本アプリは、AIを使って就職・転職活動の模擬面接を練習し、その記録を振り返るためのアプリです。",
          "本アプリは個人が非営利で運営しており、無料で利用できます。",
        ]),
      LegalSection(
        title: "第2条（利用の開始とアカウント）",
        paragraphs: [
          "本アプリはログインなしで利用できます。Appleでログインすると、同じAppleアカウントの別のiPhoneでも記録を引き継げます。",
          "未成年の方は、保護者の同意を得てから利用してください。",
          "iPhoneとAppleアカウントの管理は、利用者の責任で行ってください。",
        ]),
      LegalSection(
        title: "第3条（禁止事項）",
        paragraphs: [
          "利用者は、次の行為をしてはいけません。",
          "・法令や公序良俗に反する行為",
          "・他人の個人情報や、勤務先・応募先の機密情報を入力する行為",
          "・本アプリやサーバーへの不正なアクセス、過度な負荷をかける行為",
          "・模擬面接の練習以外の目的でAI機能を使う行為",
          "・他人になりすます行為、その他運営を妨げる行為",
        ]),
      LegalSection(
        title: "第4条（AIによる質問と評価）",
        paragraphs: [
          "質問、点数、フィードバックは、AIが作成する練習用の参考情報です。内容の正確さや、実際の選考での結果を保証するものではありません。"
        ]),
      LegalSection(
        title: "第5条（サービスの変更・停止）",
        paragraphs: [
          "運営者は、予告なく本アプリの内容を変更し、AI機能を含むサービスの全部または一部を停止・終了することがあります。"
        ]),
      LegalSection(
        title: "第6条（情報の取り扱い）",
        paragraphs: [
          "利用者の情報は、プライバシーポリシーに従って取り扱います。",
          "利用者は、メニューの「すべてのデータを削除」から、いつでも記録を削除できます。",
        ]),
      LegalSection(
        title: "第7条（免責）",
        paragraphs: [
          "運営者は、本アプリの利用によって利用者に生じた損害について、運営者に故意または重大な過失がある場合を除き、責任を負いません。"
        ]),
      LegalSection(
        title: "第8条（規約の変更）",
        paragraphs: ["運営者は本規約を変更することがあります。変更した場合はアプリ内でお知らせし、改めて同意をお願いします。"]),
      LegalSection(title: "第9条（準拠法）", paragraphs: ["本規約は、日本法に従って解釈します。"]),
    ]
  }

  private static var privacySections: [LegalSection] {
    [
      LegalSection(
        title: "1. サーバーに保存する情報",
        paragraphs: [
          "・お名前（ニックネーム）と、採用区分・業界・職種の希望",
          "・面接の設定（会社名、業界、職種、面接の種類、採用区分、質問数）",
          "・AIが作成した質問、文字に起こした回答、回答時間",
          "・視線と頭の動きの減点回数、点数、フィードバック",
          "・利用規約とプライバシーポリシーに同意した版と日時",
          "・このiPhoneを見分けるための値（ハッシュ化して保存）と、Appleでログインした場合のAppleの利用者識別子",
          "このほか、サーバーの運用のため、アクセスの日時やIPアドレスなどの記録がサーバー事業者に残ることがあります。",
        ]),
      LegalSection(
        title: "2. 取得しない情報",
        paragraphs: [
          "・カメラの映像とマイクの音声は、保存も送信もしません。音声の文字起こしと、視線・頭の動きの計算は、このiPhoneの中だけで行います。",
          "・Appleでログインしても、Appleアカウントのメールアドレスと名前は受け取りません。",
        ]),
      LegalSection(
        title: "3. 利用目的",
        paragraphs: [
          "・模擬面接の質問の作成、回答の評価、フィードバックの作成",
          "・記録の表示と、点数の推移などの分析",
          "・不正な利用の防止と、障害への対応",
          "・本アプリの改善",
        ]),
      LegalSection(
        title: "4. 外部への送信",
        paragraphs: [
          "本アプリは、次の事業者に情報を送ります。いずれも米国など日本国外のサーバーで処理されることがあります。",
          "・Anthropic社（Claude API）：質問の作成と評価のために、面接の設定、お名前（ニックネーム）、質問と回答を送ります。",
          "・Cloudflare社：サーバーとデータベースを提供する事業者です。保存する情報はここに置かれます。",
          "・Apple社：Appleでログインを使うと、ログインの確認のためにAppleと通信します。",
          "法令に基づく場合を除き、これ以外の第三者に情報を提供することはありません。",
        ]),
      LegalSection(
        title: "5. 運営者による確認",
        paragraphs: ["障害への対応や本アプリの改善のため、運営者はサーバーに保存した情報を見ることがあります。"]),
      LegalSection(
        title: "6. 保存期間と削除",
        paragraphs: [
          "情報は、利用者が削除するまで保存します。メニューの「すべてのデータを削除」から、サーバーに保存された情報をいつでもすべて削除できます。",
          "Appleでログインしている場合、ログアウトしても記録はAppleアカウントに残り、再びログインすると見ることができます。",
        ]),
      LegalSection(
        title: "7. 安全管理",
        paragraphs: ["通信は暗号化し、iPhoneを見分けるための値はハッシュ化して保存します。"]),
      LegalSection(
        title: "8. お問い合わせ",
        paragraphs: ["情報の開示・訂正・削除の依頼やご質問は、本アプリのGitHubリポジトリからご連絡ください。"]),
      LegalSection(
        title: "9. 改定",
        paragraphs: ["本ポリシーを変更した場合は、アプリ内でお知らせし、改めて同意をお願いします。"]),
    ]
  }
}
