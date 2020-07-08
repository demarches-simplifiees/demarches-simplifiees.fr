describe StatsController, type: :controller do
  describe "#last_four_months_hash" do
    context "while a regular user is logged in" do
      before do
        FactoryBot.create(:procedure, :created_at => 6.months.ago, :updated_at => 6.months.ago)
        FactoryBot.create(:procedure, :created_at => 2.months.ago, :updated_at => 62.days.ago)
        FactoryBot.create(:procedure, :created_at => 2.months.ago, :updated_at => 62.days.ago)
        FactoryBot.create(:procedure, :created_at => 2.months.ago, :updated_at => 31.days.ago)
        FactoryBot.create(:procedure, :created_at => 2.months.ago, :updated_at => Time.zone.now)
        @controller = StatsController.new

        allow(@controller).to receive(:administration_signed_in?).and_return(false)
      end

      let (:association) { Procedure.all }

      subject { @controller.send(:last_four_months_hash, association, :updated_at) }

      it do
        expect(subject).to match_array([
          [I18n.l(62.days.ago.beginning_of_month, format: "%B %Y"), 2],
          [I18n.l(31.days.ago.beginning_of_month, format: "%B %Y"), 1]
        ])
      end
    end

    context "while a super admin is logged in" do
      before do
        FactoryBot.create(:procedure, :updated_at => 6.months.ago)
        FactoryBot.create(:procedure, :updated_at => 45.days.ago)
        FactoryBot.create(:procedure, :updated_at => 1.day.ago)
        FactoryBot.create(:procedure, :updated_at => 1.day.ago)

        @controller = StatsController.new

        allow(@controller).to receive(:administration_signed_in?).and_return(true)
      end

      let (:association) { Procedure.all }

      subject { @controller.send(:last_four_months_hash, association, :updated_at) }

      it do
        expect(subject).to eq([
          [I18n.l(45.days.ago.beginning_of_month, format: "%B %Y"), 1],
          [I18n.l(1.day.ago.beginning_of_month, format: "%B %Y"), 2]
        ])
      end
    end
  end

  describe '#cumulative_hash' do
    before do
      Timecop.freeze(Time.zone.local(2016, 10, 2))
      FactoryBot.create(:procedure, :created_at => 55.days.ago, :updated_at => 43.days.ago)
      FactoryBot.create(:procedure, :created_at => 45.days.ago, :updated_at => 40.days.ago)
      FactoryBot.create(:procedure, :created_at => 45.days.ago, :updated_at => 20.days.ago)
      FactoryBot.create(:procedure, :created_at => 15.days.ago, :updated_at => 20.days.ago)
      FactoryBot.create(:procedure, :created_at => 15.days.ago, :updated_at => 1.hour.ago)
    end

    after { Timecop.return }

    let (:association) { Procedure.all }

    context "while a super admin is logged in" do
      before { allow(@controller).to receive(:administration_signed_in?).and_return(true) }

      subject { @controller.send(:cumulative_hash, association, :updated_at) }

      it do
        expect(subject).to eq({
          Time.utc(2016, 8, 1) => 2,
          Time.utc(2016, 9, 1) => 4,
          Time.utc(2016, 10, 1) => 5
        })
      end
    end

    context "while a super admin is not logged in" do
      before { allow(@controller).to receive(:administration_signed_in?).and_return(false) }

      subject { @controller.send(:cumulative_hash, association, :updated_at) }

      it do
        expect(subject).to eq({
          Time.utc(2016, 8, 1) => 2,
          Time.utc(2016, 9, 1) => 4
        })
      end
    end
  end

  describe "#dossier_instruction_mean_time" do
    # Month-2: mean 3 days
    #  procedure_1: mean 2 days
    #   dossier_p1_a: 3 days
    #   dossier_p1_b: 1 days
    #  procedure_2: mean 4 days
    #    dossier_p2_a: 4 days
    #
    # Month-1: mean 5 days
    #   procedure_1: mean 5 days
    #     dossier_p1_c: 5 days

    before do
      procedure_1 = FactoryBot.create(:procedure)
      procedure_2 = FactoryBot.create(:procedure)
      dossier_p1_a = FactoryBot.create(:dossier, :accepte,
        :procedure          => procedure_1,
        :en_construction_at => 2.months.ago.beginning_of_month,
        :processed_at       => 2.months.ago.beginning_of_month + 3.days)
      dossier_p1_b = FactoryBot.create(:dossier, :accepte,
        :procedure          => procedure_1,
        :en_construction_at => 2.months.ago.beginning_of_month,
        :processed_at       => 2.months.ago.beginning_of_month + 1.day)
      dossier_p1_c = FactoryBot.create(:dossier, :accepte,
        :procedure          => procedure_1,
        :en_construction_at => 1.month.ago.beginning_of_month,
        :processed_at       => 1.month.ago.beginning_of_month + 5.days)
      dossier_p2_a = FactoryBot.create(:dossier, :accepte,
        :procedure          => procedure_2,
        :en_construction_at => 2.months.ago.beginning_of_month,
        :processed_at       => 2.months.ago.beginning_of_month + 4.days)

      @expected_hash = {
        (2.months.ago.beginning_of_month).to_s => 3.0,
        (1.month.ago.beginning_of_month).to_s => 5.0
      }
    end

    let (:association) { Dossier.state_not_brouillon }

    subject { StatsController.new.send(:dossier_instruction_mean_time, association) }

    it { expect(subject).to eq(@expected_hash) }
  end

  describe "#dossier_filling_mean_time" do
    # Month-2: mean 30 minutes
    #  procedure_1: mean 20 minutes
    #   dossier_p1_a: 30 minutes
    #   dossier_p1_b: 10 minutes
    #  procedure_2: mean 40 minutes
    #    dossier_p2_a: 80 minutes, for twice the fields
    #
    # Month-1: mean 50 minutes
    #   procedure_1: mean 50 minutes
    #     dossier_p1_c: 50 minutes

    before do
      procedure_1 = FactoryBot.create(:procedure, :with_type_de_champ, :types_de_champ_count => 24)
      procedure_2 = FactoryBot.create(:procedure, :with_type_de_champ, :types_de_champ_count => 48)
      dossier_p1_a = FactoryBot.create(:dossier, :accepte,
        :procedure    => procedure_1,
        :created_at   => 2.months.ago.beginning_of_month,
        :en_construction_at => 2.months.ago.beginning_of_month + 30.minutes,
        :processed_at => 2.months.ago.beginning_of_month + 1.day)
      dossier_p1_b = FactoryBot.create(:dossier, :accepte,
        :procedure    => procedure_1,
        :created_at   => 2.months.ago.beginning_of_month,
        :en_construction_at => 2.months.ago.beginning_of_month + 10.minutes,
        :processed_at => 2.months.ago.beginning_of_month + 1.day)
      dossier_p1_c = FactoryBot.create(:dossier, :accepte,
        :procedure    => procedure_1,
        :created_at   => 1.month.ago.beginning_of_month,
        :en_construction_at => 1.month.ago.beginning_of_month + 50.minutes,
        :processed_at => 1.month.ago.beginning_of_month + 1.day)
      dossier_p2_a = FactoryBot.create(:dossier, :accepte,
        :procedure    => procedure_2,
        :created_at   => 2.months.ago.beginning_of_month,
        :en_construction_at => 2.months.ago.beginning_of_month + 80.minutes,
        :processed_at => 2.months.ago.beginning_of_month + 1.day)

      @expected_hash = {
        (2.months.ago.beginning_of_month).to_s => 30.0,
        (1.month.ago.beginning_of_month).to_s => 50.0
      }
    end

    let (:association) { Dossier.state_not_brouillon }

    subject { StatsController.new.send(:dossier_filling_mean_time, association) }

    it { expect(subject).to eq(@expected_hash) }
  end

  describe "#satisfaction_usagers" do
    before do
      # Test the stats on October 2018 – where the 1st, 8th, 15th, 22th and 29th are conveniently Mondays
      # Current week: 1 negative feedback
      Timecop.freeze(Time.zone.local(2018, 10, 22, 12, 00)) { create(:feedback, :unhappy) }
      # Last week: 3 positive, 1 negative
      Timecop.freeze(Time.zone.local(2018, 10, 21, 12, 00)) { create(:feedback, :unhappy) }
      Timecop.freeze(Time.zone.local(2018, 10, 19, 12, 00)) { create(:feedback, :happy) }
      Timecop.freeze(Time.zone.local(2018, 10, 17, 12, 00)) { create(:feedback, :happy) }
      Timecop.freeze(Time.zone.local(2018, 10, 15, 12, 00)) { create(:feedback, :happy) }
      # N-2 week: 2 positive, 2 negative
      Timecop.freeze(Time.zone.local(2018, 10, 14, 12, 00)) { create(:feedback, :unhappy) }
      Timecop.freeze(Time.zone.local(2018, 10, 12, 12, 00)) { create(:feedback, :happy) }
      Timecop.freeze(Time.zone.local(2018, 10, 10, 12, 00)) { create(:feedback, :unhappy) }
      Timecop.freeze(Time.zone.local(2018, 10, 8, 12, 00)) { create(:feedback, :happy) }
      # N-3 week: 1 positive, 3 negative
      Timecop.freeze(Time.zone.local(2018, 10, 1, 12, 00)) { create(:feedback, :unhappy) }
      Timecop.freeze(Time.zone.local(2018, 10, 3, 12, 00)) { create(:feedback, :happy) }
      Timecop.freeze(Time.zone.local(2018, 10, 5, 12, 00)) { create(:feedback, :unhappy) }
      Timecop.freeze(Time.zone.local(2018, 10, 7, 12, 00)) { create(:feedback, :unhappy) }
    end

    subject(:stats) do
      Timecop.freeze(Time.zone.local(2018, 10, 28, 12, 00)) {
        StatsController.new.send(:satisfaction_usagers)
      }
    end

    it 'returns one set of values for each kind of feedback' do
      expect(stats.count).to eq 3
      expect(stats.map { |g| g[:name] }).to contain_exactly('Satisfaits', 'Neutres', 'Mécontents')
    end

    it 'returns weekly ratios between a given feedback and all feedback' do
      happy_data = stats.find { |g| g[:name] == 'Satisfaits' }[:data]

      expect(happy_data.values[-4]).to eq 0
      expect(happy_data.values[-3]).to eq 25.0
      expect(happy_data.values[-2]).to eq 50.0
      expect(happy_data.values[-1]).to eq 75.0

      unhappy_data = stats.find { |g| g[:name] == 'Mécontents' }[:data]
      expect(unhappy_data.values[-4]).to eq 0
      expect(unhappy_data.values[-3]).to eq 75.0
      expect(unhappy_data.values[-2]).to eq 50.0
      expect(unhappy_data.values[-1]).to eq 25.0
    end

    it 'excludes values still in the current week' do
      unhappy_data = stats.find { |g| g[:name] == 'Mécontents' }[:data]
      expect(unhappy_data.values).not_to include(100.0)
    end
  end

  describe '#avis_usage' do
    let!(:dossier) { create(:dossier) }
    let!(:avis_with_dossier) { create(:avis) }
    let!(:dossier2) { create(:dossier) }

    before { Timecop.freeze(Time.zone.now) }
    after { Timecop.return }

    subject { StatsController.new.send(:avis_usage) }

    it { expect(subject).to match([[3.weeks.ago.to_i, 0], [2.weeks.ago.to_i, 0], [1.week.ago.to_i, 33.33]]) }
  end
end
