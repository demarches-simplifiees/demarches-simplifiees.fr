describe 'deployment:20241021111111:feature_flag_referentiel_de_polynesie' do
  let(:rake_task) { Rake::Task['after_party:feature_flag_referentiel_de_polynesie'] }
  let!(:procedure_with_admin_featured) { create(:procedure) }
  let!(:types_de_champ_private) { [{ type: :referentiel_de_polynesie }] }
  let!(:procedure_with_referentiel_de_polynesie_with_admin_featured) { create(:procedure, types_de_champ_private:, administrateurs: [procedure_with_admin_featured.administrateurs.first]) }
  let!(:procedure_without_admin_featured) { create(:procedure) }
  let!(:procedure_with_referentiel_de_polynesie_without_admin_featured) { create(:procedure, types_de_champ_private:, administrateurs: [procedure_without_admin_featured.administrateurs.first]) }

  subject(:run_task) do
    rake_task.invoke
  end

  before { Flipper.enable(:referentiel_de_polynesie, procedure_with_admin_featured.administrateurs.first.user) }

  after { rake_task.reenable }

  describe 'feature_flag_referentiel_de_polynesie' do
    it "with bad champs" do
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_admin_featured.administrateurs.first.user)).to eq(true)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_referentiel_de_polynesie_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_without_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_referentiel_de_polynesie_without_admin_featured)).to eq(false)

      run_task

      procedure_with_admin_featured.reload
      procedure_with_referentiel_de_polynesie_with_admin_featured.reload
      procedure_without_admin_featured.reload
      procedure_with_referentiel_de_polynesie_without_admin_featured.reload

      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_admin_featured.administrateurs.first.user)).to eq(false)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_referentiel_de_polynesie_with_admin_featured)).to eq(true)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_without_admin_featured)).to eq(false)
      expect(Flipper.enabled?(:referentiel_de_polynesie, procedure_with_referentiel_de_polynesie_without_admin_featured)).to eq(false)
    end
  end
end
