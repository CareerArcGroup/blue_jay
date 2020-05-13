# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

include BlueJay

config = SpecHelper::Config.new(BlueJay::BitlyClient)

describe BitlyClient do
  it 'generates the expected authorization url' do
    url = config.client.authorize_url('https://example.com/callback', state: 'state123')
    uri = URI.parse(url)
    query = URI.decode_www_form(uri.query).to_h

    expect(uri.scheme).to eq('https')
    expect(uri.host).to eq('bitly.com')
    expect(uri.path).to eq('/oauth/authorize')
    expect(query['client_id']).to eq(config.client.client_id)
    expect(query['state']).to eq('state123')
    expect(query['redirect_uri']).to eq('https://example.com/callback')
  end

  context 'with valid credentials' do
    it 'is authorized' do
      expect(config.client).to be_authorized
    end

    describe '#account_info' do
      it 'returns information about the user' do
        response = config.client.account_info

        expect(response).to be_successful
        expect(response.data['is_active']).to be_truthy
      end
    end

    describe '#shorten' do
      it 'returns a shortened url' do
        response = config.client.shorten('https://www.careerarc.com/')

        expect(response).to be_successful
        expect(response.data['link'].start_with?('https://bit.ly/')).to be_truthy
        expect(response.data['long_url']).to eq('https://www.careerarc.com/')
      end
    end
  end
end
