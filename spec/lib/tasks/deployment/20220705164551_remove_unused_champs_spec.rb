describe '20220705164551_remove_unused_champs' do
  let(:rake_task) { Rake::Task['after_party:remove_unused_champs'] }
  let(:procedure) { create(:procedure, :with_all_champs) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }
  let(:champ_repetition) { dossier.champs_public.find(&:repetition?) }

  subject(:run_task) do
    dossier
    rake_task.invoke
  end

  before { champ_repetition.champs.first.update(type_de_champ: create(:type_de_champ)) }
  after { rake_task.reenable }

  describe 'remove_unused_champs' do
    it "with bad champs" do
      expect(Champ.where(dossier: dossier).count).to eq(44)
      run_task
      expect(Champ.where(dossier: dossier).count).to eq(43)
    end
  end
end
