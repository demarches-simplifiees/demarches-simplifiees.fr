describe SimpleFormatComponent, type: :component do
  let(:allow_a) { false }
  before { render_inline(described_class.new(text, allow_a: allow_a)) }

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
      TEXT
    end

    it { expect(page).to have_selector("ol", count: 1) }
    it { expect(page).to have_selector("li", count: 2) }
  end

  context 'auto-link' do
    let(:text) do
      <<~TEXT
        bonjour https://www.demarches-simplifiees.fr
        nohttp www.ds.io
        ecrivez à ds@rspec.io
      TEXT
    end

    context 'enabled' do
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
    end

    context 'disabled' do
      it { expect(page).not_to have_selector("a") }
    end
  end
end
