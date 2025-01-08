import { initializeUserInput } from './user_input'; // user_input.jsをインポート

// ✅ 検索条件の初期化と動的追加・削除
export function initializeSearchConditions() {
  console.log('✅ 検索条件の初期化開始');

  const searchConditionsContainer = document.getElementById('search-conditions');
  const addConditionBtn = document.getElementById('add-condition-btn');
  const removeConditionBtn = document.getElementById('remove-condition-btn');
  const searchForm = document.getElementById('spotify-search-form');
  let conditionId = 0; // 条件IDのカウンター
  const MAX_CONDITIONS = 2; // 初期条件 + 追加2つ

  if (!searchConditionsContainer || !addConditionBtn || !removeConditionBtn || !searchForm) {
    console.warn('⚠️ 検索条件関連の要素が見つかりません。');
    return;
  }

  // ✅ conditionId を動的に再計算する関数
  function getNextConditionId() {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    const ids = Array.from(conditions).map((condition) => parseInt(condition.dataset.conditionId, 10) || 0);
    return Math.max(0, ...ids) + 1;
  }

  // ✅ 検索条件テンプレート
  const conditionTemplate = (id, searchType = '', queryValue = '') => `
    <div class="search-condition mt-4" data-condition-id="${id}">
      <div class="mb-4">
        <label class="block text-sm font-medium text-white mb-2">🔍 検索タイプ</label>
        <select name="search_conditions[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700" data-condition-id="${id}">
          <option value="">検索タイプを選択</option>
          <option value="track" ${searchType === 'track' ? 'selected' : ''}>曲名</option>
          <option value="artist" ${searchType === 'artist' ? 'selected' : ''}>アーティスト名</option>
          <option value="keyword" ${searchType === 'keyword' ? 'selected' : ''}>キーワード</option>
          <option value="year" ${searchType === 'year' ? 'selected' : ''}>年代</option>
        </select>
      </div>
      <div class="mb-6" id="query-container-${id}">
        ${
          searchType === 'year'
            ? `<select name="search_values[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
                <option value="">年代を選択</option>
                ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}" ${queryValue === String(2000 + i) ? 'selected' : ''}>${2000 + i}</option>`).join('')}
              </select>`
            : `<input type="text" name="search_values[]" value="${queryValue}" placeholder="キーワードを入力"
                class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">`
        }
      </div>
    </div>
  `;

  // ✅ ボタン状態を更新
  function updateButtonStates() {
    const conditionCount = searchConditionsContainer.querySelectorAll('.search-condition').length;
    addConditionBtn.disabled = conditionCount >= MAX_CONDITIONS;
    removeConditionBtn.disabled = conditionCount <= 1;
    console.log(`🔄 現在の条件数: ${conditionCount}`);
  }

// 検索タイプ変更時の処理
function attachConditionListeners(id) {
  const searchType = document.querySelector(`[data-condition-id="${id}"] .condition-select`);
  const queryContainer = document.getElementById(`query-container-${id}`);

  if (!searchType || !queryContainer) {
    console.warn(`⚠️ 検索タイプまたは検索フィールドコンテナが見つかりません。ID: ${id}`);
    return;
  }

  // 検索タイプが変更されたときに処理
  searchType.addEventListener('change', () => {
    const currentQueryValue = queryContainer.querySelector('input, select')?.value || '';

    // 検索タイプに応じて入力フィールドを更新
    if (searchType.value === 'year') {
      queryContainer.innerHTML = `
        <select name="search_values[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
          <option value="">年代を選択</option>
          ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}" ${currentQueryValue === String(2000 + i) ? 'selected' : ''}>${2000 + i}</option>`).join('')}
        </select>
      `;
    } else {
      queryContainer.innerHTML = `
        <input type="text" name="search_values[]" value="${currentQueryValue}" placeholder="キーワードを入力"
          class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
      `;
    }
  });
}

  // ✅ 検索条件追加
  addConditionBtn.addEventListener('click', () => {
    if (searchConditionsContainer.querySelectorAll('.search-condition').length < MAX_CONDITIONS) {
      const id = getNextConditionId();
      searchConditionsContainer.insertAdjacentHTML('beforeend', conditionTemplate(id));
      attachConditionListeners(id);
      updateButtonStates();
      console.log(`🟢 検索条件${id}が追加されました`);
    }
  });

  // ✅ 検索条件削除
  removeConditionBtn.addEventListener('click', () => {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove();
      updateButtonStates();
      console.log('🗑️ 最後の検索条件が削除されました。');
    }
  });

  // ✅ 初期条件にリスナーを適用
  attachConditionListeners('initial');

  // ✅ 初期状態を設定
  updateButtonStates();
}

// ✅ 初期化関数
function initializeSpotifySearch() {
  initializeSearchConditions();
}

// ✅ TurboとDOMContentLoadedで初期化
document.addEventListener('turbo:load', initializeSpotifySearch);
document.addEventListener('turbo:render', initializeSpotifySearch);
document.addEventListener('DOMContentLoaded', initializeSpotifySearch);

// ユーザー入力の初期化
document.addEventListener('turbo:load', () => {
  initializeUserInput();
});

document.addEventListener('turbo:render', () => {
  initializeUserInput();
});

document.addEventListener('DOMContentLoaded', () => {
  initializeUserInput();
});
