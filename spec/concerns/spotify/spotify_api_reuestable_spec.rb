require 'rails_helper'
require 'rest-client'
require 'json'

RSpec.describe Spotify::SpotifyApiRequestable do
  # ダミークラスを作成してモジュールをインクルード
  before do
    stub_const(
      "DummyClass",
      Class.new do
        include Spotify::SpotifyApiRequestable

        # `get_spotify_access_token`をモックするためにpublicに設定
        def get_spotify_access_token
          "mock_access_token"
        end
      end
    )
  end

  let(:dummy_instance) { DummyClass.new }

  describe '#spotify_get' do
    let(:endpoint) { 'mock_endpoint' }
    let(:params) { { query: 'test' } }
    let(:response_body) { { data: 'mock_data' }.to_json }
    let(:response) { instance_double(RestClient::Response, body: response_body) }

    context 'when the request is successful' do
      before do
        allow(RestClient).to receive(:get).and_return(response)
      end

      it 'returns the parsed JSON response' do
        result = dummy_instance.send(:spotify_get, endpoint, params)
        expect(result).to eq(JSON.parse(response_body))
      end

      it 'sends a GET request with the correct headers and parameters' do
        expect(RestClient).to receive(:get).with(
          "https://api.spotify.com/v1/#{endpoint}",
          hash_including(
            Authorization: "Bearer mock_access_token",
            "Accept-Language" => "ja",
            query: 'test'
          )
        ).and_return(response)

        dummy_instance.send(:spotify_get, endpoint, params)
      end
    end

    context 'when the request returns 401 Unauthorized' do
      let(:unauthorized_exception) { RestClient::Unauthorized.new }

      before do
        allow(RestClient).to receive(:get).and_raise(unauthorized_exception)
        allow(dummy_instance).to receive(:get_spotify_access_token).and_return("new_mock_access_token")
      end

      it 'retries the request up to the maximum number of attempts' do
        expect(RestClient).to receive(:get).exactly(Spotify::SpotifyApiRequestable::MAX_ATTEMPTS).times.and_raise(unauthorized_exception)

        expect {
          dummy_instance.send(:spotify_get, endpoint, params)
        }.to raise_error(RuntimeError, /Unauthorized access after #{Spotify::SpotifyApiRequestable::MAX_ATTEMPTS} attempts/)
      end

      it 'clears the cached access token and retries' do
        expect(dummy_instance).to receive(:get_spotify_access_token).exactly(Spotify::SpotifyApiRequestable::MAX_ATTEMPTS).times.and_return("new_mock_access_token")
        expect(RestClient).to receive(:get).exactly(Spotify::SpotifyApiRequestable::MAX_ATTEMPTS).times.and_raise(unauthorized_exception)

        expect {
          dummy_instance.send(:spotify_get, endpoint, params)
        }.to raise_error(RuntimeError, /Unauthorized access after #{Spotify::SpotifyApiRequestable::MAX_ATTEMPTS} attempts/)
      end
    end

    context 'when the request fails with another error' do
      let(:error_response) { instance_double(RestClient::Response, body: 'Internal Server Error') }
      let(:exception) { RestClient::ExceptionWithResponse.new(error_response) }

      before do
        allow(RestClient).to receive(:get).and_raise(exception)
      end

      it 'logs the error and raises an exception' do
        # Rails.loggerをモック
        logger_double = instance_double("Logger")
        allow(Rails).to receive(:logger).and_return(logger_double)
        expect(logger_double).to receive(:error).with(/Spotify API request failed: Internal Server Error. Endpoint: #{endpoint}, Params: #{params}/)

        # 例外が発生することを確認
        expect {
          dummy_instance.send(:spotify_get, endpoint, params)
        }.to raise_error(RuntimeError, /Spotify API request failed: Internal Server Error/)
      end
    end
  end
end
