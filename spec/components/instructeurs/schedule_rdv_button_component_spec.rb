# frozen_string_literal: true

require "rails_helper"

RSpec.describe Instructeurs::ScheduleRdvButtonComponent, type: :component do
  let(:procedure) { create(:procedure) }
  let(:dossier) { create(:dossier, procedure: procedure) }

  subject(:component) { described_class.new(dossier: dossier) }

  it "renders the button with correct attributes" do
    render_inline(component)

    expect(page).to have_css("button.fr-btn")
    expect(page).to have_button("Prendre un rendez-vous")
  end
end
