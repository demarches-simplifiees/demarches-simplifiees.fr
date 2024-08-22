# frozen_string_literal: true

RSpec.describe GroupeGestionnaire::GroupeGestionnaireTreeStructures::TreeStructureComponent, type: :component do
  let(:component) do
    described_class.new(
      parent: groupe_gestionnaire,
      children: { child_groupe_gestionnaire => {} }
    )
  end
  let(:gestionnaire) { create(:gestionnaire) }
  let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
  let!(:child_groupe_gestionnaire) { create(:groupe_gestionnaire, ancestry: "/#{groupe_gestionnaire.id}/", gestionnaires: []) }

  subject { render_inline(component).to_html }

  it { is_expected.to include(groupe_gestionnaire.name) }
  it { is_expected.to include(child_groupe_gestionnaire.name) }
end
