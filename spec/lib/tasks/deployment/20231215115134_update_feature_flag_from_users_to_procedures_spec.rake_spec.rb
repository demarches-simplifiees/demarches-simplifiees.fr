describe '20220705164551_feature_flag_visa_champs' do
  let(:rake_task) { Rake::Task['after_party:feature_flag_visa_champs'] }
  let!(:procedure_with_admin_featured) { create(:procedure) }
  let!(:procedure_with_visa_with_admin_featured) { create(:procedure, :with_visa, administrateurs: [procedure_with_admin_featured.administrateurs.first]) }
  let!(:procedure_without_admin_featured) { create(:procedure) }
  let!(:procedure_with_visa_without_admin_featured) { create(:procedure, :with_visa, administrateurs: [procedure_without_admin_featured.administrateurs.first]) }

  subject(:run_task) do
    rake_task.invoke
  end

  before { Flipper.enable(:visa, procedure_with_admin_featured.administrateurs.first.user) }

  after { rake_task.reenable }

  describe 'feature_flag_visa_champs' do
    it "with bad champs" do
      expect(Flipper.enabled?(:visa, procedure_with_admin_featured.administrateurs.first.user)).to eq(true)
      expect(Flipper.enabled?(:visa, procedure_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:visa, procedure_with_visa_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:visa, procedure_without_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:visa, procedure_with_visa_without_admin_featured)).to eq(false)

      run_task

      procedure_with_admin_featured.reload
      procedure_with_visa_with_admin_featured.reload
      procedure_without_admin_featured.reload
      procedure_with_visa_without_admin_featured.reload

      expect(Flipper.enabled?(:visa, procedure_with_admin_featured.administrateurs.first.user)).to eq(false)
      expect(Flipper.enabled?(:visa, procedure_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:visa, procedure_with_visa_with_admin_featured)).to eq(true)
      expect(Flipper.enabled?(:visa, procedure_without_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:visa, procedure_with_visa_without_admin_featured)).to eq(false)
    end
  end
end
