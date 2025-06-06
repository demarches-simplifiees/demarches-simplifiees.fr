# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attachment::GalleryItemComponent, type: :component do
  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, types_de_champ_public:, types_de_champ_private:) }
  let(:types_de_champ_public) { [{ type: :piece_justificative }] }
  let(:types_de_champ_private) { [{ type: :piece_justificative }] }
  let(:dossier) { create(:dossier, :with_populated_champs, :with_populated_annotations, :en_construction, procedure:) }
  let(:filename) { attachment.blob.filename.to_s }
  let(:gallery_demande) { false }
  let(:seen_at) { nil }
  let(:now) { Time.zone.now }

  let(:component) { described_class.new(attachment: attachment, gallery_demande:, seen_at: seen_at) }

  subject { render_inline(component).to_html }

  context "when attachment is from a public piece justificative champ" do
    let(:champ) do
      dossier.champs.where(private: false).first
    end
    let(:libelle) { champ.libelle }
    let(:attachment) { champ.piece_justificative_file.attachments.first }

    # Correspond au cas standard où le blob est créé avant le dépôt du dossier
    before { dossier.touch(:depose_at) }

    it "displays libelle, link, tag and renders title" do
      expect(subject).to have_text(libelle)
      expect(subject).not_to have_text('Pièce jointe au message')
      expect(subject).to have_link(filename)
      expect(subject).to have_text('Dossier usager')
      expect(component.title).to eq("#{libelle} -- #{filename}")
    end

    it "displays when gallery item has been added" do
      expect(subject).to have_text('Ajoutée le')
      expect(subject).not_to have_css('.highlighted')
      expect(subject).to have_text(component.helpers.try_format_datetime(attachment.record.created_at, format: :veryshort))
    end

    context "when gallery item has been updated" do
      # un nouveau blob est créé après modification d'un champ pièce justificative
      before { attachment.blob.touch(:created_at) }

      it 'displays the right text' do
        expect(subject).to have_text('Modifiée le')
      end
    end

    context "when gallery item is in page Demande" do
      let(:gallery_demande) { true }

      it "does not display libelle" do
        expect(subject).not_to have_text(libelle)
      end
    end
  end

  context "when attachment is from a private piece justificative champ" do
    let(:annotation) do
      dossier.champs.where(private: true).first
    end
    let(:libelle) { annotation.libelle }
    let(:attachment) { annotation.piece_justificative_file.attachments.first }

    # Correspond au cas standard où le blob est créé avant le dépôt du dossier
    before { dossier.touch(:depose_at) }

    it "displays libelle, link, tag and renders title" do
      expect(subject).to have_text(libelle)
      expect(subject).to have_link(filename)
      expect(subject).to have_text('Annotation privée')
      expect(component.title).to eq("#{libelle} -- #{filename}")
    end

    it "displays when gallery item has been added" do
      expect(subject).to have_text('Ajoutée le')
      expect(subject).not_to have_css('.highlighted')
      expect(subject).to have_text(component.helpers.try_format_datetime(attachment.record.created_at, format: :veryshort))
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

    context 'from an usager' do
      it "displays a generic libelle, link, tag and renders title" do
        expect(subject).to have_text('Pièce jointe au message')
        expect(subject).to have_link(filename)
        expect(subject).to have_text('Messagerie (usager)')
        expect(component.title).to eq("Pièce jointe au message -- #{filename}")
      end

      context "when instructeur has not seen it yet" do
        let(:seen_at) { now - 1.day }

        before do
          attachment.blob.update(created_at: now)
        end

        it 'displays datetime in the right style' do
          # TODO: remove this test if we choose to remove the highlighting for new PJs
          expect(subject).not_to have_css('.highlighted')
        end
      end

      context "when instructeur has already seen it" do
        let!(:seen_at) { now }

        before do
          freeze_time
          attachment.blob.touch(:created_at)
        end

        it 'displays datetime in the right style' do
          expect(subject).not_to have_css('.highlighted')
        end
      end
    end

    context 'from an instructeur' do
      before { commentaire.update!(instructeur:) }
      it "displays the right tag" do
        expect(subject).to have_text('Messagerie (instructeur)')
      end
    end

    context 'from an expert' do
      let(:expert) { create(:expert) }
      before { commentaire.update!(expert:) }
      it "displays the right tag" do
        expect(subject).to have_text('Messagerie (expert)')
      end
    end
  end

  context "when attachment is from a justificatif motivation" do
    let(:fake_justificatif) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }
    let(:attachment) { dossier.justificatif_motivation.attachment }

    before { dossier.update!(justificatif_motivation: fake_justificatif) }

    it "displays a generic libelle, link, tag and renders title" do
      expect(subject).to have_text('Justificatif de décision')
      expect(subject).to have_link(filename)
      expect(subject).to have_text('Pièce jointe à la décision')
      expect(component.title).to eq("Pièce jointe à la décision -- #{filename}")
    end
  end

  context "when attachment is from an avis" do
    context 'from an instructeur' do
      let(:avis) { create(:avis, :with_introduction, dossier: dossier) }
      let(:attachment) { avis.introduction_file.attachment }

      it "displays a generic libelle, link, tag and renders title" do
        expect(subject).to have_text('Pièce jointe à l’avis')
        expect(subject).to have_link(filename)
        expect(subject).to have_text('Avis externe (instructeur)')
        expect(component.title).to eq("Pièce jointe à l’avis -- #{filename}")
      end

      context "when instructeur has not seen it yet" do
        let(:seen_at) { now - 1.day }

        before do
          attachment.blob.update(created_at: now)
        end

        it 'displays datetime in the right style' do
          # TODO: remove this test if we choose to remove the highlighting for new PJs
          expect(subject).not_to have_css('.highlighted')
        end
      end

      context "when instructeur has already seen it" do
        let!(:seen_at) { now }

        before do
          freeze_time
          attachment.blob.touch(:created_at)
        end

        it 'displays datetime in the right style' do
          expect(subject).not_to have_css('.highlighted')
        end
      end
    end

    context 'from an expert' do
      let(:avis) { create(:avis, :with_piece_justificative, dossier: dossier) }
      let(:attachment) { avis.piece_justificative_file.attachment }

      it "displays the right tag" do
        expect(subject).to have_text('Avis externe (expert)')
      end
    end
  end
end
