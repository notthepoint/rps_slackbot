require_relative 'bots/always_rock'
require_relative 'bots/random'

class MetaMetaStrategy
	def initialize(previous_scores=nil)
		@bots = {
			"random" => RandomBot.new,
			"always_rock" => AlwaysRockBot.new
		}

		@scores = previous_scores || scores_template(@bots)
	end

	attr_accessor :scores

	def move(opponent_moves)
		if opponent_moves.length > 0
			run_bots(opponent_moves)
			selected_bot = choose_best_bot
			@bots[selected_bot].move(opponent_moves)
		else
			['r','p','s'].sample
		end
	end

	def run_bots(opponent_moves)
		latest_move = opponent_moves.pop(1)[0]

		if opponent_moves.length > 0
			@scores.map do |score|

				bot = @bots[score[0]]
				response = bot.move(opponent_moves)
				score[1] += calculate_result(latest_move, response)

				[score[0], score[1]]
			end
		end
	end

	def choose_best_bot
		@scores.max_by{ |s| s[1] }[0]
	end

	private

	def scores_template(bots)
		@bots.map do |bot_name, bot|
			[bot_name, 0]
		end
	end

	def calculate_result(opp_move, move)
		if opp_move == move
			0
		else
			case opp_move + move
			when "rp", "ps", "sr"
  			1
			when "rs", "pr", "sp"
  			-1
			end
  	end
	end
end