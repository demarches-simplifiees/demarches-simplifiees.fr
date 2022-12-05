describe PiecesJustificativesService do
  describe '.liste_documents' do
    let(:for_expert) { false }

    subject do
      PiecesJustificativesService
        .liste_documents(Dossier.where(id: dossier.id), for_expert)
        .map(&:first)
    end

    context 'with a pj champ' do
      let(:procedure) { create(:procedure, :with_piece_justificative) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:witness) { create(:dossier, procedure: procedure) }

      let(:pj_champ) { -> (d) { d.champs_public.find { |c| c.type == 'Champs::PieceJustificativeChamp' } } }

      before do
        attach_file_to_champ(pj_champ.call(dossier))
        attach_file_to_champ(pj_champ.call(witness))
      end

      context 'with a single attachment' do
        it { expect(subject).to match_array(pj_champ.call(dossier).piece_justificative_file.attachments) }
      end

      context 'with a multiple attachments' do
        before do
          attach_file_to_champ(pj_champ.call(dossier))
        end

        it { expect(subject.count).to eq(2) }
        it { expect(subject).to match_array(pj_champ.call(dossier).piece_justificative_file.attachments) }
      end
    end

    context 'with a pj not safe on a champ' do
      let(:procedure) { create(:procedure, :with_piece_justificative) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:pj_champ) { -> (d) { d.champs_public.find { |c| c.type == 'Champs::PieceJustificativeChamp' } } }

      before { attach_file_to_champ(pj_champ.call(dossier), safe = false) }

      it { expect(subject).to be_empty }
    end

    context 'with a private pj champ' do
      let(:procedure) { create(:procedure) }
      let(:dossier) { create(:dossier, procedure: procedure) }
      let(:witness) { create(:dossier, procedure: procedure) }

      let!(:private_pj) { create(:type_de_champ_piece_justificative, procedure: procedure, private: true) }
      let(:private_pj_champ) { -> (d) { d.champs_private.find { |c| c.type == 'Champs::PieceJustificativeChamp' } } }

      before do
        attach_file_to_champ(private_pj_champ.call(dossier))
        attach_file_to_champ(private_pj_champ.call(witness))
      end

      it { expect(subject).to match_array(private_pj_champ.call(dossier).piece_justificative_file.attachments) }

      context 'for expert' do
        let(:for_expert) { true }

        it { expect(subject).to be_empty }
      end
    end

    context 'with a identite champ pj' do
      let(:procedure) { create(:procedure, :with_titre_identite) }
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

      it { expect(subject).to match_array(dossier.commentaires.first.piece_jointe.attachment) }
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

    context 'with a bill' do
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

      it "returns serialized bill and signature" do
        expect(subject).to match_array([dossier_bs.serialized.attachment, dossier_bs.signature.attachment])
      end

      context 'for expert' do
        let(:for_expert) { true }

        it { expect(subject).to be_empty }
      end
    end

    context 'with a dol' do
      let(:dossier) { create(:dossier) }
      let(:witness) { create(:dossier) }

      let(:dol) { create(:dossier_operation_log, dossier: dossier) }
      let(:witness_dol) { create(:dossier_operation_log, dossier: witness) }

      before do
        attach_file(dol.serialized)
        attach_file(witness_dol.serialized)
      end

      it { expect(subject).to match_array(dol.serialized.attachment) }

      context 'for expert' do
        let(:for_expert) { true }

        it { expect(subject).to be_empty }
      end
    end
  end

  describe '.generate_dossier_export' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, children: [{ type: :piece_justificative }] }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }

    subject { PiecesJustificativesService.generate_dossier_export(Dossier.where(id: dossier.id)) }

    it "doesn't update dossier" do
      expect { subject }.not_to change { dossier.updated_at }
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
