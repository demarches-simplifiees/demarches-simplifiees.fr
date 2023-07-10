describe API::V2::GraphqlController do
  let(:admin) { create(:administrateur) }
  let(:token) { APIToken.generate(admin)[1] }
  let(:legacy_token) { APIToken.send(:unpack, token)[:plain_token] }
  let(:procedure) { create(:procedure, :published, :for_individual, :with_service, administrateurs: [admin]) }
  let(:dossier)  { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
  let(:dossier1) { create(:dossier, :en_construction, :with_individual, procedure: procedure, en_construction_at: 1.day.ago) }
  let(:dossier2) { create(:dossier, :en_construction, :with_individual, :archived, procedure: procedure, en_construction_at: 3.days.ago) }
  let(:dossiers) { [dossier] }
  let(:instructeur) { create(:instructeur, followed_dossiers: dossiers) }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }

  before do
    instructeur.assign_to_procedure(procedure)
  end

  let(:query_id) { nil }
  let(:variables) { {} }
  let(:operation_name) { nil }
  let(:body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:gql_data) { body[:data] }
  let(:gql_errors) { body[:errors] }

  subject { post :execute, params: { queryId: query_id, variables: variables, operationName: operation_name }.compact, as: :json }

  before do
    request.env['HTTP_AUTHORIZATION'] = authorization_header
  end

  describe 'ds-query-v2' do
    let(:procedure) { create(:procedure, :published, :for_individual, administrateurs: [admin]) }
    let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
    let(:query_id) { 'ds-query-v2' }

    context 'not found operation id' do
      let(:query_id) { 'ds-query-v0' }

      it {
        expect(gql_errors.first[:message]).to eq('No query with id "ds-query-v0"')
      }
    end

    context 'not found operation name' do
      let(:operation_name) { 'getStuff' }

      it {
        expect(gql_errors.first[:message]).to eq('No operation named "getStuff"')
      }
    end

    context 'getDossier' do
      let(:variables) { { dossierNumber: dossier.id } }
      let(:operation_name) { 'getDossier' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
      }
    end

    context 'getDemarche' do
      let(:variables) { { demarcheNumber: procedure.id } }
      let(:operation_name) { 'getDemarche' }

      before { dossier }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
        expect(gql_data[:demarche][:dossiers]).to be_nil
      }

      context 'include Dossiers' do
        let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarche][:dossiers][:nodes].size).to eq(1)
        }
      end

      context 'include Revision' do
        let(:variables) { { demarcheNumber: procedure.id, includeRevision: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarche][:activeRevision]).not_to be_nil
        }
      end
    end

    context 'getGroupeInstructeur' do
      let(:groupe_instructeur) { procedure.groupe_instructeurs.first }
      let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id } }
      let(:operation_name) { 'getGroupeInstructeur' }

      before { dossier }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
        expect(gql_data[:groupeInstructeur][:dossiers]).to be_nil
      }

      context 'include Dossiers' do
        let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id, includeDossiers: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
          expect(gql_data[:groupeInstructeur][:dossiers][:nodes].size).to eq(1)
        }
      end
    end

    context 'getDemarcheDescriptor' do
      let(:operation_name) { 'getDemarcheDescriptor' }

      context 'find by number' do
        let(:variables) { { demarche: { number: procedure.id } } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
        }
      end

      context 'find by id' do
        let(:variables) { { demarche: { id: procedure.to_typed_id } } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
        }
      end

      context 'not opendata' do
        let(:variables) { { demarche: { id: procedure.to_typed_id } } }

        before { procedure.update(opendata: false) }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
        }
      end

      context 'without authorization token' do
        let(:authorization_header) { nil }

        context 'opendata' do
          let(:variables) { { demarche: { id: procedure.to_typed_id } } }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
          }
        end

        context 'not opendata' do
          let(:variables) { { demarche: { id: procedure.to_typed_id } } }

          before { procedure.update(opendata: false) }

          it {
            expect(gql_errors).not_to be_nil
            expect(gql_errors.first[:message]).to eq('An object of type DemarcheDescriptor was hidden due to permissions')
          }
        end
      end
    end
  end

  describe 'ds-mutation-v2' do
    let(:query_id) { 'ds-mutation-v2' }

    context 'not found operation name' do
      let(:operation_name) { 'dossierStuff' }

      it {
        expect(gql_errors.first[:message]).to eq('No operation named "dossierStuff"')
      }
    end

    context 'dossierArchiver' do
      let(:dossier) { create(:dossier, :refuse, :with_individual, procedure: procedure) }
      let(:variables) { { input: { dossierId: dossier.to_typed_id, instructeurId: instructeur.to_typed_id } } }
      let(:operation_name) { 'dossierArchiver' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossierArchiver][:errors]).to be_nil
        expect(gql_data[:dossierArchiver][:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossierArchiver][:dossier][:archived]).to be_truthy
      }
    end

    context 'dossierPasserEnInstruction' do
      let(:dossier) { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
      let(:variables) { { input: { dossierId: dossier.to_typed_id, instructeurId: instructeur.to_typed_id } } }
      let(:operation_name) { 'dossierPasserEnInstruction' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossierPasserEnInstruction][:errors]).to be_nil
        expect(gql_data[:dossierPasserEnInstruction][:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossierPasserEnInstruction][:dossier][:state]).to eq('en_instruction')
      }
    end

    context 'dossierRepasserEnConstruction' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
      let(:variables) { { input: { dossierId: dossier.to_typed_id, instructeurId: instructeur.to_typed_id } } }
      let(:operation_name) { 'dossierRepasserEnConstruction' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossierRepasserEnConstruction][:errors]).to be_nil
        expect(gql_data[:dossierRepasserEnConstruction][:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossierRepasserEnConstruction][:dossier][:state]).to eq('en_construction')
      }
    end

    context 'dossierRepasserEnInstruction' do
      let(:dossier) { create(:dossier, :refuse, :with_individual, procedure: procedure) }
      let(:variables) { { input: { dossierId: dossier.to_typed_id, instructeurId: instructeur.to_typed_id } } }
      let(:operation_name) { 'dossierRepasserEnInstruction' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossierRepasserEnInstruction][:errors]).to be_nil
        expect(gql_data[:dossierRepasserEnInstruction][:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossierRepasserEnInstruction][:dossier][:state]).to eq('en_instruction')
      }
    end

    context 'dossierAccepter' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
      let(:variables) { { input: { dossierId: dossier.to_typed_id, instructeurId: instructeur.to_typed_id } } }
      let(:operation_name) { 'dossierAccepter' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossierAccepter][:errors]).to be_nil
        expect(gql_data[:dossierAccepter][:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossierAccepter][:dossier][:state]).to eq('accepte')
      }
    end

    context 'dossierRefuser' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
      let(:variables) { { input: { dossierId: dossier.to_typed_id, instructeurId: instructeur.to_typed_id, motivation: 'yolo' } } }
      let(:operation_name) { 'dossierRefuser' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossierRefuser][:errors]).to be_nil
        expect(gql_data[:dossierRefuser][:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossierRefuser][:dossier][:state]).to eq('refuse')
      }
    end

    context 'dossierClasserSansSuite' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
      let(:variables) { { input: { dossierId: dossier.to_typed_id, instructeurId: instructeur.to_typed_id, motivation: 'yolo' } } }
      let(:operation_name) { 'dossierClasserSansSuite' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossierClasserSansSuite][:errors]).to be_nil
        expect(gql_data[:dossierClasserSansSuite][:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossierClasserSansSuite][:dossier][:state]).to eq('sans_suite')
      }
    end

    context 'groupeInstructeurModifier' do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, procedure: procedure) }
      let(:variables) { { input: { groupeInstructeurId: dossier.groupe_instructeur.to_typed_id, label: 'nouveau groupe instructeur' } } }
      let(:operation_name) { 'groupeInstructeurModifier' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:groupeInstructeurModifier][:errors]).to be_nil
        expect(gql_data[:groupeInstructeurModifier][:groupeInstructeur][:id]).to eq(dossier.groupe_instructeur.to_typed_id)
        expect(dossier.groupe_instructeur.reload.label).to eq('nouveau groupe instructeur')
      }

      context 'close groupe instructeur' do
        let(:variables) { { input: { groupeInstructeurId: dossier.groupe_instructeur.to_typed_id, closed: true } } }

        context 'with multiple groupes' do
          before do
            create(:groupe_instructeur, procedure: procedure)
          end

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:groupeInstructeurModifier][:errors]).to be_nil
            expect(gql_data[:groupeInstructeurModifier][:groupeInstructeur][:id]).to eq(dossier.groupe_instructeur.to_typed_id)
            expect(dossier.groupe_instructeur.reload.closed).to be_truthy
          }
        end

        context 'validation error' do
          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:groupeInstructeurModifier][:errors].first[:message]).to eq('Il doit y avoir au moins un groupe instructeur actif sur chaque démarche')
          }
        end
      end
    end

    context 'groupeInstructeurCreer' do
      let(:variables) { { input: { demarche: { id: procedure.to_typed_id }, groupeInstructeur: { label: 'nouveau groupe instructeur' } }, includeInstructeurs: true } }
      let(:operation_name) { 'groupeInstructeurCreer' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:groupeInstructeurCreer][:errors]).to be_nil
        expect(gql_data[:groupeInstructeurCreer][:groupeInstructeur][:id]).not_to be_nil
        expect(gql_data[:groupeInstructeurCreer][:groupeInstructeur][:instructeurs]).to eq([{ id: admin.instructeur.to_typed_id, email: admin.email }])
        expect(GroupeInstructeur.last.label).to eq('nouveau groupe instructeur')
      }

      context 'with instructeurs' do
        let(:email) { 'test@test.com' }
        let(:variables) { { input: { demarche: { id: procedure.to_typed_id }, groupeInstructeur: { label: 'nouveau groupe instructeur avec instructeurs', instructeurs: [email:] } }, includeInstructeurs: true } }
        let(:operation_name) { 'groupeInstructeurCreer' }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeurCreer][:errors]).to be_nil
          expect(gql_data[:groupeInstructeurCreer][:groupeInstructeur][:id]).not_to be_nil
          expect(gql_data[:groupeInstructeurCreer][:groupeInstructeur][:instructeurs]).to eq([{ id: admin.instructeur.to_typed_id, email: admin.instructeur.email }, { id: Instructeur.last.to_typed_id, email: }])
        }
      end
    end

    context 'groupeInstructeurAjouterInstructeurs' do
      let(:email) { 'test@test.com' }
      let(:groupe_instructeur) { procedure.groupe_instructeurs.first }
      let(:existing_instructeur) { groupe_instructeur.instructeurs.first }
      let(:variables) { { input: { groupeInstructeurId: groupe_instructeur.to_typed_id, instructeurs: [{ email: }, { email: 'yolo' }, { id: existing_instructeur.to_typed_id }] }, includeInstructeurs: true } }
      let(:operation_name) { 'groupeInstructeurAjouterInstructeurs' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:groupeInstructeurAjouterInstructeurs][:errors]).to be_nil
        expect(gql_data[:groupeInstructeurAjouterInstructeurs][:warnings]).to eq([message: "yolo n’est pas une adresse email valide"])
        expect(gql_data[:groupeInstructeurAjouterInstructeurs][:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
        expect(groupe_instructeur.instructeurs.count).to eq(2)
        expect(gql_data[:groupeInstructeurAjouterInstructeurs][:groupeInstructeur][:instructeurs]).to eq([{ id: existing_instructeur.to_typed_id, email: existing_instructeur.email }, { id: Instructeur.last.to_typed_id, email: }])
      }
    end

    context 'groupeInstructeurSupprimerInstructeurs' do
      let(:email) { 'test@test.com' }
      let(:groupe_instructeur) { procedure.groupe_instructeurs.first }
      let(:existing_instructeur) { groupe_instructeur.instructeurs.first }
      let(:new_instructeur) { create(:instructeur) }
      let(:variables) { { input: { groupeInstructeurId: groupe_instructeur.to_typed_id, instructeurs: [{ email: }, { id: new_instructeur.to_typed_id }] }, includeInstructeurs: true } }
      let(:operation_name) { 'groupeInstructeurSupprimerInstructeurs' }

      before do
        existing_instructeur
        groupe_instructeur.add(new_instructeur)
      end

      it {
        expect(groupe_instructeur.reload.instructeurs.count).to eq(2)
        expect(gql_errors).to be_nil
        expect(gql_data[:groupeInstructeurSupprimerInstructeurs][:errors]).to be_nil
        expect(gql_data[:groupeInstructeurSupprimerInstructeurs][:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
        expect(groupe_instructeur.instructeurs.count).to eq(1)
        expect(gql_data[:groupeInstructeurSupprimerInstructeurs][:groupeInstructeur][:instructeurs]).to eq([{ id: existing_instructeur.to_typed_id, email: existing_instructeur.email }])
      }
    end

    context 'demarcheCloner' do
      let(:operation_name) { 'demarcheCloner' }

      context 'find by number' do
        let(:variables) { { input: { demarche: { number: procedure.id } } } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheCloner][:errors]).to be_nil
          expect(gql_data[:demarcheCloner][:demarche][:id]).not_to be_nil
          expect(gql_data[:demarcheCloner][:demarche][:id]).not_to eq(procedure.to_typed_id)
          expect(gql_data[:demarcheCloner][:demarche][:id]).to eq(Procedure.last.to_typed_id)
        }
      end

      context 'find by id' do
        let(:variables) { { input: { demarche: { id: procedure.to_typed_id } } } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheCloner][:errors]).to be_nil
          expect(gql_data[:demarcheCloner][:demarche][:id]).not_to be_nil
          expect(gql_data[:demarcheCloner][:demarche][:id]).not_to eq(procedure.to_typed_id)
          expect(gql_data[:demarcheCloner][:demarche][:id]).to eq(Procedure.last.to_typed_id)
        }
      end

      context 'with title' do
        let(:variables) { { input: { demarche: { id: procedure.to_typed_id }, title: new_title } } }
        let(:new_title) { "#{procedure.libelle} TEST 1" }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheCloner][:errors]).to be_nil
          expect(gql_data[:demarcheCloner][:demarche][:id]).to eq(Procedure.last.to_typed_id)
          expect(Procedure.last.libelle).to eq(new_title)
        }
      end
    end
  end
end
