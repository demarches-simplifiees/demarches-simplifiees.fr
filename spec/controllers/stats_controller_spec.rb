describe StatsController, type: :controller do
  describe "#last_four_months_hash" do
    context "while a regular user is logged in" do
      before do
        create(:procedure, created_at: 6.months.ago, updated_at: 6.months.ago)
        create(:procedure, created_at: 2.months.ago, updated_at: 62.days.ago)
        create(:procedure, created_at: 2.months.ago, updated_at: 62.days.ago)
        create(:procedure, created_at: 2.months.ago, updated_at: 31.days.ago)
        create(:procedure, created_at: 2.months.ago, updated_at: Time.zone.now)
        @controller = StatsController.new

        allow(@controller).to receive(:super_admin_signed_in?).and_return(false)
      end

      let(:association) { Procedure.all }

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
        create(:procedure, updated_at: 6.months.ago)
        create(:procedure, updated_at: 45.days.ago)
        create(:procedure, updated_at: 1.day.ago)
        create(:procedure, updated_at: 1.day.ago)

        @controller = StatsController.new

        allow(@controller).to receive(:super_admin_signed_in?).and_return(true)
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
      create(:procedure, created_at: 55.days.ago, updated_at: 43.days.ago)
      create(:procedure, created_at: 45.days.ago, updated_at: 40.days.ago)
      create(:procedure, created_at: 45.days.ago, updated_at: 20.days.ago)
      create(:procedure, created_at: 15.days.ago, updated_at: 20.days.ago)
      create(:procedure, created_at: 15.days.ago, updated_at: 1.hour.ago)
    end

    after { Timecop.return }

    let (:association) { Procedure.all }

    context "while a super admin is logged in" do
      before { allow(@controller).to receive(:super_admin_signed_in?).and_return(true) }

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
      before { allow(@controller).to receive(:super_admin_signed_in?).and_return(false) }

      subject { @controller.send(:cumulative_hash, association, :updated_at) }

      it do
        expect(subject).to eq({
          Time.utc(2016, 8, 1) => 2,
          Time.utc(2016, 9, 1) => 4
        })
      end
    end
  end
end
