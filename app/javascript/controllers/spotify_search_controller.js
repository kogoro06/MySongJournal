import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Spotify Search controller connected")
  }

  toggleSearchInput(event) {
    console.log("toggleSearchInput called")
    const select = event.currentTarget
    const conditionId = select.closest('.search-condition').dataset.conditionId
    const queryContainer = document.getElementById(`query-container-${conditionId}`)
    const textInputContainer = queryContainer.querySelector('.text-input-container')
    const yearSelectContainer = queryContainer.querySelector('.year-select-container')

    if (select.value === 'year') {
      console.log("Switching to year select")
      textInputContainer.classList.add('hidden')
      yearSelectContainer.classList.remove('hidden')
      textInputContainer.querySelector('input').disabled = true
      yearSelectContainer.querySelector('select').disabled = false
    } else {
      console.log("Switching to text input")
      textInputContainer.classList.remove('hidden')
      yearSelectContainer.classList.add('hidden')
      textInputContainer.querySelector('input').disabled = false
      yearSelectContainer.querySelector('select').disabled = true
    }
  }

  addCondition(event) {
    event.preventDefault()
    console.log("addCondition called")
    const conditions = document.querySelectorAll('.search-condition')
    const newId = conditions.length
    
    if (newId < 2) {  // 最大2つまで
      const template = document.querySelector('.search-condition').cloneNode(true)
      template.dataset.conditionId = newId
      
      // ID更新
      template.querySelectorAll('[id]').forEach(el => {
        el.id = el.id.replace(/\d+/, newId)
      })

      // 新しい要素のselect要素にdata-action属性を追加
      const newSelect = template.querySelector('.search-type-select');
      newSelect.setAttribute('data-action', 'change->spotify-search#toggleSearchInput');

      // 入力状態をリセット
      template.querySelector('select').value = ''
      template.querySelector('input[type="text"]').value = ''
      template.querySelector('select[id^="year-select"]').value = ''

      // 表示状態をリセット
      const textInputContainer = template.querySelector('.text-input-container')
      const yearSelectContainer = template.querySelector('.year-select-container')
      textInputContainer.classList.remove('hidden')
      yearSelectContainer.classList.add('hidden')
      textInputContainer.querySelector('input').disabled = false
      yearSelectContainer.querySelector('select').disabled = true

      document.getElementById('search-conditions').appendChild(template)
    }
  }

  removeCondition(event) {
    event.preventDefault()
    console.log("removeCondition called")
    const conditions = document.querySelectorAll('.search-condition')
    if (conditions.length > 1) {
      conditions[conditions.length - 1].remove()
    }
  }
}
