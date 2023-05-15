describe Recovery::LifeCycle do
  describe '.load_export_destroy_and_import' do
    it 'works with one dossier' do
      dossier = create(:dossier, :with_individual)
      expect { Recovery::LifeCycle.new(dossier_ids: [dossier.id]).load_export_destroy_and_import }.not_to change {Dossier.count}
    end
  end
end
