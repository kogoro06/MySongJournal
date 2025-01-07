// ✅ 検索条件の初期化と動的追加・削除
export function initializeSearchConditions() {
  console.log('✅ 検索条件の初期化開始');

  const searchConditionsContainer = document.getElementById('search-conditions');
  const addConditionBtn = document.getElementById('add-condition-btn');
  const removeConditionBtn = document.getElementById('remove-condition-btn');
  const searchForm = document.getElementById('spotify-search-form');
  let conditionId = 0; // 条件IDのカウンター
  const MAX_CONDITIONS = 3; // 初期条件 + 追加2つ

  if (!searchConditionsContainer || !addConditionBtn || !removeConditionBtn || !searchForm) {
    console.warn('⚠️ 検索条件関連の要素が見つかりません。');
    return;
  }


  // ✅ conditionId を動的に再計算する関数
  function getNextConditionId() {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    let maxId = 0;
    conditions.forEach(condition => {
      const id = parseInt(condition.dataset.conditionId, 10);
      if (!isNaN(id) && id > maxId) {
        maxId = id;
      }
    });
    return maxId + 1;
  }

  // ✅ 検索条件テンプレート
  const conditionTemplate = (id) => `
    <div class="search-condition mt-4" data-condition-id="${id}">
      <div class="mb-4">
        <label class="block text-sm font-medium text-white mb-2">🔍 検索タイプ</label>
        <select name="search_conditions[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700" data-condition-id="${id}">
          <option value="">検索タイプを選択</option>
          <option value="track">曲名</option>
          <option value="artist">アーティスト名</option>
          <option value="keyword">キーワード</option>
          <option value="year">年代</option>
        </select>
      </div>
      <div class="mb-6" id="query-container-${id}">
        <input type="text" name="search_values[]" placeholder="キーワードを入力"
          class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
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

  // ✅ 検索タイプ変更時の処理
  function attachConditionListeners(id) {
    const searchType = document.querySelector(`[data-condition-id="${id}"]`);
    const queryContainer = document.getElementById(`query-container-${id}`);

    if (!searchType || !queryContainer) {
      console.warn(`⚠️ 検索タイプまたは検索フィールドコンテナが見つかりません。ID: ${id}`);
      return;
    }

    searchType.addEventListener('change', () => {
      if (searchType.value === 'year') {
        queryContainer.innerHTML = `
          <select name="search_values[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
            <option value="">年代を選択</option>
            ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}">${2000 + i}</option>`).join('')}
          </select>
        `;
        console.log(`🟢 検索フィールド ${id} が年代選択に切り替わりました`);
      } else {
        queryContainer.innerHTML = `
          <input type="text" name="search_values[]" placeholder="キーワードを入力"
            class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
        `;
        console.log(`🟢 検索フィールド ${id} がテキスト入力に戻りました`);
      }
    });
  }

// ✅ 検索条件追加 (重複イベントを防止)
if (!addConditionBtn.dataset.listenerAdded) {
  addConditionBtn.addEventListener('click', () => {
    if (searchConditionsContainer.querySelectorAll('.search-condition').length < MAX_CONDITIONS) {
      conditionId += 1;
      searchConditionsContainer.insertAdjacentHTML('beforeend', conditionTemplate(conditionId));
      attachConditionListeners(conditionId);
      updateButtonStates();
      console.log(`🟢 検索条件${conditionId}が追加されました`);
    }
  });
  addConditionBtn.dataset.listenerAdded = 'true';
}

// ✅ 検索条件削除 (重複イベントを防止)
if (!removeConditionBtn.dataset.listenerAdded) {
  removeConditionBtn.addEventListener('click', () => {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove();
      updateButtonStates();
      console.log('🗑️ 最後の検索条件が削除されました。');
    }
  });
  removeConditionBtn.dataset.listenerAdded = 'true';
}

  // ✅ 初期条件にリスナーを適用
  searchConditionsContainer.querySelectorAll('.search-condition').forEach((condition) => {
    const id = condition.dataset.conditionId;
    attachConditionListeners(id);
  });

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
