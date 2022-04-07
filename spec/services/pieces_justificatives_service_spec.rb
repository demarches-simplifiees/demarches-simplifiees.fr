describe PiecesJustificativesService do
  describe '.liste_documents' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:for_expert) { false }

    subject do
      PiecesJustificativesService
        .liste_documents(Dossier.where(id: dossier.id), for_expert)
        .map(&:first)
    end

    context 'with a pj champ' do
      let(:procedure) { create(:procedure, :with_piece_justificative) }
      let(:pj_champ) { dossier.champs.find { |c| c.type == 'Champs::PieceJustificativeChamp' } }

      before { attach_file_to_champ(pj_champ) }

      it { expect(subject).to match_array([pj_champ.piece_justificative_file.attachment]) }
    end

    context 'with a private pj champ' do
      let(:procedure) { create(:procedure) }
      let!(:private_pj) { create(:type_de_champ_piece_justificative, procedure: procedure, private: true) }
      let(:private_pj_champ) { dossier.champs_private.find { |c| c.type == 'Champs::PieceJustificativeChamp' } }

      before { attach_file_to_champ(private_pj_champ) }

      it { expect(subject).to match_array([private_pj_champ.piece_justificative_file.attachment]) }

      context 'for expert' do
        let(:for_expert) { true }

        it { expect(subject).to be_empty }
      end
    end

    context 'with a identite champ pj' do
      let(:procedure) { create(:procedure, :with_titre_identite) }
      let(:champ_identite) { dossier.champs.find { |c| c.type == 'Champs::TitreIdentiteChamp' } }

      before { attach_file_to_champ(champ_identite) }

      it "doesn't return sensitive documents like titre_identite" do
        expect(champ_identite.piece_justificative_file).to be_attached
        expect(subject).to be_empty
      end
    end

    context 'with a pj on an commentaire' do
      let!(:commentaire) { create(:commentaire, :with_file, dossier: dossier) }

      it { expect(subject).to match_array(dossier.commentaires.first.piece_jointe.attachment) }
    end

    context 'with a motivation' do
      let(:dossier) { create(:dossier, :with_justificatif) }

      it { expect(subject).to match_array(dossier.justificatif_motivation.attachment) }
    end

    context 'with an attestation' do
      let(:dossier) { create(:dossier, :with_attestation) }

      it { expect(subject).to match_array(dossier.attestation.pdf.attachment) }
    end

    context 'with an etablissement' do
      let(:dossier) { create(:dossier, :with_entreprise) }
      let(:attestation_sociale) { dossier.etablissement.entreprise_attestation_sociale }
      let(:attestation_fiscale) { dossier.etablissement.entreprise_attestation_fiscale }

      before do
        attach_file(attestation_sociale)
        attach_file(attestation_fiscale)
      end

      it { expect(subject).to match_array([attestation_sociale.attachment, attestation_fiscale.attachment]) }
    end

    context 'with a bill' do
      let(:bill_signature) do
        bs = build(:bill_signature, :with_serialized, :with_signature)
        bs.save(validate: false)
        bs
      end

      before { create(:dossier_operation_log, dossier: dossier, bill_signature: bill_signature) }

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
      let(:dol) { create(:dossier_operation_log, dossier: dossier) }

      before { attach_file(dol.serialized) }

      it { expect(subject).to match_array(dol.serialized.attachment) }

      context 'for expert' do
        let(:for_expert) { true }

        it { expect(subject).to be_empty }
      end
    end
  end

  describe '.generate_dossier_export' do
    let(:dossier) { create(:dossier) }

    subject { PiecesJustificativesService.generate_dossier_export(dossier) }

    it "doesn't update dossier" do
      expect { subject }.not_to change { dossier.updated_at }
    end
  end

  def attach_file_to_champ(champ)
    attach_file(champ.piece_justificative_file)
  end

  def attach_file(attachable)
    attachable
      .attach(io: StringIO.new("toto"), filename: "toto.png", content_type: "image/png")
  end
end
