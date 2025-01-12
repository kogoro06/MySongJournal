/** ✅ 検索条件の初期化 */
export function initializeSearchConditions() {
  console.log('✅ 検索条件の初期化開始');

  // DOM要素の取得
  const searchConditionsContainer = document.getElementById('search-conditions');
  const addConditionBtn = document.getElementById('add-condition-btn');
  const removeConditionBtn = document.getElementById('remove-condition-btn');
  const MAX_CONDITIONS = 2; // 最大条件数

  // 必要な要素が存在するかチェック
  if (!searchConditionsContainer || !addConditionBtn || !removeConditionBtn) {
    console.warn('⚠️ 検索条件の要素が見つかりません。');
    return;
  }

  /** 🔄 次の検索条件IDを取得 */
  function getNextConditionId() {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    const ids = Array.from(conditions).map((c) => parseInt(c.dataset.conditionId, 10) || 0);
    return Math.max(0, ...ids) + 1;
  }

  /** 📝 検索条件のテンプレート生成 */
  function createConditionTemplate(id) {
    return `
      <div class="search-condition mt-4" data-condition-id="${id}">
        <div class="mb-4">
          <label class="block text-md font-medium text-white mb-2">🔍 検索タイプ</label>
          <select name="search_conditions[]" class="select select-bordered w-full px-4 py-2 rounded-md bg-gray-700 text-white">
            <option value="">検索タイプを選択</option>
            <option value="track">曲名</option>
            <option value="artist">アーティスト名</option>
            <option value="keyword">キーワード</option>
            <option value="year">年代</option>
          </select>
        </div>
        <div class="mb-4">
          <label class="block text-md font-medium text-white mb-2">📝 検索キーワード</label>
          <div id="query-container-${id}">
            <input type="text" name="search_values[]" placeholder="キーワードを入力" class="input input-bordered w-full px-4 py-2 rounded-md bg-gray-700 text-white">
          </div>
        </div>
      </div>
    `;
  }

  /** ➕ 検索条件を追加 */
  function addCondition() {
    if (searchConditionsContainer.querySelectorAll('.search-condition').length < MAX_CONDITIONS) {
      const id = getNextConditionId();
      searchConditionsContainer.insertAdjacentHTML('beforeend', createConditionTemplate(id));
      console.log(`🟢 検索条件 ${id} が追加されました`);
      updateButtonStates();
    }
  }

  /** ➖ 検索条件を削除 */
  function removeCondition() {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove();
      console.log('🗑️ 最後の検索条件が削除されました。');
      updateButtonStates();
    }
  }

  /** 🔄 ボタン状態の更新 */
  function updateButtonStates() {
    const conditionCount = searchConditionsContainer.querySelectorAll('.search-condition').length;
    addConditionBtn.disabled = conditionCount >= MAX_CONDITIONS;
    removeConditionBtn.disabled = conditionCount <= 1;
  }

  /** 🔄 検索タイプ変更時の処理 */
  function handleConditionTypeChange(event) {
    if (event.target.classList.contains('select')) {
      const container = event.target.closest('.search-condition');
      const queryContainer = container.querySelector('[id^="query-container-"]');

      if (event.target.value === 'year') {
        queryContainer.innerHTML = `
          <select name="search_values[]" class="select select-bordered w-full px-4 py-2 rounded-md bg-gray-700 text-white">
            <option value="">年代を選択</option>
            ${Array.from({ length: 26 }, (_, i) => `<option value="${2000 + i}">${2000 + i}</option>`).join('')}
          </select>
        `;
      } else {
        queryContainer.innerHTML = `
          <input type="text" name="search_values[]" placeholder="キーワードを入力" class="input input-bordered w-full px-4 py-2 rounded-md bg-gray-700 text-white">
        `;
      }
    }
  }

  // イベントリスナーを登録
  addConditionBtn.addEventListener('click', addCondition);
  removeConditionBtn.addEventListener('click', removeCondition);
  searchConditionsContainer.addEventListener('change', handleConditionTypeChange);

  // 初期状態のボタン設定
  updateButtonStates();
  console.log('✅ 検索条件の初期化完了');
}
