RSpec.describe DossierCloneConcern do
  let(:procedure) do
    create(:procedure, types_de_champ_public: [
      { type: :text, libelle: "Un champ text", stable_id: 99 },
      { type: :text, libelle: "Un autre champ text", stable_id: 999 },
      { type: :yes_no, libelle: "Un champ yes no", stable_id: 9999 }
    ])
  end
  let(:dossier) { create(:dossier, procedure:) }
  let(:forked_dossier) { dossier.find_or_create_editing_fork(dossier.user, :public) }

  before { procedure.publish! }

  describe '#make_diff' do
    subject { dossier.make_diff(forked_dossier) }

    context 'with no changes' do
      it { is_expected.to eq(added: [], updated: [], removed: []) }
    end

    context 'with updated champ' do
      let(:updated_champ) { forked_dossier.champs.find { _1.stable_id == 99 } }

      before { updated_champ.update(value: 'new value') }

      it { is_expected.to eq(added: [], updated: [updated_champ], removed: []) }
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

      it { is_expected.to eq(added: [added_champ], updated: [], removed: [removed_champ]) }
    end
  end

  describe '#merge_fork' do
    subject { dossier.merge_fork(forked_dossier) }

    context 'with updated champ' do
      let(:updated_champ) { forked_dossier.champs.find { _1.stable_id == 99 } }

      before do
        dossier.champs.each do |champ|
          champ.update(value: 'old value')
        end
        updated_champ.update(value: 'new value')
      end

      it { expect { subject }.to change { dossier.reload.champs.size }.by(0) }
      it { expect { subject }.not_to change { dossier.reload.champs.order(:created_at).filter { _1.stable_id != 99 }.map(&:value) } }
      it { expect { subject }.to change { dossier.reload.champs.find { _1.stable_id == 99 }.value }.from('old value').to('new value') }
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
      it { expect { subject }.to change { dossier.reload.champs.order(:created_at).map(&:to_s) }.from(['old value', 'old value', 'Non']).to(['old value', 'Non', '']) }
    end
  end
end
