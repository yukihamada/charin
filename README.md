# チャリン — 届いた、チャリン。

> フリーランス向け収入管理・インボイス発行アプリ

[![TestFlight](https://img.shields.io/badge/TestFlight-Beta-blue)](https://testflight.apple.com/join/SAqxf1bm)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Open Source](https://img.shields.io/badge/Open%20Source-Enabler-E8A838)](https://enablerdao.com)

## Features

- PDF請求書ワンタップ作成 — 必要項目を入力するだけでプロフェッショナルな請求書を生成
- インボイス制度対応 — 適格請求書の要件を満たすフォーマットを自動適用
- 収入可視化 — 月別・クライアント別の収入をグラフで一目把握
- 定期請求自動管理 — 毎月の固定請求を自動リマインド・テンプレート化

## Tech Stack

| Layer | Technology |
|-------|-----------|
| iOS | SwiftUI, SwiftData |
| PDF | PDFKit |

## Getting Started

```bash
git clone https://github.com/yukihamada/charin.git
cd charin/ios
xcodegen generate
xcodebuild -project Charin.xcodeproj -scheme Charin \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

## Contributing

PRs welcome!

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit your changes
4. Push and create a PR

### コントリビューションポイント

Enablerエコシステムへの貢献はポイントとして記録されます。
将来的なガバナンス参加に活用される予定です。

## Security

- 全データはiPhoneのローカルに保存
- 外部サーバーへのデータ送信なし
- オープンソースでコードを検証可能

## License

MIT — 詳細は [LICENSE](LICENSE) を参照

## Links

- [TestFlight Beta](https://testflight.apple.com/join/SAqxf1bm)
- [Enabler](https://enablerdao.com)
- [pasha.run/charin](https://pasha.run/charin)

---

Built with AI. Tested with AI. Polished by humans.
