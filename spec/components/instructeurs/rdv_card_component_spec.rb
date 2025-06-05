# frozen_string_literal: true

RSpec.describe Instructeurs::RdvCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(rdv:) }

  subject do
    render_inline(component)
  end

  let(:dossier) { create(:dossier, :en_instruction) }
  let(:rdv) { create(:rdv, dossier:, instructeur: create(:instructeur)) }
  let(:starts_at) { Time.zone.parse("2025-02-14 10:00:00") }

  before do
    allow(component).to receive(:current_instructeur).and_return(current_instructeur)
  end

  let(:current_instructeur) { create(:instructeur) }

  describe "rendering" do
    it "displays appointment information" do
      expect(subject).to have_css("span.fr-icon-calendar-fill")
      expect(subject).to have_text(I18n.l(starts_at, format: :human))
      expect(subject).to have_link(rdv.rdv_plan_url, href: rdv.rdv_plan_url)
    end

    it "displays the owner information" do
      expect(subject).to have_css("span.fr-icon-user-fill")
      expect(subject).to have_text("Instructeur :\n\n#{component.owner}")
    end

    it "does not show dossier information" do
      expect(subject).not_to have_css(".fr-icon-user-line")
      expect(subject).not_to have_text("Dossier Nº\n#{dossier.id}")
    end
  end

  describe "#icon_class" do
    let(:rdv) { create(:rdv, dossier: dossier, location_type: location_type, instructeur: create(:instructeur)) }
    let(:component) { described_class.new(rdv: rdv) }

    context "when location_type is phone" do
      let(:location_type) { "phone" }

      it "returns the phone icon class" do
        expect(component.icon_class).to eq("fr-icon-phone-fill")
      end
    end

    context "when location_type is visio" do
      let(:location_type) { "visio" }

      it "returns the video icon class" do
        expect(component.icon_class).to eq("fr-icon-vidicon-fill")
      end
    end

    context "when location_type is home" do
      let(:location_type) { "home" }

      it "returns the home icon class" do
        expect(component.icon_class).to eq("fr-icon-home-4-fill")
      end
    end

    context "when location_type is something else" do
      let(:location_type) { "other" }

      it "returns nil" do
        expect(component.icon_class).to be_nil
      end
    end
  end
end
