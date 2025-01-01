function initializeSearchConditions() {
  console.log('✅ Turbo: ページロードが完了しました');

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
        <option value="album">アルバム名</option>
      </select>
      <input type="text" name="search_values[]" placeholder="キーワードを入力"
        class="block w-2/3 px-4 py-2 border rounded-md text-white bg-gray-700">
      <button type="button" class="confirm-condition-btn px-4 py-2 bg-yellow-500 text-white rounded-md">✔️ 確定</button>
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
    } else {
      alert('⚠️ 少なくとも1つの条件が必要です。');
    }
  });

  // ✅ 検索フォーム送信
  searchForm?.addEventListener('submit', (event) => {
    console.log('🔎 検索フォームが送信されました');
    // Turboが処理を管理するので、searchForm.submit()は呼ばない
  });
}

// ✅ 初期化
document.addEventListener('turbo:load', initializeSearchConditions);
document.addEventLis
