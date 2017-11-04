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
			selected_bot, move_index = choose_best_move
			potential_move = @bots[selected_bot].move(opponent_moves)

			calculate_move(potential_move, move_index)
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
				score[2] += calculate_result(latest_move, bluff_move(response))
				score[3] += calculate_result(latest_move, double_bluff_move(response))

				[score[0], score[1], score[2], score[3]]
			end
		end
	end

	def choose_best_bot
		# bot with highest score (bluff or no bluff)
		best_bot = @scores.max_by{ |s| s.max }[0]
	end

	def choose_best_move
		best_arr = @scores.max_by{ |s| s[1..-1].max }
		[best_arr[0], best_arr.index(best_arr[1..-1].max)]
	end

	private

	def scores_template(bots)
		@bots.map do |bot_name, bot|
			# bot name, straight move, bluff move, double bluff move
			[bot_name, 0, 0, 0]
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

	def bluff_move(move)
		{ "r" => "s",
			"p" => "r",
			"s" => "p"
			}[move]
	end

	def double_bluff_move(move)
		{ "r" => "p",
			"p" => "s",
			"s" => "r"
			}[move]
	end

	def calculate_move(move, bluff_index)
		puts "BLUFF INDEX"
		puts bluff_index
		case bluff_index
		when 1
			puts "JUST MOVE"
			move
		when 2
			puts "BLUFF"
			bluff_move(move)
		when 3
			puts "DOUBLE BLUFF"
			double_bluff_move(move)
		end
	end
end