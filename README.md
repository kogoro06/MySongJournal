# My Song Journal

![アプリ紹介画像](https://github.com/user-attachments/assets/c6873fd3-7c4a-441b-b2b4-b34d174030e5)

## 目次
- [サービス概要](#サービス概要)
- [サービスURL](#サービスURL)
- [サービス開発の背景](#サービス開発の背景)
- [ユーザー層について](#ユーザー層について)
- [機能紹介](#機能紹介)
- [技術構成について](#技術構成について)

---

## サービス概要

**MySongJournal** は、ユーザーが毎日の気分に合わせてお気に入りの曲を選び、感情や一言メモを記録する音楽日誌アプリです。音楽と共に日々の気持ちや出来事を振り返り、楽しい思い出として残せます。

---

### 主な機能
- **SpotifyAPIを用いた楽曲検索**: 自分の気分に合わせた曲をSpotifyAPI通じて検索できます！ブラウザによっては楽曲をフルで流すことも可能です！
- **タイムラインと日記一覧ページ**: 作成順や感情、ジャンルで並べ替えが可能です、タイムラインでは他の人の日誌も覗くことができます！
- **公開設定機能**: 公開設定をした日記は他ユーザーとシェアでき、タイムラインで他のユーザーの投稿も閲覧可能です。勿論、自分だけの秘密にしたい場合は非公開でも大丈夫です！

自分だけの日誌としても、他ユーザーと交流する場としても楽しめる音楽日誌アプリです。ぜひ新しい曲を発見したり、日々の出来事を音楽とともに振り返ったりしてみてください。

---

### サービスURL
[https://mysongjournal.com/](https://mysongjournal.com/)

---

## サービス開発の背景

音楽には、気持ちをリフレッシュさせたり、心を落ち着かせたりする力があります。また、音楽を聴くと過去の思い出や気持ちが蘇ることもあります。このように、音楽は日々の感情と密接に結びついているため、音楽を通じて感情を記録し、振り返ることで自己理解が深まるのではないかと考えました。また、友人が選んだ音楽や一言メモを見ることで、友人の新たな一面を知るきっかけになったり、共通の感情を通じて新たな友人ができるようなアプリを作りたいという思いから、このサービスを考えました。

---

### ユーザー層について

- **音楽好きな10代後半から20代後半の若年層**
  - 若い世代はSNSやストリーミングサービスを通じて音楽を楽しむ機会が多く、自己表現や共感を大切にする傾向があると考えています。そんな人達がターゲットになると思います
  
- **気分や感情の振り返りを求める社会人**
  - 社会人の中には、日常の気分転換やリフレッシュのために音楽を活用する人も多く、気分に合った音楽を記録・振り返ることで自分の状態を確認したい人もいると思います。その人達もターゲットです。
 
---

## サービスの利用イメージ

ユーザーは毎日５分、その日の感情や出来事に合う曲と一言メモを記録することで、自分だけの音楽日記を作成できます。
過去の日記一覧ページを通して、気分や思い出を振り返ることができるので自己理解が深まります。タイムラインを通じて、他ユーザーが選曲した曲や、その日の心情、出来事を見ることで、他者理解にもつながると思います。

---

## ■ ユーザーの獲得について
- **SNSでの拡散:** TwitterやInstagramなどのSNSで、提案結果を簡単に共有してもらうことを促進します。ユーザーが自身の体験を投稿することで、アプリの楽しみ方を広め、認知度を向上させる狙いがあります。OGP画像と一緒に、ハッシュタグで、アーティスト名と曲名が表示されるようにするのもその一環です

- **コミュニティでの拡散:** コミュニティ内で宣伝を行い、様々な人にアプリを触ってもらい、拡散していくことを目指します。（まだまだ弱弱アプリですが、ソーシャルポートフォリオの中で、一時的に１位を取ることができました。それに見合うだけのアプリにしたいので、これからも精進していきます）

---

## サービスの差別化ポイント・推しポイント

- **気分と音楽のリンクを重視したユニークな日記アプリ**
  - 単なる日記や音楽の再生アプリではなく、気分と音楽が結びついた記録アプリとして独自性が高く、ユーザーが自分を表現しやすくしたつもりです。

- **共感・つながりの促進**
  - 公開された日記を通じて、友人の感情や趣味を知り、共通の音楽趣味を持つ人と仲良くなれる環境を提供。音楽を通じたコミュニティの形成をサポートします。（アップデートで各投稿に対するコメント機能を作成予定です！）

---

### 機能紹介

| Spotify検索、オートコンプリート |
|------------------------------------|
| <img src="https://github.com/user-attachments/assets/29eb8e1c-1283-48cf-9088-395460fb1238" width="30%"> <img src="https://github.com/user-attachments/assets/2742bb62-42f6-4aaa-ade5-1d0626743ef3" width="30%"> <img src="https://github.com/user-attachments/assets/f9bc9f38-3e98-47e4-8f2e-6eca905c5cf7" width="30%"> |
| 「曲名」「アーティスト名」「年代」「キーワード」の4条件による検索システムと、リアルタイムオートコンプリート機能を実装。検索結果の最適化により、高速かつ快適な検索体験を実現しています。|

| 日記作成、編集、削除機能 |
|------------------------------------|
| <img src="https://github.com/user-attachments/assets/36c87694-65c6-4e8c-97a9-1f28e6a6bb93" width="49%"> <img src="https://github.com/user-attachments/assets/a5d5b64f-bfca-44e7-9e9b-ba28350cac56" width="49%"> |
| Spotify連携による音楽日記の作成・編集・削除機能を実装。感情タグ付けや公開設定などの直感的操作で、ユーザーは簡単に音楽と結びつけた日記を記録・管理できます。入力途中のフォームデータや選択した曲の情報はセッションに自動保存され、検索画面への遷移後も入力内容が維持されます。|

| タイムライン、過去の日記一覧ページ |
|------------------------------------|
| <img src="https://github.com/user-attachments/assets/b268225e-1865-415e-b9c7-08be6aa42d3f">|
|タイムラインでは他ユーザーの公開日記を時系列で閲覧できる機能を実装。感情やジャンルによるフィルタリングが可能で、多様な音楽体験を発見できます。気になる曲はその場でプレビュー再生でき、新たな音楽との出会いを促進します。また、過去の日記一覧ページでは自分の記録を日付順、感情別、曲のジャンル別などで整理・表示でき、思い出と紐づいた音楽体験を効率的に振り返ることができます。両機能とも直感的なUIで、音楽を通じた感情の共有と記録の整理を実現しています。|

| X共有（動的OGP） |
|------------------------------------|
| <img src="https://github.com/user-attachments/assets/1a1bc3f6-e60d-44f8-9377-56911f381dbb">|
|アプリ内の日記をX（旧Twitter）で共有する際に動的OGP（Open Graph Protocol）を実装。シェアされた投稿には、選択した曲のアルバム画像、曲名、アーティスト名が自動的にカード形式で表示され、視覚的に魅力的な投稿となります。また、共有時には曲名とアーティスト名が自動的にハッシュタグ化されるため、SNS上での音楽コミュニティとの繋がりを促進します。これにより単なるテキスト投稿ではなく、リッチな音楽体験を共有することが可能になり、ユーザーの音楽の楽しみ方を拡張します。|

## 使用技術

| カテゴリ | 技術 |
|----------|----------------------------------|
| **フロントエンド** | Rails 7.2.2 (Turbo, Stimulus) |
| **バックエンド** | Ruby on Rails 7.2.2 |
| **データベース** | PostgreSQL |
| **インフラ** | Render・Docker |
| **フロントエンド関連** | jsbundling-rails・cssbundling-rails・Hotwire（Turbo+Stimulus） |
| **認証・通信** | Devise・OmniAuth (Google, Spotify)・Gmail SMTP |
| **ストレージ** | AWS S3（Active Storage） |
| **フォーマット・URL** | friendly_id・meta-tags (OGP対応) |
| **バックグラウンド処理** | Sidekiq・Redis・sidekiq-cron |
| **画像処理** | MiniMagick・ImageProcessing |
| **セキュリティ** | rack-attack・omniauth-rails_csrf_protection |
| **ページネーション** | Kaminari |
| **開発環境** | Ruby 3.2.3・Node.js 20.18.0・Yarn 1.22.22 |
| **テスト** | RSpec・FactoryBot・Capybara・Webmock |


## サービスの差別化ポイント・推しポイント

- **音楽日記アプリの独自性**: 多くの日記アプリやプレイリスト管理アプリが存在する中で、「音楽×感情×日記」を組み合わせた体験が最大の差別化ポイント。日々の気分や思い出を音楽と結びつけて記録できる機能が、他にはない独自の魅力です。

- **Spotify連携の充実度**: 高速なオートコンプリート機能と複数の検索条件（曲名、アーティスト名、年代、キーワード）によるきめ細かな音楽検索を実現。デバウンス処理やキャッシュ戦略による快適な検索体験により、ユーザーは任意の曲をストレスなく見つけられます。

- **タイムライン機能での音楽発見**: 他ユーザーの公開日記を通じて新しい音楽との出会いを促進。感情やジャンルでのフィルタリングにより、自分の気分に合った音楽を効率的に発見できる仕組みを提供しています。

- **視覚的な共有体験**: 動的OGP実装により、SNS共有時にアルバム画像、曲名、アーティスト名が自動的に表示される機能を実装。音楽体験をビジュアル面でも魅力的に共有できるため、音楽を通してコミュニケーションが広がります。

### 画面遷移図
Figma（面接前に再作成必至）：
[https://www.figma.com/design/5cLGxpFtDWaefTpKAy3KVt/Untitled?node-id=0-1&node-type=canvas&t=qnxHnhcyWxgzX3fg-0](https://www.figma.com/design/LoUV6glSrHbTYdC5chENuF/mysongjorunal%E7%94%BB%E9%9D%A2%E9%81%B7%E7%A7%BB%E5%9B%B3?node-id=0-1&p=f&t=Tx2yxslpVkX577LF-0)

### ER図
db:diagram:
https://dbdiagram.io/d/6713406d97a66db9a3868632

