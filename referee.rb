module Referee
	def calculate_winner(opp_move, move)
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