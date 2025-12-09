# frozen_string_literal: true

describe Columns::JSONPathColumn do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :address }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }
  let(:stable_id) { champ.stable_id }
  let(:tdc_type) { champ.type_champ }
  let(:column) { described_class.new(procedure_id: procedure.id, label: 'label', stable_id:, tdc_type:, jsonpath:, displayable: true, mandatory: true) }

  describe '#value' do
    let(:jsonpath) { '$.city_name' }

    subject { column.value(champ) }

    context 'when champ has value_json' do
      before { champ.update(value_json: { city_name: 'Grenoble' }) }

      it { is_expected.to eq('Grenoble') }
    end

    context 'when champ has no value_json' do
      it { is_expected.to be_nil }
    end
  end

  describe '#filtered_ids' do
    context 'with regular search' do
      let(:jsonpath) { '$.city_name' }

      subject { column.filtered_ids(Dossier.all, { operator: 'match', value: ['reno', 'Lyon'] }) }

      context 'when champ has value_json' do
        before { champ.update(value_json: { city_name: 'Grenoble' }) }

        it { is_expected.to eq([dossier.id]) }
      end

      context 'when champ has no value_json' do
        it { is_expected.to eq([]) }
      end
    end

    context 'with avanced search using special characters' do
      let(:jsonpath) { '$.city_name' }

      subject { column.filtered_ids(Dossier.all, { operator: 'match', value: ['*reno*', 'Lyon'] }) }

      context 'when champ has value_json we catch Invalid Regex error and return []' do
        before { champ.update(value_json: { city_name: 'Grenoble' }) }

        it { is_expected.to eq([]) }
      end

      context 'when champ has no value_json we catch Invalid Regex error and return []' do
        it { is_expected.to eq([]) }
      end
    end

    context 'with blank filter values' do
      let(:jsonpath) { '$.postal_code' }
      let(:dossier1) { create(:dossier, procedure:) }
      let(:dossier2) { create(:dossier, procedure:) }
      let(:dossier3) { create(:dossier, procedure:) }
      let(:dossiers) { Dossier.where(id: [dossier1.id, dossier2.id, dossier3.id]) }

      before do
        dossier1.champs.first.update(value_json: { postal_code: '60580' })
        dossier2.champs.first.update(value_json: { postal_code: '75001' })
      end

      context 'when filter value contains only blank strings' do
        subject { column.filtered_ids(dossiers, { operator: 'match', value: ['', '  ', nil] }) }

        it 'returns all dossiers without filtering' do
          is_expected.to contain_exactly(dossier1.id, dossier2.id, dossier3.id)
        end
      end
    end
  end

  describe '#initializer' do
    let(:jsonpath) { %{$.'city_name} }

    it { expect(column.jsonpath).to eq(%{$.''city_name}) }
  end
end
