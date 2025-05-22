require 'active_storage_validations/matchers'

describe Champs::PieceJustificativeChamp do
  include ActiveStorageValidations::Matchers

  describe "validations" do
    let(:champ) { Champs::PieceJustificativeChamp.new }
    subject { champ }
    before { allow(champ).to receive(:type_de_champ).and_return(build(:type_de_champ_piece_justificative)) }

    context "by default" do
      it { is_expected.to validate_size_of(:piece_justificative_file).less_than(Champs::PieceJustificativeChamp::FILE_MAX_SIZE) }
      it { is_expected.to validate_content_type_of(:piece_justificative_file).rejecting('application/x-ms-dos-executable') }
      it { expect(champ.type_de_champ.skip_pj_validation).to be_falsy }
    end

    context "when validation is disabled" do
      before { champ.type_de_champ.update(skip_pj_validation: true) }

      it { is_expected.not_to validate_size_of(:piece_justificative_file).less_than(Champs::PieceJustificativeChamp::FILE_MAX_SIZE) }
    end

    context "when content-type validation is disabled" do
      before { champ.type_de_champ.update(skip_content_type_pj_validation: true) }

      it { is_expected.not_to validate_content_type_of(:piece_justificative_file).rejecting('application/x-ms-dos-executable') }
    end
  end

  describe "#for_export" do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champs.first }
    subject { champ.for_export }

    it { is_expected.to eq('toto.txt') }

    context 'without attached file' do
      before { champ.piece_justificative_file.purge }
      it { is_expected.to eq(nil) }
    end
  end

  describe '#for_api' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champs.first }

    before { champ.piece_justificative_file.first.blob.update(virus_scan_result:) }

    subject { champ.for_api }

    context 'when file is safe' do
      let(:virus_scan_result) { ActiveStorage::VirusScanner::SAFE }
      it { is_expected.to include("/rails/active_storage/disk/") }
    end

    context 'when file is not scanned' do
      let(:virus_scan_result) { ActiveStorage::VirusScanner::PENDING }
      it { is_expected.to include("/rails/active_storage/disk/") }
    end

    context 'when file is infected' do
      let(:virus_scan_result) { ActiveStorage::VirusScanner::INFECTED }
      it { is_expected.to be_nil }
    end
  end
end
