# frozen_string_literal: true

require 'active_storage_validations/matchers'

describe Champs::PieceJustificativeChamp do
  include ActiveStorageValidations::Matchers

  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }

  describe "validations" do
    subject { champ }

    context "by default" do
      it { is_expected.to validate_size_of(:piece_justificative_file).less_than(Champs::PieceJustificativeChamp::FILE_MAX_SIZE) }
      it { is_expected.to validate_content_type_of(:piece_justificative_file).rejecting('application/x-ms-dos-executable') }
      it { expect(champ.type_de_champ.skip_pj_validation).to be_falsy }
    end

    context "when validation is disabled" do
      before { champ.type_de_champ.update(skip_pj_validation: true) }

      it { is_expected.not_to validate_size_of(:piece_justificative_file).on(:champs_public_value).less_than(Champs::PieceJustificativeChamp::FILE_MAX_SIZE) }
    end

    context "when content-type validation is disabled" do
      before { champ.type_de_champ.update(skip_content_type_pj_validation: true) }

      it { is_expected.not_to validate_content_type_of(:piece_justificative_file).on(:champs_public_value).rejecting('application/x-ms-dos-executable') }
    end
  end

  describe "#for_export" do
    subject { champ.type_de_champ.champ_value_for_export(champ) }

    it { is_expected.to eq('toto.txt') }

    context 'without attached file' do
      before { champ.piece_justificative_file.purge }
      it { is_expected.to eq(nil) }
    end
  end

  describe '#for_api' do
    before { champ.piece_justificative_file.first.blob.update(virus_scan_result:) }

    subject { champ.type_de_champ.champ_value_for_api(champ, version: 1) }

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

  context "external_data" do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative, nature: 'RIB' }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champs.first }

    describe "fetch_external_data_pending?" do
      context "not RIB" do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
        it { expect(champ.fetch_external_data_pending?).to be_falsey }
      end

      context "empty" do
        before { champ.piece_justificative_file.purge }
        it { expect(champ.fetch_external_data_pending?).to be_falsey }
      end

      context "pending" do
        it { expect(champ.fetch_external_data_pending?).to be_truthy }
      end

      context "done" do
        before { champ.piece_justificative_file.blobs.first.update(ocr: 'yolo') }
        it { expect(champ.fetch_external_data_pending?).to be_falsey }
      end
    end

    describe "external_data_fetched?" do
      context "not RIB" do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
        it { expect(champ.external_data_fetched?).to be_falsey }
      end

      context "empty" do
        before { champ.piece_justificative_file.purge }
        it { expect(champ.external_data_fetched?).to be_falsey }
      end

      context "pending" do
        it { expect(champ.external_data_fetched?).to be_falsey }
      end

      context "done" do
        before { champ.piece_justificative_file.blobs.first.update(ocr: 'yolo') }
        it { expect(champ.external_data_fetched?).to be_truthy }
      end
    end
  end
end
