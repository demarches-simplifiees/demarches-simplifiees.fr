RSpec.describe StringToHtmlHelper, type: :helper do
  describe "#string_to_html" do
    subject { string_to_html(description) }

    context "with some simple texte" do
      let(:description) { "1er ligne \n 2ieme ligne" }

      it { is_expected.to eq("<p>1er ligne \n<br> 2ieme ligne</p>") }
    end

    context "with a link" do
      let(:description) { "https://d-s.fr" }

      it { is_expected.to eq("<p><a target=\"_blank\" rel=\"noopener\" href=\"https://d-s.fr\">https://d-s.fr</a></p>") }
    end

    context "with empty decription" do
      let(:description) { nil }

      it { is_expected.to eq('<p></p>') }
    end

    context "with a bad script" do
      let(:description) { '<script>bad</script>' }

      it { is_expected.to eq('<p>bad</p>') }
    end
  end
end
