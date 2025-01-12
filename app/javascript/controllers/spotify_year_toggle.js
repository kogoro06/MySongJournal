// app/javascript/controllers/spotify_year_toggle.js

/** ✅ 年代検索用UIの初期化 */
export function initializeYearToggle() {
  console.log('✅ 年代検索の初期化開始');

  const searchTypeSelect = document.getElementById('initial-search-type');
  const queryContainer = document.getElementById('initial-query-container');

  if (!searchTypeSelect || !queryContainer) {
    console.warn('⚠️ 検索タイプまたは検索フィールドコンテナが見つかりません。');
    return;
  }

  /** 🔄 検索タイプ変更時の処理 */
  searchTypeSelect.addEventListener('change', async () => {
    if (searchTypeSelect.value === 'year') {
      await loadYearSearchTemplate(queryContainer);
    } else {
      resetToTextInput(queryContainer);
    }
  });

  console.log('✅ 年代トグルの初期化完了');
}

/** 📥 年代検索用フォームを動的にロード */
async function loadYearSearchTemplate(queryContainer) {
  try {
    const response = await fetch('/spotify/year_search_template', {
      headers: { 'X-Requested-With': 'XMLHttpRequest' }
    });

    if (!response.ok) {
      throw new Error(`HTTPエラー! ステータス: ${response.status}`);
    }

    const yearSearchHtml = await response.text();
    queryContainer.innerHTML = yearSearchHtml;

    console.log('🟢 年代検索用フォームがロードされました');

    // 新しい要素にイベントリスナーを再設定
    const newQueryInput = queryContainer.querySelector('select');
    if (newQueryInput) {
      addYearSearchEventListener(newQueryInput);
    }
  } catch (error) {
    console.error('❌ 年代検索フォームのロードに失敗:', error);
  }
}

/** 📝 テキスト入力フィールドにリセット */
function resetToTextInput(queryContainer) {
  queryContainer.innerHTML = `
    <input type="text" name="initial_query" id="initial-query" placeholder="キーワードを入力"
      class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
  `;
  console.log('🟢 検索フィールドがテキスト入力に戻りました');

  const newQueryInput = document.getElementById('initial-query');
  if (newQueryInput) {
    addTextInputEventListener(newQueryInput);
  }
}

/** 🎯 年代検索用フィールドのイベントリスナー */
function addYearSearchEventListener(inputElement) {
  inputElement.addEventListener('change', (event) => {
    console.log('📅 年代が選択されました:', event.target.value);
  });
}

/** 🎯 テキスト検索用フィールドのイベントリスナー */
function addTextInputEventListener(inputElement) {
  inputElement.addEventListener('input', (event) => {
    const query = event.target.value.trim();
    if (query === '') {
      console.log('ℹ️ 入力が空です');
      return;
    }

    fetch(`/spotify_search?query=${query}`)
      .then((response) => response.json())
      .then((data) => {
        console.log('🔍 検索結果:', data);
      })
      .catch((error) => console.error('❌ テキスト検索APIエラー:', error));
  });
}
