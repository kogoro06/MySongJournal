// ✅ 検索条件の初期化と動的追加・削除
export function initializeSearchConditions() {
  console.log('✅ 検索条件の初期化開始');

  const searchConditionsContainer = document.getElementById('search-conditions');
  const addConditionBtn = document.getElementById('add-condition-btn');
  const removeConditionBtn = document.getElementById('remove-condition-btn');
  const searchForm = document.getElementById('spotify-search-form');
  const initialSearchType = document.getElementById('initial-search-type');
  const initialQuery = document.getElementById('initial-query');

  let conditionId = 0;
  const MAX_CONDITIONS = 3;

  if (!searchConditionsContainer || !addConditionBtn || !removeConditionBtn || !searchForm || !initialSearchType || !initialQuery) {
    console.warn('⚠️ 検索条件関連の要素が見つかりません。');
    return;
  }

  // ✅ 検索条件テンプレート
  const conditionTemplate = (id) => `
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
      <div class="mb-6">
        <label class="block text-sm font-medium text-white mb-2">📝 検索キーワード</label>
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

  // ✅ 検索条件追加
  addConditionBtn.addEventListener('click', () => {
    if (searchConditionsContainer.querySelectorAll('.search-condition').length < MAX_CONDITIONS) {
      conditionId += 1;
      searchConditionsContainer.insertAdjacentHTML('beforeend', conditionTemplate(conditionId));
      updateButtonStates();
      console.log(`🟢 検索条件${conditionId}が追加されました`);
    }
  });

  // ✅ 検索条件削除
  removeConditionBtn.addEventListener('click', () => {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    if (conditions.length >= 1) {
      conditions[conditions.length - 1].remove();
      updateButtonStates();
      console.log('🗑️ 最後の検索条件が削除されました。');
    }
  });

  // ✅ 検索バリデーション
  searchForm.addEventListener('submit', (event) => {
    const errors = [];

    if (!initialSearchType.value.trim()) {
      errors.push('⚠️ 検索タイプが選択されていません。');
    }
    if (!initialQuery.value.trim()) {
      errors.push('⚠️ 検索キーワードが入力されていません。');
    }

    if (errors.length > 0) {
      event.preventDefault();
      alert(errors.join('\n'));
      console.warn('❌ 検索バリデーションエラー:', errors);
    }
  });

  // 初期状態を設定
  updateButtonStates();
}
