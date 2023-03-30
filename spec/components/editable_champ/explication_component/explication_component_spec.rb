describe EditableChamp::ExplicationComponent, type: :component do
  let(:component) {
    described_class.new(form: instance_double(ActionView::Helpers::FormBuilder, object_name: "dossier[champs_public_attributes]"), champ:)
  }

  let(:champ) { create(:champ_explication) }

  describe 'no description' do
    subject { render_inline(component).to_html }

    it { is_expected.not_to have_button("Lire plus") }
  end

  describe 'collapsed text is collapsed' do
    subject { render_inline(component).to_html }

    before do
      champ.type_de_champ.update!(collapsible_explanation_enabled: "1", collapsible_explanation_text: "hide me")
    end

    it { is_expected.to have_button("Lire plus") }
    it { is_expected.to have_selector(".fr-collapse", text: "hide me") }
  end
end
