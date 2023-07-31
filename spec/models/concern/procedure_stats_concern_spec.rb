describe ProcedureStatsConcern do
  describe '#stats_dossiers_funnel' do
    let(:procedure) { create(:procedure) }

    subject(:stats_dossiers_funnel) { procedure.stats_dossiers_funnel }

    before do
      create_list(:dossier, 2, :brouillon, procedure: procedure)
      create(:dossier, :en_instruction, procedure: procedure)
      create(:dossier, procedure: procedure, for_procedure_preview: true)
      create(:dossier, :accepte, procedure: procedure, hidden_by_administration_at: Time.zone.now)
    end

    it "returns the funnel stats" do
      expect(stats_dossiers_funnel).to match(
        [
          ['Démarrés', procedure.dossiers.visible_by_user_or_administration.count],
          ['Déposés', procedure.dossiers.visible_by_administration.count],
          ['Instruction débutée', procedure.dossiers.visible_by_administration.state_instruction_commencee.count],
          ['Traités', procedure.dossiers.visible_by_administration.state_termine.count]
        ]
      )
    end
  end

  describe '#usual_traitement_time_for_recent_dossiers' do
    let(:procedure) { create(:procedure) }

    before do
      Timecop.freeze(Time.utc(2019, 6, 1, 12, 0))

      delays.each do |delay|
        create_dossier(construction_date: 1.week.ago - delay, instruction_date: 1.week.ago - delay + 12.hours, processed_date: 1.week.ago)
      end
    end

    after { Timecop.return }

    context 'when there are several processed dossiers' do
      let(:delays) { [1.day, 2.days, 2.days, 2.days, 2.days, 3.days, 3.days, 3.days, 3.days, 12.days] }

      it 'returns a time representative of the dossier instruction delay' do
        expect(procedure.usual_traitement_time_for_recent_dossiers(30)).to be_between(3.days, 4.days)
      end
    end

    context 'when there are very old dossiers' do
      let(:delays) { [2.days, 2.days] }
      let!(:old_dossier) { create_dossier(construction_date: 3.months.ago, instruction_date: 2.months.ago, processed_date: 2.months.ago) }

      it 'ignores dossiers older than 1 month' do
        expect(procedure.usual_traitement_time_for_recent_dossiers(30)).to be_within(1.hour).of(2.days)
      end
    end

    context 'when there is a dossier with bad data' do
      let(:delays) { [2.days, 2.days] }
      let!(:bad_dossier) { create_dossier(construction_date: nil, instruction_date: nil, processed_date: 10.days.ago) }

      it 'ignores bad dossiers' do
        expect(procedure.usual_traitement_time_for_recent_dossiers(30)).to be_within(1.hour).of(2.days)
      end
    end

    context 'when there is only one processed dossier' do
      let(:delays) { [1.day] }
      it { expect(procedure.usual_traitement_time_for_recent_dossiers(30)).to be_within(1.hour).of(1.day) }
    end

    context 'where there is no processed dossier' do
      let(:delays) { [] }
      it { expect(procedure.usual_traitement_time_for_recent_dossiers(30)).to eq nil }
    end
  end

  describe '.usual_traitement_time_by_month_in_days' do
    let(:procedure) { create(:procedure) }

    def create_dossiers(delays_by_month)
      delays_by_month.each_with_index do |delays, index|
        delays.each do |delay|
          processed_date = (index.months + 1.week).ago
          create_dossier(construction_date: processed_date - delay, instruction_date: processed_date - delay + 12.hours, processed_date: processed_date)
        end
      end
    end

    before do
      Timecop.freeze(Time.utc(2019, 6, 25, 12, 0))

      create_dossiers(delays_by_month)
    end

    after { Timecop.return }

    context 'when there are several processed dossiers' do
      let(:delays_by_month) {
  [
    [90.days, 90.days],
    [1.day, 2.days, 2.days, 2.days, 2.days, 3.days, 3.days, 3.days, 3.days, 12.days],
    [30.days, 60.days, 60.days, 60.days]
  ]
}

      it 'computes a time representative of the dossier instruction delay for each month except current month' do
        expect(procedure.usual_traitement_time_by_month_in_days['avril 2019']).to eq 60
        expect(procedure.usual_traitement_time_by_month_in_days['mai 2019']).to eq 4
        expect(procedure.usual_traitement_time_by_month_in_days['juin 2019']).to eq nil
      end
    end
  end

  private

  def create_dossier(construction_date:, instruction_date:, processed_date:)
    dossier = create(:dossier, :accepte, procedure: procedure, depose_at: construction_date, en_instruction_at: instruction_date, processed_at: processed_date)
  end
end
