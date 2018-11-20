require 'spec_helper'

describe '2018_10_30_migrate_carto_to_carte' do
  let(:rake_task) { Rake::Task['after_party:migrate_carto_to_carte'] }
  let(:procedure) { create(:procedure, :published, :with_api_carto) }
  let(:dossier) { create(:dossier, :with_two_quartier_prioritaires, :with_two_cadastres) }

  def run_task
    procedure.module_api_carto.quartiers_prioritaires = true
    procedure.module_api_carto.cadastre = true
    procedure.module_api_carto.save
    procedure.dossiers << dossier

    rake_task.invoke
    procedure.reload
    dossier.reload
  end

  after { rake_task.reenable }

  context 'on happy path' do
    before do
      run_task
    end

    it {
      expect(procedure.module_api_carto.migrated?).to be_truthy
      expect(dossier.cadastres.count).to eq(2)
      expect(dossier.quartier_prioritaires.count).to eq(2)
      expect(dossier.champs.first.type_champ).to eq('carte')
      expect(dossier.champs.first.order_place).to eq(0)
      expect(dossier.champs.first.libelle).to eq('Cartographie')
      expect(dossier.champs.first.geo_areas.count).to eq(4)
      expect(dossier.champs.first.mandatory?).to be_truthy
      expect(dossier.champs.first.cadastres?).to be_truthy
      expect(dossier.champs.first.quartiers_prioritaires?).to be_truthy
    }
  end
end
