// app/javascript/controllers/spotify_modal.js

/**
 * Spotifyモーダルの初期化
 * モーダルの開閉とコンテンツのロードを管理する
 */
export function initializeSpotifyModal() {
  // モーダル関連の要素を取得
  const openModalButton = document.getElementById('open-search-modal');
  const reopenModalButton = document.getElementById('reopen-search-modal');
  const closeModalButton = document.getElementById('close-search-modal');
  const spotifyModal = document.getElementById('spotify-modal');
  const modalContent = document.getElementById('spotify-modal-content');

  // 必要な要素が存在しない場合は初期化を中止
  if (!spotifyModal || !modalContent) {
    console.warn('⚠️ モーダル要素が見つかりません。');
    return;
  }

  /** 
   * モーダルを開く
   * フォームの値を取得してモーダルコンテンツをロードする
   */
  async function openModal() {
    try {
      spotifyModal.showModal();
      
      // ジャーナルフォームから値を取得
      const journalForm = document.getElementById('journal-form');
      if (journalForm) {
        const formData = new FormData(journalForm);
        const params = new URLSearchParams();
        
        // フォームの値をjournalパラメータとしてエンコード
        // 空の値は送信しない
        formData.forEach((value, key) => {
          const match = key.match(/^journal\[(.*?)\]$/);
          if (match && value) {
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

  /** 
   * モーダルを閉じる
   * モーダルを閉じてコンテンツをクリアする
   */
  function closeModal() {
    spotifyModal.close();
    modalContent.innerHTML = '';
  }

  /** 
   * モーダルコンテンツを動的にロード
   * @param {URLSearchParams} params - リクエストパラメータ
   */
  async function loadSpotifyModalContent(params = new URLSearchParams()) {
    try {
      // APIリクエストを実行
      const url = `/spotify/search?${params.toString()}`;
      const response = await fetch(url, {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
      });

      if (!response.ok) {
        throw new Error(`HTTPエラー! ステータス: ${response.status}`);
      }

      // レスポンスをモーダルに表示
      const html = await response.text();
      modalContent.innerHTML = html;

      import('./spotify_autocomplete.js')
        .then((module) => module.initializeSpotifyAutocomplete())
        .catch((error) => console.error('オートコンプリートモジュールの読み込みエラー:', error));
    } catch (error) {
      modalContent.innerHTML = '<p class="text-red-500">検索フォームの読み込みに失敗しました。</p>';
      console.error('モーダルコンテンツのロードエラー:', error);
    }
  }

  // イベントリスナーの設定
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

  // モーダルが閉じられた時のイベントリスナー
  spotifyModal.addEventListener('close', closeModal);
}
