RSpec.describe DossierCloneConcern do
  let(:procedure) do
    create(:procedure, types_de_champ_public: [
      { type: :text, libelle: "Un champ text", stable_id: 99 },
      { type: :text, libelle: "Un autre champ text", stable_id: 991 },
      { type: :yes_no, libelle: "Un champ yes no", stable_id: 992 },
      { type: :repetition, libelle: "Un champ répétable", stable_id: 993, mandatory: true, children: [{ type: :text, libelle: 'Nom', stable_id: 994 }] }
    ])
  end
  let(:dossier) { create(:dossier, procedure:) }
  let(:forked_dossier) { dossier.find_or_create_editing_fork(dossier.user) }

  before { procedure.publish! }

  describe '#make_diff' do
    subject { dossier.make_diff(forked_dossier) }

    context 'with no changes' do
      it { is_expected.to eq(added: [], updated: [], removed: []) }
    end

    context 'with updated groupe instructeur' do
      before {
        dossier.update(groupe_instructeur: nil)
        forked_dossier.assign_to_groupe_instructeur(dossier.procedure.defaut_groupe_instructeur)
      }

      it { is_expected.to eq(added: [], updated: [], removed: []) }
      it { expect(forked_dossier.forked_with_changes?).to be_truthy }
    end

    context 'with updated champ' do
      let(:updated_champ) { forked_dossier.champs.find { _1.stable_id == 99 } }

      before { updated_champ.update(value: 'new value') }

      it { is_expected.to eq(added: [], updated: [updated_champ], removed: []) }
      it 'forked_with_changes? should reflect dossier state' do
        expect(dossier.forked_with_changes?).to be_falsey
        expect(forked_dossier.forked_with_changes?).to be_truthy
        expect(updated_champ.forked_with_changes?).to be_truthy
      end
    end

    context 'with new revision' do
      let(:added_champ) { forked_dossier.champs.find { _1.libelle == "Un nouveau champ text" } }
      let(:removed_champ) { dossier.champs.find { _1.stable_id == 99 } }

      before do
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un nouveau champ text"
        })
        procedure.draft_revision.remove_type_de_champ(removed_champ.stable_id)
        procedure.publish_revision!
      end

      it {
        expect(dossier.revision_id).to eq(procedure.revisions.first.id)
        expect(forked_dossier.revision_id).to eq(procedure.published_revision_id)
        is_expected.to eq(added: [added_champ], updated: [], removed: [removed_champ])
      }
    end
  end

  describe '#merge_fork' do
    subject { dossier.merge_fork(forked_dossier) }

    context 'with updated champ' do
      let(:updated_champ) { forked_dossier.champs.find { _1.stable_id == 99 } }
      let(:updated_repetition_champ) { forked_dossier.champs.find { _1.stable_id == 994 } }

      before do
        dossier.champs.each do |champ|
          champ.update(value: 'old value')
        end
        updated_champ.update(value: 'new value')
        updated_repetition_champ.update(value: 'new value in repetition')
      end

      it { expect { subject }.to change { dossier.reload.champs.size }.by(0) }
      it { expect { subject }.not_to change { dossier.reload.champs.order(:created_at).reject { _1.stable_id.in?([99, 994]) }.map(&:value) } }
      it { expect { subject }.to change { dossier.reload.champs.find { _1.stable_id == 99 }.value }.from('old value').to('new value') }
      it { expect { subject }.to change { dossier.reload.champs.find { _1.stable_id == 994 }.value }.from('old value').to('new value in repetition') }

      it 'update dossier search terms' do
        expect { subject }.to have_enqueued_job(DossierUpdateSearchTermsJob).with(dossier)
      end
    end

    context 'with new revision' do
      let(:added_champ) { forked_dossier.champs.find { _1.libelle == "Un nouveau champ text" } }
      let(:removed_champ) { dossier.champs.find { _1.stable_id == 99 } }

      before do
        dossier.champs.each do |champ|
          champ.update(value: 'old value')
        end
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un nouveau champ text"
        })
        procedure.draft_revision.remove_type_de_champ(removed_champ.stable_id)
        procedure.publish_revision!
      end

      it { expect { subject }.to change { dossier.reload.champs.size }.by(0) }
      it { expect { subject }.to change { dossier.reload.champs.order(:created_at).map(&:to_s) }.from(['old value', 'old value', 'Non', 'old value', 'old value']).to(['old value', 'Non', 'old value', 'old value', '']) }

      it "dossier after merge should be on last published revision" do
        expect(dossier.revision_id).to eq(procedure.revisions.first.id)
        expect(forked_dossier.revision_id).to eq(procedure.published_revision_id)

        subject
        perform_enqueued_jobs only: DestroyRecordLaterJob

        expect(dossier.revision_id).to eq(procedure.published_revision_id)
        expect(Dossier.exists?(forked_dossier.id)).to be_falsey
      end
    end
  end
end
