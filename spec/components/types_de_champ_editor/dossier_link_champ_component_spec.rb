describe TypesDeChampEditor::DossierLinkChampComponent, type: :component do
  describe 'render' do
    let(:procedures) do
      [
        create(:procedure, id: 1, libelle: "Procedure 1", aasm_state: "publiee"),
        create(:procedure, id: 2, libelle: "Procedure 2", aasm_state: "brouillon"),
        create(:procedure, id: 3, libelle: "Procedure 3", aasm_state: "close")
      ]
    end
    let(:procedure) { create(:procedure) }
    let(:type_de_champ) { build(:type_de_champ_dossier_link) }
    let(:form) { instance_double('Form') }
    subject { described_class.new(procedures: procedures, type_de_champ: type_de_champ, form: form, procedure: procedure) }

    before do
      allow(form).to receive(:field_name).and_return("")
    end

    describe '#react_props' do
      it 'returns the correct props' do
        expected_props = {
          id: "procedures_type_de_champ",
          label: "Sélectionnez la ou les démarches concernées",
          items: {
            '--- Démarches publiées ---' => [{ label: "N°1 - Procedure 1", value: "1" }],
            '--- Démarches en test ---' => [{ label: "N°2 - Procedure 2", value: "2" }],
            '--- Démarches closes ---' => [{ label: "N°3 - Procedure 3", value: "3" }]
          },
          name: "",
          selected_keys: [],
          'aria-label': "Liste des démarches",
          secondary_label: "Démarches concernées",
          no_items_label: "Aucune démarche sélectionnée"
        }

        expect(subject.react_props).to eq(expected_props)
      end
    end

    describe '#items' do
      it 'returns the correct items' do
        expected_items = {
          '--- Démarches publiées ---' => [{ label: "N°1 - Procedure 1", value: "1" }],
          '--- Démarches en test ---' => [{ label: "N°2 - Procedure 2", value: "2" }],
          '--- Démarches closes ---' => [{ label: "N°3 - Procedure 3", value: "3" }]
        }

        expect(subject.items).to eq(expected_items)
      end
    end

    context 'with a procedure having no selected keys' do
      let(:type_de_champ) { build(:type_de_champ, procedures: []) }

      it 'returns an empty selected_keys' do
        expect(subject.react_props[:selected_keys]).to eq([])
      end
    end

    context 'with a procedure having multiple selected keys' do
      let(:type_de_champ) { build(:type_de_champ, procedures: procedures) }

      it 'returns the correct selected_keys' do
        expect(subject.react_props[:selected_keys]).to eq(["1", "2", "3"])
      end
    end
  end
end
