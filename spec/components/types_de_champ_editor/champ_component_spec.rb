describe TypesDeChampEditor::ChampComponent, type: :component do
  describe 'render' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }]) }
    let(:drop_down_tdc) { procedure.draft_revision.types_de_champ.first }
    let(:coordinate) { drop_down_tdc.revision_type_de_champ }
    let(:component) { described_class.new(coordinate:, upper_coordinates: []) }
    let(:routing_rules_stable_ids) { [] }

    before do
      allow_any_instance_of(Procedure).to receive(:stable_ids_used_by_routing_rules).and_return(routing_rules_stable_ids)
      # pf visa & tefenua champs are activated via Flipper which requires current_user which is not active in these tests
      allow_any_instance_of(TypesDeChampEditor::ChampComponent).to receive(:filter_featured_type_champ).and_return(true)
      render_inline(component)
    end

    context 'drop down tdc not used for routing' do
      it do
        expect(page).not_to have_text(/utilisé pour\nle routage/)
        expect(page).not_to have_css("select[disabled=\"disabled\"]")
      end
    end

    context 'drop down tdc used for routing' do
      let(:routing_rules_stable_ids) { [drop_down_tdc.stable_id] }

      it do
        expect(page).to have_css("select[disabled=\"disabled\"]")
        expect(page).to have_text(/utilisé pour\nle routage/)
      end
    end
  end
end
