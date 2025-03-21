# frozen_string_literal: true

RSpec.describe Instructeurs::RdvCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:component) { described_class.new(rdv:, with_dossier_infos:) }

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
    context "with minimal information" do
      let(:with_dossier_infos) { false }
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

      context "with dossier information" do
        let(:with_dossier_infos) { true }

        it "displays dossier details" do
          expect(subject).to have_text("Dossier Nº\n#{dossier.id}")
          expect(subject).to have_css(".fr-icon-user-line")
          expect(subject).to have_css(".fr-icon-calendar-line")
          expect(subject).to have_text(I18n.l(dossier.depose_at.to_date))
        end

        it "includes dossier status" do
          expect(subject).to have_css(".fr-badge")
        end

        it "has a link to view the dossier" do
          expect(subject).to have_link(nil, href: dossier_path(dossier))
          expect(subject).to have_css(".fr-icon-arrow-right-line")
        end
      end
    end
  end
end
