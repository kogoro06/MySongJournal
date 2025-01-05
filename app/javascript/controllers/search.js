// 🎯 検索条件の初期化と動的追加・削除
function initializeSearchConditions() {
  console.log('✅ 検索条件の初期化開始');

  const searchConditionsContainer = document.getElementById('search-conditions');
  const addConditionBtn = document.getElementById('add-condition-btn');
  const removeConditionBtn = document.getElementById('remove-condition-btn');
  const searchForm = document.getElementById('spotify-search-form');
  let conditionId = 0;

  // ✅ 検索条件テンプレート
  const conditionTemplate = (id) => `
    <div class="search-condition mt-4 flex gap-4 items-center" data-condition-id="${id}">
      <select name="search_conditions[]" class="condition-select block w-1/3 px-4 py-2 border rounded-md text-white bg-gray-700">
        <option value="">--条件を選択--</option>
        <option value="track">曲名</option>
        <option value="artist">アーティスト名</option>
        <option value="keyword">キーワード</option>
      </select>
      <input type="text" name="search_values[]" placeholder="キーワードを入力"
        class="block w-2/3 px-4 py-2 border rounded-md text-white bg-gray-700">
    </div>
  `;

  // ✅ 検索条件追加
  addConditionBtn?.addEventListener('click', () => {
    console.log('🟢 「検索条件を追加」ボタンがクリックされました');

    const lastCondition = searchConditionsContainer.querySelector('.search-condition:last-child');
    if (lastCondition) {
      const select = lastCondition.querySelector('select').value;
      const input = lastCondition.querySelector('input').value;
      const isConfirmed = lastCondition.querySelector('.confirm-condition-btn').disabled;

      if (!select || !input || !isConfirmed) {
        alert('⚠️ 前の条件を入力して確定してください。');
        return;
      }
    }

    conditionId += 1;
    searchConditionsContainer.insertAdjacentHTML('beforeend', conditionTemplate(conditionId));
  });

  // ✅ 検索条件削除
  removeConditionBtn?.addEventListener('click', () => {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove();
      console.log('🗑️ 最後の検索条件が削除されました。');
    } else {
      alert('⚠️ 少なくとも1つの条件が必要です。');
    }
  });

  // ✅ 検索フォーム送信
  searchForm?.addEventListener('submit', (event) => {
    console.log('🔎 検索フォームが送信されました');
  });
}

// 🎯 トラック選択機能
function initializeTrackSelection() {
  document.addEventListener('click', (event) => {
    if (event.target.matches('.select-track-btn')) {
      const trackData = JSON.parse(event.target.dataset.track);

      // ✅ 入力フォームにデータをセット
      ['artist_name', 'song_name', 'album_image', 'preview_url'].forEach((key) => {
        const input = document.querySelector(`input[name="journal[${key}]"]`);
        if (input) input.value = trackData[key] || '';
      });

      // ✅ テキスト要素にデータをセット
      document.getElementById('selected-artist-name').textContent = trackData.artist_name || '未選択';
      document.getElementById('selected-song-name').textContent = trackData.song_name || '未選択';

      // ✅ アルバム画像の設定
      const albumImage = document.getElementById('selected-album-image');
      if (albumImage) {
        albumImage.src = trackData.album_image || '';
      }

      // ✅ オーディオ要素の設定
      const audioPlayer = document.getElementById('selected-audio');
      if (audioPlayer) {
        audioPlayer.src = trackData.preview_url || '';
        audioPlayer.load();
      }

      // ✅ モーダルを閉じる
      const spotifyModal = document.getElementById('spotify-modal');
      if (spotifyModal) spotifyModal.close();

      // ✅ ボタンの表示切り替え
      const openModalButton = document.getElementById('open-search-modal');
      const reopenModalButton = document.getElementById('reopen-search-modal');
      if (openModalButton) openModalButton.style.display = 'none';
      if (reopenModalButton) reopenModalButton.style.display = 'block';

      console.log('🎯 トラックが選択されました');
    }
  });
}

// 🎯 初期化関数
function initializeSearchController() {
  initializeSearchConditions();
  initializeTrackSelection();
}

// ✅ TurboとDOMContentLoadedで初期化
document.addEventListener('turbo:load', initializeSearchController);
document.addEventListener('DOMContentLoaded', initializeSearchController);
