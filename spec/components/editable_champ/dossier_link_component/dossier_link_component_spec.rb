RSpec.describe EditableChamp::DossierLinkComponent, type: :component do
  let(:form) { instance_double("Form", object: instance_double("Object")) }

  let(:component) { described_class.new(form: form, champ: champ) }
  let(:champ) { instance_double(Champ, describedby_id: 'describedby_id', error_id: 'error_id', description: 'description', input_id: 'input_id', public_id: 'public_id', blank?: false, to_s: '123') }
  let(:type_de_champ) { instance_double(TypeDeChamp, procedures: [procedure]) }
  let(:procedure) { instance_double(Procedure, id: 1, libelle: 'Procedure 1', dossiers: [dossier]) }
  let(:dossier) { instance_double(Dossier, id: 123, user: current_user, state: 'deposé', depose_at: Time.zone.now) }
  let(:current_user) { instance_double(User) }

  before do
    allow(champ).to receive(:type_de_champ).and_return(type_de_champ)
    allow(dossier).to receive(:user).and_return(current_user)
    allow(component).to receive(:current_user).and_return(current_user)
    allow(Dossier).to receive(:visible_by_administration).and_return(Dossier)
    allow(Dossier).to receive(:find_by).with(id: '123').and_return(dossier)
  end

  describe '#dsfr_input_classname' do
    it 'renvoie le nom de classe pour l\'élément d\'entrée' do
      expect(component.send(:dsfr_input_classname)).to eq('fr-input')
    end
  end
  describe '#dossier' do
    it 'renvoie le dossier associé au champ' do
      expect(component.send(:dossier)).to eq(dossier)
    end
  end

  describe '#other_element_class_names' do
    it 'renvoie les noms de classe pour les autres éléments' do
      expect(component.send(:other_element_class_names)).to include('fr-fieldset__element')
    end
  end

  describe '#dossier' do
    it 'renvoie le dossier associé au champ' do
      expect(component.send(:dossier)).to eq(dossier)
    end
  end

  describe '#dossier_options_for' do
    it 'renvoie les options pour la sélection de dossier' do
      options = component.send(:dossier_options_for, champ)
      expect(options).to include({ value: "separator_1", label: "-- Démarche : Procedure 1 --" })
      expect(options).to include({ value: "123", label: "N° 123 - déposé le #{dossier.depose_at.strftime('%d/%m/%Y')}" })
    end
  end

  describe '#react_props' do
    it 'renvoie les props pour le composant React' do
      props = component.send(:react_props)
      expect(props[:items]).to include({ value: "separator_1", label: "-- Démarche : Procedure 1 --" })
      expect(props[:placeholder]).to eq('Sélectionnez un dossier')
      expect(props[:name]).to eq('dossier[champs_public_attributes][public_id][value]')
      expect(props[:id]).to eq('input_id')
      expect(props[:class]).to eq('small-margin')
    end
  end

  describe '#render_dossiers' do
    it 'renvoie les dossiers à rendre' do
      expect(component.send(:render_dossiers)).to eq([dossier])
    end
  end

  describe '#render_as_radios?' do
    it 'renvoie true s\'il y a 5 dossiers ou moins' do
      expect(component.send(:render_as_radios?)).to be_truthy
    end

    it 'renvoie false s\'il y a plus de 5 dossiers' do
      allow(procedure).to receive(:dossiers).and_return(Array.new(6) { dossier })
      expect(component.send(:render_as_radios?)).to be_falsy
    end
  end

  describe '#render_as_combobox?' do
    it 'renvoie true s\'il y a 20 dossiers ou plus' do
      allow(procedure).to receive(:dossiers).and_return(Array.new(20) { dossier })
      expect(component.send(:render_as_combobox?)).to be_truthy
    end

    it 'renvoie false s\'il y a moins de 20 dossiers' do
      expect(component.send(:render_as_combobox?)).to be_falsy
    end
  end

  describe '#contains_long_option?' do
    it 'renvoie true si l\'une des étiquettes d\'option est plus longue que 100 caractères' do
      long_option = { value: 'long_option', label: 'a' * 101 }
      allow(component).to receive(:dossier_options_for).and_return([long_option])
      expect(component.send(:contains_long_option?)).to be_truthy
    end

    it 'renvoie false si toutes les étiquettes d\'option ont 100 caractères ou moins' do
      expect(component.send(:contains_long_option?)).to be_falsy
    end
  end
end