describe 'shared/dossiers/edit.html.haml', type: :view do
  before do
    allow(controller).to receive(:current_user).and_return(dossier.user)
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

    before { dossier.champs << champs }

    it 'renders labels and editable values of champs' do
      expect(subject).to have_field(champ_checkbox.libelle, checked: true)
      expect(subject).to have_css(".header-section", text: champ_header_section.libelle)
      expect(subject).to have_text(champ_explication.libelle)
      expect(subject).to have_field(champ_dossier_link.libelle, with: champ_dossier_link.value)
      expect(subject).to have_field(champ_textarea.libelle, with: champ_textarea.value)
    end
  end

  context 'with a single-value list' do
    let(:dossier) { create(:dossier) }
    let(:type_de_champ) { create(:type_de_champ_drop_down_list, mandatory: mandatory, procedure: dossier.procedure) }
    let(:champ) { create(:champ_drop_down_list, dossier: dossier, type_de_champ: type_de_champ) }
    let(:options) { champ.options }
    let(:enabled_options) { type_de_champ.drop_down_list_enabled_non_empty_options }
    let(:mandatory) { true }

    before { dossier.champs << champ }

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
        pp subject
        expect(subject).to have_select(type_de_champ.libelle, options: options)
      end
    end
  end

  context 'with a multiple-values list' do
    let(:dossier) { create(:dossier) }
    let(:type_de_champ) { create(:type_de_champ_multiple_drop_down_list, procedure: dossier.procedure) }
    let(:champ) { create(:champ_multiple_drop_down_list, dossier: dossier, type_de_champ: type_de_champ) }
    let(:options) { type_de_champ.drop_down_list_options }
    let(:enabled_options) { type_de_champ.drop_down_list_enabled_non_empty_options }

    before { dossier.champs << champ }

    context 'when the list is short' do
      it 'renders the list as checkboxes' do
        expect(subject).to have_selector('input[type=checkbox]', count: enabled_options.count)
      end

      it 'adds an extra hidden input, to send a blank value even when all checkboxes are unchecked' do
        expect(subject).to have_selector('input[type=hidden][value=""]')
      end
    end

    context 'when the list is long' do
      let(:type_de_champ) { create(:type_de_champ_multiple_drop_down_list, :long, procedure: dossier.procedure) }

      it 'renders the list as a multiple-selection dropdown' do
        expect(subject).to have_selector('[data-react-class="ComboMultipleDropdownList"]')
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
      expect(subject).to include(dossier.groupe_instructeur.label)
    end
  end
end
