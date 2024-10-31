# frozen_string_literal: true

describe Columns::DossierColumn do
  describe 'value' do
    let(:groupe_instructeur) { create(:groupe_instructeur, instructeurs: [create(:instructeur)]) }

    context 'when dossier columns' do
      context 'when procedure for individual' do
        let(:individual) { create(:individual, nom: "Sim", prenom: "Paul", gender: 'M.') }
        let(:procedure) { create(:procedure, for_individual: true, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, individual:, mandataire_first_name: "Martin", mandataire_last_name: "Christophe", for_tiers: true) }

        it 'retrieve individual information' do
          expect(procedure.find_column(label: "Prénom").value(dossier)).to eq("Paul")
          expect(procedure.find_column(label: "Nom").value(dossier)).to eq("Sim")
          expect(procedure.find_column(label: "Civilité").value(dossier)).to eq("M.")
        end
      end

      context 'when procedure for entreprise' do
        let(:procedure) { create(:procedure, for_individual: false, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure:) }

        it 'retrieve entreprise information' do
          expect(procedure.find_column(label: "Libellé NAF").value(dossier)).to eq('Transports par conduites')
        end
      end

      context 'when sva/svr enabled' do
        let(:procedure) { create(:procedure, :sva, for_individual: true, groupe_instructeurs: [groupe_instructeur]) }
        let(:dossier) { create(:dossier, :en_instruction, procedure:) }

        it 'does not fail' do
          expect(procedure.find_column(label: "Date décision SVA").value(dossier)).to eq(nil)
        end
      end
    end
  end
end
