describe Recovery::AlignChampWithDossierRevision do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ stable_id: bad_stable_id }, {}]) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:bad_dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:bad_stable_id) { 999 }
  let(:bad_champ) { bad_dossier.champs.find { bad_stable_id == _1.stable_id } }

  context 'when type_de_champ exists in dossier revision' do
    before do
      procedure.publish!
      procedure.draft_revision
        .find_and_ensure_exclusive_use(bad_stable_id)
        .update(libelle: "New libelle")
      previous_revision = procedure.published_revision
      previous_type_de_champ = previous_revision.types_de_champ.find { bad_stable_id == _1.stable_id }

      procedure.publish_revision!
      procedure.reload

      bad_dossier
      bad_champ.update(type_de_champ: previous_type_de_champ)
    end

    it 'bad dossier shoud be bad' do
      expect(procedure.revisions.size).to eq(3)
      expect(bad_dossier.revision).to eq(procedure.published_revision)
      expect(bad_dossier.champs.size).to eq(2)
      expect(bad_dossier.champs_public.size).to eq(2)
      expect { DossierPreloader.load_one(bad_dossier) }.not_to raise_error

      fixer = Recovery::AlignChampWithDossierRevision.new(Dossier)
      fixer.run

      expect(fixer.logs.size).to eq(1)
      expect(fixer.logs.first.fetch(:status)).to eq(:updated)
      expect { DossierPreloader.load_one(bad_dossier) }.not_to raise_error
      expect(bad_dossier.champs.size).to eq(2)
      expect(bad_dossier.champs_public.size).to eq(2)
    end
  end

  context 'when type_de_champ does not exist in dossier revision' do
    before do
      procedure.publish!
      bad_dossier
      procedure.draft_revision.remove_type_de_champ(bad_stable_id)
      procedure.publish_revision!
      bad_dossier.update(revision: procedure.published_revision)
    end

    it 'bad dossier shoud be bad' do
      expect(procedure.revisions.size).to eq(3)
      expect(bad_dossier.revision).to eq(procedure.published_revision)
      expect(bad_dossier.champs.size).to eq(2)
      expect(bad_dossier.champs_public.size).to eq(2)
      expect { DossierPreloader.load_one(bad_dossier) }.not_to raise_error

      fixer = Recovery::AlignChampWithDossierRevision.new(Dossier)
      fixer.run(destroy_extra_champs: true)

      expect(fixer.logs.size).to eq(1)
      expect(fixer.logs.first.fetch(:status)).to eq(:not_found)
      expect { DossierPreloader.load_one(bad_dossier) }.not_to raise_error
      expect(bad_dossier.champs.size).to eq(1)
      expect(bad_dossier.champs_public.size).to eq(1)
    end
  end
end
