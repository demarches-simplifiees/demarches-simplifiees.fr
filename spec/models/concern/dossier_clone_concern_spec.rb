RSpec.describe DossierCloneConcern do
  let(:procedure) do
    create(:procedure, types_de_champ_public: [
      { type: :text, libelle: "Un champ text", stable_id: 99 },
      { type: :text, libelle: "Un autre champ text", stable_id: 991 },
      { type: :yes_no, libelle: "Un champ yes no", stable_id: 992 },
      { type: :repetition, libelle: "Un champ répétable", stable_id: 993, mandatory: true, children: [{ type: :text, libelle: 'Nom', stable_id: 994 }] }
    ])
  end
  let(:dossier) { create(:dossier, :en_construction, procedure:) }
  let(:forked_dossier) { dossier.find_or_create_editing_fork(dossier.user) }

  before { procedure.publish! }

  describe '#clone' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:fork) { false }
    let(:new_dossier) { dossier.clone(fork:) }

    context 'reset most attributes' do
      it { expect(new_dossier.id).not_to eq(dossier.id) }
      it { expect(new_dossier.api_entreprise_job_exceptions).to be_nil }
      it { expect(new_dossier.archived).to be_falsey }
      it { expect(new_dossier.brouillon_close_to_expiration_notice_sent_at).to be_nil }
      it { expect(new_dossier.conservation_extension).to eq(0.seconds) }
      it { expect(new_dossier.declarative_triggered_at).to be_nil }
      it { expect(new_dossier.deleted_user_email_never_send).to be_nil }
      it { expect(new_dossier.depose_at).to be_nil }
      it { expect(new_dossier.en_construction_at).to be_nil }
      it { expect(new_dossier.en_construction_close_to_expiration_notice_sent_at).to be_nil }
      it { expect(new_dossier.en_instruction_at).to be_nil }
      it { expect(new_dossier.for_procedure_preview).to be_falsey }
      it { expect(new_dossier.groupe_instructeur_updated_at).to be_nil }
      it { expect(new_dossier.hidden_at).to be_nil }
      it { expect(new_dossier.hidden_by_administration_at).to be_nil }
      it { expect(new_dossier.hidden_by_reason).to be_nil }
      it { expect(new_dossier.hidden_by_user_at).to be_nil }
      it { expect(new_dossier.identity_updated_at).to be_nil }
      it { expect(new_dossier.last_avis_updated_at).to be_nil }
      it { expect(new_dossier.last_champ_private_updated_at).to be_nil }
      it { expect(new_dossier.last_champ_updated_at).to be_nil }
      it { expect(new_dossier.last_commentaire_updated_at).to be_nil }
      it { expect(new_dossier.motivation).to be_nil }
      it { expect(new_dossier.private_search_terms).to eq("") }
      it { expect(new_dossier.processed_at).to be_nil }
      it { expect(new_dossier.search_terms).to match(dossier.user.email) }
      it { expect(new_dossier.termine_close_to_expiration_notice_sent_at).to be_nil }
      it { expect(new_dossier.dossier_transfer_id).to be_nil }
    end

    context 'copies some attributes' do
      context 'when fork' do
        let(:fork) { true }
        it { expect(new_dossier.groupe_instructeur).to eq(dossier.groupe_instructeur) }
      end

      context 'when not forked' do
        it { expect(new_dossier.groupe_instructeur).to be_nil }
      end
      it { expect(new_dossier.autorisation_donnees).to eq(dossier.autorisation_donnees) }
      it { expect(new_dossier.revision_id).to eq(dossier.revision_id) }
      it { expect(new_dossier.user_id).to eq(dossier.user_id) }
    end

    context 'forces some attributes' do
      let(:dossier) { create(:dossier, :accepte) }

      it { expect(new_dossier.brouillon?).to eq(true) }
      it { expect(new_dossier.parent_dossier).to eq(dossier) }

      context 'destroy parent' do
        before { new_dossier }

        it 'clean fk' do
          expect { dossier.destroy }.to change { new_dossier.reload.parent_dossier_id }.from(dossier.id).to(nil)
        end
      end
    end

    context 'procedure with_individual' do
      let(:procedure) { create(:procedure, :for_individual) }
      it { expect(new_dossier.individual.slice(:nom, :prenom, :gender)).to eq(dossier.individual.slice(:nom, :prenom, :gender)) }
      it { expect(new_dossier.individual.id).not_to eq(dossier.individual.id) }
    end

    context 'procedure with etablissement' do
      let(:dossier) { create(:dossier, :with_entreprise) }
      it { expect(new_dossier.etablissement.slice(:siret)).to eq(dossier.etablissement.slice(:siret)) }
      it { expect(new_dossier.etablissement.id).not_to eq(dossier.etablissement.id) }
    end

    describe 'champs' do
      it { expect(new_dossier.id).not_to eq(dossier.id) }

      context 'public are duplicated' do
        it { expect(new_dossier.champs_public.count).to eq(dossier.champs_public.count) }
        it { expect(new_dossier.champs_public.ids).not_to eq(dossier.champs_public.ids) }

        it 'keeps champs.values' do
          original_first_champ = dossier.champs_public.first
          original_first_champ.update!(value: 'kthxbye')

          expect(new_dossier.champs_public.first.value).to eq(original_first_champ.value)
        end

        context 'for Champs::Repetition with rows, original_champ.repetition and rows are duped' do
          let(:dossier) { create(:dossier) }
          let(:type_de_champ_repetition) { create(:type_de_champ_repetition, :with_types_de_champ, procedure: dossier.procedure) }
          let(:champ_repetition) { create(:champ_repetition, type_de_champ: type_de_champ_repetition, dossier: dossier) }
          before { dossier.champs_public << champ_repetition }

          it { expect(Champs::RepetitionChamp.where(dossier: new_dossier).first.champs.count).to eq(4) }
          it { expect(Champs::RepetitionChamp.where(dossier: new_dossier).first.champs.ids).not_to eq(champ_repetition.champs.ids) }
        end

        context 'for Champs::CarteChamp with geo areas, original_champ.geo_areas are duped' do
          let(:dossier) { create(:dossier) }
          let(:type_de_champ_carte) { create(:type_de_champ_carte, procedure: dossier.procedure) }
          let(:geo_area) { create(:geo_area, :selection_utilisateur, :polygon) }
          let(:champ_carte) { create(:champ_carte, type_de_champ: type_de_champ_carte, geo_areas: [geo_area]) }
          before { dossier.champs_public << champ_carte }

          it { expect(Champs::CarteChamp.where(dossier: new_dossier).first.geo_areas.count).to eq(1) }
          it { expect(Champs::CarteChamp.where(dossier: new_dossier).first.geo_areas.ids).not_to eq(champ_carte.geo_areas.ids) }
        end

        context 'for Champs::SiretChamp, original_champ.etablissement is duped' do
         let(:dossier) { create(:dossier) }
         let(:type_de_champs_siret) { create(:type_de_champ_siret, procedure: dossier.procedure) }
         let(:etablissement) { create(:etablissement) }
         let(:champ_siret) { create(:champ_siret, type_de_champ: type_de_champs_siret, etablissement: create(:etablissement)) }
         before { dossier.champs_public << champ_siret }

         it { expect(Champs::SiretChamp.where(dossier: dossier).first.etablissement).not_to be_nil }
         it { expect(Champs::SiretChamp.where(dossier: new_dossier).first.etablissement.id).not_to eq(champ_siret.etablissement.id) }
       end

        context 'for Champs::PieceJustificative, original_champ.piece_justificative_file is duped' do
          let(:dossier) { create(:dossier) }
          let(:champ_piece_justificative) { create(:champ_piece_justificative, dossier_id: dossier.id) }
          before { dossier.champs_public << champ_piece_justificative }
          it { expect(Champs::PieceJustificativeChamp.where(dossier: new_dossier).first.piece_justificative_file.first.blob).to eq(champ_piece_justificative.piece_justificative_file.first.blob) }
        end

        context 'for Champs::AddressChamp, original_champ.data is duped' do
          let(:dossier) { create(:dossier) }
          let(:type_de_champs_adress) { create(:type_de_champ_address, procedure: dossier.procedure) }
          let(:etablissement) { create(:etablissement) }
          let(:champ_address) { create(:champ_address, type_de_champ: type_de_champs_adress, external_id: 'Address', data: { city_code: '75019' }) }
          before { dossier.champs_public << champ_address }

          it { expect(Champs::AddressChamp.where(dossier: dossier).first.data).not_to be_nil }
          it { expect(Champs::AddressChamp.where(dossier: dossier).first.external_id).not_to be_nil }
          it { expect(Champs::AddressChamp.where(dossier: new_dossier).first.external_id).to eq(champ_address.external_id) }
          it { expect(Champs::AddressChamp.where(dossier: new_dossier).first.data).to eq(champ_address.data) }
        end
      end

      context 'private are renewd' do
        it { expect(new_dossier.champs_private.count).to eq(dossier.champs_private.count) }
        it { expect(new_dossier.champs_private.ids).not_to eq(dossier.champs_private.ids) }

        it 'reset champs private values' do
          original_first_champs_private = dossier.champs_private.first
          original_first_champs_private.update!(value: 'kthxbye')

          expect(new_dossier.champs_private.first.value).not_to eq(original_first_champs_private.value)
          expect(new_dossier.champs_private.first.value).to eq(nil)
        end
      end
    end

    context "as a fork" do
      let(:new_dossier) { dossier.clone(fork: true) }

      it { expect(new_dossier.editing_fork_origin).to eq(dossier) }
      it { expect(new_dossier.champs_public[0].id).not_to eq(dossier.champs_public[0].id) }
      it { expect(new_dossier.champs_public[0].created_at).to eq(dossier.champs_public[0].created_at) }
      it { expect(new_dossier.champs_public[0].updated_at).to eq(dossier.champs_public[0].updated_at) }

      context "piece justificative champ" do
        let(:champ_pj) { create(:champ_piece_justificative, dossier_id: dossier.id) }
        before { dossier.champs_public << champ_pj }

        it {
          champ_pj_fork = Champs::PieceJustificativeChamp.where(dossier: new_dossier).first
          expect(champ_pj_fork.piece_justificative_file.first.blob).to eq(champ_pj.piece_justificative_file.first.blob)
          expect(champ_pj_fork.created_at).to eq(champ_pj.created_at)
          expect(champ_pj_fork.updated_at).to eq(champ_pj.updated_at)
        }
      end

      context 'invalid origin' do
        let(:procedure) do
          create(:procedure, types_de_champ_public: [
            { type: :drop_down_list, libelle: "Le savez-vous?", stable_id: 992, drop_down_list_value: ["Oui", "Non", "Peut-être"].join("\r\n"), mandatory: true }
          ])
        end

        before do
          champ = dossier.champs.find { _1.stable_id == 992 }
          champ.value = "Je ne sais pas"
          champ.save!(validate: false)
        end

        it 'can still fork' do
          # rubocop:disable Lint/BooleanSymbol
          expect(dossier.valid?(context: :false)).to be_falsey

          new_dossier.champs.load # load relation so champs are validated below

          expect(new_dossier.valid?(context: :false)).to be_falsey
          expect(new_dossier.champs.find { _1.stable_id == 992 }.value).to eq("Je ne sais pas")

          # rubocop:enable Lint/BooleanSymbol
        end

        context 'when associated record is invalid' do
          let(:procedure) do
            create(:procedure, types_de_champ_public: [
              { type: :carte, libelle: "Carte", stable_id: 992, mandatory: true }
            ])
          end

          before do
            champ = dossier.champs.find { _1.stable_id == 992 }
            geo_area = build(:geo_area, champ:, geometry: { "i'm" => "invalid" })
            geo_area.save!(validate: false)
          end

          it 'can still fork' do
            new_dossier.champs.load # load relation so champs are validated below

            expect(new_dossier.champs.find { _1.stable_id == 992 }.geo_areas.first).not_to be_valid
          end
        end
      end
    end
  end

  describe '#make_diff' do
    subject { dossier.make_diff(forked_dossier) }

    context 'with no changes' do
      it { is_expected.to eq(added: [], updated: [], removed: []) }
    end

    context 'with updated groupe instructeur' do
      before {
        dossier.update!(groupe_instructeur: create(:groupe_instructeur))
        forked_dossier.assign_to_groupe_instructeur(dossier.procedure.defaut_groupe_instructeur, DossierAssignment.modes.fetch(:manual))
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
      let(:new_dossier) { dossier.clone }

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
        expect(new_dossier.revision_id).to eq(procedure.published_revision.id)
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

      it 'fork is hidden after merge' do
        subject
        expect(forked_dossier.reload.hidden_by_reason).to eq("stale_fork")
        expect(dossier.reload.editing_forks).to be_empty
      end
    end

    context 'with new revision' do
      let(:added_champ) { forked_dossier.champs.find { _1.libelle == "Un nouveau champ text" } }
      let(:added_repetition_champ) { forked_dossier.champs.find { _1.libelle == "Texte en répétition" } }
      let(:removed_champ) { dossier.champs.find { _1.stable_id == 99 } }
      let(:updated_champ) { dossier.champs.find { _1.stable_id == 991 } }

      before do
        dossier.champs.each do |champ|
          champ.update(value: 'old value')
        end
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          libelle: "Un nouveau champ text"
        })
        procedure.draft_revision.add_type_de_champ({
          type_champ: TypeDeChamp.type_champs.fetch(:text),
          parent_stable_id: 993,
          libelle: "Texte en répétition"
        })
        procedure.draft_revision.remove_type_de_champ(removed_champ.stable_id)
        procedure.draft_revision.find_and_ensure_exclusive_use(updated_champ.stable_id).update(libelle: "Un nouveau libelle")
        procedure.publish_revision!
      end

      subject {
        added_champ.update(value: 'new value for added champ')
        updated_champ.update(value: 'new value for updated champ')
        added_repetition_champ.update(value: "new value in repetition champ")
        dossier.reload
        super()
        dossier.reload
      }

      it { expect { subject }.to change { dossier.reload.champs.size }.by(1) }
      it { expect { subject }.to change { dossier.reload.champs.order(:created_at).map(&:to_s) }.from(['old value', 'old value', 'Non', 'old value', 'old value']).to(['new value for updated champ', 'Non', 'old value', 'old value', 'new value for added champ', 'new value in repetition champ']) }

      it "dossier after merge should be on last published revision" do
        expect(dossier.revision_id).to eq(procedure.revisions.first.id)
        expect(forked_dossier.revision_id).to eq(procedure.published_revision_id)

        subject
        perform_enqueued_jobs only: DestroyRecordLaterJob

        expect(dossier.revision_id).to eq(procedure.published_revision_id)
        expect(dossier.champs.all? { dossier.revision.in?(_1.type_de_champ.revisions) }).to be_truthy
        expect(Dossier.exists?(forked_dossier.id)).to be_falsey
      end
    end

    context 'with old revision having repetition' do
      let(:added_champ) { nil }
      let(:removed_champ) { dossier.champs.find(&:repetition?) }
      let(:updated_champ) { nil }

      before do
        dossier.champs.each do |champ|
          champ.update(value: 'old value')
        end
        procedure.draft_revision.remove_type_de_champ(removed_champ.stable_id)
        procedure.publish_revision!
      end
      it 'works' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
