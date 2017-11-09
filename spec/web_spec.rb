require 'spec_helper'

describe RpsBot::Web do
  context '/authorize' do
    let(:expected_url) { 'https://slack.com/api/oauth.access' }
    let(:expected_body) do
      {
        client_id: 'client_id',
        client_secret: 'client_secret',
        code: '12345'
      }
    end

    it 'makes an API call to slack oauth' do
      expect(HTTParty).to receive(:post).with(expected_url, body: expected_body)

      get '/authorize', code: '12345'

      expect(last_response).to be_ok
      expect(last_response.body).to eq 'INSTALLED'
    end
  end

  context '/' do
    let!(:id) { 'some-generated-id' }
    let(:payload) do
      {
        'text' => 'Rock Paper Scissors',
        'attachments' => [
          {
            'text' => 'Make your move...',
            'fallback' => 'BOOOO!',
            'callback_id' => id,
            'color' => '#3AA3E3',
            'attachment_type' => 'default',
            'actions' => [
              {
                'name' => 'move',
                'text' => ':fist:',
                'type' => 'button',
                'value' => 'r'
              },
              {
                'name' => 'move',
                'text' => ':hand:',
                'type' => 'button',
                'value' => 'p'
              },
              {
                'name' => 'move',
                'text' => ':v:',
                'type' => 'button',
                'value' => 's'
              },
              {
                'name' => 'move',
                'text' => 'End game',
                'type' => 'button',
                'value' => 'stop'
              }
            ]
          }
        ]
      }
    end

    it 'discards unauthorized requests' do
      post '/', token: 'bad-token'

      expect(last_response).to be_forbidden
    end

    context 'a good token' do
      before do
        allow(SecureRandom).to receive(:uuid).and_return(id)
      end

      it 'responds with the expected slack appropriate response' do
        post '/', token: 'good-token'

        expect(last_response).to be_ok
        expect(last_response.content_type).to eq 'application/json'
        expect(JSON.parse(last_response.body)).to eq payload
      end
    end
  end

  context '/move' do
    it 'discards unauthorized requests' do
      post '/', token: 'bad-token'

      expect(last_response).to be_forbidden
    end

    context 'a game is inflight' do
      # needed to call mock redis instance
      def app
        RpsBot::Web.new!
      end

      let!(:id) { 'some-game-id' }
      let!(:game) do
        {
          'scores' => { 'player' => 1, 'bot' => 0 },
          'matches' => [['r', 'p'], ['s', 'r'], ['r', 'r']],
          'bot_scores' => { 'some' => 'structure' }
        }
      end

      context 'move is stop' do
        let(:move) { 'stop' }
        let(:payload) do
          {
            callback_id: id,
            token: 'good-token',
            actions: [{ value: move }]
          }.to_json
        end

        before do
          app.redis.set(id, game.to_json)
        end

        it 'returns the result' do
          post '/move', payload: payload

          expect(last_response).to be_ok
          expect(last_response.content_type).to eq 'application/json'
          expect(JSON.parse(last_response.body)).to eq({ 'text' => 'You won' })
        end
      end

      context 'move is rock' do
        let(:move) { 'r' }
        let(:strategy) { double 'strategy' }
        let(:payload) do
          {
            callback_id: id,
            token: 'good-token',
            actions: [{ value: move }]
          }.to_json
        end
        let(:response) do
          {
            'text' => 'You played move r',
            'attachments' => [
              {
                'text' => ':fist: :hand:'
              },
              {
                'text' => ':v: :fist:'
              },

              {
                'text' => ':fist: :fist:'
              },
              {
                'text' => ':fist: :v:'
              },
              {
                'text' => 'Make your move...',
                'fallback' => 'BOOOO!',
                'callback_id' => id,
                'color' => '#3AA3E3',
                'attachment_type' => 'default',
                'actions' => [
                  {
                    'name' => 'move',
                    'text' => ':fist:',
                    'type' => 'button',
                    'value' => 'r'
                  },
                  {
                    'name' => 'move',
                    'text' => ':hand:',
                    'type' => 'button',
                    'value' => 'p'
                  },
                  {
                    'name' => 'move',
                    'text' => ':v:',
                    'type' => 'button',
                    'value' => 's'
                  },
                  {
                    'name' => 'move',
                    'text' => 'End game',
                    'type' => 'button',
                    'value' => 'stop'
                  }
                ]
              }
            ]
          }
        end

        before do
          app.redis.set(id, game.to_json)
          allow(MetaMetaStrategy).to receive(:new).with('some' => 'structure').and_return strategy
        end

        it 'returns the result' do
          expect(strategy).to receive(:move).with(['r', 's', 'r']).and_return 's'
          expect(strategy).to receive(:scores).and_return 'some-other' => 'structure'

          post '/move', payload: payload

          expect(last_response).to be_ok
          expect(last_response.content_type).to eq 'application/json'
          expect(JSON.parse(last_response.body)).to eq response
        end
      end

    end
  end
end
