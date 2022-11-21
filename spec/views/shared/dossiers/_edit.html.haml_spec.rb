describe 'shared/dossiers/edit.html.haml', type: :view do
  before do
    allow(controller).to receive(:current_user).and_return(dossier.user)
    allow(view).to receive(:administrateur_signed_in?).and_return(false)
  end

  subject { render 'shared/dossiers/edit.html.haml', dossier: dossier, apercu: false }

  context 'when there are some champs' do
    let(:dossier) { create(:dossier) }
    let(:champ_checkbox) { create(:champ_checkbox, dossier: dossier, value: 'on') }
    let(:champ_header_section) { create(:champ_header_section, dossier: dossier, value: 'Section') }
    let(:champ_explication) { create(:champ_explication, dossier: dossier, value: 'mazette') }
    let(:champ_dossier_link) { create(:champ_dossier_link, dossier: dossier, value: dossier.id) }
    let(:champ_textarea) { create(:champ_textarea, dossier: dossier, value: 'Some long text in a textarea.') }
    let(:champs) { [champ_checkbox, champ_header_section, champ_explication, champ_dossier_link, champ_textarea] }

    before { dossier.champs_public << champs }

    it 'renders labels and editable values of champs' do
      expect(subject).to have_field(champ_checkbox.libelle, checked: true)
      expect(subject).to have_css(".header-section", text: champ_header_section.libelle)
      expect(subject).to have_text(champ_explication.libelle)
      expect(subject).to have_field(champ_dossier_link.libelle, with: champ_dossier_link.value)
      expect(subject).to have_field(champ_textarea.libelle, with: champ_textarea.value)
    end

    context "with standard champs" do
      let(:champ_email) { create(:champ_email, dossier: dossier) }
      let(:champ_phone) { create(:champ_phone, dossier: dossier) }
      let(:champs) { [champ_email, champ_phone] }

      it "renders basic placeholders" do
        expect(subject).to have_css('input[type="email"][placeholder$="exemple.fr"]')
        expect(subject).to have_css('input[type="tel"][placeholder^="0612"]')
      end
    end
  end

  context 'with a single-value list' do
    let(:dossier) { create(:dossier) }
    let(:type_de_champ) { create(:type_de_champ_drop_down_list, mandatory: mandatory, procedure: dossier.procedure) }
    let(:champ) { create(:champ_drop_down_list, dossier: dossier, type_de_champ: type_de_champ) }
    let(:options) { type_de_champ.drop_down_list_options }
    let(:enabled_options) { type_de_champ.drop_down_list_enabled_non_empty_options }
    let(:mandatory) { true }

    before { dossier.champs_public << champ }

    context 'when the list is short' do
      it 'renders the list as radio buttons' do
        expect(subject).to have_selector('input[type=radio]', count: enabled_options.count)
      end

      context 'when the champ is optional' do
        let(:mandatory) { false }

        it 'allows unselecting a previously selected value' do
          expect(subject).to have_selector('input[type=radio]', count: enabled_options.count + 1)
          expect(subject).to have_unchecked_field('Non renseigné', count: 1)
        end
      end
    end

    context 'when the list is long' do
      let(:type_de_champ) { create(:type_de_champ_drop_down_list, :long, procedure: dossier.procedure) }

      it 'renders the list as a dropdown' do
        expect(subject).to have_select(type_de_champ.libelle, options: options)
      end
    end
  end

  context 'with a multiple-values list' do
    let(:dossier) { create(:dossier) }
    let(:type_de_champ) { create(:type_de_champ_multiple_drop_down_list, procedure: dossier.procedure, drop_down_list_value: drop_down_list_value) }
    let(:champ) { create(:champ_multiple_drop_down_list, dossier: dossier, type_de_champ: type_de_champ, value: champ_value) }
    let(:options) { type_de_champ.drop_down_list_options }
    let(:enabled_options) { type_de_champ.drop_down_list_enabled_non_empty_options }

    before { dossier.champs_public << champ }

    context 'when the list is short' do
      let(:drop_down_list_value) { ['valid', 'invalid', 'not sure yet'].join("\r\n") }
      let(:champ_value) { ['invalid'].to_json }

      it 'renders the list as checkboxes' do
        expect(subject).to have_selector('input[type=checkbox]', count: enabled_options.count)
        expect(subject).to have_selector('input[type=checkbox][checked=checked]', count: 1)
      end

      it 'adds an extra hidden input, to send a blank value even when all checkboxes are unchecked' do
        expect(subject).to have_selector('input[type=hidden][value=""]')
      end
    end

    context 'when the list is long' do
      let(:drop_down_list_value) { ['peach', 'banana', 'pear', 'apricot', 'apple', 'grapefruit'].join("\r\n") }
      let(:champ_value) { ['banana', 'grapefruit'].to_json }

      it 'renders the list as a multiple-selection dropdown' do
        expect(subject).to have_selector('[data-react-component-value="ComboMultipleDropdownList"]')
      end
    end
  end

  context 'with a mandatory piece justificative' do
    let(:dossier) { create(:dossier) }
    let(:type_de_champ) { create(:type_de_champ_piece_justificative, procedure: dossier.procedure, mandatory: true) }
    let(:champ) { create(:champ_piece_justificative, dossier: dossier, type_de_champ: type_de_champ) }

    context 'when dossier is en construction' do
      let(:dossier) { create(:dossier, :en_construction) }
      before { dossier.champs_public << champ }

      it 'cannot delete a piece justificative' do
        expect(subject).not_to have_selector("[title='Supprimer le fichier #{champ.piece_justificative_file.attachments[0].filename}']")
      end
    end

    context 'when dossier is brouillon' do
      before do
        dossier.champs_public << champ
      end

      it 'can delete a piece justificative' do
        expect(subject).to have_selector("[title='Supprimer le fichier #{champ.piece_justificative_file.attachments[0].filename}']")
      end
    end
  end

  context 'with a routed procedure' do
    let(:procedure) do
      create(:procedure,
        :routee,
        routing_criteria_name: 'departement')
    end
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:champs) { [] }

    it 'renders the routing criteria name and its value' do
      expect(subject).to have_field(procedure.routing_criteria_name)
    end

    context 'when groupe instructeur is selected' do
      before do
        dossier.groupe_instructeur = dossier.procedure.defaut_groupe_instructeur
      end

      it 'renders the routing criteria name and its value' do
        expect(subject).to have_field(procedure.routing_criteria_name)
        expect(subject).to include(dossier.groupe_instructeur.label)
      end
    end
  end
end
