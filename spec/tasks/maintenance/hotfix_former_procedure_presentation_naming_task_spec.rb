# frozen_string_literal: true

require "rails_helper"

# this commit : https://github.com/demarches-simplifiees/demarches-simplifiees.fr/pull/10625/commits/305b8c13c75a711a85521d0b19659293d8d92805
#   it brokes a naming convention on ProcedurePresentation.filters|displayed_fields|sort
#   we adjust live data to fit new convention
module Maintenance
  RSpec.describe HotfixFormerProcedurePresentationNamingTask do
    let(:procedure) { create(:procedure, types_de_champ_private: [{ type: :text }]) }
    let(:groupe_instructeur) { create(:groupe_instructeur, procedure: procedure, instructeurs: [build(:instructeur)]) }
    let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: groupe_instructeur.instructeurs.first) }
    let(:procedure_presentation) { create(:procedure_presentation, procedure: procedure, assign_to: assign_to) }

    describe "#process" do
      subject(:process) { described_class.process(procedure_presentation) }

      it "fix table naming" do
        stable_id = procedure.draft_revision.types_de_champ.first.stable_id.to_s
        procedure_presentation.update_column(:displayed_fields, [{ table: 'type_de_champ_private', column: stable_id }])
        procedure_presentation.update_column(:filters, "a-suivre" => [{ table: 'type_de_champ_private', column: stable_id }])
        procedure_presentation.update_column(:sort, table: 'type_de_champ_private', column: stable_id, order: 'asc')
        subject
        procedure_presentation.reload
        expect(procedure_presentation.displayed_fields.map { _1['table'] }).to eq(['type_de_champ'])
        expect(procedure_presentation.filters.flat_map { |_, filters| filters.map { _1['table'] } }).to eq(['type_de_champ'])
        expect(procedure_presentation.sort['table']).to eq('type_de_champ')
      end
    end
  end
end
