# frozen_string_literal: true

describe '20241215115134_feature_flag_lexpol_champs' do
  let(:rake_task) { Rake::Task['after_party:feature_flag_lexpol_champs'] }
  let!(:procedure_with_admin_featured) { create(:procedure) }
  let!(:types_de_champ_private) { [{ type: :lexpol }] }
  let!(:procedure_with_lexpol_with_admin_featured) { create(:procedure, types_de_champ_private:, administrateurs: [procedure_with_admin_featured.administrateurs.first]) }
  let!(:procedure_without_admin_featured) { create(:procedure, :new_administrateur) }
  let!(:procedure_with_lexpol_without_admin_featured) { create(:procedure, types_de_champ_private:, administrateurs: [procedure_without_admin_featured.administrateurs.first]) }

  subject(:run_task) do
    rake_task.invoke
  end

  before { Flipper.enable(:lexpol, procedure_with_admin_featured.administrateurs.first.user) }

  after { rake_task.reenable }

  describe 'feature_flag_lexpol_champs' do
    it "with bad champs" do
      expect(Flipper.enabled?(:lexpol, procedure_with_admin_featured.administrateurs.first.user)).to eq(true)
      expect(Flipper.enabled?(:lexpol, procedure_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:lexpol, procedure_with_lexpol_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:lexpol, procedure_without_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:lexpol, procedure_with_lexpol_without_admin_featured)).to eq(false)

      run_task

      procedure_with_admin_featured.reload
      procedure_with_lexpol_with_admin_featured.reload
      procedure_without_admin_featured.reload
      procedure_with_lexpol_without_admin_featured.reload

      expect(Flipper.enabled?(:lexpol, procedure_with_admin_featured.administrateurs.first.user)).to eq(false)
      expect(Flipper.enabled?(:lexpol, procedure_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:lexpol, procedure_with_lexpol_with_admin_featured)).to eq(true)
      expect(Flipper.enabled?(:lexpol, procedure_without_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:lexpol, procedure_with_lexpol_without_admin_featured)).to eq(false)
    end
  end
end
