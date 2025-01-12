/** ✅ 年代検索用UIの初期化 */
export function initializeYearToggle() {
  console.log('✅ 年代検索の初期化開始');

  const searchConditionsContainer = document.getElementById('search-conditions');

  if (!searchConditionsContainer) {
    console.warn('⚠️ 検索条件コンテナが見つかりません。');
    return;
  }

  /** 🔄 検索タイプ変更時の処理 */
  function handleSearchTypeChange(event) {
    const select = event.target;
    const queryContainer = select.closest('.search-condition').querySelector('.query-container');

    if (!queryContainer) {
      console.warn('⚠️ 対応する queryContainer が見つかりません。');
      return;
    }

    if (select.value === 'year') {
      loadYearSearchTemplate(queryContainer);
    } else {
      resetToTextInput(queryContainer);
    }
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
      queryContainer.innerHTML = '<p class="text-red-500">フォームの読み込みに失敗しました。</p>';
    }
  }

  /** 📝 テキスト入力フィールドにリセット */
  function resetToTextInput(queryContainer) {
    queryContainer.innerHTML = `
      <input type="text" name="search_values[]" placeholder="キーワードを入力" class="input input-bordered w-full px-4 py-2 rounded-md bg-gray-700 text-white">
    `;
    console.log('🟢 検索フィールドがテキスト入力に戻りました');

    const newQueryInput = queryContainer.querySelector('input');
    if (newQueryInput) {
      addTextInputEventListener(newQueryInput);
    }
  }

  /** 🎯 年代検索用フィールドのイベントリスナー */
  function addYearSearchEventListener(selectElement) {
    selectElement.addEventListener('change', (event) => {
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

  // 既存の検索条件にイベントリスナーを設定
  document.querySelectorAll('.search-condition select[name="search_conditions[]"]').forEach((select) => {
    select.addEventListener('change', handleSearchTypeChange);
  });

  // 動的に追加される検索条件を監視
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'childList') {
        mutation.addedNodes.forEach((node) => {
          if (node.classList && node.classList.contains('search-condition')) {
            const newSelect = node.querySelector('select[name="search_conditions[]"]');
            if (newSelect) {
              newSelect.addEventListener('change', handleSearchTypeChange);
            }
          }
        });
      }
    });
  });

  observer.observe(searchConditionsContainer, { childList: true, subtree: true });

  console.log('✅ 年代トグルの初期化完了');
}
