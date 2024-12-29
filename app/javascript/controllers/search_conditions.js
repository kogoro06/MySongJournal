console.group('🔍 ボタン動作デバッグ開始');

// ✅ ページロード時の初期化
function initializeSearchConditions() {
  console.log('✅ Turbo: ページロードが完了しました');

  const searchConditionsContainer = document.getElementById('search-conditions');
  const addConditionBtn = document.getElementById('add-condition-btn');
  const removeConditionBtn = document.getElementById('remove-condition-btn');
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

  // ✅ 検索条件追加ボタン
  if (addConditionBtn && !addConditionBtn.dataset.listenerAttached) {
    addConditionBtn.dataset.listenerAttached = 'true'; // 二重登録防止
    addConditionBtn.addEventListener('click', () => {
      console.log('🟢 「検索条件を追加」ボタンがクリックされました');

      const lastCondition = searchConditionsContainer.querySelector('.search-condition:last-child');
      if (lastCondition) {
        const select = lastCondition.querySelector('select').value;
        const input = lastCondition.querySelector('input').value;
        const isConfirmed = lastCondition.querySelector('.confirm-condition-btn').disabled;

        console.log('🔍 最後の条件 - select:', select);
        console.log('🔍 最後の条件 - input:', input);
        console.log('🔍 最後の条件 - isConfirmed:', isConfirmed);

        if (!select || !input || !isConfirmed) {
          alert('⚠️ 前の条件を入力して確定してください。');
          console.log('⚠️ 前の条件が未入力または未確定です。');
          return;
        }
      }

      conditionId += 1;
      searchConditionsContainer.insertAdjacentHTML('beforeend', conditionTemplate(conditionId));
      console.log(`✅ 新しい条件 (ID: ${conditionId}) が追加されました`);
    });
  } else {
    console.warn('⚠️ 検索条件追加ボタン (add-condition-btn) は既に初期化済みか存在しません');
  }

  // ✅ 確定ボタンで入力欄をロック
  document.addEventListener('click', (event) => {
    if (event.target.classList.contains('confirm-condition-btn')) {
      const conditionDiv = event.target.closest('.search-condition');
      if (conditionDiv) {
        conditionDiv.querySelectorAll('select, input').forEach((el) => {
          el.disabled = true;
        });
        event.target.disabled = true;
        console.log(`🔒 条件 (ID: ${conditionDiv.dataset.conditionId}) が確定されました`);
      } else {
        console.error('❌ 確定ボタンの親要素 (search-condition) が見つかりません');
      }
    }
  });

  // ✅ 検索条件削除ボタン
  if (removeConditionBtn && !removeConditionBtn.dataset.listenerAttached) {
    removeConditionBtn.dataset.listenerAttached = 'true'; // 二重登録防止
    removeConditionBtn.addEventListener('click', () => {
      console.log('➖ 「検索条件を削除」ボタンがクリックされました');

      const conditions = searchConditionsContainer.querySelectorAll('.search-condition');
      if (conditions.length > 1) {
        conditions[conditions.length - 1].remove();
        console.log('🗑️ 最後の条件が削除されました');
      } else {
        alert('⚠️ 少なくとも1つの条件が必要です。');
        console.log('⚠️ 最後の条件を削除できません');
      }
    });
  } else {
    console.warn('⚠️ 検索条件削除ボタン (remove-condition-btn) は既に初期化済みか存在しません');
  }
}

// ✅ TurboとDOMContentLoadedで初期化
document.addEventListener('turbo:load', initializeSearchConditions);
document.addEventListener('DOMContentLoaded', initializeSearchConditions);

console.groupEnd();
