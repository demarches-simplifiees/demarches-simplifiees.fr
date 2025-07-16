# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dsfr::InputStatusMessageComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:champ) { dossier.champs.first }
  let(:component) { described_class.new(errors_on_attribute:, error_full_messages:, champ:) }

  subject { render_inline(component) }

  context "when there are errors on the attribute" do
    let(:types_de_champ_public) { [{ type: :text }] }
    let(:errors_on_attribute) { true }
    let(:error_full_messages) { ["Invalid input"] }
    it "renders the error message" do
      expect(subject).to have_css(".fr-message--error", text: "« #{champ.libelle} »")
    end
  end
  context 'without errors' do
    let(:error_full_messages) { [] }
    let(:errors_on_attribute) { false }

    context 'with rna champs' do
      let(:types_de_champ_public) { [{ type: :rna }] }
      context "when there are no errors but the field supports statut" do
        it "renders the statut message" do
          allow(champ).to receive(:title).and_return("Title")
          allow(champ).to receive(:address).and_return("123 Street")

          expect(subject).to have_css(".fr-message--info") # , text: I18n.t(".rna.data_fetched", title: "Title", address: "123 Street"))
        end
      end
    end

    context 'with referentiel champs' do
      let(:referentiel) { create(:api_referentiel, :configured) }
      let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }

      context "when the field is a referentiel and waiting_for_external_data? is true" do
        before do
          allow(champ).to receive(:waiting_for_external_data?).and_return(true)
        end

        it "renders the pending message" do
          expect(subject).to have_css(".fr-message--info", text: "Recherche en cours.")
        end
      end

      context "when the field is a referentiel and external_error_present? is true" do
        before do
          allow(champ).to receive(:waiting_for_external_data?).and_return(false)
          allow(champ).to receive(:external_error_present?).and_return(true)
        end

        it "renders the error message 'KC'" do
          expect(subject).to have_css(".fr-message--info", text: "Aucun élément trouvé pour la référence : ")
        end
      end

      context "when the field is a referentiel and value is present" do
        before do
          allow(champ).to receive(:waiting_for_external_data?).and_return(false)
          allow(champ).to receive(:external_error_present?).and_return(false)
          allow(champ).to receive(:value).and_return('value')
        end
        it "renders the OK message" do
          expect(subject).to have_css(".fr-message--valid", text: 'value')
        end
      end
    end

    context 'with piece_justificative champs (RIB)' do
      let(:types_de_champ_public) { [{ type: :piece_justificative, nature: 'RIB' }] }

      context "when OCR is nil" do
        before do
          allow(champ).to receive(:piece_justificative_file).and_return(double(blobs: [double]))
          allow(champ.piece_justificative_file.blobs.first).to receive(:ocr).and_return(nil)
        end

        it "renders the info message" do
          expect(subject).to have_css(".fr-message--info")
        end
      end

      context "when OCR exists but IBAN is nil" do
        before do
          allow(champ).to receive(:piece_justificative_file).and_return(double(blobs: [double]))
          allow(champ.piece_justificative_file.blobs.first).to receive(:ocr).and_return({ 'rib' => {} })
        end

        it "renders the warning message" do
          expect(subject).to have_css(".fr-message--warning")
        end
      end

      context "when IBAN is present" do
        let(:iban) { "FRjesuisuniban" }

        before do
          allow(champ).to receive(:piece_justificative_file).and_return(double(blobs: [double]))
          allow(champ.piece_justificative_file.blobs.first).to receive(:ocr).and_return({ 'rib' => { 'iban' => iban } })
        end

        it "renders the valid message with IBAN" do
          expect(subject).to have_css(".fr-message--valid", text: iban)
        end
      end

      context "when OCR has an error" do
        before do
          allow(champ).to receive(:piece_justificative_file).and_return(double(blobs: [double]))
          allow(champ.piece_justificative_file.blobs.first).to receive(:ocr).and_return({ 'error' => true })
        end

        it "renders the warning message" do
          expect(subject).to have_css(".fr-message--warning", text: 'Une erreur')
        end
      end
    end
  end
end
