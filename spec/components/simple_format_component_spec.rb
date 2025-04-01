# frozen_string_literal: true

describe SimpleFormatComponent, type: :component do
  let(:allow_a) { false }
  let(:allow_autolink) { false }
  before { render_inline(described_class.new(text, allow_a: allow_a, allow_autolink: allow_autolink)) }

  context 'one line' do
    let(:text) do
      "1er paragraphe"
    end
    it { expect(page).to have_selector("p", count: 1, text: text) }
  end

  context 'one with leading spaces' do
    let(:text) do
      <<-TEXT
      1er paragraphe
TEXT
    end
    it { expect(page).to have_selector("p", count: 1, text: text.strip) }
  end

  context 'two lines' do
    let(:text) do
      <<~TEXT
        1er paragraphe
        2eme paragraphe
      TEXT
    end

    it { expect(page).to have_selector("p", count: 2) }
    it { text.split("\n").map(&:strip).map { expect(page).to have_text(_1) } }
  end

  context 'unordered list items' do
    let(:text) do
      <<~TEXT
        - 1er paragraphe
        - paragraphe
      TEXT
    end

    it { expect(page).to have_selector("ul", count: 1) }
    it { expect(page).to have_selector("li", count: 2) }
  end

  context 'ordered list items' do
    let(:text) do
      <<~TEXT
        1. 1er paragraphe
        2. paragraphe
        4. 4eme paragraphe
      TEXT
    end

    it { expect(page).to have_selector("ol", count: 1) }
    it { expect(page).to have_selector("li", count: 3) }
    it { expect(page.native.inner_html).to match('value="1"') }
    it { expect(page.native.inner_html).to match('value="4"') }
  end

  context 'multi line lists' do
    let(:text) do
      <<~TEXT
        Lorsque nous souhaitons envoyer ce message :

        1. Premier point de la recette
        Commentaire 1
        2. Deuxième point de la recette
          Commentaire 2

        4. Troisième point de la recette
        Commentaire 3

        trois nouveaux paragraphes
        sur plusieures
        lignes

        - 1er point de la recette
        * 2eme point de la recette
        avec des détailles
        + 3eme point de la recette
        beaucoup
        de détails

        conclusion
      TEXT
    end

    it { expect(page).to have_selector("ol", count: 1) }
    it { expect(page).to have_selector("ul", count: 1) }
    it { expect(page).to have_selector("li", count: 6) }
    it { expect(page).to have_selector("p", count: 5) }
  end

  context 'strong' do
    let(:text) do
      <<~TEXT
        1er paragraphe **fort** un_mot_pas_italic
      TEXT
    end

    it { expect(page).to have_selector("strong", count: 1) }
    it { expect(page).not_to have_selector("em") }
  end

  context 'auto-link' do
    let(:text) do
      <<~TEXT
        bonjour https://www.demarches-simplifiees.fr
        nohttp www.ds.io
        ecrivez à ds@rspec.io
        <a href="https://demarches.numerique.gouv.fr">lien html</a>
        [lien markdown](https://github.com)
      TEXT
    end

    context 'enabled with html links' do
      let(:allow_a) { true }
      it { expect(page).to have_selector("a") }
      it "inject expected attributes" do
        link = page.find_link("https://www.demarches-simplifiees.fr").native
        expect(link[:rel]).to eq("noopener noreferrer")
        expect(link[:title]).to eq("Nouvel onglet")
      end

      it "convert email autolinks" do
        link = page.find_link("ds@rspec.io").native
        expect(link[:href]).to eq("mailto:ds@rspec.io")
        expect(link[:rel]).to be_nil
      end

      it "convert www only" do
        link = page.find_link("www.ds.io").native
        expect(link[:href]).to eq("http://www.ds.io")
        expect(link[:rel]).to eq("noopener noreferrer")
        expect(link[:title]).to eq("Nouvel onglet")
      end

      it "render html link" do
        link = page.find_link("lien html").native
        expect(link[:href]).to eq("https://demarches.numerique.gouv.fr")
      end

      it "convert markdown link" do
        link = page.find_link("lien markdown").native
        expect(link[:href]).to eq("https://github.com")
        expect(link[:rel]).to eq("noopener noreferrer")
        expect(link[:title]).to eq("Nouvel onglet")
      end
    end

    context 'enabled only without html links' do
      let(:allow_autolink) { true }

      it "convert only visible http link, not html links" do
        expect(page).to have_link("https://www.demarches-simplifiees.fr")
        expect(page).to have_selector("a", count: 1)
      end

      it "inject expected attributes" do
        link = page.find_link("https://www.demarches-simplifiees.fr").native
        expect(link[:rel]).to eq("noopener noreferrer")
        expect(link[:title]).to include("Nouvel onglet")
      end

      context 'url ending the paragraph' do
        let(:text) { "bonjour https://www.demarches-simplifiees.fr" }

        it "does not include the closing p" do
          link = page.find_link("https://www.demarches-simplifiees.fr").native
          expect(link[:href]).to eq("https://www.demarches-simplifiees.fr")
          expect(link.text).to eq("https://www.demarches-simplifiees.fr")
        end
      end
    end

    context 'completely disabled' do
      it { expect(page).not_to have_selector("a") }
    end
  end

  context 'emphasis not in urls' do
    let(:text) do
      <<~TEXT
        A _string emphased_ but https://example.fr/path_preserves_underscore
        email: here_is_my@email.com
      TEXT
    end

    context "without autolink" do
      let(:allow_a) { false }
      it { expect(page).to have_selector("em", count: 1, text: "string emphased") }
      it { expect(page).to have_text("https://example.fr/path_preserves_underscore") }
      it { expect(page).to have_text("email: here_is_my@email.com") }
    end

    context "with autolink" do
      let(:allow_a) { true }
      it {
        expect(page).to have_link("https://example.fr/path_preserves_underscore")

        # NOTE: As of Redcarpet 3.6.0, autolinking email containing _ is broken https://github.com/vmg/redcarpet/issues/402
        # but we still want the email to be displayed
        expect(page).to have_text("here_is_my@email.com")
      }
    end
  end
end
