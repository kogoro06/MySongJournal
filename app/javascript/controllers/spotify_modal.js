// app/javascript/controllers/spotify_modal.js

/** Spotifyモーダルの初期化 */
export default class SpotifyModalController {
  constructor() {
    console.log('✅ Spotifyモーダルの初期化開始');

    const openModalButton = document.getElementById('open-search-modal');
    const reopenModalButton = document.getElementById('reopen-search-modal');
    const closeModalButton = document.getElementById('close-search-modal');
    const spotifyModal = document.getElementById('spotify-modal');
    const modalContent = document.getElementById('spotify-modal-content');

    if (!spotifyModal || !modalContent) {
      console.warn('⚠️ モーダル要素が見つかりません。');
      return;
    }

    /** 🎯 モーダルを開く */
    async function openModal() {
      console.log('🟢 モーダルを開きます');
      try {
        spotifyModal.showModal();
        
        // フォームの値を取得
        const journalForm = document.getElementById('journal-form');
        if (journalForm) {
          const formData = new FormData(journalForm);
          const params = new URLSearchParams();
          
          // フォームの値をjournalパラメータとしてエンコード
          formData.forEach((value, key) => {
            const match = key.match(/^journal\[(.*?)\]$/);
            if (match && value) {  // 空の値は送信しない
              params.append(`journal[${match[1]}]`, value);
            }
          });

          // パラメータ付きでモーダルコンテンツをロード
          await loadSpotifyModalContent(params);
        } else {
          await loadSpotifyModalContent();
        }
      } catch (error) {
        console.error('❌ showModalが失敗しました:', error);
      }
    }

    /** 🛑 モーダルを閉じる */
    function closeModal() {
      console.log('🛑 モーダルを閉じます');
      spotifyModal.close();
      modalContent.innerHTML = '';
    }

    /** 📥 モーダルコンテンツを動的にロード */
    async function loadSpotifyModalContent(params = new URLSearchParams()) {
      try {
        const url = `/spotify/search?${params.toString()}`;
        const response = await fetch(url, {
          headers: { 'X-Requested-With': 'XMLHttpRequest' }
        });

        if (!response.ok) {
          throw new Error(`HTTPエラー! ステータス: ${response.status}`);
        }

        const html = await response.text();
        modalContent.innerHTML = html;

        console.log('🟢 モーダルコンテンツがロードされました');

        // 検索条件モジュールの初期化
        import('./spotify_search.js')
          .then((module) => module.initializeSearchConditions())
          .catch((error) => console.error('❌ 検索条件モジュールの読み込みエラー:', error));

        import('./spotify_autocomplete.js')
          .then((module) => module.initializeSpotifyAutocomplete())
          .catch((error) => console.error('❌ オートコンプリートモジュールの読み込みエラー:', error));
      } catch (error) {
        modalContent.innerHTML = '<p class="text-red-500">検索フォームの読み込みに失敗しました。</p>';
        console.error('❌ モーダルコンテンツのロードエラー:', error);
      }
    }

    /** 🎯 イベントリスナーを設定 */
    if (openModalButton) {
      openModalButton.addEventListener('click', openModal);
      console.log('🟢 openModalButton イベントリスナーが設定されました');
    }

    if (reopenModalButton) {
      reopenModalButton.addEventListener('click', openModal);
      console.log('🟢 reopenModalButton イベントリスナーが設定されました');
    }

    if (closeModalButton) {
      closeModalButton.addEventListener('click', closeModal);
      console.log('🟢 closeModalButton イベントリスナーが設定されました');
    }

    spotifyModal.addEventListener('close', closeModal);
  }
}
