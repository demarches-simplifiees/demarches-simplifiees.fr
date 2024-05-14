# frozen_string_literal: true

describe '20230407124517_back_fill_procedure_defaut_groupe_instructeur_id' do
  let(:rake_task) { Rake::Task['after_party:back_fill_procedure_defaut_groupe_instructeur_id'] }
  let(:procedure) { create(:procedure) }

  subject(:run_task) { rake_task.invoke }
  after(:each) { rake_task.reenable }

  it 'populates defaut_groupe_instructeur_id' do
    expect(procedure.defaut_groupe_instructeur_id).to be_nil

    run_task

    procedure.reload
    expect(procedure.defaut_groupe_instructeur_id).to eq(procedure.defaut_groupe_instructeur.id)
  end
end
