describe '20230421091957_fix_defaut_groupe_instructeur_id_for_cloned_procedure' do
  let(:rake_task) { Rake::Task['after_party:fix_defaut_groupe_instructeur_id_for_cloned_procedure'] }

  let!(:parent_procedure) { create(:procedure, hidden_at: Time.zone.now) }
  let(:procedure) { create(:procedure, parent_procedure:, hidden_at: Time.zone.now) }
  let(:dossier) { create(:dossier, procedure:) }

  subject(:run_task) { rake_task.invoke }
  after(:each) { rake_task.reenable }

  it 'populates defaut_groupe_instructeur_id' do
    procedure.update_columns(defaut_groupe_instructeur_id: parent_procedure.defaut_groupe_instructeur_id)
    dossier

    expect(procedure.defaut_groupe_instructeur_id.in?(procedure.groupe_instructeurs.ids)).to be false
    expect(dossier.groupe_instructeur_id.in?(procedure.groupe_instructeurs.ids)).to be false

    run_task

    procedure.reload
    dossier.reload

    expect(procedure.defaut_groupe_instructeur_id.in?(procedure.groupe_instructeurs.ids)).to be true
    expect(dossier.groupe_instructeur_id.in?(procedure.groupe_instructeurs.ids)).to be true
  end
end
