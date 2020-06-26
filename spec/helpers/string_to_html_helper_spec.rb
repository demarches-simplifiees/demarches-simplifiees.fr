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

    context "with a table" do
      let(:description) { "Table des enfants\n<table class='table table-striped'><tr><th>Enfant</th></tr><tr><td>Riri</td></tr></table>\net une phrase\n" }
      it { is_expected.to eq "<p>Table des enfants\n<br></p><table class=\"table table-striped\">\n<tr><th>Enfant</th></tr>\n<tr><td>Riri</td></tr>\n</table>\net une phrase\n<br>" }
    end

    context "with a list" do
      let(:description) { "Avec une liste\n<ul><li>Liste d'éléments</li></ul><ol><li>Liste d'éléments</li></ol>\net une phrase\n" }
      it { is_expected.to eq "<p>Avec une liste\n<br></p><ul><li>Liste d'éléments</li></ul><ol><li>Liste d'éléments</li></ol>\net une phrase\n<br>" }
    end
  end
end
