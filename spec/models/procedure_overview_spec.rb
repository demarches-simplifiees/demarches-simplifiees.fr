require 'spec_helper'

describe ProcedureOverview, type: :model do
  let(:procedure) { create(:procedure, libelle: 'libelle') }
  let(:friday) { DateTime.new(2017, 5, 12) } # vendredi 12 mai 2017, de la semaine du 8 mai
  let(:monday) { DateTime.new(2017, 5, 8) }

  before :each do
    Timecop.freeze(friday)
  end

  let(:procedure_overview) { ProcedureOverview.new(procedure, monday, 0) }

  describe 'received_dossiers_count' do
    let!(:received_dossier) do
      dossier = create(:dossier, procedure: procedure, state: :received, created_at: monday)
    end

    it { expect(procedure_overview.received_dossiers_count).to eq(1) }
  end

  describe 'created_dossiers_count' do
    let!(:created_dossier_during_the_week) do
      create(:dossier, procedure: procedure, created_at: monday, state: :received)
    end

    let!(:created_dossier_during_the_week_but_in_draft) do
      create(:dossier, procedure: procedure, created_at: monday, state: :draft)
    end

    let!(:created_dossier_before_the_week) do
      create(:dossier, procedure: procedure, created_at: (monday - 1.week), state: :received)
    end

    it { expect(procedure_overview.created_dossiers_count).to eq(1) }
  end

  describe 'processed_dossiers_count' do
    let!(:processed_dossier_during_the_week) do
      create(:dossier, procedure: procedure, created_at: monday, processed_at: monday)
    end

    let!(:processed_dossier_before_the_week) do
      create(:dossier, procedure: procedure, created_at: (monday - 1.week), processed_at: (monday - 1.week))
    end

    it { expect(procedure_overview.processed_dossiers_count).to eq(1) }
  end

  describe 'to_html' do
    subject { procedure_overview.to_html }

    context 'when the different count are equal to 0' do
      it { is_expected.to match(/^<a href='.+'><strong>libelle<\/strong><\/a>$/) }
    end

    context 'when the different counts are equal to 1' do
      before :each do
        procedure_overview.notifications_count = 1
        procedure_overview.received_dossiers_count = 1
        procedure_overview.created_dossiers_count = 1
        procedure_overview.processed_dossiers_count = 1
      end

      it { is_expected.to match(/^<a href='.+'><strong>libelle<\/strong><\/a>/) }
      it { is_expected.to include("1 dossier est en cours d'instruction") }
      it { is_expected.to include('1 nouveau dossier a été déposé') }
      it { is_expected.to include('1 dossier a été instruit') }
      it { is_expected.to include('1 notification en attente sur les dossiers que vous suivez') }
    end

    context 'when the different counts are equal to 2' do
      before :each do
        procedure_overview.notifications_count = 2
        procedure_overview.received_dossiers_count = 3
        procedure_overview.created_dossiers_count = 4
        procedure_overview.processed_dossiers_count = 5
      end

      it { is_expected.to match(/^<a href='.+'><strong>libelle<\/strong><\/a>/) }
      it { is_expected.to include("3 dossiers sont en cours d'instruction") }
      it { is_expected.to include('4 nouveaux dossiers ont été déposés') }
      it { is_expected.to include('5 dossiers ont été instruits') }
      it { is_expected.to include('2 notifications en attente sur les dossiers que vous suivez') }
    end
  end
end
