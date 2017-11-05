# frozen_string_literal: true

# MostFrequentBot
class MostFrequentBot
  COUNTERS = { 'r' => 'p', 'p' => 's', 's' => 'r' }.freeze

  def move(opponent_moves)
    histogram = opponent_moves.reduce(Hash.new(0)) do |hist, move|
      # increment the moves count by one
      hist.tap { |h| h[move] += 1 }
    end

    # return counter move for the most frequent
    # opponent move
    COUNTERS[histogram.to_a.max_by { |v| v[1] }[0]]
  end
end
