require 'rails_helper'

describe SVASVRDecisionDateCalculatorService do
  include ActiveSupport::Testing::TimeHelpers

  let(:procedure) { create(:procedure, sva_svr: config) }
  let(:dossier) { create(:dossier, :en_instruction, procedure:, depose_at: DateTime.new(2023, 5, 15, 12)) }

  subject { described_class.new(dossier, procedure).decision_date }

  describe '#decision_date' do
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

    context 'when sva resume setting is continue' do
      let(:config) { { decision: :sva, period: 2, unit: :months, resume: :continue } }

      context 'when a dossier is corrected and resolved' do
        let!(:correction) do
          created_at = DateTime.new(2023, 5, 20, 15)
          resolved_at = DateTime.new(2023, 5, 25, 12)
          create(:dossier_correction, dossier:, created_at:, resolved_at:)
        end

        it 'calculates the date based on SVA rules with correction delay' do
          expect(subject).to eq(Date.new(2023, 7, 20))
        end

        context 'when there are multiple corrections' do
          let!(:correction2) do
            created_at = DateTime.new(2023, 5, 30, 18)
            resolved_at = DateTime.new(2023, 6, 3, 8)
            create(:dossier_correction, dossier:, created_at:, resolved_at:)
          end

          it 'calculates the date based on SVA rules with all correction delays' do
            expect(subject).to eq(Date.new(2023, 7, 24))
          end
        end

        context 'there is a pending correction' do
          before do
            travel_to DateTime.new(2023, 5, 30, 18) do
              dossier.flag_as_pending_correction!(build(:commentaire, dossier:))
            end

            travel_to DateTime.new(2023, 6, 5, 8) # 6 days elapsed
          end

          it 'calculates the date, like if resolution will be today' do
            expect(subject).to eq(Date.new(2023, 7, 26))
          end
        end
      end
    end

    context 'when sva resume setting is reset' do
      let(:config) { { decision: :sva, period: 2, unit: :months, resume: :reset } }

      context 'there is no correction' do
        it 'calculates the date based on deposed_at' do
          expect(subject).to eq(Date.new(2023, 7, 15))
        end
      end

      context 'there are multiple resolved correction' do
        before do
          created_at = DateTime.new(2023, 5, 16, 15)
          resolved_at = DateTime.new(2023, 5, 17, 12)
          create(:dossier_correction, dossier:, created_at:, resolved_at:)

          created_at = DateTime.new(2023, 5, 20, 15)
          resolved_at = DateTime.new(2023, 5, 25, 12)
          create(:dossier_correction, dossier:, created_at:, resolved_at:)
        end

        it 'calculates the date based on SVA rules from the last resolved date' do
          expect(subject).to eq(Date.new(2023, 7, 25))
        end
      end

      context 'there is a pending correction' do
        before do
          travel_to DateTime.new(2023, 5, 30, 18) do
            dossier.flag_as_pending_correction!(build(:commentaire, dossier:))
          end

          travel_to DateTime.new(2023, 6, 5, 8)
        end

        it 'calculates the date, like if resolution will be today and delay restarted' do
          expect(subject).to eq(Date.new(2023, 8, 5))
        end
      end
    end
  end
end
