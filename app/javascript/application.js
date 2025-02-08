// ⚡️ アプリケーションのエントリーポイント
// Turbo Railsをインポートして、ページ遷移を高速化
import "@hotwired/turbo-rails"
// Stimulusコントローラーをインポートして、インタラクティブな機能を追加
import "./controllers"

// 🎵 Spotify関連機能のインポート
// モーダルウィンドウの制御機能をインポート
import { initializeSpotifyModal } from "./controllers/spotify_modal"
/** 
 * ✨ Spotify関連機能の初期化
 * モーダル、オートコンプリート、入力フィールドの設定を行う
 * 各機能の初期化を順番に実行し、エラーハンドリングも行う
 */
function initializeSpotifySearch() {

  try {
    // モーダルウィンドウの初期化を実行
    initializeSpotifyModal();

    // 楽曲検索の自動補完機能を初期化
    initializeSpotifyAutocomplete();

    // 楽曲情報入力フィールドの初期化
    initializeSpotifyInput();
    console.log('✅ 入力フィールドが初期化されました');
  } catch (error) {
    // エラーが発生した場合はコンソールにエラー内容を出力
    console.error('❌ 初期化中にエラーが発生しました:', error);
  }
}

/** 
 * 🔄 ページ遷移時の再初期化設定
 * Turboとの連携のため、各イベントで初期化関数を実行
 * - turbo:load: Turboによるページ読み込み完了時
 * - turbo:render: Turboによるページレンダリング完了時
 * - DOMContentLoaded: 通常のページ読み込み完了時
 */
document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);
