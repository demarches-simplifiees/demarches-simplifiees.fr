# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attachment::GalleryItemComponent, type: :component do
  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:types_de_champ_public) { [{ type: :piece_justificative }] }
  let(:dossier) { create(:dossier, :with_populated_champs, :en_construction, procedure:) }
  let(:filename) { attachment.blob.filename.to_s }
  let(:gallery_demande) { false }

  let(:component) { described_class.new(attachment: attachment, gallery_demande:) }

  subject { render_inline(component).to_html }

  context "when attachment is from a piece justificative champ" do
    let(:champ) { dossier.champs.first }
    let(:libelle) { champ.libelle }
    let(:attachment) { champ.piece_justificative_file.attachments.first }

    it "displays libelle, link and renders title" do
      expect(subject).to have_text(libelle)
      expect(subject).not_to have_text('Pièce jointe au message')
      expect(subject).to have_link(filename)
      expect(component.title).to eq("#{libelle} -- #{filename}")
    end

    context "when gallery item is in page Demande" do
      let(:gallery_demande) { true }

      it "does not display libelle" do
        expect(subject).not_to have_text(libelle)
      end
    end
  end

  context "when attachment is from a commentaire" do
    let(:commentaire) { create(:commentaire, :with_file, dossier: dossier) }
    let(:attachment) { commentaire.piece_jointe.first }

    it "displays a generic libelle, link and renders title" do
      expect(subject).to have_text('Pièce jointe au message')
      expect(subject).to have_link(filename)
      expect(component.title).to eq("Pièce jointe au message -- #{filename}")
    end
  end
end
