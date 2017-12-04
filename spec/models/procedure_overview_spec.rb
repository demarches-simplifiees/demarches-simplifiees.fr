require 'spec_helper'

describe ProcedureOverview, type: :model do
  let(:procedure) { create(:procedure, libelle: 'libelle') }
  let(:friday) { DateTime.new(2017, 5, 12) } # vendredi 12 mai 2017, de la semaine du 8 mai
  let(:monday) { DateTime.new(2017, 5, 8) }

  before { Timecop.freeze(friday) }
  after { Timecop.return }

  let(:procedure_overview) { ProcedureOverview.new(procedure, monday) }

  describe 'dossiers_en_instruction_count' do
    let!(:en_instruction_dossier) do
      create(:dossier, procedure: procedure, state: :received, created_at: monday)
    end

    it { expect(procedure_overview.dossiers_en_instruction_count).to eq(1) }
  end

  describe 'old_dossiers_en_instruction' do
    let!(:old_dossier_en_instruction) do
      create(:dossier, procedure: procedure, state: :received, received_at: monday - 1.month)
    end

    let!(:dossier_en_instruction) do
      create(:dossier, procedure: procedure, state: :received, received_at: monday)
    end

    it do
      expect(procedure_overview.old_dossiers_en_instruction).to match([old_dossier_en_instruction])
    end
  end

  describe 'dossiers_en_construction_count' do
    let!(:dossier_en_construction) do
      create(:dossier, procedure: procedure, state: :en_construction, created_at: monday)
    end

    it { expect(procedure_overview.dossiers_en_construction_count).to eq(1) }
  end

  describe 'created_dossiers_count' do
    let!(:created_dossier_during_the_week) do
      create(:dossier, procedure: procedure, created_at: monday, state: :received)
    end

    let!(:created_dossier_during_the_week_but_in_brouillon) do
      create(:dossier, procedure: procedure, created_at: monday, state: :brouillon)
    end

    let!(:created_dossier_before_the_week) do
      create(:dossier, procedure: procedure, created_at: (monday - 1.week), state: :received)
    end

    it { expect(procedure_overview.created_dossiers_count).to eq(1) }
  end

  describe 'had_some_activities?' do
    subject { procedure_overview.had_some_activities? }

    before :each do
      procedure_overview.dossiers_en_instruction_count = 0
      procedure_overview.dossiers_en_construction_count = 0
      procedure_overview.created_dossiers_count = 0
    end

    context 'when there are no activities' do
      it { is_expected.to be false }
    end

    context 'when there are some dossiers en instruction' do
      before { procedure_overview.dossiers_en_instruction_count = 2 }
      it { is_expected.to be true }
    end

    context 'when there are some dossiers en construction' do
      before { procedure_overview.dossiers_en_construction_count = 2 }
      it { is_expected.to be true }
    end

    context 'when there are some created dossiers' do
      before { procedure_overview.created_dossiers_count = 2 }
      it { is_expected.to be true }
    end
  end
end
