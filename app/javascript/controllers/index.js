/**
 * ⚠️ 自動生成ファイル
 * このファイルは自動生成されます。手動での編集は避けてください。
 * 新しいコントローラーを追加する場合は以下のコマンドを実行：
 * ./bin/rails stimulus:manifest:update
 */

// 🎮 Stimulusアプリケーションのインポート
import { application } from "./application"

// 📝 各コントローラーのインポートと登録
// サンプルコントローラー
import HelloController from "./hello_controller"
application.register("hello", HelloController)

// Spotify検索機能のコントローラー
import SpotifySearchController from "./spotify_search_controller"
application.register("spotify-search", SpotifySearchController)
