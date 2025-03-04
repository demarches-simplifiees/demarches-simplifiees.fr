# frozen_string_literal: true

describe Traitement, type: :model do
  let(:dossier) { create(:dossier) }
  let(:instructeur) { create(:instructeur) }

  describe '#event' do
    it do
      dossier.traitements.passer_en_construction
      expect(dossier.traitements.last.event).to eq(:depose)

      dossier.traitements.submit_en_construction
      expect(dossier.traitements.last.event).to eq(:depose_correction_usager)

      dossier.traitements.passer_en_instruction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:passe_en_instruction)

      dossier.traitements.passer_en_construction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:repasse_en_construction)

      dossier.traitements.submit_en_construction
      expect(dossier.traitements.last.event).to eq(:depose_correction_usager)

      dossier.traitements.submit_en_construction
      expect(dossier.traitements.last.event).to eq(:depose_correction_usager)

      dossier.traitements.passer_en_instruction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:passe_en_instruction)

      dossier.traitements.accepter(instructeur:)
      expect(dossier.traitements.last.event).to eq(:accepte)

      dossier.traitements.passer_en_instruction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:repasse_en_instruction)

      dossier.traitements.refuser(instructeur:)
      expect(dossier.traitements.last.event).to eq(:refuse)

      dossier.traitements.passer_en_instruction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:repasse_en_instruction)

      dossier.traitements.classer_sans_suite(instructeur:)
      expect(dossier.traitements.last.event).to eq(:classe_sans_suite)

      dossier.traitements.passer_en_instruction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:repasse_en_instruction)

      dossier.traitements.refuser_automatiquement(motivation: 'yolo')
      expect(dossier.traitements.last.event).to eq(:refuse_automatiquement)

      dossier.traitements.passer_en_instruction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:repasse_en_instruction)

      dossier.traitements.accepter_automatiquement
      expect(dossier.traitements.last.event).to eq(:accepte_automatiquement)

      dossier.traitements.passer_en_instruction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:repasse_en_instruction)

      dossier.traitements.passer_en_construction(instructeur:)
      expect(dossier.traitements.last.event).to eq(:repasse_en_construction)

      dossier.traitements.passer_en_instruction
      expect(dossier.traitements.last.event).to eq(:passe_en_instruction_automatiquement)
    end
  end
end
