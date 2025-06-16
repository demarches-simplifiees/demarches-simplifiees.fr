RSpec.describe EditableChamp::DossierLinkComponent, type: :component do
  let(:form) { instance_double('Form') }
  let(:current_user) { create(:user) }
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :dossier_link}]) }
  let(:dossier) { create(:dossier, :en_construction, user: current_user, depose_at: Time.zone.now, procedure: procedure) }
  let(:champ) { dossier.champs.first }

  let(:procedures) do
    [
      create(:procedure, id: 1, libelle: "Procedure 1", aasm_state: "publiee"),
      create(:procedure, id: 2, libelle: "Procedure 2", aasm_state: "brouillon"),
      create(:procedure, id: 3, libelle: "Procedure 3", aasm_state: "close")
    ]
  end

  let(:procedures_no_in_the_limitation) do
    [
      create(:procedure, id: 4, libelle: "Procedure 4 - pas dans la limitation", aasm_state: "publiee"),
      create(:procedure, id: 5, libelle: "Procedure 5 - pas dans la limitation", aasm_state: "publiee"),
    ]
  end

  def create_dossiers(number, status, procedure_limited, hidden_by_user_at = nil)
    Array.new(number) do
      create(:dossier, status, user: current_user, depose_at: Time.zone.now, procedure: procedure_limited, hidden_by_user_at: hidden_by_user_at)
    end
  end

  before do
    allow_any_instance_of(described_class).to receive(:current_user).and_return(current_user)
    procedure.active_revision.types_de_champ.first.procedures = procedures
  end

  subject { described_class.new(form: form, champ: champ) }

  describe '#dsfr_input_classname' do
    it 'returns the class name for the input element' do
      expect(subject.send(:dsfr_input_classname)).to eq('fr-input')
    end
  end

  describe '#dossier_options_for' do
    let(:dossiers_en_construction) { create_dossiers(1, :en_construction, procedures[0]) }

    it 'returns the options for dossier selection'do
      procedures[0].dossiers = dossiers_en_construction
      subject.send(:before_render)
      options = subject.send(:dossier_options_for, champ)

      expect(options).to include({ :label => "-- Démarche : Procedure 1 --", :value => "separator_1" })
      expect(options).to include({ :label => "N° " + dossiers_en_construction[0].id.to_s + " - déposé le " + dossiers_en_construction[0].depose_at.strftime('%d/%m/%Y') , :value => dossiers_en_construction[0].id.to_s})
      expect(options).to include({ :label => "-- Démarche : Procedure 2 --", :value => "separator_2" })
      expect(options).to include({ :label => "Vous n’avez déposé aucun dossier sur cette démarche. ", :value => "no_dossier_2" })
      expect(options).to include({ :label => "-- Démarche : Procedure 3 --", :value => "separator_3" })
      expect(options).to include({ :label => "Vous n’avez déposé aucun dossier sur cette démarche. ", :value => "no_dossier_3" })
    end
  end

  describe '#react_props' do
    it 'returns the props for the React component' do
      champ.value = "toto"
      props = subject.send(:react_props)
      expect(props[:items]).to include({ value: "separator_1", label: "-- Démarche : Procedure 1 --" })
      expect(props[:placeholder]).to eq('Sélectionnez un dossier')
      expect(props[:name]).to eq("dossier[champs_public_attributes][#{champ.public_id}][value]")
      expect(props[:id]).to eq(champ.input_id)
      expect(props[:class]).to eq('small-margin')
    end
  end

  context '#render_as_radios?' do
    describe '1 dossier' do
      let(:dossiers_en_construction) { create_dossiers(1, :en_construction, procedures[0]) }
      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers' do
      let(:dossiers_en_construction) { create_dossiers(3, :en_construction, procedures[0]) }
      let(:dossiers_accepte) { create_dossiers(1, :accepte, procedures[0]) }
      let(:dossiers_refuse) { create_dossiers(1, :refuse, procedures[0]) }
      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_accepte + dossiers_refuse
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers + 2 dossiers in other procedure no limited' do
      let(:dossiers_en_construction) { create_dossiers(3, :en_construction, procedures[0]) }
      let(:dossiers_accepte) { create_dossiers(1, :accepte, procedures[0]) }
      let(:dossiers_refuse) { create_dossiers(1, :refuse, procedures[0]) }

      let(:dossiers_en_construction_no_limited_1) { create_dossiers(1, :en_construction, procedures_no_in_the_limitation[0]) }
      let(:dossiers_en_construction_no_limited_2) { create_dossiers(1, :en_construction, procedures_no_in_the_limitation[1]) }

      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_accepte + dossiers_refuse
        procedures_no_in_the_limitation[0] = dossiers_en_construction_no_limited_1
        procedures_no_in_the_limitation[1] = dossiers_en_construction_no_limited_2
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers + 1 dossier brouillon' do
      let(:dossiers_en_construction) { create_dossiers(5, :en_construction, procedures[0]) }
      let(:dossiers_brouillon) { create_dossiers(1, :brouillon, procedures[0]) }
      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_brouillon
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '5 dossiers + 1 dossier supprime' do
      let(:dossiers_en_construction) { create_dossiers(5, :en_construction, procedures[0]) }
      let(:dossiers_supprime) { create_dossiers(1, :en_construction, procedures[0], 1.day.ago) }
      it {
        procedures[0].dossiers = dossiers_en_construction + dossiers_supprime
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_truthy
      }
    end

    describe '6 dossiers' do
      let(:dossiers_en_construction) { create_dossiers(6, :en_construction, procedures[0]) }

      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_radios?)).to be_falsey
      }
    end
  end

  context '#render_as_combobox?' do
    describe 'returns true if there 20 dossiers or more' do
      let(:dossiers_en_construction) { create_dossiers(20, :en_construction, procedures[0]) }

      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_combobox?)).to be_truthy
      }
    end

    describe 'returns false if there are less than 20 dossiers' do
      let(:dossiers_en_construction) { create_dossiers(19, :en_construction, procedures[0]) }

      it {
        procedures[0].dossiers = dossiers_en_construction
        subject.send(:before_render)
        expect(subject.send(:render_as_combobox?)).to be_falsey
      }
    end
  end
end
