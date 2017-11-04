# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'redis'
require 'json'
require 'httparty'
# require 'bots/random'
require_relative 'meta_meta_strategy'

SLACK_CLIENT_ID = ENV['SLACK_CLIENT_ID'] || ''
SLACK_CLIENT_SECRET = ENV['SLACK_CLIENT_SECRET'] || ''
ACTIONS = [
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
].freeze

EMOJIS = { 'r' => ':fist:', 'p' => ':hand:', 's' => ':v:' }.freeze

module RpsBot
  class Web < Sinatra::Base
    configure do
      enable :logging
    end

    def initialize
      super
      @redis = Redis.new
    end

    attr_reader :redis

    def valid?(payload)
      token = payload['token']
      token && token == ENV['SLACK_VERIFICATION_TOKEN']
    end

    get '/' do
      <<-HEREDOC
        <h1 style='text-align: center'>Install Rock Paper Scissors Slackbot</h1>
        <a href='https://slack.com/oauth/authorize?scope=commands&client_id=26989713078.245362537426' style='display: block; width: 139px; margin: 0 auto'>
          <img alt='Add to Slack' height='40' width='139' src='https://platform.slack-edge.com/img/add_to_slack.png' srcset='https://platform.slack-edge.com/img/add_to_slack.png 1x, https://platform.slack-edge.com/img/add_to_slack@2x.png 2x' />
        </a>
      HEREDOC
    end

    get '/authorize' do
      response = HTTParty.post('https://slack.com/api/oauth.access',
                               body: {
                                 client_id:     SLACK_CLIENT_ID,
                                 client_secret: SLACK_CLIENT_SECRET,
                                 code:          params['code']
                               })
      logger.info(response)

      [200, {}, 'INSTALLED']
    end

    post '/' do
      return [403, {}, 'Invalid Request'] unless valid?(request.params)

      id = SecureRandom.uuid

      redis.setex(id, 60 * 60 * 24,
                  {
                    scores: {
                      player: 0,
                      bot: 0
                    },
                    matches: [],
                    bot_scores: MetaMetaStrategy.new.scores
                  }.to_json)

      json(build_response(id, 'Rock Paper Scissors'))
    end

    post '/move' do
      payload = JSON.parse(request['payload'] || '{}')

      return [403, {}, 'Invalid Request'] unless valid?(payload)

      id = payload['callback_id']
      move = payload['actions'][0]['value']

      game = JSON.parse(redis.get(id))
      mm_strategy = MetaMetaStrategy.new(game['bot_scores'])

      if move == 'stop'
        result = if game['scores']['player'] > game['scores']['bot']
                   'won'
                 elsif game['scores']['bot'] > game['scores']['player']
                   'lost'
                 else
                   'drew'
                 end

        json('text' => "You #{result}")
      else
        opponent_moves = game['matches'].map { |m| m[0] }
        response = mm_strategy.move(opponent_moves)

        game['bot_scores'] = mm_strategy.scores
        game['matches'] << [move, response]

        unless response == move
          case [move, response]
          when %w[r p], %w[p s], %w[s r]
            game['scores']['bot'] += 1
          when %w[r s], %w[p r], %w[s p]
            game['scores']['player'] += 1
          end
        end

        moves = game['matches'].map do |match|
          {
            'text' => "#{EMOJIS[match[0]]} #{EMOJIS[match[1]]}"
          }
        end

        redis.setex(id, 60 * 60 * 24, game.to_json)

        json(build_response(id, "You played move #{move}", *moves))
      end
    end

    def build_response(id, message, *moves)
      {
        'text' => message,
        'attachments' => moves.push(base_move(id))
      }
    end

    def base_move(id)
      {
        'text' => 'Make your move...',
        'fallback' => 'BOOOO!',
        'callback_id' => id,
        'color' => '#3AA3E3',
        'attachment_type' => 'default',
        'actions' => ACTIONS
      }
    end
  end
end
