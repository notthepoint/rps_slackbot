require 'spec_helper'

describe RpsBot::Web do
  context '#authorize' do
    let(:expected_url) { 'https://slack.com/api/oauth.access' }
    let(:expected_body) do
      {
        client_id: 'client_id',
        client_secret: 'client_secret',
        code: '12345'
      }
    end

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SLACK_CLIENT_ID').and_return 'client_id'
      allow(ENV).to receive(:[])
        .with('SLACK_CLIENT_SECRET').and_return 'client_secret'
    end

    it 'makes an API call to slack oauth' do
      expect(HTTParty).to receive(:post).with(expected_url, body: expected_body)

      get '/authorize', code: '12345'

      expect(last_response).to be_ok
      expect(last_response.body).to eq 'INSTALLED'
    end
  end
end
