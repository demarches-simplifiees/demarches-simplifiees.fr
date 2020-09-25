require 'active_storage_validations/matchers'

describe Champs::PieceJustificativeChamp do
  include ActiveStorageValidations::Matchers

  describe "skip_validation is not set anymore" do
    subject { champ_pj.type_de_champ.skip_pj_validation }

    context 'before_save' do
      let(:champ_pj) { build (:champ_piece_justificative) }
      it { is_expected.to be_falsy }
    end
    context 'after_save' do
      let(:champ_pj) { create (:champ_piece_justificative) }
      it { is_expected.to be_falsy }
    end
  end

  describe "validations" do
    let(:champ_pj) { create(:champ_piece_justificative) }
    subject { champ_pj }

    context "by default" do
      it { is_expected.to validate_size_of(:piece_justificative_file).less_than(Champs::PieceJustificativeChamp::MAX_SIZE) }
      it { expect(champ_pj.type_de_champ.skip_pj_validation).to be_falsy }
    end

    context "when validation is disabled" do
      before { champ_pj.type_de_champ.update(skip_pj_validation: true) }

      it { is_expected.not_to validate_size_of(:piece_justificative_file).less_than(Champs::PieceJustificativeChamp::MAX_SIZE) }
    end
  end

  describe "#for_export" do
    let(:champ_pj) { create(:champ_piece_justificative) }
    subject { champ_pj.for_export }

    it { is_expected.to eq('toto.txt') }

    context 'without attached file' do
      before { champ_pj.piece_justificative_file.purge }
      it { is_expected.to eq(nil) }
    end
  end

  describe '#for_api' do
    let(:champ_pj) { create(:champ_piece_justificative) }
    let(:metadata) { champ_pj.piece_justificative_file.blob.metadata }

    before { champ_pj.piece_justificative_file.blob.update(metadata: metadata.merge(virus_scan_result: status)) }

    subject { champ_pj.for_api }

    context 'when file is safe' do
      let(:status) { ActiveStorage::VirusScanner::SAFE }
      it { is_expected.to include("/rails/active_storage/disk/") }
    end

    context 'when file is not scanned' do
      let(:status) { ActiveStorage::VirusScanner::PENDING }
      it { is_expected.to include("/rails/active_storage/disk/") }
    end

    context 'when file is infected' do
      let(:status) { ActiveStorage::VirusScanner::INFECTED }
      it { is_expected.to be_nil }
    end
  end
end
