# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DossierAssignment, type: :model do
  include Logic

  context 'Assignment from routing engine' do
    let(:procedure) do
      create(:procedure,
             types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }]).tap do |p|
        p.groupe_instructeurs.create(label: 'a second group')
        p.groupe_instructeurs.create(label: 'a third group')
      end
    end

    let(:drop_down_tdc) { procedure.draft_revision.types_de_champ.first }

    let(:dossier) { create(:dossier, :en_construction, procedure:).tap { _1.update(groupe_instructeur_id: nil) } }

    before do
      RoutingEngine.compute(dossier)
      dossier.reload
    end

    it 'creates a dossier assignment with right attributes' do
      expect(dossier.dossier_assignments.count).to eq 1
      expect(dossier.dossier_assignment.mode).to eq 'auto'
      expect(dossier.dossier_assignment.dossier_id).to eq dossier.id
      expect(dossier.dossier_assignment.groupe_instructeur_id).to eq dossier.groupe_instructeur.id
      expect(dossier.dossier_assignment.groupe_instructeur_label).to eq dossier.groupe_instructeur.label
      expect(dossier.dossier_assignment.previous_groupe_instructeur_id).to be nil
      expect(dossier.dossier_assignment.previous_groupe_instructeur_label).to be nil
      expect(dossier.dossier_assignment.assigned_by).to be nil
    end
  end
end
