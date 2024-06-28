describe PiecesJustificativesService do
  describe '.liste_documents' do
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:dossiers) { Dossier.where(id: dossier.id) }
    subject do
      PiecesJustificativesService.new(user_profile:).liste_documents(dossiers).map(&:first)
    end

    context 'no acl' do
      let(:user_profile) { build(:administrateur) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
      let(:witness) { create(:dossier, procedure: procedure) }
      let(:pj_champ) { -> (d) { d.champs_public.find { |c| c.type == 'Champs::PieceJustificativeChamp' } } }

      context 'with a single attachment' do
        before do
          attach_file_to_champ(pj_champ.call(dossier))
          attach_file_to_champ(pj_champ.call(witness))
        end

        it { expect(subject).to match_array(pj_champ.call(dossier).piece_justificative_file.attachments) }
      end

      context 'with a multiple attachments' do
        before do
          attach_file_to_champ(pj_champ.call(dossier))
          attach_file_to_champ(pj_champ.call(witness))
          attach_file_to_champ(pj_champ.call(dossier))
        end

        it { expect(subject.count).to eq(2) }
        it { expect(subject).to match_array(pj_champ.call(dossier).piece_justificative_file.attachments) }
      end

      context 'with a pj not safe on a champ' do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:pj_champ) { -> (d) { d.champs_public.find { |c| c.type == 'Champs::PieceJustificativeChamp' } } }

        before { attach_file_to_champ(pj_champ.call(dossier), safe = false) }

        it { expect(subject).to be_empty }
      end

      context 'with a identite champ pj' do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :titre_identite }]) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:witness) { create(:dossier, procedure: procedure) }

        let(:champ_identite) { dossier.champs_public.find { |c| c.type == 'Champs::TitreIdentiteChamp' } }

        before { attach_file_to_champ(champ_identite) }

        it "doesn't return sensitive documents like titre_identite" do
          expect(champ_identite.piece_justificative_file).to be_attached
          expect(subject).to be_empty
        end
      end

      context 'with a pj on an commentaire' do
        let(:dossier) { create(:dossier) }
        let(:witness) { create(:dossier) }

        let!(:commentaire) { create(:commentaire, dossier: dossier) }
        let!(:witness_commentaire) { create(:commentaire, dossier: witness) }

        before do
          attach_file(commentaire.piece_jointe)
          attach_file(witness_commentaire.piece_jointe)
        end

        it { expect(subject).to match_array(dossier.commentaires.first.piece_jointe.attachments) }
      end

      context 'with a pj not safe on a commentaire' do
        let(:dossier) { create(:dossier) }
        let!(:commentaire) { create(:commentaire, dossier: dossier) }

        before { attach_file(commentaire.piece_jointe, safe = false) }

        it { expect(subject).to be_empty }
      end

      context 'with a motivation' do
        let(:dossier) { create(:dossier, :with_justificatif) }
        let!(:witness) { create(:dossier, :with_justificatif) }

        it { expect(subject).to match_array(dossier.justificatif_motivation.attachment) }
      end

      context 'with a motivation not safe' do
        let(:dossier) { create(:dossier) }

        before { attach_file(dossier.justificatif_motivation, safe = false) }

        it { expect(subject).to be_empty }
      end

      context 'with an attestation' do
        let(:dossier) { create(:dossier, :with_attestation) }
        let!(:witness) { create(:dossier, :with_attestation) }

        it { expect(subject).to match_array(dossier.attestation.pdf.attachment) }
      end

      context 'with an etablissement' do
        let(:dossier) { create(:dossier, :with_entreprise) }
        let(:attestation_sociale) { dossier.etablissement.entreprise_attestation_sociale }
        let(:attestation_fiscale) { dossier.etablissement.entreprise_attestation_fiscale }

        let!(:witness) { create(:dossier, :with_entreprise) }
        let!(:witness_attestation_sociale) { witness.etablissement.entreprise_attestation_sociale }
        let!(:witness_attestation_fiscale) { witness.etablissement.entreprise_attestation_fiscale }

        before do
          attach_file(attestation_sociale)
          attach_file(attestation_fiscale)
        end

        it { expect(subject).to match_array([attestation_sociale.attachment, attestation_fiscale.attachment]) }
      end
    end

    context 'acl on private pj champ' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:witness) { create(:dossier, procedure: procedure) }

      let!(:private_pj) { create(:type_de_champ_piece_justificative, procedure: procedure, private: true) }
      let(:private_pj_champ) { -> (d) { d.champs_private.find { |c| c.type == 'Champs::PieceJustificativeChamp' } } }

      before do
        attach_file_to_champ(private_pj_champ.call(dossier))
        attach_file_to_champ(private_pj_champ.call(witness))
      end

      context 'given an administrateur' do
        let(:user_profile) { build(:administrateur) }
        it { expect(subject).to match_array(private_pj_champ.call(dossier).piece_justificative_file.attachments) }
      end

      context 'given an instructeur' do
        let(:user_profile) { create(:instructeur) }
        it { expect(subject).to match_array(private_pj_champ.call(dossier).piece_justificative_file.attachments) }
      end

      context 'given an expert' do
        let(:user_profile) { create(:expert) }
        it { expect(subject).not_to match_array(private_pj_champ.call(dossier).piece_justificative_file.attachments) }
      end
    end

    context 'acl on bill' do
      let(:dossier) { create(:dossier) }
      let(:witness) { create(:dossier) }

      let(:bill_signature) do
        bs = build(:bill_signature, :with_serialized, :with_signature)
        bs.save(validate: false)
        bs
      end

      let(:witness_bill_signature) do
        bs = build(:bill_signature, :with_serialized, :with_signature)
        bs.save(validate: false)
        bs
      end

      before do
        create(:dossier_operation_log, dossier: dossier, bill_signature: bill_signature)
        create(:dossier_operation_log, dossier: witness, bill_signature: witness_bill_signature)
      end

      let(:dossier_bs) { dossier.dossier_operation_logs.first.bill_signature }

      context 'given an Administrateur, includes bills' do
        let(:user_profile) { build(:administrateur) }

        it "returns serialized bill and signature" do
          expect(subject).to match_array([dossier_bs.serialized.attachment, dossier_bs.signature.attachment])
        end

        context 'with a dol' do
          let(:dol) { create(:dossier_operation_log, dossier: dossier) }
          let(:witness_dol) { create(:dossier_operation_log, dossier: witness) }

          before do
            attach_file(dol.serialized)
            attach_file(witness_dol.serialized)
          end

          it { expect(subject).to include(dol.serialized.attachment) }
        end
      end

      context 'given an expert, does not includes bills' do
        let(:user_profile) { create(:expert) }

        it { expect(subject).to be_empty }
      end

      context 'given an instructeur, does not includes bills' do
        let(:user_profile) { create(:instructeur) }

        it { expect(subject).to be_empty }
      end
    end

    context 'acl on with_avis_piece_justificative' do
      let(:user_profile) { create(:expert) }
      let(:procedure) { create(:procedure) }
      let(:dossier) { create(:dossier, procedure: procedure) }

      context 'with avis.piece_justificative being confidentiel' do
        let(:procedure) { create(:procedure) }
        let(:avis) { create(:avis, dossier: dossier, confidentiel: true) }

        before do
          to_be_attached = {
            io: StringIO.new("toto"),
            filename: "toto.png",
            content_type: "image/png",
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          }

          avis.piece_justificative_file.attach(to_be_attached)
          avis.introduction_file.attach(avis.piece_justificative_file.blob)
        end

        context 'given an administrateur' do
          let(:user_profile) { build(:administrateur) }
          it "doesn't return confidentiel avis.piece_justificative_file" do
            expect(subject.size).to eq(2)
          end
        end

        context 'given an instructeur' do
          let(:user_profile) { create(:instructeur) }
          it "doesn't return confidentiel avis.piece_justificative_file" do
            expect(subject.size).to eq(2)
          end
        end

        context 'given an expert' do
          let(:user_profile) { create(:expert) }
          it "doesn't return confidentiel avis.piece_justificative_file" do
            expect(subject.size).to eq(0)
          end
        end

        context 'when the expert has given the avis' do
          let(:experts_procedure) { create(:experts_procedure, expert: user_profile, procedure:) }
          let(:avis) { create(:avis, experts_procedure:, dossier: dossier, confidentiel: true) }
          let(:user_profile) { create(:expert) }
          it "doesn't return confidentiel avis.piece_justificative_file" do
            expect(subject.size).to eq(2)
          end
        end
      end

      context 'with avis.piece_justificative being public' do
        let(:procedure) { create(:procedure) }
        let(:dossier) { create(:dossier, procedure: procedure) }
        let(:avis) { create(:avis, dossier: dossier, confidentiel: false) }
        before do
          to_be_attached = {
            io: StringIO.new("toto"),
            filename: "toto.png",
            content_type: "image/png",
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          }

          avis.piece_justificative_file.attach(to_be_attached)
          avis.introduction_file.attach(avis.piece_justificative_file.blob)
        end

        context 'given an administrateur' do
          let(:user_profile) { build(:administrateur) }
          it "doesn't return confidentiel avis.piece_justificative_file" do
            expect(subject.size).to eq(2)
          end
        end

        context 'given an instructeur' do
          let(:user_profile) { create(:instructeur) }
          it "doesn't return confidentiel avis.piece_justificative_file" do
            expect(subject.size).to eq(2)
          end
        end

        context 'given an expert' do
          let(:user_profile) { create(:expert) }
          it "doesn't return confidentiel avis.piece_justificative_file" do
            expect(subject.size).to eq(2)
          end
        end
      end
    end
  end

  describe '.generate_dossiers_export' do
    let(:user_profile) { build(:administrateur) }
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :piece_justificative }] }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }
    let(:dossiers) { Dossier.where(id: dossier.id) }
    subject { PiecesJustificativesService.new(user_profile:).generate_dossiers_export(dossiers) }

    it "doesn't update dossier" do
      expect { subject }.not_to change { dossier.updated_at }
    end

    context 'when given an expert' do
      let!(:user_profile) { create(:expert) }
      let!(:confidentiel_avis) { create(:avis, :confidentiel, dossier: dossier) }
      let!(:not_confidentiel_avis) { create(:avis, :not_confidentiel, dossier: dossier) }
      let!(:expert_avis) { create(:avis, :confidentiel, dossier: dossier, expert: user_profile) }

      subject { PiecesJustificativesService.new(user_profile:).generate_dossiers_export(dossiers) }
      it "includes avis not confidentiel as well as expert's avis" do
        expect_any_instance_of(Dossier).to receive(:avis_for_expert).with(user_profile).and_return([])
        subject
      end
    end
  end

  def attach_file_to_champ(champ, safe = true)
    attach_file(champ.piece_justificative_file, safe)
  end

  def attach_file(attachable, safe = true)
    to_be_attached = {
      io: StringIO.new("toto"),
      filename: "toto.png", content_type: "image/png"
    }

    if safe
      to_be_attached[:metadata] = { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    end

    attachable.attach(to_be_attached)
  end
end
