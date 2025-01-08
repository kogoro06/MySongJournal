// app/javascript/controllers/spotify_search.js

/** ✅ 検索条件の初期化 */
export function initializeSearchConditions() {
  console.log('✅ 検索条件の初期化開始');

  const searchConditionsContainer = document.getElementById('search-conditions');
  const addConditionBtn = document.getElementById('add-condition-btn');
  const removeConditionBtn = document.getElementById('remove-condition-btn');
  const MAX_CONDITIONS = 2; // 最大条件数

  if (!searchConditionsContainer || !addConditionBtn || !removeConditionBtn) {
    console.warn('⚠️ 検索条件の要素が見つかりません。');
    return;
  }

  let conditionId = 0; // 条件IDのカウンター

  /** 🔄 次の検索条件IDを取得 */
  function getNextConditionId() {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    const ids = Array.from(conditions).map((c) => parseInt(c.dataset.conditionId, 10) || 0);
    return Math.max(0, ...ids) + 1;
  }

  /** 📝 検索条件のテンプレート */
  function createConditionTemplate(id) {
    return `
      <div class="search-condition mt-4" data-condition-id="${id}">
        <div class="mb-4">
          <label class="block text-sm font-medium text-white mb-2">🔍 検索タイプ</label>
          <select name="search_conditions[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
            <option value="">検索タイプを選択</option>
            <option value="track">曲名</option>
            <option value="artist">アーティスト名</option>
            <option value="keyword">キーワード</option>
            <option value="year">年代</option>
          </select>
        </div>
        <div class="mb-6" id="query-container-${id}">
          <input type="text" name="search_values[]" placeholder="キーワードを入力" class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
        </div>
      </div>
    `;
  }

  /** ➕ 検索条件を追加 */
  addConditionBtn.addEventListener('click', () => {
    if (searchConditionsContainer.querySelectorAll('.search-condition').length < MAX_CONDITIONS) {
      const id = getNextConditionId();
      searchConditionsContainer.insertAdjacentHTML('beforeend', createConditionTemplate(id));
      console.log(`🟢 検索条件${id}が追加されました`);
      updateButtonStates();
    }
  });

  /** ➖ 検索条件を削除 */
  removeConditionBtn.addEventListener('click', () => {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove();
      console.log('🗑️ 最後の検索条件が削除されました。');
      updateButtonStates();
    }
  });

  /** 🔄 ボタン状態の更新 */
  function updateButtonStates() {
    const conditionCount = searchConditionsContainer.querySelectorAll('.search-condition').length;
    addConditionBtn.disabled = conditionCount >= MAX_CONDITIONS;
    removeConditionBtn.disabled = conditionCount <= 1;
  }

  /** 🛠️ 検索タイプ変更時のリスナー */
  searchConditionsContainer.addEventListener('change', (event) => {
    if (event.target.classList.contains('condition-select')) {
      const container = event.target.closest('.search-condition');
      const queryContainer = container.querySelector('[id^="query-container-"]');

      if (event.target.value === 'year') {
        queryContainer.innerHTML = `
          <select name="search_values[]" class="condition-select block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
            <option value="">年代を選択</option>
            ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}">${2000 + i}</option>`).join('')}
          </select>
        `;
      } else {
        queryContainer.innerHTML = `
          <input type="text" name="search_values[]" placeholder="キーワードを入力"
            class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
        `;
      }
    }
  });

  updateButtonStates();
  console.log('✅ 検索条件の初期化完了');
}
