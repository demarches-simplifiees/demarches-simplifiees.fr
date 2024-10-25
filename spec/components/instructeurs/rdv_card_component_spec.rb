# frozen_string_literal: true

RSpec.describe Instructeurs::RdvCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject do
    render_inline(described_class.new(rdv:, with_dossier_infos:))
  end

  let(:dossier) { create(:dossier, :en_instruction) }
  let(:rdv) { create(:rdv, dossier:) }
  let(:starts_at) { Time.zone.parse("2025-02-14 10:00:00") }

  describe "rendering" do
    context "with minimal information" do
      let(:with_dossier_infos) { false }
      it "displays appointment information" do
        expect(subject).to have_css("span.fr-icon-calendar-fill")
        expect(subject).to have_text(I18n.l(starts_at, format: :human))
        expect(subject).to have_link(rdv.rdv_plan_url, href: rdv.rdv_plan_url)
      end

      it "does not show dossier information" do
        expect(subject).not_to have_css(".fr-icon-user-line")
        expect(subject).not_to have_text(dossier.id.to_s)
      end

      context "with dossier information" do
        let(:with_dossier_infos) { true }

        it "displays dossier details" do
          expect(subject).to have_text(dossier.id.to_s)
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
