describe '20200812203517_ccism_instructeur_setup2.rake' do
  let(:rake_task) { Rake::Task['after_party:ccism_instructeur_setup2'] }
  let!(:procedure_to_unassign) { create(:procedure, id: 406) }
  let!(:procedure_to_assign) { create(:procedure, id: 477) }
  let!(:instructeur) { create(:instructeur, email: 'heitiare#ccism.pf'.tr('#', '@')) }
  let!(:instructeur_unchanged) { create(:instructeur, email: 'toto@ccism.pf') }
  let!(:dossier) { create(:dossier, procedure: procedure_to_unassign) }

  before do
    instructeur.assign_to_procedure(procedure_to_unassign)
    instructeur_unchanged.assign_to_procedure(procedure_to_unassign)
    instructeur.follow(dossier)

    rake_task.invoke

    procedure_to_unassign.reload
    procedure_to_assign.reload
    instructeur.reload
  end

  after { rake_task.reenable }

  context 'After party task executed' do
    it 'sets the assignment' do
      expect(instructeur.procedures).to include(procedure_to_assign)
      expect(instructeur.procedures).not_to include(procedure_to_unassign)
      expect(instructeur_unchanged.procedures).to include(procedure_to_unassign)
    end
  end
end
