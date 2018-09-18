require 'spec_helper'

describe DossierFieldService do
  describe '#filtered_ids' do
    let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }

    context 'for type_de_champ table' do
      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ) { procedure.types_de_champ.first }

      before do
        type_de_champ.champ.create(dossier: kept_dossier, value: 'keep me')
        type_de_champ.champ.create(dossier: discarded_dossier, value: 'discard me')
      end

      subject { described_class.filtered_ids(procedure.dossiers, [{ 'table' => 'type_de_champ', 'column' => type_de_champ.id, 'value' => 'keep' }]) }

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end

    context 'for type_de_champ_private table' do
      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ_private) { procedure.types_de_champ_private.first }

      before do
        type_de_champ_private.champ.create(dossier: kept_dossier, value: 'keep me')
        type_de_champ_private.champ.create(dossier: discarded_dossier, value: 'discard me')
      end

      subject { described_class.filtered_ids(procedure.dossiers, [{ 'table' => 'type_de_champ_private', 'column' => type_de_champ_private.id, 'value' => 'keep' }]) }

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end

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

    context 'for user table' do
      let!(:kept_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@keepmail.com')) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@discard.com')) }

      subject { described_class.filtered_ids(procedure.dossiers, [{ 'table' => 'user', 'column' => 'email', 'value' => 'keepmail' }]) }

      it { is_expected.to contain_exactly(kept_dossier.id) }
    end
  end
end
