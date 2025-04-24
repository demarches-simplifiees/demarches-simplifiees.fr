# frozen_string_literal: true

describe TypesDeChampEditor::InfoReferentielComponent, type: :component do
  describe 'render' do
    let(:component) { described_class.new(procedure:, type_de_champ:) }
    let(:types_de_champ_public) { [{ type: :referentiel }] }
    let(:type_de_champ) { procedure.draft_revision.types_de_champ_public.first }
    let(:whitelist) { %w[https://rnb-api.beta.gouv.fr] }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ALLOWED_API_DOMAINS_FROM_FRONTEND', '').and_return(whitelist.join(','))
      referentiel
      type_de_champ
      Flipper.enable_actor(:referentiel_type_de_champ, procedure)
      render_inline(component)
    end

    context "draft_procedure" do
      let(:procedure) { create(:procedure, types_de_champ_public:) }
      context 'having referentiel' do
        let(:referentiel) { create(:api_referentiel, types_de_champ: [type_de_champ], url: "https://rnb-api.beta.gouv.fr") }

        it "allows to edit referentiel" do
          expect(page).to have_link("Configurer le champ", href: Rails.application.routes.url_helpers.edit_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel.id))
        end
      end
      context 'not having referentiel' do
        let(:referentiel) { nil }

        it "new referentiel" do
          expect(page).to have_link("Configurer le champ", href: Rails.application.routes.url_helpers.new_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id))
        end
      end
    end

    context "published_procedure" do
      let(:procedure) { create(:procedure, :published, types_de_champ_public:) }

      context "having referentiel" do
        let(:referentiel) { create(:api_referentiel, types_de_champ: [type_de_champ], url: "https://rnb-api.beta.gouv.fr") }

        it "does not allow to edit existing referentiel" do
          expect(page).to have_link("Configurer le champ", href: Rails.application.routes.url_helpers.new_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id, referentiel_id: referentiel.id))
        end
      end

      context 'not having referentiel' do
        let(:referentiel) { nil }

        it "new referentiel" do
          expect(page).to have_link("Configurer le champ", href: Rails.application.routes.url_helpers.new_admin_procedure_referentiel_path(procedure, type_de_champ.stable_id))
        end
      end
    end
  end
end
