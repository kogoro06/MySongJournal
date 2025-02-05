class OpenaiService
  def initialize
    @client = OpenAI::Client.new(
      access_token: ENV["OPENAI_API_KEY"],
      request_timeout: 240
    )
  end

  def analyze_journal_mood(journal)
    prompt = create_analysis_prompt(journal)
    response = @client.chat(
      parameters: {
        model: "gpt-4",
        messages: [ { role: "user", content: prompt } ],
        temperature: 0.7
      }
    )

    parse_response(response)
  end

  def recommend_songs(journal)
    prompt = create_recommendation_prompt(journal)
    response = @client.chat(
      parameters: {
        model: "gpt-4",
        messages: [ { role: "user", content: prompt } ],
        temperature: 0.7
      }
    )

    parse_response(response)
  end

  private

  def create_analysis_prompt(journal)
    <<~PROMPT
      以下の日記の内容から、音楽的な特徴を抽出してください。

      タイトル: #{journal.title}
      内容: #{journal.content}
      感情: #{journal.emotion}

      以下の形式でJSON形式で返してください：
      {
        "mood": "曲の雰囲気（明るい、暗い、エネルギッシュなど）",
        "tempo": "テンポの好み（遅い、中程度、速いなど）",
        "genre_preference": "好みそうなジャンル（複数可）",
        "keywords": ["検索キーワード1", "検索キーワード2", ...]
      }
    PROMPT
  end

  def create_recommendation_prompt(journal)
    <<~PROMPT
      あなたは音楽に精通したプロのDJです。
      以下の日記の内容から、ユーザーの気分や状況に合った具体的な楽曲を5曲提案してください。

      タイトル: #{journal.title}
      内容: #{journal.content}
      感情: #{journal.emotion}

      以下の形式でJSON形式で返してください：
      {
        "context": "日記の内容から読み取った状況や気分の分析",
        "recommendations": [
          {
            "title": "曲名",
            "artist": "アーティスト名",
            "reason": "この曲を推薦する理由（日記の内容や感情との関連）",
            "spotify_search_query": "Spotify検索用のクエリ（曲名 アーティスト）"
          },
          ...
        ],
        "playlist_name": "この選曲のテーマに合ったプレイリスト名の提案",
        "playlist_description": "プレイリストの説明文"
      }
    PROMPT
  end

  def parse_response(response)
    JSON.parse(response.dig("choices", 0, "message", "content"))
  rescue JSON::ParserError => e
    Rails.logger.error "OpenAI response parsing error: #{e.message}"
    {
      "context" => "解析エラーが発生しました",
      "recommendations" => [],
      "playlist_name" => "おすすめプレイリスト",
      "playlist_description" => "あなたの日記に基づいた選曲"
    }
  end
end
