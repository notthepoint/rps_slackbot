require 'spec_helper'

# OneMoveBot
class OneMoveBot
  def initialize(move)
    @move = move
  end

  def move(_)
    @move
  end
end

# CycleBot
class CycleBot
  def initialize
    @index = 0
  end

  def move(_)
    @index += 1
    %w[r p s][@index % 3]
  end
end

describe MetaMetaStrategy do
  subject { MetaMetaStrategy }

  context '#scores' do
    let(:strategy) { subject.new(nil, 'paper_bot' => OneMoveBot.new('p')) }
    let(:expected_scores) { [['paper_bot', 0, 0, 0]] }

    it 'returns the blank scores as expected' do
      expect(strategy.scores).to eq expected_scores
    end
  end

  context 'some previous scores' do
    let(:previous_scores) { [['a', 0, 5, 0], ['b', 1, 2, 3], ['c', 0, 2, 7]] }
    let(:strategy) { subject.new(previous_scores) }

    describe '#choose_best_bot' do
      it 'returns c' do
        expect(strategy.choose_best_bot).to eq 'c'
      end
    end

    describe '#choose_best_move' do
      it "returns ['c', 3]" do
        expect(strategy.choose_best_move).to eq ['c', 3]
      end
    end
  end

  describe '#move' do
    let(:strategies) do
      {
        'cycle_bot' => CycleBot.new,
        'scissor_bot' => OneMoveBot.new('s')
      }
    end

    let(:strategy) { subject.new(nil, strategies) }
    let(:scissor) { 's' }
    let(:moves) { [scissor, scissor, scissor, scissor] }

    it 'returns an appropriate counter move' do
      result = ''
      0.upto(moves.size - 1).each do |i|
        result = strategy.move(moves[0..i])
      end

      expect(result).to eq 'r'
      expect(strategy.choose_best_bot).to eq 'scissor_bot'
    end
  end
end
