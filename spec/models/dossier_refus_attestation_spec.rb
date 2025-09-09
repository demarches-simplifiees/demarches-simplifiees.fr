# frozen_string_literal: true

describe 'Dossier refusal attestation', type: :model do
  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
  let(:instructeur) { create(:instructeur) }

  describe '#after_refuser' do
    let(:motivation) { 'Dossier incomplet' }

    context 'with attestation_refus_template activated' do
      let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure, activated: true) }

      it 'creates an attestation on refusal' do
        expect { dossier.refuser!(motivation: motivation, instructeur: instructeur) }
          .to change { dossier.reload.attestation }
          .from(nil)
          .to(an_instance_of(Attestation))
      end

      it 'sets the processed_at timestamp' do
        dossier.refuser!(motivation: motivation, instructeur: instructeur)
        expect(dossier.reload.processed_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    context 'without attestation_refus_template' do
      it 'does not create an attestation' do
        expect { dossier.refuser!(motivation: motivation, instructeur: instructeur) }
          .not_to change { dossier.reload.attestation }
      end
    end

    context 'with attestation_refus_template deactivated' do
      let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure, activated: false) }

      it 'does not create an attestation' do
        expect { dossier.refuser!(motivation: motivation, instructeur: instructeur) }
          .not_to change { dossier.reload.attestation }
      end
    end
  end

  describe '#after_refuser_automatiquement' do
    context 'with attestation_refus_template activated' do
      let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure, activated: true) }

      it 'creates an attestation on automatic refusal' do
        expect { dossier.refuser_automatiquement!(motivation: 'SVR refus automatique') }
          .to change { dossier.reload.attestation }
          .from(nil)
          .to(an_instance_of(Attestation))
      end
    end
  end

  describe '#build_attestation_refus' do
    context 'with activated attestation_refus_template' do
      let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure, activated: true) }

      it 'builds an attestation from the template' do
        attestation = dossier.build_attestation_refus
        expect(attestation).to be_an_instance_of(Attestation)
        expect(attestation.pdf).to be_attached
      end
    end

    context 'without attestation_refus_template' do
      it 'returns nil' do
        expect(dossier.build_attestation_refus).to be_nil
      end
    end

    context 'with deactivated attestation_refus_template' do
      let!(:attestation_refus_template) { create(:attestation_refus_template, procedure: procedure, activated: false) }

      it 'returns nil' do
        expect(dossier.build_attestation_refus).to be_nil
      end
    end
  end
end