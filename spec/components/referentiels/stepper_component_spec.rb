# frozen_string_literal: true

RSpec.describe Referentiels::StepperComponent, type: :component do
  let(:component) { described_class.new(referentiel:, type_de_champ:, procedure:, step_component: Referentiels::MappingFormComponent) }
  let(:referentiel) { create(:api_referentiel, :exact_match) }
  let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
  let(:types_de_champ_public) { [] }
  let(:types_de_champ_private) { [] }

  subject { render_inline(component) }

  context 'when referentiel is private' do
    let(:type_de_champ) { procedure.draft_revision.types_de_champ_private.first }
    let(:types_de_champ_private) { [{ type: :referentiel, referentiel: }] }

    it 'back links goes to annotations' do
      expect(subject).to have_link("Annotations privées", href: Rails.application.routes.url_helpers.annotations_admin_procedure_path(procedure))
    end
  end

  context 'when referentiel is public' do
    let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }
    let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }

    it 'back links goes to champs' do
      expect(subject).to have_link("Champs du formulaire", href: Rails.application.routes.url_helpers.champs_admin_procedure_path(procedure))
    end
  end
end
