require 'rails_helper'
require 'rest-client'
require 'json'
require_relative '../../../app/controllers/concerns/spotify/spotify_autocompletable'

RSpec.describe Spotify::SpotifyAutocompletable do
  before do
    stub_const(
      "DummyController",
      Class.new(ActionController::Base) do
        include Spotify::SpotifyAutocompletable
        public :autocomplete, :autocomplete_params, :format_items, :handle_autocomplete_error
      end
    )
  end

  let(:dummy_instance) { DummyController.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return("mock_client_id")
    allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return("mock_client_secret")
  end

  let(:mock_results) do
    {
      "tracks" => {
        "items" => [
          {
            "id" => "track1",
            "name" => "Track 1",
            "artists" => [ { "name" => "Artist 1" } ]
          },
          {
            "id" => "track2",
            "name" => "Track 2",
            "artists" => [ { "name" => "Artist 2" } ]
          }
        ]
      },
      "artists" => {
        "items" => [
          {
            "id" => "artist1",
            "name" => "Artist 1"
          },
          {
            "id" => "artist2",
            "name" => "Artist 2"
          }
        ]
      }
    }
  end

  describe '#autocomplete_params' do
    it '正しいパラメータを返す' do
      # paramsメソッドをモック
      allow(dummy_instance).to receive(:params).and_return({
        query: 'test_query',
        type: 'track,artist'
      })

      expected_params = {
        params: {
          q: 'test_query',
          type: 'track,artist',
          limit: 10,
          fields: "tracks.items(id,name,artists.name),artists.items(id,name)"
        }
      }

      expect(dummy_instance.autocomplete_params).to eq(expected_params)
    end
  end

  describe '#format_items' do
    context '曲の情報をフォーマットする場合' do
      it '正しくフォーマットする' do
        formatted_tracks = dummy_instance.format_items(mock_results, "tracks", "track")

        expect(formatted_tracks).to eq([
          {
            id: "track1",
            name: "Track 1",
            type: "track",
            artist: "Artist 1"
          },
          {
            id: "track2",
            name: "Track 2",
            type: "track",
            artist: "Artist 2"
          }
        ])
      end
    end

    context 'アーティストの情報をフォーマットする場合' do
      it '正しくフォーマットする' do
        formatted_artists = dummy_instance.format_items(mock_results, "artists", "artist")

        expect(formatted_artists).to eq([
          {
            id: "artist1",
            name: "Artist 1",
            type: "artist"
          },
          {
            id: "artist2",
            name: "Artist 2",
            type: "artist"
          }
        ])
      end
    end
  end

  describe '#handle_autocomplete_error' do
    context '通常のエラーが発生した場合' do
      it 'エラーをログに記録し、適切なレスポンスを返す' do
        error = StandardError.new("Something went wrong")
        allow(Rails.logger).to receive(:error)

        allow(dummy_instance).to receive(:params).and_return(ActionController::Parameters.new({ query: 'test_query' }))

        # renderメソッドをモック
        allow(dummy_instance).to receive(:render)

        expect(dummy_instance).to receive(:render).with(
          json: { error: "検索中にエラーが発生しました" },
          status: :bad_request
        )

        dummy_instance.handle_autocomplete_error(error)

        expect(Rails.logger).to have_received(:error).with(
          "Autocomplete Error: Something went wrong. Params: {\"query\"=>\"test_query\"}"
        )
      end
    end

    context 'Spotify API特有のエラーが発生した場合' do
      it 'エラーをログに記録し、適切なレスポンスを返す' do
        error = SpotifyApiError.new("Spotify API is unavailable")
        allow(Rails.logger).to receive(:error)

        allow(dummy_instance).to receive(:params).and_return(ActionController::Parameters.new({ query: 'test_query' }))

        # renderメソッドをモック
        allow(dummy_instance).to receive(:render)

        expect(dummy_instance).to receive(:render).with(
          json: { error: "Spotify APIでエラーが発生しました" },
          status: :service_unavailable
        )

        dummy_instance.handle_autocomplete_error(error)

        expect(Rails.logger).to have_received(:error).with(
          "Spotify API Error: Spotify API is unavailable. Params: {\"query\"=>\"test_query\"}"
        )
      end
    end
  end
end
