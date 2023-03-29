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
      TEXT
    end

    context 'enabled' do
      let(:allow_a) { true }
      it { expect(page).to have_selector("a") }
    end

    context 'disabled' do
      it { expect(page).not_to have_selector("a") }
    end
  end
end
