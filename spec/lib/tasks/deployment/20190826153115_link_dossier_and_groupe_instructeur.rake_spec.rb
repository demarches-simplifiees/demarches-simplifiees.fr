describe '20190826153115_link_dossier_and_groupe_instructeur.rake' do
  let(:rake_task) { Rake::Task['after_party:link_dossier_and_groupe_instructeur'] }

  subject { rake_task.invoke }
  after { rake_task.reenable }

  context 'with 3 dossiers' do
    let!(:procedure) { create(:procedure) }
    let!(:procedure2) { create(:procedure) }
    let!(:other_procedure_needed_to_create_dossier) { create(:procedure) }
    let!(:other_gi) { other_procedure_needed_to_create_dossier.defaut_groupe_instructeur }
    let!(:dossier) { Dossier.create(user: create(:user), procedure_id: procedure.id, groupe_instructeur: other_gi) }
    let!(:dossier2) { Dossier.create(user: create(:user), procedure_id: procedure2.id, groupe_instructeur: other_gi) }
    let!(:dossier3) { Dossier.create(user: create(:user), procedure_id: procedure2.id, groupe_instructeur: other_gi) }

    before do
      [dossier, dossier2, dossier3].each do |d|
        d.update_column('groupe_instructeur_id', nil)
      end

      other_procedure_needed_to_create_dossier.groupe_instructeurs.destroy_all
      other_procedure_needed_to_create_dossier.destroy
    end

    it do
      expect(dossier.reload.groupe_instructeur_id).to be_nil
      subject
      expect(Dossier.count).to eq(3)
      expect(Procedure.count).to eq(2)
      expect(GroupeInstructeur.count).to eq(2)
      expect(dossier.reload.groupe_instructeur_id).to eq(procedure.defaut_groupe_instructeur.id)
      expect(dossier2.reload.groupe_instructeur_id).to eq(procedure2.defaut_groupe_instructeur.id)
      expect(dossier3.reload.groupe_instructeur_id).to eq(procedure2.defaut_groupe_instructeur.id)
    end
  end
end
