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

  let usedSearchTypes = []; // 選択済みの検索タイプを追跡

  /** 🔄 次の検索条件IDを取得 */
  function getNextConditionId() {
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
    const ids = Array.from(conditions).map((c) => parseInt(c.dataset.conditionId, 10) || 0);
    return Math.max(0, ...ids) + 1;
  }

  /** 📝 検索条件のテンプレート生成 */
  function createConditionTemplate(id, selectedType = '', value = '') {
    return `
      <div class="search-condition mt-4" data-condition-id="${id}">
        <div class="mb-4">
          <label class="block text-md font-medium text-white mb-2">🔍 検索タイプ</label>
          <select name="search_conditions[]" class="select select-bordered w-full px-4 py-2 rounded-md bg-gray-700 text-white" data-condition-id="${id}" onchange="updateUsedSearchTypes()">
            <option value="" ${selectedType === '' ? 'selected' : ''}>検索タイプを選択</option>
            ${getAllSearchTypes()
              .map(
                (type) =>
                  `<option value="${type}" ${type === selectedType ? 'selected' : ''} ${
                    usedSearchTypes.includes(type) && type !== selectedType ? 'disabled' : ''
                  }>${getSearchTypeLabel(type)}</option>`
              )
              .join('')}
          </select>
        </div>
        <div class="mb-4">
          <label class="block text-md font-medium text-white mb-2">📝 検索キーワード</label>
          <div id="query-container-${id}">
            ${generateTextInput(value)}
          </div>
        </div>
      </div>
    `;
  }

  /** 📝 テキスト入力生成 */
  function generateTextInput(value) {
    return `
      <input type="text" name="search_values[]" value="${value}" placeholder="キーワードを入力" class="input input-bordered w-full px-4 py-2 rounded-md bg-gray-700 text-white">
    `;
  }

  /** 🔄 全検索タイプを取得 */
  function getAllSearchTypes() {
    return ['track', 'artist', 'keyword'];
  }

  /** 🛠️ 利用可能な検索タイプを取得 */
  function getAvailableSearchTypes() {
    return getAllSearchTypes().filter((type) => !usedSearchTypes.includes(type));
  }

  /** 🏷️ 検索タイプのラベルを取得 */
  function getSearchTypeLabel(type) {
    const labels = {
      track: '曲名',
      artist: 'アーティスト名',
      keyword: 'キーワード',
    };
    return labels[type] || type;
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
      const lastCondition = conditions[conditions.length - 1];
      const lastType = lastCondition.querySelector('select').value;
      usedSearchTypes = usedSearchTypes.filter((type) => type !== lastType); // 選択済みタイプから削除
      lastCondition.remove();
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

  /** 検索条件が正しいかチェック */
  function validateSearchConditions() {
    let isValid = true;
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition');

    conditions.forEach((condition) => {
      const searchType = condition.querySelector('select').value;
      const searchValue = condition.querySelector('input')?.value.trim();

      if (!searchType || !searchValue) {
        isValid = false;
      }
    });

    return isValid;
  }

  /** 検索ボタンがクリックされたときの処理 */
  function handleFormSubmit(event) {
    event.preventDefault(); // 画面遷移を防止

    // 検索条件が不正な場合はアラートを表示
    if (!validateSearchConditions()) {
      alert("検索条件が不完全です。検索キーワードとタイプを正しく入力してください。");
      return;
    }

    // 検索フォームを送信
    const form = event.target;
    form.submit();
  }

  /** 検索条件タイプが変更されたときの処理 */
  function handleConditionTypeChange(event) {
    if (event.target.classList.contains('select')) {
      const container = event.target.closest('.search-condition');
      const queryContainer = container?.querySelector('[id^="query-container-"]');

      if (!queryContainer) return;

      const id = container.dataset.conditionId;
      const previousType = event.target.dataset.previousValue || '';
      const newType = event.target.value;

      if (previousType && previousType !== newType) {
        usedSearchTypes = usedSearchTypes.filter((type) => type !== previousType);
      }
      if (newType && newType !== previousType) {
        usedSearchTypes.push(newType);
      }

      // タイプを切り替えた場合、キーワードをリセット
      queryContainer.innerHTML = generateTextInput('');

      event.target.dataset.previousValue = newType; // 新しいタイプを保存
    }
  }

  /** 検索条件が変更された後、選択したタイプを更新する */
  function updateUsedSearchTypes() {
    usedSearchTypes = [];
    const conditions = searchConditionsContainer.querySelectorAll('.search-condition select');
    conditions.forEach((select) => {
      const type = select.value;
      if (type) {
        usedSearchTypes.push(type);
      }
    });

    // 再度、利用可能な検索タイプを反映
    searchConditionsContainer.querySelectorAll('.search-condition select').forEach((select) => {
      const options = select.querySelectorAll('option');
      options.forEach((option) => {
        if (usedSearchTypes.includes(option.value) && option.value !== select.value) {
          option.disabled = true;
        } else {
          option.disabled = false;
        }
      });
    });
  }

  /** 検索結果を処理 */
  function handleInputValueChange(event) {
    if (event.target.tagName === 'SELECT' || event.target.tagName === 'INPUT') {
      const container = event.target.closest('.search-condition');
      const id = container.dataset.conditionId;
      console.log(`条件ID ${id} の値が更新されました: ${event.target.value}`);
    }
  }

  // イベントリスナーを登録
  addConditionBtn.addEventListener('click', addCondition);
  removeConditionBtn.addEventListener('click', removeCondition);
  searchConditionsContainer.addEventListener('change', handleConditionTypeChange);
  searchConditionsContainer.addEventListener('input', handleInputValueChange);

  // 検索フォームの送信イベント
  const form = document.getElementById('spotify-search-form');
  if (form) {
    form.addEventListener('submit', handleFormSubmit);
  }

  updateButtonStates();
  console.log('✅ 検索条件の初期化完了');
}
