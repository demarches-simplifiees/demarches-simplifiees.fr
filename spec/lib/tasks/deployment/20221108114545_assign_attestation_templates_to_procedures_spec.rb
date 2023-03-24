describe '20221108114545_assign_attestation_templates_to_procedures' do
  let(:rake_task) { Rake::Task['after_party:assign_attestation_templates_to_procedures'] }
  let(:procedure) { create(:procedure, :published) }
  let(:attestation_template) { create(:attestation_template) }
  let(:attestation_template_old) { create(:attestation_template, procedure: procedure) }
  let(:procedure2) { create(:procedure, :published) }
  let(:attestation_template2) { create(:attestation_template) }

  subject(:run_task) do
    rake_task.invoke
  end

  before do
    procedure.draft_revision.add_type_de_champ(type_champ: :integer_number, libelle: 'l1')
    procedure.publish_revision!
    procedure.draft_revision.update!(attestation_template: attestation_template)
    procedure.published_revision.update!(attestation_template: attestation_template)
    procedure.revisions.first.update!(attestation_template: attestation_template_old)

    procedure2.draft_revision.update!(attestation_template: attestation_template2)
    procedure2.published_revision.update!(attestation_template: attestation_template2)
  end
  after { rake_task.reenable }

  it "assigns attestation template to procedure" do
    expect(procedure.attestation_template).to eq(attestation_template_old)
    expect(procedure2.attestation_template).to be_nil
    run_task
    expect(procedure.reload.attestation_template).to eq(attestation_template)
    expect(attestation_template_old.reload.procedure_id).to be_nil
    expect(procedure2.reload.attestation_template).to eq(attestation_template2)
  end
end
