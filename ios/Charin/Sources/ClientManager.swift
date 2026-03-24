import Foundation
import SwiftData
import SwiftUI

struct ClientManager {
    @MainActor
    static func seedIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<Client>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let clients: [(name: String, email: String, company: String, address: String, notes: String)] = [
            ("chatweb.ai", "support@chatweb.ai", "Chatweb AI Inc.", "Tokyo, Japan", "AIチャットプラットフォーム"),
            ("StayFlow", "hello@stayflowapp.com", "StayFlow Inc.", "Tokyo, Japan", "宿泊施設管理SaaS"),
            ("JiuFlow", "contact@jiuflow.art", "JiuFlow", "Tokyo, Japan", "柔術トレーニングアプリ"),
            ("Elio", "hello@elio.love", "Elio", "Tokyo, Japan", "P2P AIアシスタント"),
            ("ENAI", "info@enablerdao.com", "EnablerDAO", "Tokyo, Japan", "ENAIトークンプロジェクト"),
            ("Consulting", "mail@yukihamada.jp", "Various", "", "コンサルティング案件"),
        ]

        for c in clients {
            let client = Client(
                name: c.name,
                email: c.email,
                company: c.company,
                address: c.address,
                notes: c.notes
            )
            context.insert(client)
        }
    }
}
