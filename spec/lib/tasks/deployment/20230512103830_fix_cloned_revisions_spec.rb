# frozen_string_literal: true

describe.skip '20230512103830_fix_cloned_published_revisions' do
  let(:rake_task) { Rake::Task['after_party:fix_cloned_published_revisions'] }

  subject(:run_task) { rake_task.invoke }
  after(:each) { rake_task.reenable }

  let(:procedure) { create(:procedure, types_de_champ_public: [{}]) }
  let(:cloned_procedure) { procedure.clone(procedure.administrateurs.first, false) }
  let(:dossier_parent_procedure) { create(:dossier, procedure:) }
  let(:dossier_cloned_procedure) { create(:dossier, procedure: cloned_procedure) }

  before do
    procedure.publish!
    dossier_parent_procedure
    procedure.reload
    cloned_procedure
    dossier_cloned_procedure
    procedure.reload
  end

  context 'just clone' do
    it do
      # procedures
      expect(procedure.published_revision.procedure_id).not_to eq(procedure.id)
      expect(cloned_procedure.draft_revision_id).to eq(procedure.published_revision_id)
      # dossiers
      expect(dossier_parent_procedure.revision_id).to eq(dossier_cloned_procedure.revision_id)
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to be_nil
      expect(dossier_cloned_procedure.groupe_instructeur_id).not_to be_nil
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to eq(dossier_cloned_procedure.groupe_instructeur_id)
      expect(procedure.dossiers).to match_array([])
      expect(procedure.published_revision.dossiers).to match_array([dossier_parent_procedure, dossier_cloned_procedure])
      expect(cloned_procedure.dossiers).to match_array([dossier_parent_procedure, dossier_cloned_procedure])

      # subject
      subject
      procedure.reload
      cloned_procedure.reload
      dossier_parent_procedure.reload
      dossier_cloned_procedure.reload

      expect(procedure.published_revision.procedure_id).to eq(procedure.id)
      expect(cloned_procedure.draft_revision_id).not_to eq(procedure.published_revision_id)
      expect(cloned_procedure.draft_revision.procedure_id).to eq(cloned_procedure.id)
      expect(procedure.draft_revision_id).not_to eq(cloned_procedure.draft_revision_id)
      expect(procedure.published_revision_id).not_to eq(cloned_procedure.published_revision_id)

      # dossiers
      expect(dossier_parent_procedure.revision_id).not_to eq(dossier_cloned_procedure.revision_id)
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to eq(dossier_cloned_procedure.groupe_instructeur_id)
      expect(procedure.dossiers).to match_array([dossier_parent_procedure])
      expect(procedure.published_revision.dossiers).to match_array([dossier_parent_procedure])
      expect(cloned_procedure.dossiers).to match_array([dossier_cloned_procedure])
    end
  end

  context 'clone and publish' do
    before do
      cloned_procedure.publish!
      cloned_procedure.reload
    end

    it do
      # procedures
      expect(procedure.published_revision.procedure_id).not_to eq(procedure.id)
      expect(cloned_procedure.published_revision_id).to eq(procedure.published_revision_id)
      # dossiers
      expect(dossier_parent_procedure.revision_id).to eq(dossier_cloned_procedure.revision_id)
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to be_nil
      expect(dossier_cloned_procedure.groupe_instructeur_id).not_to be_nil
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to eq(dossier_cloned_procedure.groupe_instructeur_id)
      expect(procedure.dossiers).to match_array([])
      expect(procedure.published_revision.dossiers).to match_array([dossier_parent_procedure, dossier_cloned_procedure])
      expect(cloned_procedure.dossiers).to match_array([dossier_parent_procedure, dossier_cloned_procedure])

      # subject
      subject
      procedure.reload
      cloned_procedure.reload
      dossier_parent_procedure.reload
      dossier_cloned_procedure.reload

      expect(procedure.published_revision.procedure_id).to eq(procedure.id)
      expect(cloned_procedure.draft_revision.procedure_id).to eq(cloned_procedure.id)
      expect(cloned_procedure.published_revision_id).not_to eq(procedure.published_revision_id)
      expect(cloned_procedure.published_revision.procedure_id).to eq(cloned_procedure.id)
      expect(procedure.draft_revision_id).not_to eq(cloned_procedure.draft_revision_id)
      expect(procedure.published_revision_id).not_to eq(cloned_procedure.published_revision_id)

      # dossiers
      expect(dossier_parent_procedure.revision_id).not_to eq(dossier_cloned_procedure.revision_id)
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to eq(dossier_cloned_procedure.groupe_instructeur_id)
      expect(procedure.dossiers).to match_array([dossier_parent_procedure])
      expect(procedure.published_revision.dossiers).to match_array([dossier_parent_procedure])
      expect(cloned_procedure.dossiers).to match_array([dossier_cloned_procedure])
    end
  end

  context 'clone, publish and publish again' do
    before do
      cloned_procedure.publish!
      cloned_procedure.reload
      cloned_procedure.draft_revision.add_type_de_champ(libelle: 'test', type_champ: 'text')
      cloned_procedure.reload
      cloned_procedure.publish_revision!
      cloned_procedure.reload
    end

    it do
      # procedures
      expect(procedure.published_revision.procedure_id).not_to eq(procedure.id)
      expect(procedure.published_revision_id.in?(cloned_procedure.revisions.ids)).to be_truthy
      # dossiers
      expect(dossier_parent_procedure.revision_id).to eq(dossier_cloned_procedure.revision_id)
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to be_nil
      expect(dossier_cloned_procedure.groupe_instructeur_id).not_to be_nil
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to eq(dossier_cloned_procedure.groupe_instructeur_id)
      expect(procedure.dossiers).to match_array([])
      expect(procedure.published_revision.dossiers).to match_array([dossier_parent_procedure, dossier_cloned_procedure])
      expect(cloned_procedure.dossiers).to match_array([dossier_parent_procedure, dossier_cloned_procedure])

      # subject
      subject
      procedure.reload
      cloned_procedure.reload
      dossier_parent_procedure.reload
      dossier_cloned_procedure.reload

      expect(procedure.published_revision.procedure_id).to eq(procedure.id)
      expect(procedure.published_revision_id.in?(cloned_procedure.revisions.ids)).to be_falsey
      expect(procedure.draft_revision_id).not_to eq(cloned_procedure.draft_revision_id)
      expect(procedure.published_revision_id).not_to eq(cloned_procedure.published_revision_id)

      # # dossiers
      expect(dossier_parent_procedure.revision_id).not_to eq(dossier_cloned_procedure.revision_id)
      expect(dossier_parent_procedure.groupe_instructeur_id).not_to eq(dossier_cloned_procedure.groupe_instructeur_id)
      expect(procedure.dossiers).to match_array([dossier_parent_procedure])
      expect(procedure.published_revision.dossiers).to match_array([dossier_parent_procedure])
      expect(cloned_procedure.dossiers).to match_array([dossier_cloned_procedure])
    end
  end
end
