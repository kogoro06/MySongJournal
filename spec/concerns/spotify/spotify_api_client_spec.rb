require 'rails_helper'

RSpec.describe Spotify::SpotifyApiClient do
  before do
    stub_const(
      "DummyClass",
      Class.new do
        include Spotify::SpotifyApiClient
        public :get_spotify_access_token, :spotify_auth_request, :auth_params, :auth_headers
      end
    )
  end

  let(:dummy_instance) { DummyClass.new }

  describe '#get_spotify_access_token' do
    context 'when the request is successful' do
      let(:access_token) { 'mock_access_token' }
      let(:response) { double('response', body: { access_token: access_token }.to_json) }

      before do
        allow(dummy_instance).to receive(:spotify_auth_request).and_return(response)
      end

      it 'returns the access token' do
        expect(dummy_instance.get_spotify_access_token).to eq(access_token)
      end
    end

    context 'when the request fails' do
      before do
        allow(dummy_instance).to receive(:spotify_auth_request).and_raise(RestClient::ExceptionWithResponse.new(double('response', body: 'Invalid response')))
      end

      it 'raises an error' do
        expect { dummy_instance.get_spotify_access_token }.to raise_error(RuntimeError, /Failed to get Spotify access token/)
      end
    end
  end

  describe '#spotify_auth_request' do
    context 'when the request is successful' do
      let(:response) { double('response', body: { access_token: 'mock_access_token' }.to_json) }

      before do
        allow(RestClient).to receive(:post).and_return(response)
      end

      it 'returns the response' do
        expect(dummy_instance.spotify_auth_request).to eq(response)
      end
    end

    context 'when the request fails' do
      before do
        allow(RestClient).to receive(:post).and_raise(RestClient::ExceptionWithResponse.new(double('response', body: 'Error occurred')))
      end

      it 'raises an error' do
        expect { dummy_instance.spotify_auth_request }.to raise_error(RuntimeError, /Failed to authenticate with Spotify/)
      end
    end
  end

  describe '#auth_params' do
    context 'when environment variables are set' do
      it 'returns the correct authentication parameters' do
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return("mock_client_id")
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return("mock_client_secret")

        expected_params = {
          grant_type: "client_credentials",
          client_id: "mock_client_id",
          client_secret: "mock_client_secret"
        }

        expect(dummy_instance.auth_params).to eq(expected_params)
      end
    end

    context 'when environment variables are not set' do
      it 'raises an error if SPOTIFY_CLIENT_ID is missing' do
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return(nil)
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return("mock_client_secret")

        expect { dummy_instance.auth_params }.to raise_error(RuntimeError, /Environment variables SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET must be set/)
      end

      it 'raises an error if SPOTIFY_CLIENT_SECRET is missing' do
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return("mock_client_id")
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return(nil)

        expect { dummy_instance.auth_params }.to raise_error(RuntimeError, /Environment variables SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET must be set/)
      end

      it 'raises an error if both SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET are missing' do
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return(nil)
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return(nil)

        expect { dummy_instance.auth_params }.to raise_error(RuntimeError, /Environment variables SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET must be set/)
      end
    end
  end

  describe '#auth_headers' do
    it 'returns the correct headers' do
      expect(dummy_instance.auth_headers).to eq({ content_type: "application/x-www-form-urlencoded" })
    end
  end

  describe 'SPOTIFY_TOKEN_URL' do
    it 'is defined and has the correct value' do
      expect(DummyClass::SPOTIFY_TOKEN_URL).to eq("https://accounts.spotify.com/api/token")
    end
  end
end
