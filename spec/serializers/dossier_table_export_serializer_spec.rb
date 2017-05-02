require 'spec_helper'

describe DossierTableExportSerializer do

  describe '#emails_accompagnateurs' do

    let(:gestionnaire){ create(:gestionnaire) }
    let(:follow) { create(:follow, gestionnaire: gestionnaire) }

    subject { DossierTableExportSerializer.new(dossier).emails_accompagnateurs }

    context 'when there is no accompagnateurs' do
      let(:dossier) { create(:dossier, follows: []) }

      it { is_expected.to eq('') }
    end

    context 'when there one accompagnateur' do
      let(:dossier) { create(:dossier, follows: [follow]) }

      it { is_expected.to eq(gestionnaire.email) }
    end

    context 'when there is 2 followers' do
      let(:gestionnaire2) { create :gestionnaire}
      let(:follow2) { create(:follow, gestionnaire: gestionnaire2) }
      let(:dossier) { create(:dossier, follows: [follow, follow2]) }

      it { is_expected.to eq "#{gestionnaire.email} #{gestionnaire2.email}" }
    end

  end

end
