require 'sinatra/base'
require 'sinatra/json'
require 'redis'
require 'json'


module RpsBot
  class Web < Sinatra::Base
		
		def initialize
			@redis = Redis.new
		end

		attr_reader :redis

  	def valid?(payload)
  		token = payload['token']
  		token && token == ENV['SLACK_VERIFICATION_TOKEN']
  	end

    get '/' do
      json $games
    end

    post '/' do
    	return [403, {}, "Invalid Request"] unless valid?(request.params)

    	id = SecureRandom.uuid

    	redis.setex(id, 60 * 60 * 24, {scores: {player: 0, bot: 0}, matches: []}.to_json)

    	json({
    		"text" => "Rock Paper Scissors",
    		"attachments" => [
          {
            "text" => "Make your move...",
            "fallback" => "BOOOO!",
            "callback_id" => id,
            "color" => "#3AA3E3",
            "attachment_type" => "default",
            "actions" => [
              {
                "name" => "move",
                "text" => ":fist:",
                "type" => "button",
                "value" => "rock"
              },
              {
                "name" => "move",
                "text" => ":hand:",
                "type" => "button",
                "value" => "paper"
              },
              {
                "name" => "move",
                "text" => ":v:",
                "type" => "button",
                "value" => "scissors"
              },
              {
                "name" => "move",
                "text" => "End game",
                "type" => "button",
                "value" => "stop"
              }
            ]
          }
        ]
      })
    end

    post '/move' do
    	payload = JSON.parse(request['payload'] || '{}')

    	return [403, {}, "Invalid Request"] unless valid?(payload)

    	id = payload["callback_id"]
    	move = payload["actions"][0]["value"]

    	game = JSON.parse(redis.get(id))

    	puts payload

    	if move == "stop"
    		result = if game[:scores][:player] > game[:scores][:bot]
	    			"won"
	    		elsif game[:scores][:bot] > game[:scores][:player]
	    			"lost"
	    		else
	    			"drew"
	    		end

    		json({
    			"text" => "You #{result}"
    			})
    	else
	    	response = ["rock", "paper", "scissors"].sample

	    	game[:matches] << [move, response]

	    	unless response == move
	    		case [move, response]
	    		when (["rock", "paper"] || ["paper", "scissors"] || ["scissors", "rock"])
	    			game[:scores][:bot] += 1
	    		when (["rock", "scissors"] || ["paper", "rock"] || ["scissors", "paper"])
	    			game[:scores][:player] += 1
	    		end
	    	end

	    	moves = game[:matches].map do |match|
	    		{
	    			"text" => { "rock" => ":fist:", "paper" => ":hand:", "scissors" => ":v:" }[match[0]] + " " + { "rock" => ":fist:", "paper" => ":hand:", "scissors" => ":v:" }[match[1]]
	    		}
	    	end

	    	redis.setex(id, 60 * 60 * 24, game.to_json)

	    	json({
	    		"text" => "You played move #{move}",
	    		"attachments" => moves.push({
	          "text" => "Make your move...",
	          "fallback" => "BOOOO!",
	          "callback_id" => id,
	          "color" => "#3AA3E3",
	          "attachment_type" => "default",
	          "actions" => [
	            {
	              "name" => "move",
	              "text" => ":fist:",
	              "type" => "button",
	              "value" => "rock"
	            },
	            {
	              "name" => "move",
	              "text" => ":hand:",
	              "type" => "button",
	              "value" => "paper"
	            },
	            {
	              "name" => "move",
	              "text" => ":v:",
	              "type" => "button",
	              "value" => "scissors"
	            },
	            {
                "name" => "move",
                "text" => "End game",
                "type" => "button",
                "value" => "stop"
              }
	          ]
	        })
	      })
	    end
    end
  end
end