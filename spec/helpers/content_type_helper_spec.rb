RSpec.describe ContentTypeHelper, type: :helper do
  describe ".file_descriptions_from_content_types" do
    subject { file_descriptions_from_content_types(content_types) }

    context "when a content-type does not exist" do
      let(:content_types) { ['invalid content type'] }
      it { is_expected.to eq("") }
    end

    context "when a content type is valid" do
      let(:content_types) { ["application/msword"] }
      it { is_expected.to eq 'Word' }
    end

    context "when two content types have the same description" do
      let(:content_types) { ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/vnd.ms-excel"] }
      it { is_expected.to eq 'Excel' }
    end

    context "when two content types have different descriptions" do
      let(:content_types) { ["application/msword", "application/vnd.ms-excel"] }
      it { is_expected.to eq 'Word, Excel' }
    end
  end

  describe ".file_extensions_from_content_types" do
    subject { file_extensions_from_content_types(content_types) }

    context "when a content-type does not exist" do
      let(:content_types) { ['invalid content type'] }
      it { is_expected.to eq("") }
    end

    context "when a content type is valid" do
      let(:content_types) { ["application/msword"] }
      it { is_expected.to eq '.doc' }
    end

    context "when two content types have different extensions" do
      let(:content_types) { ["application/vnd.ms-excel", "application/msword"] }
      it { is_expected.to eq '.doc, .xls' }
    end
  end
end
