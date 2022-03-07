describe '20220112184331_revise_attestation_templates' do
  let(:rake_task) { Rake::Task['after_party:revise_attestation_templates'] }
  let(:procedure) { create(:procedure) }
  let(:attestation_template) { create(:attestation_template, procedure: procedure) }

  subject(:run_task) do
    attestation_template
    rake_task.invoke
    attestation_template.reload
  end

  after { rake_task.reenable }

  describe 'revise_attestation_templates' do
    it 'attaches the attestation_template to the latest revision (without removing the link between attestation_template and procedure for now)' do
      expect(attestation_template.procedure.revisions.first.attestation_template_id).to be_nil
      run_task
      expect(attestation_template.procedure_id).to eq(procedure.id)
      expect(attestation_template.procedure.revisions.first.attestation_template_id).to eq(attestation_template.id)
    end
  end
end
