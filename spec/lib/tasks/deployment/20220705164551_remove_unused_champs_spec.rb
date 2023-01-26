describe '20220705164551_remove_unused_champs' do
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  let(:rake_task) { Rake::Task['after_party:remove_unused_champs'] }
  let(:procedure) { create(:procedure, :with_all_champs) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }
  let(:champ_repetition) { dossier.champs_public.find(&:repetition?) }

  subject(:run_task) do
    dossier
    rake_task.invoke
  end

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear

    champ_repetition.champs.first.update(type_de_champ: create(:type_de_champ))
  end
  after { rake_task.reenable }

  describe 'remove_unused_champs', vcr: { cassette_name: 'api_geo_all' } do
    it "with bad champs" do
      expect(Champ.where(dossier: dossier).count).to eq(39)
      run_task
      expect(Champ.where(dossier: dossier).count).to eq(38)
    end
  end
end
