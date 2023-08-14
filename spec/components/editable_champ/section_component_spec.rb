describe EditableChamp::SectionComponent, type: :component do
  include TreeableConcern
  let(:component) { described_class.new(champs: champs) }
  before { render_inline(component).to_html }

  context 'list of champs without an header_section' do
    let(:champs) { [build(:champ_text), build(:champ_textarea)] }

    it 'does not render fieldset' do
      expect(page).not_to have_selector("fieldset")
    end

    it 'renders champs' do
      expect(page).to have_selector("input[type=text]", count: 1)
      expect(page).to have_selector("textarea", count: 1)
    end
  end

  context 'list of champs with an header_section' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_text), build(:champ_textarea)] }

    it 'renders fieldset' do
      expect(page).to have_selector("fieldset")
      expect(page).to have_selector("legend h2")
    end

    it 'renders champs within fieldset' do
      expect(page).to have_selector("fieldset input[type=text]")
      expect(page).to have_selector("fieldset textarea")
    end
  end

  context 'list of champs without section and an header_section having champs' do
    let(:champs) { [build(:champ_text), build(:champ_header_section_level_1), build(:champ_text)] }

    it 'renders fieldset' do
      expect(page).to have_selector("fieldset")
      expect(page).to have_selector("legend h2")
    end

    it 'renders all champs, one outside fieldset, one within fieldset' do
      expect(page).to have_selector("input[type=text]", count: 2)
      expect(page).to have_selector("fieldset input[type=text]", count: 1)
    end
  end

  context 'list of header_section without champs' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_header_section_level_2), build(:champ_header_section_level_3)] }

    it 'does not render header within fieldset' do
      expect(page).not_to have_selector("fieldset")
      expect(page).to have_selector("h2")
      expect(page).to have_selector("h3")
      expect(page).to have_selector("h4")
    end
  end

  context 'header_section followed by explication and another fieldset' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_explication), build(:champ_header_section_level_1), build(:champ_text)] }

    it 'render fieldset, header_section (one within fieldset, one outside), also render explication' do
      expect(page).to have_selector("h2", count: 2)
      expect(page).to have_selector("h3") # explication
      expect(page).to have_selector("fieldset h2", count: 1)
      expect(page).to have_selector("fieldset input[type=text]", count: 1)
    end
  end

  context 'nested fieldsset' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_text), build(:champ_header_section_level_2), build(:champ_textarea)] }

    it 'render nested fieldsets' do
      expect(page).to have_selector("fieldset")
      expect(page).to have_selector("legend h2")
      expect(page).to have_selector("fieldset fieldset")
      expect(page).to have_selector("fieldset fieldset legend h3")
    end

    it 'contains all champs' do
      expect(page).to have_selector("fieldset input[type=text]", count: 1)
      expect(page).to have_selector("fieldset fieldset textarea", count: 1)
    end
  end

  context 'with repetition' do
    let(:procedure) do
      create(:procedure, types_de_champ_public: [
        { type: :header_section, header_section_level: 1 },
        {
          type: :repetition,
          libelle: 'repetition',
          children: [
            { type: :header_section, header_section_level: 1, libelle: 'child_1' },
            { type: :text, libelle: 'child_2' }
          ]
        }
      ])
    end
    let(:dossier) { create(:dossier, :with_populated_champs, procedure: procedure) }
    let(:champs) { dossier.champs_public }

    it 'render nested fieldsets, increase heading level for repetition header_section' do
      expect(page).to have_selector("fieldset")
      expect(page).to have_selector("legend h2")
      expect(page).to have_selector("fieldset fieldset")
      expect(page).to have_selector("fieldset fieldset legend h3")
    end

    it 'contains as many text champ as repetition.rows' do
      expect(page).to have_selector("fieldset fieldset input[type=text]", count: dossier.champs_public.find(&:repetition?).rows.size)
    end
  end
end
