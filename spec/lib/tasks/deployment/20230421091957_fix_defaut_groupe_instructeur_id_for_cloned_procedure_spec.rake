# frozen_string_literal: true

describe '20230421091957_fix_defaut_groupe_instructeur_id_for_cloned_procedure' do
  let(:rake_task) { Rake::Task['after_party:fix_defaut_groupe_instructeur_id_for_cloned_procedure'] }

  let!(:parent_procedure) { create(:procedure, hidden_at: Time.zone.now) }
  let(:procedure) { create(:procedure, parent_procedure:, hidden_at: Time.zone.now) }
  let(:procedure_with_new_groupe) do
    create(:procedure, parent_procedure:, hidden_at: Time.zone.now).tap do |p|
      p.groupe_instructeurs.first.update!(label: 'a new label')
    end
  end
  let(:dossier) { create(:dossier, procedure:) }

  subject(:run_task) { rake_task.invoke }
  after(:each) { rake_task.reenable }

  it 'populates defaut_groupe_instructeur_id' do
    [procedure, procedure_with_new_groupe].each do |p|
      defaut_groupe_instructeur_id = parent_procedure.defaut_groupe_instructeur_id
      p.update_columns(defaut_groupe_instructeur_id:)
    end
    dossier

    expect(procedure_has_defaut_groupe?(procedure)).to be false
    expect(dossier.groupe_instructeur_id.in?(procedure.groupe_instructeurs.ids)).to be false

    run_task

    [procedure, procedure_with_new_groupe, dossier].each(&:reload)

    expect(procedure_has_defaut_groupe?(procedure)).to be true
    expect(procedure_has_defaut_groupe?(procedure_with_new_groupe)).to be true
    expect(dossier.groupe_instructeur_id.in?(procedure.groupe_instructeurs.ids)).to be true
  end

  def procedure_has_defaut_groupe?(p)
    p.defaut_groupe_instructeur_id.in?(p.groupe_instructeurs.ids)
  end
end
