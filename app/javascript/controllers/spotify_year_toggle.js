// ✅ 年代検索用フォームを動的にロード
async function loadYearSearchTemplate() {
    try {
      const response = await fetch('/spotify/year_search_template', {
        headers: { 'X-Requested-With': 'XMLHttpRequest' }
      });
  
      if (!response.ok) {
        throw new Error(`HTTPエラー! ステータス: ${response.status}`);
      }
  
      const yearSearchHtml = await response.text();
      const queryContainer = document.getElementById('initial-query-container');
  
      if (queryContainer) {
        queryContainer.innerHTML = yearSearchHtml;
        console.log('🟢 年代検索用フォームがロードされました');
        
        // 新しく生成された要素にイベントリスナーを再設定
        const newQueryInput = document.getElementById('initial-query');
        if (newQueryInput) {
          addInputEventListener(newQueryInput);
        }
      } else {
        console.warn('⚠️ initial-query-container が見つかりません。');
      }
    } catch (error) {
      console.error('❌ 年代検索フォームのロードに失敗:', error);
    }
  }
  
  // 入力フィールドのイベントリスナーを追加する関数
  function addInputEventListener(queryInput) {
    queryInput.addEventListener('input', function (event) {
      const query = event.target.value.trim();
  
      if (query === '') {
        autoCompleteList.innerHTML = '';
        return;
      }
  
      // APIリクエストを送信
      fetch(`/spotify_search?query=${query}`)
        .then((response) => response.json())
        .then((data) => {
          const suggestions = data.suggestions;
          renderSuggestions(suggestions);
        })
        .catch((error) => console.error('Error fetching data:', error));
    });
  }
  
  // ✅ 検索タイプ変更時の処理
  export function initializeYearToggle() {
    const searchType = document.getElementById('initial-search-type');
    const queryContainer = document.getElementById('initial-query-container');
  
    if (!searchType || !queryContainer) {
      console.warn('⚠️ 検索タイプまたは検索フィールドコンテナが見つかりません。');
      return;
    }
  
    searchType.addEventListener('change', async () => {
      if (searchType.value === 'year') {
        await loadYearSearchTemplate(); // 年代検索フォームをロード
      } else {
        queryContainer.innerHTML = `
          <input type="text" name="initial_query" id="initial-query" placeholder="キーワードを入力"
            class="condition-input block w-full px-4 py-2 border rounded-md text-white bg-gray-700">
        `;
        console.log('🟢 検索フィールドがテキスト入力に戻りました');
        
        // 新しく生成された input 要素にイベントリスナーを再設定
        const newQueryInput = document.getElementById('initial-query');
        if (newQueryInput) {
          addInputEventListener(newQueryInput);
        }
      }
    });
  }
  