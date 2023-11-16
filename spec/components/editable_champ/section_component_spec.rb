describe EditableChamp::SectionComponent, type: :component do
  include TreeableConcern
  include Logic
  let(:component) { described_class.new(champs: champs) }
  subject { render_inline(component).to_html }

  context 'list of champs without an header_section' do
    let(:champs) { [build(:champ_text), build(:champ_textarea)] }

    it 'render in a fieldset' do
      expect(subject).to have_selector("fieldset", count: 1)
    end

    it 'renders champs' do
      expect(subject).to have_selector("input[type=text]", count: 1)
      expect(subject).to have_selector("textarea", count: 1)
    end
  end

  context 'list of champs with an header_section' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_text), build(:champ_textarea)] }

    it 'renders fieldset' do
      expect(subject).to have_selector("fieldset")
      expect(subject).to have_selector("legend h2")
    end

    it 'renders champs within fieldset' do
      expect(subject).to have_selector("fieldset input[type=text]")
      expect(subject).to have_selector("fieldset textarea")
    end
  end

  context 'list of champs without section and an header_section having champs' do
    let(:champs) { [build(:champ_text), build(:champ_header_section_level_1), build(:champ_text)] }

    it 'renders fieldset' do
      expect(subject).to have_selector("fieldset", count: 2)
      expect(subject).to have_selector("legend h2")
    end

    it 'renders all champs, each in its fieldset' do
      expect(subject).to have_selector("input[type=text]", count: 2)
      expect(subject).to have_selector("fieldset > .fr-fieldset__element input[type=text]", count: 2)
    end

    context 'when champ before section is conditionnable and section have a condition' do
      let(:dossier) { create(:dossier) }
      let(:tdc_header_section) { champs[1].type_de_champ }
      let(:tdc_checkbox) { champs[0].type_de_champ }
      let(:condition) { ds_eq(champ_value(tdc_checkbox.stable_id), constant(true)) }

      before do
        tdc_header_section.condition = condition
        tdc_header_section.save!
      end

      context 'when condition is true' do
        let(:champs) { [create(:champ_checkbox, dossier:, value: 'true'), create(:champ_header_section_level_1, dossier:), create(:champ_text, dossier:)] }

        it 'renders fieldset' do
          expect(subject).to have_selector(".hidden", count: 0)
        end
      end

      context 'when condition is false' do
        let(:champs) { [create(:champ_checkbox, dossier:, value: 'false'), create(:champ_header_section_level_1, dossier:), create(:champ_text, dossier:)] }

        it 'renders fieldset' do
          expect(subject).to have_selector(".hidden", count: 1)
        end
      end
    end
  end

  context 'list of header_section without champs' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_header_section_level_2), build(:champ_header_section_level_3)] }

    it 'render header within fieldset' do
      expect(subject).to have_selector("fieldset > legend", count: 3)
      expect(subject).to have_selector("h2")
      expect(subject).to have_selector("h3")
      expect(subject).to have_selector("h4")
    end
  end

  context 'header_section followed by explication and another fieldset' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_explication), build(:champ_header_section_level_1), build(:champ_text)] }

    it 'render fieldset, header_section, also render explication' do
      expect(subject).to have_selector("h2", count: 2)
      expect(subject).to have_selector("h3") # explication
      expect(subject).to have_selector("fieldset > legend > h2", count: 2)
      expect(subject).to have_selector("fieldset input[type=text]", count: 1)
    end
  end

  context 'nested fieldsset' do
    let(:champs) { [build(:champ_header_section_level_1), build(:champ_text), build(:champ_header_section_level_2), build(:champ_textarea)] }

    it 'render nested fieldsets' do
      expect(subject).to have_selector("fieldset")
      expect(subject).to have_selector("legend h2")
      expect(subject).to have_selector("fieldset fieldset")
      expect(subject).to have_selector("fieldset fieldset legend h3")
    end

    it 'contains all champs' do
      expect(subject).to have_selector("fieldset input[type=text]", count: 1)
      expect(subject).to have_selector("fieldset fieldset textarea", count: 1)
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
      expect(subject).to have_selector("fieldset")
      expect(subject).to have_selector("legend h2")
      expect(subject).to have_selector("fieldset fieldset")
      expect(subject).to have_selector("fieldset fieldset legend h3")
    end

    it 'contains as many text champ as repetition.rows' do
      expect(subject).to have_selector("fieldset fieldset input[type=text]", count: dossier.champs_public.find(&:repetition?).rows.size)
    end
  end

  context 'with complex markup structure' do
    def check_fieldset_structure(fieldset)
      expect(fieldset[:class]).to include('fr-fieldset')

      # Vérifie que chaque fr-fieldset a un enfant fr-fieldset__element ou une légende
      fieldset.all('> *').each do |child|
        expect(child.tag_name).to be_in(['div', 'legend', 'input'])

        case child.tag_name
        when 'legend'
          expect(child[:class]).to include('fr-fieldset__legend')
        when 'input'
          expect(child[:type]).to eq("hidden")
        else
          expect(child[:class]).to include('fr-fieldset__element')
          # Vérifie récursivement les fieldsets imbriqués
          child.all('> fieldset').each do |nested_fieldset|
            check_fieldset_structure(nested_fieldset)
          end
        end
      end
    end

    let(:champs) {
      [
        build(:champ_header_section_level_1),
        build(:champ_header_section_level_2),
        build(:champ_header_section_level_3),
        build(:champ_integer_number),

        build(:champ_header_section_level_3),
        build(:champ_yes_no),

        build(:champ_header_section_level_2),
        build(:champ_header_section_level_3),
        build(:champ_integer_number),

        build(:champ_header_section_level_1),
        build(:champ_text),
        build(:champ_header_section_level_2),
        build(:champ_text)
      ]
    }

    it 'respect dsfr fieldset hierarchy' do
      within('.dossier-edit .form') do
        all('fieldset').each do |fieldset|
          check_fieldset_structure(fieldset)
        end
      end
    end
  end
end
