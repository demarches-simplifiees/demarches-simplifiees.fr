describe '20190117154829_delete_dossiers_without_procedure.rake' do
  let(:rake_task) { Rake::Task['after_party:delete_dossiers_without_procedure'] }

  subject do
    rake_task.invoke
  end

  after do
    rake_task.reenable
  end

  context 'when the procedure of some dossiers has been deleted' do
    let!(:procedure1) { create(:procedure_with_dossiers, dossiers_count: 2) }
    let!(:procedure2) { create(:procedure_with_dossiers, :published, dossiers_count: 2) }
    let!(:procedure3) { create(:procedure_with_dossiers, :published, dossiers_count: 2) }
    let!(:procedure4) { create(:procedure_with_dossiers, :archived, dossiers_count: 2) }

    let(:procedure_2_dossier_ids) { procedure2.dossiers.pluck(:id) }

    before do
      procedure_2_dossier_ids
      procedure2.delete
      expect(procedure_2_dossier_ids.count).to eq(2)
      expect(Dossier.find_by(id: procedure_2_dossier_ids.first).procedure).to be nil
      expect(Dossier.find_by(id: procedure_2_dossier_ids.second).procedure).to be nil
    end

    it 'destroy dossiers without an existing procedure' do
      subject
      expect(Dossier.unscoped.find_by(id: procedure_2_dossier_ids.first)).to be nil
      expect(Dossier.unscoped.find_by(id: procedure_2_dossier_ids.last)).to be nil
    end

    it 'doesn’t destroy other dossiers' do
      subject
      expect(Dossier.all.count).to eq(6)
      expect(procedure1.reload.dossiers.count).to eq(2)
      expect(procedure3.reload.dossiers.count).to eq(2)
      expect(procedure4.reload.dossiers.count).to eq(2)
    end
  end
end
