// 🎮 Stimulusの基本設定ファイル
import { Application } from "@hotwired/stimulus"

// ⚡️ Stimulusアプリケーションの初期化
const application = Application.start()

// 🛠 開発環境の設定
// デバッグモードをオフに設定（必要に応じてtrueに変更可能）
application.debug = false

// 🌍 グローバルアクセス用の設定
// 開発ツールからアクセス可能にする
window.Stimulus = application

// 📤 他のファイルで使用できるようにエクスポート
export { application }

document.addEventListener('turbo:load', function() {
  const tabs = document.querySelectorAll('.tab');
  tabs.forEach(tab => {
    tab.addEventListener('click', function() {
      document.querySelector('.tab-active').classList.remove('tab-active');
      this.classList.add('tab-active');
    });
  });
});
