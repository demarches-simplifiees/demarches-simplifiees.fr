# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instructeurs::ProcedureSummaryComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:administrateur) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure) }
  let(:instructeur) { instructeurs(:default_instructeur_admin) }

  # Default empty counters, using Hash.new(0) for simplicity
  let(:component) { described_class.new(procedure:) }

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
end
