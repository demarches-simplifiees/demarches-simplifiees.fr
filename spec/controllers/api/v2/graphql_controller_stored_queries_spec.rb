describe API::V2::GraphqlController do
  let(:admin) { create(:administrateur) }
  let(:generated_token) { APIToken.generate(admin) }
  let(:api_token) { generated_token.first }
  let(:token) { generated_token.second }
  let(:legacy_token) { APIToken.send(:unpack, token)[:plain_token] }
  let(:procedure) { create(:procedure, :published, :for_individual, :with_service, administrateurs: [admin], types_de_champ_public:) }
  let(:types_de_champ_public) { [] }
  let(:dossier)  { create(:dossier, :en_construction, :with_individual, procedure: procedure) }
  let(:dossier1) { create(:dossier, :en_construction, :with_individual, procedure: procedure, en_construction_at: 1.day.ago) }
  let(:dossier2) { create(:dossier, :en_construction, :with_individual, :archived, procedure: procedure, en_construction_at: 3.days.ago) }
  let(:dossier_accepte) { create(:dossier, :accepte, :with_individual, procedure: procedure) }
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

  describe 'introspection' do
    let(:query_id) { 'introspection' }
    let(:operation_name) { 'IntrospectionQuery' }
    let(:champ_descriptor) { gql_data[:__schema][:types].find { _1[:name] == 'ChampDescriptor' } }

    it {
      expect(gql_errors).to be_nil
      expect(gql_data[:__schema]).not_to be_nil
      expect(champ_descriptor).not_to be_nil
      expect(champ_descriptor[:fields].find { _1[:name] == 'options' }).to be_nil
    }
  end

  describe 'ds-query-v2' do
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

    context 'timeout' do
      let(:variables) { { dossierNumber: dossier.id } }
      let(:operation_name) { 'getDossier' }

      before { allow_any_instance_of(API::V2::Schema::Timeout).to receive(:max_seconds).and_return(0) }

      it {
        expect(gql_errors.first[:message]).to eq('Timeout on Query.dossier')
        expect(gql_errors.first[:extensions]).to eq({ code: 'timeout' })
      }
    end

    context 'getDossier' do
      let(:variables) { { dossierNumber: dossier.id } }
      let(:operation_name) { 'getDossier' }

      it {
        expect(gql_errors).to be_nil
        expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
        expect(gql_data[:dossier][:demandeur][:__typename]).to eq('PersonnePhysique')
        expect(gql_data[:dossier][:demandeur][:nom]).to eq(dossier.individual.nom)
        expect(gql_data[:dossier][:demandeur][:prenom]).to eq(dossier.individual.prenom)
      }

      context 'not found' do
        let(:variables) { { dossierNumber: 0 } }

        it {
          expect(gql_errors.first[:message]).to eq('Dossier not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
        }
      end

      context 'with entreprise' do
        let(:procedure) { create(:procedure, :published, :with_service, administrateurs: [admin], types_de_champ_public:) }
        let(:dossier) { create(:dossier, :en_construction, :with_entreprise, procedure: procedure) }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
          expect(gql_data[:dossier][:demandeur][:__typename]).to eq('PersonneMorale')
          expect(gql_data[:dossier][:demandeur][:siret]).to eq(dossier.etablissement.siret)
          expect(gql_data[:dossier][:demandeur][:libelleNaf]).to eq(dossier.etablissement.libelle_naf)
        }

        context 'when in degraded mode' do
          before { dossier.etablissement.update(adresse: nil) }

          it {
            expect(gql_errors).to be_nil
            expect(gql_data[:dossier][:id]).to eq(dossier.to_typed_id)
            expect(gql_data[:dossier][:demandeur][:__typename]).to eq('PersonneMoraleIncomplete')
            expect(gql_data[:dossier][:demandeur][:siret]).to eq(dossier.etablissement.siret)
            expect(gql_data[:dossier][:demandeur][:libelleNaf]).to be_nil
          }
        end
      end
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

      context 'not found' do
        let(:variables) { { demarcheNumber: 0 } }

        it {
          expect(gql_errors.first[:message]).to eq('Demarche not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
        }
      end

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

      context 'include deleted Dossiers' do
        let(:variables) { { demarcheNumber: procedure.id, includeDeletedDossiers: true, deletedSince: 2.weeks.ago.iso8601 } }
        let(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier_accepte, DeletedDossier.reasons.fetch(:user_request)) }

        before { deleted_dossier }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].size).to eq(1)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].first[:id]).to eq(deleted_dossier.to_typed_id)
          expect(gql_data[:demarche][:deletedDossiers][:nodes].first[:dateSupression]).to eq(deleted_dossier.deleted_at.iso8601)
        }
      end

      context 'include pending deleted Dossiers' do
        let(:variables) { { demarcheNumber: procedure.id, includePendingDeletedDossiers: true, pendingDeletedSince: 2.weeks.ago.iso8601 } }

        before {
          dossier.hide_and_keep_track!(dossier.user, DeletedDossier.reasons.fetch(:user_request))
          dossier_accepte.hide_and_keep_track!(instructeur, DeletedDossier.reasons.fetch(:instructeur_request))
        }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarche][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].size).to eq(2)
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].first[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier.id))
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].second[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier_accepte.id))
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].first[:dateSupression]).to eq(dossier.hidden_by_user_at.iso8601)
          expect(gql_data[:demarche][:pendingDeletedDossiers][:nodes].second[:dateSupression]).to eq(dossier_accepte.hidden_by_administration_at.iso8601)
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

      context 'not found' do
        let(:variables) { { groupeInstructeurNumber: 0 } }

        it {
          expect(gql_errors.first[:message]).to eq('GroupeInstructeurWithDossiers not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
        }
      end

      context 'include Dossiers' do
        let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id, includeDossiers: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
          expect(gql_data[:groupeInstructeur][:dossiers][:nodes].size).to eq(1)
        }
      end

      context 'include deleted Dossiers' do
        let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id, includeDeletedDossiers: true, deletedSince: 2.weeks.ago.iso8601 } }
        let(:deleted_dossier) { DeletedDossier.create_from_dossier(dossier_accepte, DeletedDossier.reasons.fetch(:user_request)) }

        before { deleted_dossier }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
          expect(gql_data[:groupeInstructeur][:deletedDossiers][:nodes].size).to eq(1)
          expect(gql_data[:groupeInstructeur][:deletedDossiers][:nodes].first[:id]).to eq(deleted_dossier.to_typed_id)
          expect(gql_data[:groupeInstructeur][:deletedDossiers][:nodes].first[:dateSupression]).to eq(deleted_dossier.deleted_at.iso8601)
        }
      end

      context 'include pending deleted Dossiers' do
        let(:variables) { { groupeInstructeurNumber: groupe_instructeur.id, includePendingDeletedDossiers: true, pendingDeletedSince: 2.weeks.ago.iso8601 } }

        before {
          dossier.hide_and_keep_track!(dossier.user, DeletedDossier.reasons.fetch(:user_request))
          dossier_accepte.hide_and_keep_track!(instructeur, DeletedDossier.reasons.fetch(:instructeur_request))
        }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:groupeInstructeur][:id]).to eq(groupe_instructeur.to_typed_id)
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].size).to eq(2)
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].first[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier.id))
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].second[:id]).to eq(GraphQL::Schema::UniqueWithinType.encode('DeletedDossier', dossier_accepte.id))
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].first[:dateSupression]).to eq(dossier.hidden_by_user_at.iso8601)
          expect(gql_data[:groupeInstructeur][:pendingDeletedDossiers][:nodes].second[:dateSupression]).to eq(dossier_accepte.hidden_by_administration_at.iso8601)
        }
      end
    end

    context 'getDemarcheDescriptor' do
      let(:operation_name) { 'getDemarcheDescriptor' }
      let(:types_de_champ_public) { [{ type: :text }, { type: :piece_justificative }, { type: :regions }] }

      context 'find by number' do
        let(:variables) { { demarche: { number: procedure.id }, includeRevision: true } }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:demarcheDescriptor][:id]).to eq(procedure.to_typed_id)
          expect(gql_data[:demarcheDescriptor][:demarcheUrl]).to match("commencer/#{procedure.path}")
        }
      end

      context 'not found' do
        let(:variables) { { demarche: { number: 0 } } }

        it {
          expect(gql_errors.first[:message]).to eq('DemarcheDescriptor not found')
          expect(gql_errors.first[:extensions]).to eq({ code: 'not_found' })
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

      context 'read only token' do
        before { api_token.update(write_access: false) }

        it {
          expect(gql_data[:dossierArchiver][:errors].first[:message]).to eq('Le jeton utilisé est configuré seulement en lecture')
        }
      end
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

      context 'read only token' do
        before { api_token.update(write_access: false) }

        it {
          expect(gql_data[:dossierAccepter][:errors].first[:message]).to eq('Le jeton utilisé est configuré seulement en lecture')
        }
      end

      context 'when already rejected' do
        let(:dossier) { create(:dossier, :refuse, :with_individual, procedure:) }

        it {
          expect(gql_data[:dossierAccepter][:errors].first[:message]).to eq('Le dossier est déjà refusé')
        }
      end

      context 'with entreprise' do
        let(:procedure) { create(:procedure, :published, :with_service, administrateurs: [admin]) }
        let(:dossier) { create(:dossier, :en_instruction, :with_entreprise, procedure:) }

        it {
          expect(gql_errors).to be_nil
          expect(gql_data[:dossierAccepter][:errors]).to be_nil
          expect(gql_data[:dossierAccepter][:dossier][:id]).to eq(dossier.to_typed_id)
          expect(gql_data[:dossierAccepter][:dossier][:state]).to eq('accepte')
        }

        context 'when in degraded mode' do
          before { dossier.etablissement.update(adresse: nil) }

          it {
            expect(gql_data[:dossierAccepter][:errors].first[:message]).to eq('Les informations du SIRET du dossier ne sont pas complètes. Veuillez réessayer plus tard.')
          }
        end
      end
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

      context 'read only token' do
        before { api_token.update(write_access: false) }

        it {
          expect(gql_data[:dossierRefuser][:errors].first[:message]).to eq('Le jeton utilisé est configuré seulement en lecture')
        }
      end
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

      context 'read only token' do
        before { api_token.update(write_access: false) }

        it {
          expect(gql_data[:dossierClasserSansSuite][:errors].first[:message]).to eq('Le jeton utilisé est configuré seulement en lecture')
        }
      end
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
          expect(gql_data[:groupeInstructeurCreer][:groupeInstructeur][:instructeurs]).to match_array([{ id: admin.instructeur.to_typed_id, email: admin.instructeur.email }, { id: Instructeur.last.to_typed_id, email: }])
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
        expect(gql_data[:groupeInstructeurAjouterInstructeurs][:groupeInstructeur][:instructeurs]).to match_array([{ id: existing_instructeur.to_typed_id, email: existing_instructeur.email }, { id: Instructeur.last.to_typed_id, email: }])
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
