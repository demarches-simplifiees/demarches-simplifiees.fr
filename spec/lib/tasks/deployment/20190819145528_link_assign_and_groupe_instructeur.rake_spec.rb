describe '20190819145528_link_assign_and_groupe_instructeur.rake' do
  let(:rake_task) { Rake::Task['after_party:link_assign_and_groupe_instructeur'] }

  subject { rake_task.invoke }
  after { rake_task.reenable }

  context 'with an assign_to without groupe_instructeur' do
    let!(:procedure) { create(:procedure) }
    let!(:instructeur) { create(:instructeur) }
    let!(:assign_to) do
      at = AssignTo.create!(instructeur: instructeur)
      at.update_column(:procedure_id, procedure.id)
      at
    end

    it 'assigns its defaut groupe instructeur' do
      expect(assign_to.groupe_instructeur).to be_nil
      subject
      expect(assign_to.reload.groupe_instructeur).to eq(procedure.defaut_groupe_instructeur)
    end
  end

  context 'with an assign_to with groupe_instructeur' do
    let!(:procedure) { create(:procedure) }
    let!(:instructeur) { create(:instructeur, groupe_instructeurs: [procedure.defaut_groupe_instructeur]) }
    let!(:assign_to) { instructeur.assign_to.first }

    it 'assigns its defaut groupe instructeur' do
      expect(assign_to.groupe_instructeur).to eq(procedure.defaut_groupe_instructeur)
      expect(procedure.reload.defaut_groupe_instructeur.assign_tos.count).to eq(1)
      subject
      expect(instructeur.assign_to).to eq([assign_to])
      expect(procedure.reload.defaut_groupe_instructeur.assign_tos.count).to eq(1)
    end
  end
end
