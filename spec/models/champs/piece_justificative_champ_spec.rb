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
      it do
        is_expected.to validate_size_of(:piece_justificative_file).less_than(Champs::PieceJustificativeChamp::FILE_MAX_SIZE)
        is_expected.to validate_content_type_of(:piece_justificative_file).rejecting('application/x-ms-dos-executable')
        expect(champ.type_de_champ.skip_pj_validation).to be_falsy
      end
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

  describe 'dynamic validations' do
    context 'titre_identite nature' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative, nature: 'TITRE_IDENTITE' }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champ) { dossier.champs.first }

      it 'accepts jpeg under 20MB' do
        champ.piece_justificative_file.purge
        champ.piece_justificative_file.attach(io: StringIO.new('x' * 1024), filename: 'id.jpg', content_type: 'image/jpeg')
        expect(champ.valid?(:champs_public_value)).to be true
      end

      it 'rejects pdf' do
        champ.piece_justificative_file.purge
        champ.piece_justificative_file.attach(io: StringIO.new('x'), filename: 'id.pdf', content_type: 'application/pdf')
        expect(champ.valid?(:champs_public_value)).to be false
        expect(champ.errors[:piece_justificative_file]).to be_present
      end

      it 'rejects file bigger than 20MB' do
        champ.piece_justificative_file.purge
        champ.piece_justificative_file.attach(io: StringIO.new('x'), filename: 'id.jpg', content_type: 'image/jpeg')
        champ.piece_justificative_file.first.blob.update(byte_size: 21.megabytes)
        expect(champ.valid?(:champs_public_value)).to be false
        expect(champ.errors[:piece_justificative_file]).to be_present
      end
    end

    context 'pj_limit_formats with document_texte' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative, pj_limit_formats: '1', pj_format_families: ['document_texte'] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champ) { dossier.champs.first }

      it 'accepts pdf' do
        champ.piece_justificative_file.purge
        champ.piece_justificative_file.attach(io: StringIO.new('x'), filename: 'doc.pdf', content_type: 'application/pdf')
        expect(champ.valid?(:champs_public_value)).to be true
      end

      it 'rejects zip' do
        champ.piece_justificative_file.purge
        champ.piece_justificative_file.attach(io: StringIO.new('x'), filename: 'arc.zip', content_type: 'application/zip')
        expect(champ.valid?(:champs_public_value)).to be false
        expect(champ.errors[:piece_justificative_file]).to be_present
      end
    end

    context 'pj_limit_formats enabled with empty families' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative, pj_limit_formats: '1', pj_format_families: [] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champ) { dossier.champs.first }

      it 'accepts pdf' do
        champ.piece_justificative_file.purge
        champ.piece_justificative_file.attach(io: StringIO.new('x'), filename: 'doc.pdf', content_type: 'application/pdf')
        expect(champ.valid?(:champs_public_value)).to be true
      end

      it 'accepts zip' do
        champ.piece_justificative_file.purge
        champ.piece_justificative_file.attach(io: StringIO.new('x'), filename: 'arc.zip', content_type: 'application/zip')
        expect(champ.valid?(:champs_public_value)).to be true
      end
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

    describe "waiting_for_external_data?" do
      context "not RIB" do
        let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
        it { expect(champ.waiting_for_external_data?).to be_falsey }
      end

      context "empty" do
        before { champ.piece_justificative_file.purge }
        it { expect(champ.waiting_for_external_data?).to be_falsey }
      end

      context "pending" do
        it { expect(champ.waiting_for_external_data?).to be_truthy }
      end

      context "done" do
        before { champ.update(value_json: 'yolo') }
        it { expect(champ.waiting_for_external_data?).to be_falsey }
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
        before { champ.update(value_json: 'yolo') }
        it { expect(champ.external_data_fetched?).to be_truthy }
      end
    end

    describe "#external_error_present?" do
      context 'an error is present' do
        before { champ.update(fetch_external_data_exceptions: [ExternalDataException.new(reason: 'oops', code: 123)]) }

        it { expect(champ.external_error_present?).to be_truthy }
      end
    end

    describe "cleaning up" do
      let(:dossier) { create(:dossier, procedure:) }

      describe 'when there already is a file' do
        before do
          champ.piece_justificative_file.attach(io: StringIO.new('test'), filename: 'test.txt')
          champ.update_columns(value_json: "stuff")
        end

        it "cleans up the value_json when the file is purged and the champ is saved" do
          expect do
            champ.piece_justificative_file.purge
            champ.save
          end.to change { champ.value_json }.from("stuff").to(nil)
        end
      end

      describe 'when there is no previous file but some old data' do
        before { champ.update_columns(value_json: "stuff") }

        it "cleans up the value_json when the file is attached again" do
          expect do
            champ.piece_justificative_file.attach(io: StringIO.new('new content'), filename: 'new.txt')
            champ.save
          end.to change { champ.value_json }.from("stuff").to(nil)
        end
      end
    end
  end
end
