describe '20220211090402_reassign_redundant_attestation_templates' do
  let(:rake_task) { Rake::Task['after_party:reassign_redundant_attestation_templates'] }
  let(:procedure) { create(:procedure, :published) }
  let(:procedure_with_revisions) { create(:procedure, :published) }

  before do
    procedure.published_revision.update(attestation_template: create(:attestation_template))
    procedure.draft_revision.update(attestation_template: procedure.published_attestation_template.dup)

    Flipper.enable(:procedure_revisions, procedure_with_revisions)
    procedure_with_revisions.published_revision.update(attestation_template: create(:attestation_template))
    procedure_with_revisions.draft_revision.update(attestation_template: procedure_with_revisions.published_attestation_template.dup)
  end

  subject(:run_task) do
    rake_task.invoke
    procedure.reload
    procedure_with_revisions.reload
  end

  after { rake_task.reenable }

  describe 'reassign_redundant_attestation_templates' do
    it 'reassign draft attestation template as published attestation template on procedures without revisions' do
      expect(procedure.published_attestation_template).not_to be_nil
      expect(procedure.draft_attestation_template).not_to be_nil
      expect(procedure.draft_attestation_template).not_to eq(procedure.published_attestation_template)

      expect(procedure_with_revisions.published_attestation_template).not_to be_nil
      expect(procedure_with_revisions.draft_attestation_template).not_to be_nil
      expect(procedure_with_revisions.draft_attestation_template).not_to eq(procedure_with_revisions.published_attestation_template)

      orphans = AttestationTemplate.where(procedure_id: nil).left_outer_joins(:revisions).filter { |a| a.revisions.empty? }
      expect(orphans).to eq([])
      to_be_orphan = procedure.published_attestation_template

      run_task

      expect(procedure.published_attestation_template).not_to be_nil
      expect(procedure.draft_attestation_template).not_to be_nil
      expect(procedure.draft_attestation_template).to eq(procedure.published_attestation_template)

      expect(procedure_with_revisions.published_attestation_template).not_to be_nil
      expect(procedure_with_revisions.draft_attestation_template).not_to be_nil
      expect(procedure_with_revisions.draft_attestation_template).not_to eq(procedure_with_revisions.published_attestation_template)

      orphans = AttestationTemplate.where(procedure_id: nil).left_outer_joins(:revisions).filter { |a| a.revisions.empty? }
      expect(orphans).to eq([to_be_orphan])
    end
  end
end
