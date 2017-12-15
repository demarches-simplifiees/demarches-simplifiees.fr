require 'spec_helper'

describe StatsController, type: :controller do
  describe "#last_four_months_hash" do
    context "while a regular user is logged in" do
      before do
        FactoryGirl.create(:procedure, :created_at => 6.months.ago, :updated_at => 6.months.ago)
        FactoryGirl.create(:procedure, :created_at => 2.months.ago, :updated_at => 62.days.ago)
        FactoryGirl.create(:procedure, :created_at => 2.months.ago, :updated_at => 62.days.ago)
        FactoryGirl.create(:procedure, :created_at => 2.months.ago, :updated_at => 31.days.ago)
        FactoryGirl.create(:procedure, :created_at => 2.months.ago, :updated_at => Time.now)
        @controller = StatsController.new

        allow(@controller).to receive(:administration_signed_in?).and_return(false)
      end

      let (:association) { Procedure.all }

      subject { @controller.send(:last_four_months_hash, association, :updated_at) }

      it { expect(subject).to match_array([
        [I18n.l(62.days.ago.beginning_of_month, format: "%B %Y"), 2],
        [I18n.l(31.days.ago.beginning_of_month, format: "%B %Y"), 1]
        ])
      }
    end

    context "while a super admin is logged in" do
      before do
        FactoryGirl.create(:procedure, :updated_at => 6.months.ago)
        FactoryGirl.create(:procedure, :updated_at => 45.days.ago)
        FactoryGirl.create(:procedure, :updated_at => 1.day.ago)
        FactoryGirl.create(:procedure, :updated_at => 1.day.ago)

        @controller = StatsController.new

        allow(@controller).to receive(:administration_signed_in?).and_return(true)
      end

      let (:association) { Procedure.all }

      subject { @controller.send(:last_four_months_hash, association, :updated_at) }

      it { expect(subject).to eq([
        [I18n.l(45.days.ago.beginning_of_month, format: "%B %Y"), 1],
        [I18n.l(1.days.ago.beginning_of_month, format: "%B %Y"), 2]
        ])
      }
    end
  end

  describe '#cumulative_hash' do
    before do
      Timecop.freeze(Time.new(2016, 10, 2))
      FactoryGirl.create(:procedure, :created_at => 55.days.ago, :updated_at => 43.days.ago)
      FactoryGirl.create(:procedure, :created_at => 45.days.ago, :updated_at => 40.days.ago)
      FactoryGirl.create(:procedure, :created_at => 45.days.ago, :updated_at => 20.days.ago)
      FactoryGirl.create(:procedure, :created_at => 15.days.ago, :updated_at => 20.days.ago)
      FactoryGirl.create(:procedure, :created_at => 15.days.ago, :updated_at => 1.hour.ago)
    end

    after { Timecop.return }

    let (:association) { Procedure.all }

    context "while a super admin is logged in" do
      before { allow(@controller).to receive(:administration_signed_in?).and_return(true) }

      subject { @controller.send(:cumulative_hash, association, :updated_at) }

      it { expect(subject).to eq({
          2.month.ago.beginning_of_month => 2,
          1.month.ago.beginning_of_month => 4,
          1.hour.ago.beginning_of_month => 5
        })
      }
    end

    context "while a super admin is not logged in" do
      before { allow(@controller).to receive(:administration_signed_in?).and_return(false) }

      subject { @controller.send(:cumulative_hash, association, :updated_at) }

      it { expect(subject).to eq({
          2.month.ago.beginning_of_month => 2,
          1.month.ago.beginning_of_month => 4
        })
      }
    end
  end

  describe "#procedures_count_per_administrateur" do
    let!(:administrateur_1) { create(:administrateur) }
    let!(:administrateur_2) { create(:administrateur) }
    let!(:administrateur_3) { create(:administrateur) }
    let!(:administrateur_4) { create(:administrateur) }
    let!(:administrateur_5) { create(:administrateur) }

    before do
      3.times do
        create(:procedure, published_at: Time.now, administrateur: administrateur_1)
      end

      2.times do
        create(:procedure, published_at: Time.now, administrateur: administrateur_2)
      end

      8.times do
        create(:procedure, published_at: Time.now, administrateur: administrateur_3)
      end

      create(:procedure, published_at: Time.now, administrateur: administrateur_4)
    end

    let(:association){ Procedure.all }

    subject { StatsController.new.send(:procedures_count_per_administrateur, association) }

    it do
      is_expected.to eq({
        'Une procédure' => 1,
        'Entre deux et cinq procédures' => 2,
        'Plus de cinq procédures' => 1
      })
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
      procedure_1 = FactoryGirl.create(:procedure)
      procedure_2 = FactoryGirl.create(:procedure)
      dossier_p1_a = FactoryGirl.create(:dossier,
        :procedure          => procedure_1,
        :en_construction_at => 2.months.ago.beginning_of_month,
        :processed_at       => 2.months.ago.beginning_of_month + 3.days)
      dossier_p1_b = FactoryGirl.create(:dossier,
        :procedure          => procedure_1,
        :en_construction_at => 2.months.ago.beginning_of_month,
        :processed_at       => 2.months.ago.beginning_of_month + 1.days)
      dossier_p1_c = FactoryGirl.create(:dossier,
        :procedure          => procedure_1,
        :en_construction_at => 1.months.ago.beginning_of_month,
        :processed_at       => 1.months.ago.beginning_of_month + 5.days)
      dossier_p2_a = FactoryGirl.create(:dossier,
        :procedure          => procedure_2,
        :en_construction_at => 2.month.ago.beginning_of_month,
        :processed_at       => 2.month.ago.beginning_of_month + 4.days)

      # Write directly in the DB to avoid the before_validation hook
      Dossier.update_all(state: "accepte")

      @expected_hash = {
        "#{2.months.ago.beginning_of_month}" => 3.0,
        "#{1.months.ago.beginning_of_month}" => 5.0
      }
    end

    let (:association) { Dossier.where.not(:state => :brouillon) }

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
      procedure_1 = FactoryGirl.create(:procedure, :with_type_de_champ, :types_de_champ_count => 24)
      procedure_2 = FactoryGirl.create(:procedure, :with_type_de_champ, :types_de_champ_count => 48)
      dossier_p1_a = FactoryGirl.create(:dossier,
        :procedure    => procedure_1,
        :created_at   => 2.months.ago.beginning_of_month,
        :en_construction_at => 2.months.ago.beginning_of_month + 30.minutes,
        :processed_at => 2.months.ago.beginning_of_month + 1.day)
      dossier_p1_b = FactoryGirl.create(:dossier,
        :procedure    => procedure_1,
        :created_at   => 2.months.ago.beginning_of_month,
        :en_construction_at => 2.months.ago.beginning_of_month + 10.minutes,
        :processed_at => 2.months.ago.beginning_of_month + 1.day)
      dossier_p1_c = FactoryGirl.create(:dossier,
        :procedure    => procedure_1,
        :created_at   => 1.months.ago.beginning_of_month,
        :en_construction_at => 1.months.ago.beginning_of_month + 50.minutes,
        :processed_at => 1.months.ago.beginning_of_month + 1.day)
      dossier_p2_a = FactoryGirl.create(:dossier,
        :procedure    => procedure_2,
        :created_at   => 2.month.ago.beginning_of_month,
        :en_construction_at => 2.month.ago.beginning_of_month + 80.minutes,
        :processed_at => 2.month.ago.beginning_of_month + 1.day)

      # Write directly in the DB to avoid the before_validation hook
      Dossier.update_all(state: "accepte")

      @expected_hash = {
        "#{2.months.ago.beginning_of_month}" => 30.0,
        "#{1.months.ago.beginning_of_month}" => 50.0
      }
    end

    let (:association) { Dossier.where.not(:state => :brouillon) }

    subject { StatsController.new.send(:dossier_filling_mean_time, association) }

    it { expect(subject).to eq(@expected_hash) }
  end

  describe '#avis_usage' do
    let!(:dossier) { create(:dossier) }
    let!(:avis_with_dossier) { create(:avis) }
    let!(:dossier2) { create(:dossier) }

    before { Timecop.freeze(Time.now) }
    after { Timecop.return }

    subject { StatsController.new.send(:avis_usage) }

    it { expect(subject).to match([[3.week.ago.to_i, 0], [2.week.ago.to_i, 0], [1.week.ago.to_i, 33.33]]) }
  end

  describe "#avis_average_answer_time" do
    before do
      # 1 week ago
      create(:avis, answer: "voila ma réponse", created_at: 1.week.ago + 1.day, updated_at: 1.week.ago + 2.days) # 1 day
      create(:avis, created_at: 1.week.ago + 2.days)

      # 2 weeks ago
      create(:avis, answer: "voila ma réponse", created_at: 2.week.ago + 1.day, updated_at: 2.week.ago + 2.days) # 1 day
      create(:avis, answer: "voila ma réponse2", created_at: 2.week.ago + 3.days, updated_at: 1.week.ago + 6.days) # 10 days
      create(:avis, answer: "voila ma réponse2", created_at: 2.week.ago + 2.days, updated_at: 1.week.ago + 6.days) # 11 days
      create(:avis, created_at: 2.week.ago + 1.day, updated_at: 2.week.ago + 2.days)

      # 3 weeks ago
      create(:avis, answer: "voila ma réponse2", created_at: 3.weeks.ago + 1.day, updated_at: 3.weeks.ago + 2.days) # 1 day
      create(:avis, answer: "voila ma réponse2", created_at: 3.weeks.ago + 1.day, updated_at: 1.week.ago + 5.days) # 18 day
    end

    subject { StatsController.new.send(:avis_average_answer_time) }

    it { expect(subject.count).to eq(3) }
    it { is_expected.to include [1.week.ago.to_i, 1.0] }
    it { is_expected.to include [2.week.ago.to_i, 7.33] }
    it { is_expected.to include [3.week.ago.to_i, 9.5] }
  end

  describe '#avis_answer_percentages' do
    let!(:avis) { create(:avis, created_at: 2.days.ago) }
    let!(:avis2) { create(:avis, answer: 'answer', created_at: 2.days.ago) }
    let!(:avis3) { create(:avis, answer: 'answer', created_at: 2.days.ago) }

    subject { StatsController.new.send(:avis_answer_percentages) }

    before { Timecop.freeze(Time.now) }
    after { Timecop.return }

    it { is_expected.to match [[3.week.ago.to_i, 0], [2.week.ago.to_i, 0], [1.week.ago.to_i, 66.67]] }
  end

  describe '#motivation_usage_dossier' do
    let!(:dossier) { create(:dossier, processed_at: 1.week.ago, motivation: "Motivation") }
    let!(:dossier2) { create(:dossier, processed_at: 1.week.ago) }
    let!(:dossier3) { create(:dossier, processed_at: 1.week.ago) }

    before { Timecop.freeze(Time.now) }
    after { Timecop.return }

    subject { StatsController.new.send(:motivation_usage_dossier) }

    it { expect(subject).to match([[I18n.l(3.week.ago.end_of_week, format: '%d/%m/%Y'), 0], [I18n.l(2.week.ago.end_of_week, format: '%d/%m/%Y'), 0], [I18n.l(1.week.ago.end_of_week, format: '%d/%m/%Y'), 33.33]]) }
  end

  describe '#motivation_usage_procedure' do
    let!(:dossier) { create(:dossier, processed_at: 1.week.ago, motivation: "Motivation" ) }
    let!(:dossier1) { create(:dossier, processed_at: 1.week.ago, motivation: "Motivation", procedure: dossier.procedure) }
    let!(:dossier2) { create(:dossier, processed_at: 1.week.ago) }
    let!(:dossier3) { create(:dossier, processed_at: 1.week.ago) }

    before { Timecop.freeze(Time.now) }
    after { Timecop.return }

    subject { StatsController.new.send(:motivation_usage_procedure) }

    it { expect(subject).to match([[I18n.l(3.week.ago.end_of_week, format: '%d/%m/%Y'), 0], [I18n.l(2.week.ago.end_of_week, format: '%d/%m/%Y'), 0], [I18n.l(1.week.ago.end_of_week, format: '%d/%m/%Y'), 33.33]]) }
  end
end
