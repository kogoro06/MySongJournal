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

  def recommend_songs(journal, preferences = nil)
    messages = build_conversation_messages(journal, preferences)
    response = @client.chat(
      parameters: {
        model: "gpt-4",
        messages: messages,
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

  def build_conversation_messages(journal, preferences)
    messages = [
      {
        role: "system",
        content: system_prompt
      }
    ]

    # ユーザーの好みがある場合は追加
    if preferences
      messages << {
        role: "user",
        content: "私の音楽の好みについて：#{preferences}"
      }
    end

    # 日記の内容を追加
    messages << {
      role: "user",
      content: create_recommendation_prompt(journal)
    }

    messages
  end

  def system_prompt
    <<~PROMPT
      あなたは日本の音楽シーンに精通した音楽アドバイザーです。
      以下の方針で楽曲を推薦してください：

      1. 基本的に日本の音楽（J-POP、J-ROCK、演歌など）を中心に提案
      2. 洋楽は補足的に提案（特に合う曲がある場合のみ）
      3. 新しい曲から懐かしい曲まで幅広く提案
      4. ユーザーの感情や状況に合わせて選曲
      5. 理由は具体的に説明（歌詞の内容や曲調との関連付け）

      レスポンスは必ず以下のJSON形式で返してください。
    PROMPT
  end

  def create_recommendation_prompt(journal)
    <<~PROMPT
      以下の日記の内容から、ユーザーの気分や状況に合った楽曲を5曲提案してください。

      タイトル: #{journal.title}
      内容: #{journal.content}
      感情: #{journal.emotion}

      以下の形式でJSON形式で返してください：
      {
        "context": "日記の内容から読み取った状況や気分の分析",
        "genre_suggestion": "提案したいジャンル（理由も含めて）",
        "recommendations": [
          {
            "title": "曲名",
            "artist": "アーティスト名",
            "year": "リリース年（わかる場合）",
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
      "genre_suggestion" => "一般的な提案",
      "recommendations" => [],
      "playlist_name" => "おすすめプレイリスト",
      "playlist_description" => "あなたの日記に基づいた選曲"
    }
  end
end
