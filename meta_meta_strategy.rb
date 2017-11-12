# frozen_string_literal: true

require_relative 'bots/always_rock'
require_relative 'bots/most_frequent'
require_relative 'bots/random'

DEFAULT_BOTS = {
  'random' => RandomBot.new,
  'always_rock' => AlwaysRockBot.new,
  'most_frequent' => MostFrequentBot.new
}.freeze

# MetaMetaStrategy is a RPS bot which decides based on a set of strategies,
# which one is likely in play (along with the possibility of a bluff or double
# bluff of that strategy) and suggests a move to combat said strategy.
class MetaMetaStrategy
  def initialize(previous_scores = nil, bots = DEFAULT_BOTS)
    @bots = bots

    @scores = previous_scores || scores_template(@bots)
  end

  attr_accessor :scores

  def move(opponent_moves)
    return %w[r p s].sample unless opponent_moves.length.positive?

    run_bots(opponent_moves)
    selected_bot, move_index = choose_best_move
    potential_move = @bots[selected_bot].move(opponent_moves)

    calculate_move(potential_move, move_index)
  end

  def run_bots(opponent_moves)
    latest_move = opponent_moves.pop(1)[0]

    return unless opponent_moves.length.positive?

    run_bots_for_move(opponent_moves, latest_move)
  end

  def choose_best_bot
    # bot with highest score (bluff or no bluff)
    best_arr[0]
  end

  def choose_best_move
    [best_arr[0], best_arr.index(best_arr[1..-1].max)]
  end

  private

  def best_arr
    @scores.max_by { |s| s[1..-1].max }
  end

  def run_bots_for_move(opponent_moves, latest_move)
    @scores.map do |score|
      bot = @bots[score[0]]
      response = bot.move(opponent_moves)
      all_moves = [response, bluff_move(response), double_bluff_move(response)]
      all_moves.each_with_index do |move, idx|
        score[idx + 1] += calculate_result(latest_move, move)
      end

      score
    end
  end

  def scores_template(bots)
    bots.map do |bot_name, _bot|
      # bot name, straight move, bluff move, double bluff move
      [bot_name, 0, 0, 0]
    end
  end

  def calculate_result(opp_move, move)
    return 0 if opp_move == move
    case opp_move + move
    when 'rp', 'ps', 'sr'
      1
    when 'rs', 'pr', 'sp'
      -1
    end
  end

  def bluff_move(move)
    {
      'r' => 's',
      'p' => 'r',
      's' => 'p'
    }[move]
  end

  def double_bluff_move(move)
    {
      'r' => 'p',
      'p' => 's',
      's' => 'r'
    }[move]
  end

  def calculate_move(move, bluff_index)
    [move, bluff_move(move), double_bluff_move(move)][bluff_index - 1]
  end
end
