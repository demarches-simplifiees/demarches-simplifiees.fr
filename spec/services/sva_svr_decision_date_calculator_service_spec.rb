# frozen_string_literal: true

require 'rails_helper'

describe SVASVRDecisionDateCalculatorService do
  include ActiveSupport::Testing::TimeHelpers

  let(:procedure) { create(:procedure, sva_svr: config) }
  let(:dossier) { create(:dossier, :en_instruction, procedure:, depose_at:) }
  let(:depose_at) { Time.zone.local(2023, 5, 15, 12) }

  describe '#decision_date' do
    subject { described_class.new(dossier, procedure).decision_date }

    context 'when sva has a months period' do
      let(:config) { { decision: :sva, period: 2, unit: :months, resume: :continue } }

      it 'calculates the date based on SVA rules' do
        expect(subject).to eq(Date.new(2023, 7, 16))
      end
    end

    context 'when sva has a days period' do
      let(:config) { { decision: :sva, period: 30, unit: :days, resume: :continue } }

      it 'calculates the date based on SVA rules' do
        expect(subject).to eq(Date.new(2023, 6, 15))
      end
    end

    context 'when sva has a weeks period' do
      let(:config) { { decision: :sva, period: 8, unit: :weeks, resume: :continue } }

      it 'calculates the date based on SVA rules' do
        expect(subject).to eq(Date.new(2023, 7, 11))
      end
    end

    context 'when sva resume setting is continue' do
      let(:config) { { decision: :sva, period: 2, unit: :months, resume: :continue } }

      context 'when a dossier is corrected and resolved' do
        let!(:correction) do
          created_at = Time.zone.local(2023, 5, 20, 15)
          resolved_at = Time.zone.local(2023, 5, 25, 12)
          create(:dossier_correction, dossier:, created_at:, resolved_at:)
        end

        it 'calculates the date based on SVA rules with correction delay' do
          expect(subject).to eq(Date.new(2023, 7, 22))
        end

        context 'when there are multiple corrections' do
          let!(:correction2) do
            created_at = Time.zone.local(2023, 5, 30, 18)
            resolved_at = Time.zone.local(2023, 6, 3, 8)
            create(:dossier_correction, dossier:, created_at:, resolved_at:)
          end

          it 'calculates the date based on SVA rules with all correction delays' do
            expect(subject).to eq(Date.new(2023, 7, 27))
          end
        end

        context 'there is a pending correction reason = incorrect' do
          before do
            travel_to Time.zone.local(2023, 5, 30, 18) do
              dossier.flag_as_pending_correction!(build(:commentaire, dossier:))
            end

            travel_to Time.zone.local(2023, 6, 5, 8) # 6 days elapsed, restart 1 day after resolved
          end

          it 'calculates the date, like if resolution will be today' do
            expect(subject).to eq(Date.new(2023, 7, 29))
          end
        end

        context 'there is a pending correction reason = incomplete' do
          before do
            travel_to Time.zone.local(2023, 5, 30, 18) do
              dossier.flag_as_pending_correction!(build(:commentaire, dossier:), :incomplete)
            end

            travel_to Time.zone.local(2023, 6, 5, 8) # 6 days elapsed
          end

          it 'calculates the date, like if resolution will be today' do
            expect(subject).to eq(Date.new(2023, 8, 6))
          end
        end

        context 'when correction was for an incomplete dossier' do
          let!(:correction) do
            created_at = Time.zone.local(2023, 5, 20, 15)
            resolved_at = Time.zone.local(2023, 5, 25, 12)
            create(:dossier_correction, :incomplete, dossier:, created_at:, resolved_at:)
          end

          it 'calculates the date by resetting delay' do
            expect(subject).to eq(Date.new(2023, 7, 26))
          end

          context 'when there are multiple corrections' do
            let!(:correction2) do
              created_at = Time.zone.local(2023, 5, 30, 18)
              resolved_at = Time.zone.local(2023, 6, 3, 8)
              create(:dossier_correction, dossier:, created_at:, resolved_at:)
            end

            it 'calculates the date based on SVA rules with all correction delays' do
              expect(subject).to eq(Date.new(2023, 7, 31))
            end
          end
        end
      end
    end

    context 'when sva resume setting is reset' do
      let(:config) { { decision: :sva, period: 2, unit: :months, resume: :reset } }

      context 'there is no correction' do
        it 'calculates the date based on deposed_at' do
          expect(subject).to eq(Date.new(2023, 7, 16))
        end
      end

      context 'there are multiple resolved correction' do
        before do
          created_at = Time.zone.local(2023, 5, 16, 15)
          resolved_at = Time.zone.local(2023, 5, 17, 12)
          create(:dossier_correction, :incomplete, dossier:, created_at:, resolved_at:)

          created_at = Time.zone.local(2023, 5, 20, 15)
          resolved_at = Time.zone.local(2023, 5, 25, 12)
          create(:dossier_correction, dossier:, created_at:, resolved_at:)
        end

        it 'calculates the date based on SVA rules from the last resolved date' do
          expect(subject).to eq(Date.new(2023, 7, 26))
        end
      end

      context 'there is a pending correction' do
        before do
          travel_to Time.zone.local(2023, 5, 30, 18) do
            dossier.flag_as_pending_correction!(build(:commentaire, dossier:))
          end

          travel_to Time.zone.local(2023, 6, 5, 8)
        end

        it 'calculates the date, like if resolution will be today and delay restarted' do
          expect(subject).to eq(Date.new(2023, 8, 6))
        end
      end
    end

    context 'when dossier is deposed at end of month with correction delay' do
      let(:config) { { decision: :sva, period: 2, unit: :months, resume: :continue } }

      let!(:correction) do # add 2 days
        create(:dossier_correction, dossier:, created_at: depose_at + 1.day, resolved_at: depose_at + 2.days)
      end

      context 'start date = 30' do
        let(:depose_at) { Time.zone.local(2023, 6, 29, 12) }

        it 'calculcates the date accordingly' do
          expect(subject).to eq(Date.new(2023, 9, 1))
        end
      end

      context 'start date = 31' do
        let(:depose_at) { Time.zone.local(2023, 7, 30, 12) }

        it 'calculcates the date accordingly' do
          expect(subject).to eq(Date.new(2023, 10, 2))
        end
      end

      context 'start date = 1 in month having 31 days' do
        let(:depose_at) { Time.zone.local(2023, 7, 31, 12) }

        it 'calculcates the date accordingly' do
          expect(subject).to eq(Date.new(2023, 10, 3))
        end
      end

      context 'start date = 1 in month having 30 days' do
        let(:depose_at) { Time.zone.local(2023, 6, 30, 12) }

        it 'calculcates the date accordingly' do
          expect(subject).to eq(Date.new(2023, 9, 3))
        end
      end
    end
  end

  describe '#decision_date_from_today' do
    let(:config) { { decision: :sva, period: 2, unit: :months, resume: :continue } }
    before { travel_to Time.zone.local(2023, 4, 15, 12) }

    subject { described_class.decision_date_from_today(procedure) }

    it 'calculates the date based on today' do
      expect(subject).to eq(Date.new(2023, 6, 16))
    end
  end
end
