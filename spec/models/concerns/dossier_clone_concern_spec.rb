# frozen_string_literal: true

RSpec.describe DossierCloneConcern do
  let(:procedure) do
    create(:procedure, types_de_champ_public:, types_de_champ_private:).tap(&:publish!)
  end
  let(:types_de_champ_public) do
    [
      { type: :text, libelle: "Un champ text", stable_id: 99 },
      { type: :text, libelle: "Un autre champ text", stable_id: 991 },
      { type: :yes_no, libelle: "Un champ yes no", stable_id: 992 },
      { type: :repetition, libelle: "Un champ répétable", stable_id: 993, mandatory: true, children: [{ type: :text, libelle: 'Nom', stable_id: 994 }] }
    ]
  end
  let(:types_de_champ_private) { [] }
  let(:dossier) { create(:dossier, :en_construction, procedure:) }
  let(:forked_dossier) { dossier.find_or_create_editing_fork(dossier.user) }

  describe '#clone' do
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:) }
    let(:types_de_champ_public) { [{}] }
    let(:types_de_champ_private) { [] }
    let(:fork) { false }
    subject(:new_dossier) { dossier.clone(fork:) }

    it 'resets most of the attributes for the cloned dossier' do
      expect(new_dossier.id).not_to eq(dossier.id)
      expect(new_dossier.api_entreprise_job_exceptions).to be_nil
      expect(new_dossier.archived).to be_falsey
      expect(new_dossier.brouillon_close_to_expiration_notice_sent_at).to be_nil
      expect(new_dossier.conservation_extension).to eq(0.seconds)
      expect(new_dossier.declarative_triggered_at).to be_nil
      expect(new_dossier.deleted_user_email_never_send).to be_nil
      expect(new_dossier.depose_at).to be_nil
      expect(new_dossier.en_construction_at).to be_nil
      expect(new_dossier.en_construction_close_to_expiration_notice_sent_at).to be_nil
      expect(new_dossier.en_instruction_at).to be_nil
      expect(new_dossier.for_procedure_preview).to be_falsey
      expect(new_dossier.groupe_instructeur_updated_at).to be_nil
      expect(new_dossier.hidden_by_administration_at).to be_nil
      expect(new_dossier.hidden_by_reason).to be_nil
      expect(new_dossier.hidden_by_user_at).to be_nil
      expect(new_dossier.identity_updated_at).to be_nil
      expect(new_dossier.last_avis_updated_at).to be_nil
      expect(new_dossier.last_champ_private_updated_at).to be_nil
      expect(new_dossier.last_champ_updated_at).to be_nil
      expect(new_dossier.last_champ_piece_jointe_updated_at).to be_nil
      expect(new_dossier.last_commentaire_updated_at).to be_nil
      expect(new_dossier.last_commentaire_piece_jointe_updated_at).to be_nil
      expect(new_dossier.motivation).to be_nil
      expect(new_dossier.processed_at).to be_nil
    end

    it "updates search terms" do
      # In spec, dossier and flag reference are created just before deep clone,
      # which keep the flag reference from the original, pointing to the original id.
      # We have to remove the flag reference before the clone
      dossier.remove_instance_variable(:@debounce_index_search_terms_flag_kredis_flag)

      perform_enqueued_jobs(only: DossierIndexSearchTermsJob) do
        subject
      end

      sql = "SELECT search_terms, private_search_terms FROM dossiers where id = :id"
      result = Dossier.connection.execute(Dossier.sanitize_sql_array([sql, id: new_dossier.id])).first

      expect(result["search_terms"]).to match(dossier.user.email)
      expect(result["private_search_terms"]).to eq("")
    end

    context 'copies some attributes' do
      context 'when fork' do
        let(:fork) { true }
        it { expect(new_dossier.groupe_instructeur).to eq(dossier.groupe_instructeur) }
      end

      context 'when not forked' do
        it "copies or reset attributes" do
          expect(new_dossier.groupe_instructeur).to be_nil
          expect(new_dossier.autorisation_donnees).to eq(dossier.autorisation_donnees)
          expect(new_dossier.revision_id).to eq(dossier.revision_id)
          expect(new_dossier.user_id).to eq(dossier.user_id)
        end
      end
    end

    context 'forces some attributes' do
      let(:dossier) { create(:dossier, :accepte) }

      it do
        expect(new_dossier.brouillon?).to eq(true)
        expect(new_dossier.parent_dossier).to eq(dossier)
      end

      context 'destroy parent' do
        before { new_dossier }

        it 'clean fk' do
          expect { dossier.destroy }.to change { new_dossier.reload.parent_dossier_id }.from(dossier.id).to(nil)
        end
      end
    end

    context 'procedure with_individual' do
      let(:procedure) { create(:procedure, :for_individual) }
      it do
        expect(new_dossier.individual.slice(:nom, :prenom, :gender)).to eq(dossier.individual.slice(:nom, :prenom, :gender))
        expect(new_dossier.individual.id).not_to eq(dossier.individual.id)
      end
    end

    context 'procedure with etablissement' do
      let(:dossier) { create(:dossier, :with_entreprise) }
      it do
        expect(new_dossier.etablissement.slice(:siret)).to eq(dossier.etablissement.slice(:siret))
        expect(new_dossier.etablissement.id).not_to eq(dossier.etablissement.id)
      end
    end

    describe 'champs' do
      it { expect(new_dossier.id).not_to eq(dossier.id) }

      context 'public are duplicated' do
        it do
          expect(new_dossier.project_champs_public.count).to eq(dossier.project_champs_public.count)
          expect(new_dossier.project_champs_public.map(&:id)).not_to eq(dossier.project_champs_public.map(&:id))
        end

        it 'keeps champs.values' do
          original_first_champ = dossier.project_champs_public.first
          original_first_champ.update!(value: 'kthxbye')

          expect(new_dossier.project_champs_public.first.value).to eq(original_first_champ.value)
        end

        context 'for Champs::Repetition with rows, original_champ.repetition and rows are duped' do
          let(:types_de_champ_public) { [{ type: :repetition, children: [{}, {}] }] }
          let(:champ_repetition) { dossier.project_champs_public.find(&:repetition?) }
          let(:cloned_champ_repetition) { new_dossier.project_champs_public.find(&:repetition?) }

          it do
            expect(cloned_champ_repetition.rows.flatten.count).to eq(4)
            expect(cloned_champ_repetition.rows.flatten.map(&:id)).not_to eq(champ_repetition.rows.flatten.map(&:id))
            expect(cloned_champ_repetition.row_ids).to eq(champ_repetition.row_ids)
          end
        end

        context 'for Champs::CarteChamp with geo areas, original_champ.geo_areas are duped' do
          let(:types_de_champ_public) { [{ type: :carte }] }
          let(:champ_carte) { dossier.champs.first }
          let(:cloned_champ_carte) { new_dossier.champs.first }

          it do
            expect(cloned_champ_carte.geo_areas.count).to eq(2)
            expect(cloned_champ_carte.geo_areas.ids).not_to eq(champ_carte.geo_areas.ids)
          end
        end

        context 'for Champs::SiretChamp, original_champ.etablissement is duped' do
          let(:types_de_champ_public) { [{ type: :siret }] }
          let(:champ_siret) { dossier.champs.first }
          let(:cloned_champ_siret) { new_dossier.champs.first }

          it do
            expect(champ_siret.etablissement).not_to be_nil
            expect(cloned_champ_siret.etablissement.id).not_to eq(champ_siret.etablissement.id)
          end
        end

        context 'for Champs::PieceJustificative, original_champ.piece_justificative_file is duped' do
          let(:types_de_champ_public) { [{ type: :piece_justificative }] }
          let(:champ_piece_justificative) { dossier.champs.first }
          let(:cloned_champ_piece_justificative) { new_dossier.champs.first }

          it { expect(cloned_champ_piece_justificative.piece_justificative_file.first.blob).to eq(champ_piece_justificative.piece_justificative_file.first.blob) }
        end

        context 'for Champs::AddressChamp, original_champ.data is duped' do
          let(:types_de_champ_public) { [{ type: :address }] }
          let(:champ_address) { dossier.champs.first }
          let(:cloned_champ_address) { new_dossier.champs.first }

          before { champ_address.update(external_id: 'Address', data: { city_code: '75019' }) }

          it do
            expect(champ_address.data).not_to be_nil
            expect(champ_address.external_id).not_to be_nil
            expect(cloned_champ_address.external_id).to eq(champ_address.external_id)
            expect(cloned_champ_address.data).to eq(champ_address.data)
          end
        end
      end

      context 'private are renewd' do
        let(:types_de_champ_private) { [{}] }

        it 'reset champs private values' do
          expect(new_dossier.project_champs_private.count).to eq(dossier.project_champs_private.count)
          expect(new_dossier.project_champs_private.map(&:id)).not_to eq(dossier.project_champs_private.map(&:id))
          original_first_champs_private = dossier.project_champs_private.first
          original_first_champs_private.update!(value: 'kthxbye')

          expect(new_dossier.project_champs_private.first.value).not_to eq(original_first_champs_private.value)
          expect(new_dossier.project_champs_private.first.value).to eq(nil)
        end
      end
    end

    context "as a fork" do
      let(:new_dossier) { dossier.clone(fork: true) }
      before { dossier.project_champs_public } # we compare timestamps so we have to get the precision limit from the db }

      it do
        expect(new_dossier.editing_fork_origin).to eq(dossier)
        expect(new_dossier.project_champs_public[0].id).not_to eq(dossier.project_champs_public[0].id)
        expect(new_dossier.project_champs_public[0].created_at).to eq(dossier.project_champs_public[0].created_at)
        expect(new_dossier.project_champs_public[0].updated_at).to eq(dossier.project_champs_public[0].updated_at)
      end

      context "piece justificative champ" do
        let(:types_de_champ_public) { [{ type: :piece_justificative }] }
        let(:champ_pj) { dossier.champs.first }
        let(:cloned_champ_pj) { new_dossier.champs.first }

        it {
          expect(cloned_champ_pj.piece_justificative_file.first.blob).to eq(champ_pj.piece_justificative_file.first.blob)
          expect(cloned_champ_pj.created_at).to eq(champ_pj.created_at)
          expect(cloned_champ_pj.updated_at).to eq(champ_pj.updated_at)
        }
      end

      context 'invalid origin' do
        let(:procedure) do
          create(:procedure, types_de_champ_public: [
            { type: :drop_down_list, libelle: "Le savez-vous?", stable_id: 992, drop_down_options: ["Oui", "Non", "Peut-être"], mandatory: true }
          ])
        end

        before do
          champ = dossier.champs.find { _1.stable_id == 992 }
          champ.value = "Je ne sais pas"
          champ.save!(validate: false)
        end

        it 'can still fork' do
          expect(dossier.validate(:champs_public_value)).to be_falsey

          new_dossier.champs.load # load relation so champs are validated below

          expect(new_dossier.validate(:champs_public_value)).to be_falsey
          expect(new_dossier.champs.find { _1.stable_id == 992 }.value).to eq("Je ne sais pas")
        end

        context 'when associated record is invalid' do
          let(:procedure) do
            create(:procedure, types_de_champ_public: [
              { type: :carte, libelle: "Carte", stable_id: 992, mandatory: true }
            ])
          end

          before do
            champ = dossier.champs.find { _1.stable_id == 992 }
            geo_area = champ.geo_areas.first
            geo_area.geometry = { "i'm" => "invalid" }
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

      it do
        expect(subject).to eq(added: [], updated: [], removed: [])
        expect(forked_dossier.user_buffer_changes?).to be_truthy
      end
    end

    context 'with updated champ' do
      let(:updated_champ) { forked_dossier.champs.find { _1.stable_id == 99 } }

      before { updated_champ.update(value: 'new value') }

      it 'user_buffer_changes? should reflect dossier state' do
        expect(subject).to eq(added: [], updated: [updated_champ], removed: [])
        expect(dossier.user_buffer_changes?).to be_truthy
        expect(forked_dossier.user_buffer_changes?).to be_truthy
        expect(updated_champ.user_buffer_changes?).to be_truthy
      end
    end

    context 'with new revision' do
      let(:added_champ) { forked_dossier.project_champs_public.find { _1.libelle == "Un nouveau champ text" } }
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
        expect(subject[:added].map(&:stable_id)).to eq([added_champ.stable_id])
        expect(subject[:added].first.new_record?).to be_truthy
        expect(subject[:updated]).to be_empty
        expect(subject[:removed]).to eq([removed_champ])
      }
    end
  end

  describe '#merge_fork' do
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    subject { dossier.merge_fork(forked_dossier) }

    context 'with updated champ' do
      let(:repetition_champ) { dossier.project_champs_public.last }
      let(:updated_champ) { forked_dossier.champs.find { _1.stable_id == 99 } }
      let(:updated_repetition_champs) { forked_dossier.champs.filter { _1.stable_id == 994 } }

      before do
        repetition_champ.add_row(updated_by: 'test')
        dossier.en_construction!
        dossier.champs.each do |champ|
          champ.update(value: 'old value')
        end
        updated_champ.update(value: 'new value')
        updated_repetition_champs.each { _1.update(value: 'new value in repetition') }
        dossier.debounce_index_search_terms_flag.remove
      end

      it { expect { subject }.to change { dossier.champs.reload.size }.by(0) }
      it { expect { subject }.not_to change { dossier.champs.order(:created_at).reject { _1.stable_id.in?([99, 994]) }.map(&:value) } }
      it { expect { subject }.to have_enqueued_job(DossierIndexSearchTermsJob).with(dossier) }
      it { expect { subject }.to change { dossier.champs.find { _1.stable_id == 99 }.value }.from('old value').to('new value') }
      it { expect { subject }.to change { dossier.reload.champs.find { _1.stable_id == 994 }.value }.from('old value').to('new value in repetition') }

      it 'fork is hidden after merge' do
        subject
        expect(forked_dossier.reload.hidden_by_reason).to eq("stale_fork")
        expect(dossier.reload.editing_forks).to be_empty
      end
    end

    context 'with new revision' do
      let(:added_champ) {
        tdc = forked_dossier.revision.types_de_champ.find { _1.libelle == "Un nouveau champ text" }
        forked_dossier.champ_for_update(tdc, updated_by: 'test')
      }
      let(:added_repetition_champ) {
        tdc_repetition = forked_dossier.revision.types_de_champ.find { _1.stable_id == 993 }
        tdc = forked_dossier.revision.types_de_champ.find { _1.libelle == "Texte en répétition" }
        row_id = forked_dossier.repetition_row_ids(tdc_repetition).first
        forked_dossier.champ_for_update(tdc, row_id:, updated_by: 'test')
      }
      let(:removed_champ) { dossier.champs.find { _1.stable_id == 99 } }
      let(:updated_champ) { dossier.champs.find { _1.stable_id == 991 } }
      let(:repetition_updated_champ) { champ_for_update(dossier.champs.find { _1.stable_id == 994 }) }
      let(:forked_updated_champ) { champ_for_update(forked_dossier.champs.find { _1.stable_id == 991 }) }
      let(:forked_repetition_updated_champ) { champ_for_update(forked_dossier.champs.find { _1.stable_id == 994 }) }

      before do
        dossier.champs.each do |champ|
          champ.update(value: 'old value')
        end
        dossier.reload
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
        added_champ.update(value: 'new value for added champ')
        added_repetition_champ.update(value: "new value in repetition champ")

        forked_updated_champ.update(value: 'new value for updated champ')
        forked_repetition_updated_champ.update(value: 'new value for updated champ in repetition')
        updated_champ.update(type: 'Champs::TextareaChamp')
        repetition_updated_champ.update(type: 'Champs::TextareaChamp')
        dossier.reload
        forked_dossier.reload
      end

      it { expect { subject }.to change { dossier.filled_champs.size }.by(3) }
      it { expect { subject }.to change { dossier.filled_champs.map(&:to_s).sort }.from(['Non', 'old value', 'old value']).to(["Non", "new value for added champ", "new value for updated champ", "new value for updated champ in repetition", "new value in repetition champ", "old value"]) }

      it "dossier after merge should be on last published revision" do
        expect(dossier.revision_id).to eq(procedure.revisions.first.id)
        expect(forked_dossier.revision_id).to eq(procedure.published_revision_id)

        subject
        perform_enqueued_jobs only: DestroyRecordLaterJob

        expect(dossier.revision_id).to eq(procedure.published_revision_id)
        expect(dossier.filled_champs.all? { dossier.revision.in?(_1.type_de_champ.revisions) }).to be_truthy
        expect(Dossier.exists?(forked_dossier.id)).to be_falsey
      end
    end

    context 'with old revision having repetition' do
      let(:removed_champ) { dossier.project_champs_public.find(&:repetition?) }

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

    context 'with added row' do
      let(:repetition_champ) { forked_dossier.project_champs_public.find(&:repetition?) }

      def dossier_rows(dossier) = dossier.champs.filter(&:row?)

      before do
        repetition_champ.add_row(updated_by: 'test')
      end

      it {
        expect(dossier_rows(dossier).size).to eq(2)
        expect { subject }.to change { dossier_rows(dossier).size }.by(1)
      }
    end

    context 'with removed row' do
      let(:repetition_champ) { forked_dossier.project_champs_public.find(&:repetition?) }
      let(:row_id) { repetition_champ.row_ids.first }

      def dossier_rows(dossier) = dossier.champs.filter(&:row?)
      def dossier_discarded_rows(dossier) = dossier_rows(dossier).filter(&:discarded?)

      before do
        repetition_champ.remove_row(row_id, updated_by: 'test')
      end

      it {
        expect(dossier_rows(dossier).size).to eq(2)
        expect { subject }.to change { dossier_rows(dossier).size }.by(0)
      }

      it {
        expect(dossier_discarded_rows(dossier).size).to eq(0)
        expect { subject }.to change { dossier_discarded_rows(dossier).size }.by(1)
      }
    end
  end
end
