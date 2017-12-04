require 'spec_helper'

describe DossierTableExportSerializer do
  describe '#attributes' do
    subject { DossierTableExportSerializer.new(dossier).serializable_hash }

    context 'when the dossier is en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      it { is_expected.to include(initiated_at: dossier.en_construction_at) }
      it { is_expected.to include(state: 'initiated') }
    end

    context 'when the dossier is en instruction' do
      let(:dossier) { create(:dossier, :en_instruction) }

      it { is_expected.to include(received_at: dossier.en_instruction_at) }
      it { is_expected.to include(state: 'received') }
    end

    context 'when the dossier is accepte' do
      let(:dossier) { create(:dossier, state: :accepte) }

      it { is_expected.to include(state: 'closed') }
    end
  end

  describe '#emails_accompagnateurs' do
    let(:gestionnaire){ create(:gestionnaire) }
    let(:gestionnaire2) { create :gestionnaire}
    let(:dossier) { create(:dossier) }

    subject { DossierTableExportSerializer.new(dossier).emails_accompagnateurs }

    context 'when there is no accompagnateurs' do
      it { is_expected.to eq('') }
    end

    context 'when there one accompagnateur' do
      before { gestionnaire.followed_dossiers << dossier }

      it { is_expected.to eq(gestionnaire.email) }
    end

    context 'when there is 2 followers' do
      before do
        gestionnaire.followed_dossiers << dossier
        gestionnaire2.followed_dossiers << dossier
      end

      it { is_expected.to eq "#{gestionnaire.email} #{gestionnaire2.email}" }
    end
  end
end
