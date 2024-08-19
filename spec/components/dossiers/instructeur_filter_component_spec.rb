describe Dossiers::InstructeurFilterComponent, type: :component do
  let(:component) { described_class.new(procedure:, procedure_presentation:, statut:, facet:) }

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, instructeurs: [instructeur]) }
  let(:procedure_presentation) { nil }
  let(:statut) { nil }

  before do
    allow(component).to receive(:current_instructeur).and_return(instructeur)
  end

  describe ".filterable_fields_options" do
    context 'filders' do
      let(:facet) { nil }
      let(:included_displayable_field) do
        [
          Facet.new(label: 'email', table: 'user', column: 'email'),
          Facet.new(label: "depose_since", table: "self", column: "depose_since", virtual: true)
        ]
      end

      before do
        allow(Facet).to receive(:facets).and_return(included_displayable_field)
      end
      subject { component.filterable_fields_options }

      it { is_expected.to eq([["email", "user/email"], ["depose_since", "self/depose_since"]]) }
    end
  end

  describe '.options_for_select_of_field' do
    subject { component.options_for_select_of_field }

    context "facet is groupe_instructeur" do
      let(:facet) { double("Facet", scope: nil, table: 'groupe_instructeur') }
      let!(:gi_2) { instructeur.groupe_instructeurs.create(label: 'gi2', procedure:) }
      let!(:gi_3) { instructeur.groupe_instructeurs.create(label: 'gi3', procedure: create(:procedure)) }

      it { is_expected.to eq([['défaut', procedure.defaut_groupe_instructeur.id], ['gi2', gi_2.id]]) }
    end

    context 'when facet is dropdown' do
      let(:types_de_champ_public) { [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }] }
      let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
      let(:drop_down_stable_id) { procedure.active_revision.types_de_champ.first.stable_id }
      let(:facet) { Facet.new(table: 'type_de_champ', scope: nil, column: drop_down_stable_id) }

      it 'find most recent tdc' do
        is_expected.to eq(['Paris', 'Lyon', 'Marseille'])
      end
    end
  end
end
