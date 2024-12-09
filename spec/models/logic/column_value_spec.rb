# frozen_string_literal: true

describe Logic::ColumnValue do
  include Logic

  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no, libelle: 'yes' }]) }
  let(:column) { procedure.find_column(label: 'yes') }
  let(:column_value) { Logic::ColumnValue.new(column) }

  describe '#compute' do
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }

    before { champ.update(value: 'true') }

    it { expect(column_value.compute([champ])).to be(true) }
  end

  describe '#sources' do
    it { expect(column_value.sources).to eq([column.stable_id]) }
  end

  describe '#errors' do
    it do
      expect(column_value.errors(procedure.active_revision.types_de_champ)).to eq([])
      expect(column_value.errors([])).to eq([{ type: :not_available }])
    end
  end
end
