# frozen_string_literal: true

describe 'shared/dossiers/_infos_generales', type: :view do
  let(:dossier) { create(:dossier, :en_construction) }
  subject { render 'shared/dossiers/infos_generales', dossier: dossier, profile: 'instructeur' }
  before do
    sign_in(current_role.user)
    allow(view).to receive(:current_instructeur).and_return(current_role)
    allow(view).to receive(:dossier).and_return(dossier)
  end

  context 'when expert' do
    let(:current_role) { create(:expert) }

    context 'with an attestation' do
      let(:dossier) { create :dossier, :accepte, :with_attestation_acceptation }

      it 'provides a link to the attestation' do
        pdf = dossier.attestation.pdf
        expect(dossier).to receive(:attestation).and_return(double(pdf: pdf)).at_least(2)
        expect(subject).to have_text('Attestation')
        expect(subject).to have_text("Télécharger l’attestation")
      end
    end
  end

  context 'when instructeur' do
    let(:current_role) { create(:instructeur) }
    context 'with a motivation' do
      let(:dossier) { create :dossier, :accepte, :with_motivation }

      it 'displays the motivation text' do
        expect(subject).to have_content(dossier.motivation)
      end
    end

    context 'with a motivation and procedure with accuse de lecture' do
      let(:dossier) { create :dossier, :accepte, :with_justificatif, procedure: create(:procedure, :accuse_lecture) }

      it 'still displays the motivation text for the instructeur' do
        expect(subject).to have_content(dossier.motivation)
      end
    end

    context 'with an attestation' do
      let(:dossier) { create :dossier, :accepte, :with_attestation_acceptation }

      it 'provides a link to the attestation' do
        pdf = dossier.attestation.pdf
        expect(dossier).to receive(:attestation).and_return(double(pdf: pdf)).at_least(2)
        expect(subject).to have_text('Attestation')
        expect(subject).to have_text("Télécharger l’attestation")
      end
    end

    context 'with a justificatif' do
      let(:dossier) do
        dossier = create(:dossier, :accepte, :with_justificatif)
        dossier.justificatif_motivation.blob.update(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
        dossier
      end

      it 'allows to download the justificatif' do
        expect(subject).to have_css("a[href*='/rails/active_storage/blobs/']", text: dossier.justificatif_motivation.attachment.filename.to_s)
      end
    end
  end
end
