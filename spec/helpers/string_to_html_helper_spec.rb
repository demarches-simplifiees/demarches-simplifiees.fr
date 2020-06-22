RSpec.describe StringToHtmlHelper, type: :helper do
  describe "#string_to_html" do
    subject { string_to_html(description) }

    context "with some simple texte" do
      let(:description) { "1er ligne \n 2ieme ligne" }

      it { is_expected.to eq("<p>1er ligne \n<br> 2ieme ligne</p>") }
    end

    context "with a link" do
      context "using an authorized scheme" do
        let(:description) { "Cliquez sur https://d-s.fr pour continuer." }
        it { is_expected.to eq("<p>Cliquez sur <a href=\"https://d-s.fr\" target=\"_blank\" rel=\"noopener\">https://d-s.fr</a> pour continuer.</p>") }
      end

      context "using a non-authorized scheme" do
        let(:description) { "Cliquez sur file://etc/password pour continuer." }
        it { is_expected.to eq("<p>Cliquez sur file://etc/password pour continuer.</p>") }
      end

      context "not actually an URL" do
        let(:description) { "Pour info: il ne devrait y avoir aucun lien." }
        it { is_expected.to eq("<p>Pour info: il ne devrait y avoir aucun lien.</p>") }
      end
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
