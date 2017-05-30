require 'spec_helper'

describe StatsController, type: :controller do
  describe "#last_four_months_hash" do
    context "without a date attribute" do
      before do
        FactoryGirl.create(:procedure, :created_at => 6.months.ago)
        FactoryGirl.create(:procedure, :created_at => 45.days.ago)
        FactoryGirl.create(:procedure, :created_at => 1.days.ago)
        FactoryGirl.create(:procedure, :created_at => 1.days.ago)
      end

      let (:association) { Procedure.all }

      subject { StatsController.new.send(:last_four_months_hash, association) }

      it { expect(subject).to eq([
        [I18n.l(45.days.ago.beginning_of_month, format: "%B %Y"), 1],
        [I18n.l(1.days.ago.beginning_of_month, format: "%B %Y"), 2]
      ] ) }
    end

    context "with a date attribute" do
      before do
        FactoryGirl.create(:procedure, :created_at => 6.months.ago, :updated_at => 6.months.ago)
        FactoryGirl.create(:procedure, :created_at => 2.months.ago, :updated_at => 45.days.ago)
        FactoryGirl.create(:procedure, :created_at => 2.months.ago, :updated_at => 45.days.ago)
        FactoryGirl.create(:procedure, :created_at => 2.months.ago, :updated_at => 1.days.ago)
      end

      let (:association) { Procedure.all }

      subject { StatsController.new.send(:last_four_months_hash, association, :updated_at) }

      it { expect(subject).to eq([
        [I18n.l(45.days.ago.beginning_of_month, format: "%B %Y"), 2],
        [I18n.l(1.days.ago.beginning_of_month, format: "%B %Y"), 1]
      ] ) }
    end
  end

  describe '#cumulative_hash' do
    context "without a date attribute" do
      before do
        FactoryGirl.create(:procedure, :created_at => 45.days.ago)
        FactoryGirl.create(:procedure, :created_at => 15.days.ago)
        FactoryGirl.create(:procedure, :created_at => 15.days.ago)
      end

      let (:association) { Procedure.all }

      subject { StatsController.new.send(:cumulative_hash, association) }

      it { expect(subject).to eq({
        45.days.ago.beginning_of_month => 1,
        15.days.ago.beginning_of_month => 3
      }) }
    end

    context "with a date attribute" do
      before do
        FactoryGirl.create(:procedure, :created_at => 45.days.ago, :updated_at => 20.days.ago)
        FactoryGirl.create(:procedure, :created_at => 15.days.ago, :updated_at => 20.days.ago)
        FactoryGirl.create(:procedure, :created_at => 15.days.ago, :updated_at => 10.days.ago)
      end

      let (:association) { Procedure.all }

      subject { StatsController.new.send(:cumulative_hash, association, :updated_at) }

      it { expect(subject).to eq({
        20.days.ago.beginning_of_month => 2,
        10.days.ago.beginning_of_month => 3
      }) }
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
        :procedure    => procedure_1,
        :initiated_at => 2.months.ago.beginning_of_month,
        :processed_at => 2.months.ago.beginning_of_month + 3.days)
      dossier_p1_b = FactoryGirl.create(:dossier,
        :procedure    => procedure_1,
        :initiated_at => 2.months.ago.beginning_of_month,
        :processed_at => 2.months.ago.beginning_of_month + 1.days)
      dossier_p1_c = FactoryGirl.create(:dossier,
        :procedure    => procedure_1,
        :initiated_at => 1.months.ago.beginning_of_month,
        :processed_at => 1.months.ago.beginning_of_month + 5.days)
      dossier_p2_a = FactoryGirl.create(:dossier,
        :procedure    => procedure_2,
        :initiated_at => 2.month.ago.beginning_of_month,
        :processed_at => 2.month.ago.beginning_of_month + 4.days)

      # Write directly in the DB to avoid the before_validation hook
      Dossier.update_all(state: "closed")

      @expected_hash = {
        "#{2.months.ago.beginning_of_month}" => 3.0,
        "#{1.months.ago.beginning_of_month}" => 5.0
      }
    end

    let (:association) { Dossier.where.not(:state => :draft) }

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
        :initiated_at => 2.months.ago.beginning_of_month + 30.minutes,
        :processed_at => 2.months.ago.beginning_of_month + 1.day)
      dossier_p1_b = FactoryGirl.create(:dossier,
        :procedure    => procedure_1,
        :created_at   => 2.months.ago.beginning_of_month,
        :initiated_at => 2.months.ago.beginning_of_month + 10.minutes,
        :processed_at => 2.months.ago.beginning_of_month + 1.day)
      dossier_p1_c = FactoryGirl.create(:dossier,
        :procedure    => procedure_1,
        :created_at   => 1.months.ago.beginning_of_month,
        :initiated_at => 1.months.ago.beginning_of_month + 50.minutes,
        :processed_at => 1.months.ago.beginning_of_month + 1.day)
      dossier_p2_a = FactoryGirl.create(:dossier,
        :procedure    => procedure_2,
        :created_at   => 2.month.ago.beginning_of_month,
        :initiated_at => 2.month.ago.beginning_of_month + 80.minutes,
        :processed_at => 2.month.ago.beginning_of_month + 1.day)

      # Write directly in the DB to avoid the before_validation hook
      Dossier.update_all(state: "closed")

      @expected_hash = {
        "#{2.months.ago.beginning_of_month}" => 30.0,
        "#{1.months.ago.beginning_of_month}" => 50.0
      }
    end

    let (:association) { Dossier.where.not(:state => :draft) }

    subject { StatsController.new.send(:dossier_filling_mean_time, association) }

    it { expect(subject).to eq(@expected_hash) }
  end
end
