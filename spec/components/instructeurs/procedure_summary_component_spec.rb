# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instructeurs::ProcedureSummaryComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:administrateur) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure) }
  let(:instructeur) { instructeurs(:default_instructeur_admin) }

  # Default empty counters, using Hash.new(0) for simplicity
  let(:dossiers_count_per_procedure) { Hash.new(0) }
  let(:dossiers_a_suivre_count_per_procedure) { Hash.new(0) }
  let(:dossiers_termines_count_per_procedure) { Hash.new(0) }
  let(:dossiers_expirant_count_per_procedure) { Hash.new(0) }
  let(:followed_dossiers_count_per_procedure) { Hash.new(0) }
  let(:procedure_ids_with_notifications) { { a_suivre: [], suivis: [], traites: [] } }
  let(:notifications_counts_per_procedure) { { procedure.id => [] } }
  let(:has_export_notification) { false }

  let(:component) do
    described_class.new(
      procedure:,
      dossiers_count_per_procedure:,
      dossiers_a_suivre_count_per_procedure:,
      dossiers_termines_count_per_procedure:,
      dossiers_expirant_count_per_procedure:,
      followed_dossiers_count_per_procedure:,
      procedure_ids_with_notifications:,
      notifications_counts_per_procedure:,
      has_export_notification:
    )
  end

  before do
    allow(component).to receive(:current_instructeur).and_return(instructeur)
    allow(component).to receive(:current_administrateur).and_return(administrateur)
  end

  it "renders the procedure title as a link" do
    render_inline(component)
    expect(page).to have_link(procedure.libelle, href: instructeur_procedure_path(procedure))
    expect(page).to have_text(procedure.id)
  end

  it 'contains copy link' do
    render_inline(component)
    expect(page).to have_selector('.fr-icon-clipboard-line')
  end

  context "with counters" do
    let(:dossiers_count_per_procedure) { { procedure.id => 10 } }
    let(:dossiers_a_suivre_count_per_procedure) { { procedure.id => 1 } }
    let(:dossiers_termines_count_per_procedure) { { procedure.id => 2 } }
    let(:followed_dossiers_count_per_procedure) { { procedure.id => 4 } }
    let(:dossiers_expirant_count_per_procedure) { { procedure.id => 3 } }

    it "renders the counters with correct values and labels" do
      render_inline(component)

      expect(page).to have_link("1 à suivre", href: instructeur_procedure_path(procedure, statut: 'a-suivre'))
      expect(page).to have_link("4 suivis", href: instructeur_procedure_path(procedure, statut: 'suivis'))
      expect(page).to have_link("2 traités", href: instructeur_procedure_path(procedure, statut: 'traites'))
      expect(page).to have_link("10 au total", href: instructeur_procedure_path(procedure, statut: 'tous'))
      expect(page).to have_link("3 expirants", href: instructeur_procedure_path(procedure, statut: 'expirant'))
    end
  end

  context "with notifications" do
    before { Flipper.enable_actor(:notification, instructeur) }
    let(:procedure_ids_with_notifications) { { a_suivre: [procedure.id], suivis: [], traites: [] } }
    let(:notifications_counts_per_procedure) { { procedure.id => { "message" => 2 } } }

    it "renders a notification badge for 'à suivre' counter" do
      render_inline(component)
      expect(page).to have_text("2Message")
      expect(page).to have_text("Détails des notifications")
    end
  end
end
