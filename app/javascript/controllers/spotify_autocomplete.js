export function initializeSpotifyAutocomplete() {
    console.log("✅ initializeSpotifyAutocomplete が呼び出されました");
  
    const searchBox = document.getElementById('initial-query');
    const resultsList = document.getElementById('autoComplete_list');
  
    if (!searchBox) {
      console.warn('⚠️ 検索ボックス (#initial-query) が見つかりません。');
      return;
    }
  
    if (!resultsList) {
      console.warn('⚠️ 検索結果リスト (#autoComplete_list) が見つかりません。');
      return;
    }
  
    // AutoCompleteの初期化
    new autoComplete({
      selector: '#initial-query',
      data: {
        src: async (query) => {
          console.log('🔍 APIリクエスト: ', query);
          const response = await fetch(`/spotify/autocomplete?query=${encodeURIComponent(query)}`);
          const data = await response.json();
          console.log('🔄 APIレスポンス: ', data);
          return data.map(item => ({
            name: `${item.name} (${item.artist || ''})`,
            id: item.id
          }));
        },
        cache: false
      },
      resultsList: {
        render: true,
        container: resultsList,
      },
      resultItem: {
        highlight: true,
        content: (data, source) => {
          source.innerHTML = `
            <div>
              <strong>${data.value.name}</strong>
            </div>
          `;
        }
      },
      events: {
        input: {
          selection: (event) => {
            const selection = event.detail.selection.value;
            searchBox.value = selection.name;
            console.log('✅ 選択されたアイテム:', selection);
          }
        }
      }
    });
  
    console.log('✅ AutoComplete.js が初期化されました');
  }
  