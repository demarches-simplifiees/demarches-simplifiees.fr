# frozen_string_literal: true

describe ProcedureOverview, type: :model do
  let(:procedure) { create(:procedure, libelle: 'libelle') }
  let(:friday) { Time.zone.local(2017, 5, 12) } # vendredi 12 mai 2017, de la semaine du 8 mai
  let(:monday) { Time.zone.local(2017, 5, 8) }

  before { travel_to(friday) }

  let(:procedure_overview) { ProcedureOverview.new(procedure, monday, [procedure.defaut_groupe_instructeur]) }

  describe 'dossiers_en_instruction_count' do
    let!(:en_instruction_dossier) do
      create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction), created_at: monday)
    end

    it { expect(procedure_overview.dossiers_en_instruction_count).to eq(1) }
  end

  describe 'old_dossiers_en_instruction' do
    let!(:old_dossier_en_instruction) do
      create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction), en_instruction_at: monday - 1.month)
    end

    let!(:dossier_en_instruction) do
      create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction), en_instruction_at: monday)
    end

    it do
      expect(procedure_overview.old_dossiers_en_instruction).to match([old_dossier_en_instruction])
    end
  end

  describe 'dossiers_en_construction_count' do
    let!(:dossier_en_construction) do
      create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), created_at: monday)
    end
    let(:dossier_en_construction_deleted_by_user) do
      create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), created_at: monday)
    end

    before do
      dossier_en_construction_deleted_by_user.update(hidden_by_user_at: Time.zone.now)
    end

    it { expect(procedure_overview.dossiers_en_construction_count).to eq(1) }
  end

  describe 'created_dossiers_count' do
    let!(:created_dossier_during_the_week) do
      create(:dossier, procedure: procedure, created_at: monday, state: Dossier.states.fetch(:en_instruction))
    end

    let!(:created_dossier_during_the_week_but_in_brouillon) do
      create(:dossier, procedure: procedure, created_at: monday, state: Dossier.states.fetch(:brouillon))
    end

    let!(:created_dossier_before_the_week) do
      create(:dossier, procedure: procedure, created_at: (monday - 1.week), state: Dossier.states.fetch(:en_instruction))
    end

    it { expect(procedure_overview.created_dossiers_count).to eq(1) }
  end

  describe 'with a procedure routee' do
    let!(:gi_2) { create(:groupe_instructeur, label: 'groupe instructeur 2', procedure: procedure) }
    let!(:gi_3) { create(:groupe_instructeur, label: 'groupe instructeur 3', procedure: procedure) }

    def create_dossier_in_group(g)
      create(:dossier, procedure: procedure, created_at: monday, state: Dossier.states.fetch(:en_instruction), groupe_instructeur: g)
    end

    let!(:created_dossier_during_the_week_on_group_2) { create_dossier_in_group(gi_2) }
    let!(:created_dossier_during_the_week_on_group_3_a) { create_dossier_in_group(gi_3) }
    let!(:created_dossier_during_the_week_on_group_3_b) { create_dossier_in_group(gi_3) }

    let(:procedure_overview_gi_2) { ProcedureOverview.new(procedure, monday, [gi_2]) }
    let(:procedure_overview_gi_3) { ProcedureOverview.new(procedure, monday, [gi_3]) }
    let(:procedure_overview_default) { ProcedureOverview.new(procedure, monday, [procedure.defaut_groupe_instructeur]) }

    it do
      expect(procedure_overview_gi_2.created_dossiers_count).to eq(1)
      expect(procedure_overview_gi_3.created_dossiers_count).to eq(2)
      expect(procedure_overview_default.created_dossiers_count).to eq(0)
    end
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
