require 'spec_helper'

describe DossierFieldService do
  describe '#filtered_ids' do
    let(:procedure) { create(:procedure) }

    context 'for etablissement table' do
      context 'for entreprise_date_creation column' do
        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: DateTime.new(2018, 6, 21))) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: DateTime.new(2008, 6, 21))) }

        subject { described_class.filtered_ids(procedure.dossiers, [{ 'table' => 'etablissement', 'column' => 'entreprise_date_creation', 'value' => '21/6/2018' }]) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for code_postal column' do
        # All columns except entreprise_date_creation work exacly the same, just testing one

        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75017')) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '25000')) }

        subject { described_class.filtered_ids(procedure.dossiers, [{ 'table' => 'etablissement', 'column' => 'code_postal', 'value' => '75017' }]) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end
    end
  end
end
