require 'rails_helper'

describe SVASVRDateCalculatorService do
  let(:procedure) { create(:procedure, sva_svr: config) }
  let(:dossier) { create(:dossier, :en_instruction, procedure:, depose_at: DateTime.new(2023, 5, 15, 12)) }

  subject { described_class.new(dossier, procedure).calculate }

  describe '#calculate' do
    context 'when sva has a months period' do
      let(:config) { { decision: :sva, period: 2, unit: :months, resume: :continue } }

      it 'calculates the date based on SVA rules' do
        expect(subject).to eq(Date.new(2023, 7, 15))
      end
    end

    context 'when sva has a days period' do
      let(:config) { { decision: :sva, period: 30, unit: :days, resume: :continue } }

      it 'calculates the date based on SVA rules' do
        expect(subject).to eq(Date.new(2023, 6, 14))
      end
    end

    context 'when sva has a weeks period' do
      let(:config) { { decision: :sva, period: 8, unit: :weeks, resume: :continue } }

      it 'calculates the date based on SVA rules' do
        expect(subject).to eq(Date.new(2023, 7, 10))
      end
    end
  end
end
