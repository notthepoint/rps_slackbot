require 'sinatra/base'
require 'sinatra/json'

$games = {}

module RpsBot
  class Web < Sinatra::Base

  	def valid?(payload)
  		puts payload
  		token = payload['token']
  		token && token == ENV['SLACK_VERIFICATION_TOKEN']
  	end

    get '/' do
      json $games
    end

    post '/' do
    	puts request.inspect
    	payload = JSON.parse(request['payload'] || '{}')

    	return [403, {}, "Invalid Request"] unless valid?(payload)

    	id = SecureRandom.uuid

    	$games[id] = {scores: {player: 0, bot: 0}, matches: []}

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

    	puts payload

    	if move == "stop"
    		result = if $games[id][:scores][:player] > $games[id][:scores][:bot]
	    			"won"
	    		elsif $games[id][:scores][:bot] > $games[id][:scores][:player]
	    			"lost"
	    		else
	    			"drew"
	    		end

	    	$games.delete(id)

    		json({
    			"text" => "You #{result}"
    			})
    	else
	    	response = ["rock", "paper", "scissors"].sample

	    	$games[id][:matches] << [move, response]

	    	unless response == move
	    		case [move, response]
	    		when (["rock", "paper"] || ["paper", "scissors"] || ["scissors", "rock"])
	    			$games[id][:scores][:bot] += 1
	    		when (["rock", "scissors"] || ["paper", "rock"] || ["scissors", "paper"])
	    			$games[id][:scores][:player] += 1
	    		end
	    	end

	    	moves = $games[id][:matches].map do |match|
	    		{
	    			"text" => { "rock" => ":fist:", "paper" => ":hand:", "scissors" => ":v:" }[match[0]] + " " + { "rock" => ":fist:", "paper" => ":hand:", "scissors" => ":v:" }[match[1]]
	    		}
	    	end

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