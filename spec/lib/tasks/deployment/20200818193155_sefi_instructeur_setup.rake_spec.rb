describe '20200818193155_sefi_instructeur_setup.rake' do
  let(:rake_task) { Rake::Task['after_party:sefi_instructeur_setup'] }
  let!(:procedure_to_unassign) { create(:procedure, id: 216) }
  let!(:unchanged_instructeur) { create(:instructeur, email: 'steven.wong#sefi.pf'.tr('#', '@')) }
  let!(:old_instructeur) { create(:instructeur, email: 'beatrice.maitere#sefi.pf'.tr('#', '@')) }
  let!(:dossier) { create(:dossier, procedure: procedure_to_unassign) }

  before do
    old_instructeur.assign_to_procedure(procedure_to_unassign)
    old_instructeur.follow(dossier)
    unchanged_instructeur.assign_to_procedure(procedure_to_unassign)

    rake_task.invoke

    procedure_to_unassign.reload
    old_instructeur.reload
    unchanged_instructeur.reload
  end

  after { rake_task.reenable }

  context 'After party task executed' do
    it 'sets the assignment' do
      expect(old_instructeur.procedures).not_to include(procedure_to_unassign)
      expect(unchanged_instructeur.procedures).to include(procedure_to_unassign)
      expect(dossier.followers_instructeurs).not_to include(old_instructeur)
    end
  end
end
