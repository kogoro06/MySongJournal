require 'rails_helper'
require_relative '../../../app/controllers/concerns/spotify/spotify_api_client'

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

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return("mock_client_id")
    allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return("mock_client_secret")
  end

  describe '#get_spotify_access_token' do
    context 'when the access token is cached and valid' do
      let(:access_token) { 'cached_access_token' }

      before do
        dummy_instance.instance_variable_set(:@spotify_access_token, access_token)
        dummy_instance.instance_variable_set(:@spotify_access_token_expiry, Time.now + 3600)
      end

      it 'returns the cached access token without making a new request' do
        expect(dummy_instance).not_to receive(:spotify_auth_request)
        expect(dummy_instance.get_spotify_access_token).to eq(access_token)
      end
    end

    context 'when the access token is cached but expired' do
      let(:new_access_token) { 'new_access_token' }
      let(:response) { double('response', body: { access_token: new_access_token, expires_in: 3600 }.to_json) }

      before do
        dummy_instance.instance_variable_set(:@spotify_access_token, 'expired_access_token')
        dummy_instance.instance_variable_set(:@spotify_access_token_expiry, Time.now - 3600)
        allow(dummy_instance).to receive(:spotify_auth_request).and_return(response)
      end

      it 'fetches a new access token' do
        expect(dummy_instance.get_spotify_access_token).to eq(new_access_token)
      end
    end

    context 'when SPOTIFY_CLIENT_ID or SPOTIFY_CLIENT_SECRET is not set' do
      before do
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return(nil)
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return(nil)
      end

      it 'raises an error' do
        expect { dummy_instance.get_spotify_access_token }.to raise_error(RuntimeError, /SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET must be set/)
      end
    end

    context 'when Spotify API returns an error' do
      let(:response) { instance_double(RestClient::Response, body: 'Unauthorized', to_s: 'Unauthorized') }
      let(:exception) { RestClient::ExceptionWithResponse.new(response) }

      before do
        allow(dummy_instance).to receive(:spotify_auth_request).and_raise(exception)
      end

      it 'raises an error with the response message' do
        expect { dummy_instance.get_spotify_access_token }.to raise_error(RuntimeError, /Failed to get Spotify access token: Unauthorized/)
      end
    end
  end

  describe '#spotify_auth_request' do
    let(:response) { double('response', body: { access_token: 'new_access_token', expires_in: 3600 }.to_json) }

    it 'sends a POST request to the Spotify token URL with correct parameters and headers' do
      expect(RestClient).to receive(:post).with(
        Spotify::SpotifyApiClient::SPOTIFY_TOKEN_URL,
        hash_including(grant_type: 'client_credentials', client_id: 'mock_client_id', client_secret: 'mock_client_secret'),
        hash_including(content_type: 'application/x-www-form-urlencoded')
      ).and_return(response)

      dummy_instance.spotify_auth_request
    end

    context 'when the request fails' do
      let(:response) { instance_double(RestClient::Response, body: 'Unauthorized', to_s: 'Unauthorized') }
      let(:exception) { RestClient::ExceptionWithResponse.new(response) }

      before do
        allow(RestClient).to receive(:post).and_raise(exception)
      end

      it 'raises an error with the response message' do
        expect { dummy_instance.spotify_auth_request }.to raise_error(RuntimeError, /Failed to authenticate with Spotify: Unauthorized/)
      end
    end
  end

  describe '#auth_params' do
    context 'when SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET are set' do
      it 'returns the correct parameters' do
        expect(dummy_instance.auth_params).to eq(
          grant_type: 'client_credentials',
          client_id: 'mock_client_id',
          client_secret: 'mock_client_secret'
        )
      end
    end

    context 'when SPOTIFY_CLIENT_ID or SPOTIFY_CLIENT_SECRET is not set' do
      before do
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return(nil)
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return(nil)
      end

      it 'raises an error' do
        expect { dummy_instance.auth_params }.to raise_error(RuntimeError, /SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET must be set/)
      end
    end
  end

  describe '#auth_headers' do
    it 'returns the correct headers' do
      expect(dummy_instance.auth_headers).to eq(content_type: 'application/x-www-form-urlencoded')
    end
  end
end
