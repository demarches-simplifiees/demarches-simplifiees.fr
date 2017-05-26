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

  describe '#thirty_days_flow_hash' do
    context "without a date_attribut" do
      before do
        FactoryGirl.create(:procedure, :created_at => 45.days.ago)
        FactoryGirl.create(:procedure, :created_at => 15.days.ago)
        FactoryGirl.create(:procedure, :created_at => 1.day.ago)

        @expected_hash = {}
        (30.days.ago.to_date..Time.now.to_date).each do |day|
          if [15.days.ago.to_date, 1.day.ago.to_date].include?(day)
            @expected_hash[day] = 1
          else
            @expected_hash[day] = 0
          end
        end
      end

      let (:association) { Procedure.all }

      subject { StatsController.new.send(:thirty_days_flow_hash, association) }

      it { expect(subject).to eq(@expected_hash) }
    end

    context "with a date_attribut" do
      before do
        FactoryGirl.create(:procedure, :created_at => 45.days.ago, :updated_at => 50.days.ago)
        FactoryGirl.create(:procedure, :created_at => 15.days.ago, :updated_at => 10.days.ago)
        FactoryGirl.create(:procedure, :created_at => 1.day.ago, :updated_at => 3.days.ago)

        @expected_hash = {}
        (30.days.ago.to_date..Time.now.to_date).each do |day|
          if [10.days.ago.to_date, 3.day.ago.to_date].include?(day)
            @expected_hash[day] = 1
          else
            @expected_hash[day] = 0
          end
        end
      end

      let (:association) { Procedure.all }

      subject { StatsController.new.send(:thirty_days_flow_hash, association, :updated_at) }

      it { expect(subject).to eq(@expected_hash) }
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
end
