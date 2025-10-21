# frozen_string_literal: true

describe TypesDeChamp::PieceJustificativeTypeDeChamp do
  describe '#columns' do
    let(:procedure) { create(:procedure) }

    it 'adds RIB columns' do
      tdc = create(:type_de_champ_piece_justificative, procedure:, nature: 'RIB')
      cols = tdc.dynamic_type.columns(procedure:, displayable: true)
      labels = cols.map(&:label)
      expect(labels.any? { _1.include?('Titulaire') }).to be true
      expect(labels.any? { _1.include?('IBAN') }).to be true
      expect(labels.any? { _1.include?('BIC') }).to be true
      expect(labels.any? { _1.include?('Nom de la Banque') }).to be true
    end
  end

  describe '#champ_value_for_api' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
    let(:dossier) { create(:dossier, procedure:) }
    let(:champ) { dossier.champs.first }

    before { allow(ClamavService).to receive(:safe_file?).and_return(true) }

    it 'returns url for first file in v1 when safe' do
      champ.piece_justificative_file.attach(fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png'))
      champ.piece_justificative_file.first.blob.update(virus_scan_result: ActiveStorage::VirusScanner::SAFE)
      expect(champ.type_de_champ.dynamic_type.champ_value_for_api(champ, version: 1)).to include('/rails/active_storage/')
    end

    it 'returns nil when infected' do
      champ.piece_justificative_file.attach(fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png'))
      champ.piece_justificative_file.first.blob.update(virus_scan_result: ActiveStorage::VirusScanner::INFECTED)
      expect(champ.type_de_champ.dynamic_type.champ_value_for_api(champ, version: 1)).to be_nil
    end
  end
end
