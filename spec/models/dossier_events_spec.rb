# frozen_string_literal: true

describe 'Dossier events', type: :model do
  let(:event_store) { Events.store }
  let(:procedure) { procedures.individual }
  let(:instructeur) { instructeurs.default }

  def events_of(dossier)
    event_store.read.stream(Events.dossier_stream(dossier.id)).to_a
  end

  describe '#publish_event' do
    before { stub_const('Events::Probe', Class.new(Events::DossierEvent)) }

    it 'appends to the dossier stream and links to the démarche stream, with the actor in metadata' do
      dossier = dossiers.en_construction

      dossier.publish_event(Events::Probe, author: instructeur, label_id: 12)

      expect(event_store).to have_published(
        an_event(Events::Probe)
          .with_data(dossier_id: dossier.id, procedure_id: procedure.id, label_id: 12)
          .with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_streams([Events.dossier_stream(dossier.id), Events.procedure_stream(procedure.id)])
    end

    it 'links the event to the stream of its actor' do
      dossier = dossiers.en_construction

      dossier.publish_event(Events::Probe, author: instructeur)

      expect(event_store).to have_published(an_event(Events::Probe)).in_stream(Events.stream('Instructeur', instructeur.id))
    end

    it 'records no actor for an automatic operation, and links to no actor stream' do
      dossier = dossiers.en_construction

      expect { dossier.publish_event(Events::Probe, author: :automatic) }
        .not_to change { event_store.read.stream(Events.stream('Instructeur', instructeur.id)).count }
      expect(events_of(dossier).last.metadata.to_h).not_to have_key(:actor)
    end
  end

  describe 'dossier_depose' do
    it 'records the deposit with the submitted revision, by the usager' do
      dossier = dossiers.brouillon

      dossier.passer_en_construction!

      expect(event_store).to have_published(
        an_event(Events::DossierDepose)
          .with_data(revision_id: dossier.revision_id)
          .with_metadata(actor: { type: 'User', id: dossier.user_id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'dossier_modifie' do
    it 'records a submission by the usager, with its checkpoint' do
      dossier = dossiers.en_construction
      stable_id = dossier.revision.public_root_type_de_champs.first.stable_id
      dossier.with_update_stream(dossier.user) do
        dossier.public_champ_for_update(stable_id.to_s, updated_by: dossier.user.email).assign_attributes(value: 'Nouveau nom')
      end
      dossier.save!

      dossier.usager_submit_en_construction!

      expect(event_store).to have_published(
        an_event(Events::DossierModifie)
          .with_data(revision_id: dossier.revision_id, checkpoint: a_string_starting_with('history:'))
          .with_metadata(actor: { type: 'User', id: dossier.user_id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records a submission by an instructeur' do
      dossier = dossiers.en_construction

      dossier.instructeur_submit_en_construction!(instructeur:, notify: false)

      expect(event_store).to have_published(
        an_event(Events::DossierModifie)
          .with_data(revision_id: dossier.revision_id, checkpoint: nil)
          .with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'dossier_en_instruction' do
    it 'records the transition by an instructeur' do
      dossier = dossiers.en_construction

      dossier.passer_en_instruction!(instructeur:)

      expect(event_store).to have_published(
        an_event(Events::DossierEnInstruction).with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records the automatic transition of a declarative démarche after the deposit, without actor' do
      declarative_procedure = create(:procedure, :published, :for_individual, declarative_with_state: 'en_instruction')
      dossier = create(:dossier, :brouillon, :with_individual, procedure: declarative_procedure)

      dossier.passer_en_construction!

      events = events_of(dossier)
      expect(events.map(&:class)).to eq([Events::DossierDepose, Events::DossierEnInstruction])
      expect(events.last.metadata.to_h).not_to have_key(:actor)
    end
  end

  describe 'dossier_accepte' do
    it 'records the decision by an instructeur' do
      dossier = dossiers.en_instruction

      dossier.accepter!(instructeur:, motivation: 'ok')

      expect(event_store).to have_published(
        an_event(Events::DossierAccepte).with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records the automatic decision of a declarative démarche after the deposit' do
      declarative_procedure = create(:procedure, :published, :for_individual, declarative_with_state: 'accepte')
      dossier = create(:dossier, :brouillon, :with_individual, procedure: declarative_procedure)

      dossier.passer_en_construction!

      expect(events_of(dossier).map(&:class)).to eq([Events::DossierDepose, Events::DossierAccepte])
    end
  end

  describe 'dossier_refuse' do
    it 'records the decision by an instructeur' do
      dossier = dossiers.en_instruction

      dossier.refuser!(instructeur:, motivation: 'non')

      expect(event_store).to have_published(
        an_event(Events::DossierRefuse).with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'dossier_sans_suite' do
    it 'records the decision by an instructeur' do
      dossier = dossiers.en_instruction

      dossier.classer_sans_suite!(instructeur:, motivation: 'sans objet')

      expect(event_store).to have_published(
        an_event(Events::DossierSansSuite).with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'dossier_repasse_en_construction' do
    it 'records the transition by an instructeur' do
      dossier = dossiers.en_instruction

      dossier.repasser_en_construction!(instructeur:)

      expect(event_store).to have_published(
        an_event(Events::DossierRepasseEnConstruction).with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'dossier_repasse_en_instruction' do
    it 'records the transition by an instructeur' do
      dossier = dossiers.refuse

      dossier.repasser_en_instruction!(instructeur:)

      expect(event_store).to have_published(
        an_event(Events::DossierRepasseEnInstruction).with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'correction_demandee' do
    it 'records the request after the dossier moved back en construction' do
      dossier = dossiers.en_instruction
      commentaire = CommentaireService.build(instructeur, dossier, body: 'Merci de corriger')

      dossier.flag_as_pending_correction!(commentaire)

      expect(dossier.reload).to be_en_construction
      expect(events_of(dossier).map(&:class)).to eq([Events::DossierRepasseEnConstruction, Events::CorrectionDemandee])
      expect(event_store).to have_published(
        an_event(Events::CorrectionDemandee)
          .with_data(correction_id: dossier.pending_correction.id, reason: 'incorrect')
          .with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'dossier_route' do
    let(:other_groupe) { procedure.groupe_instructeurs.create!(label: 'Autre groupe') }

    it 'records a reassignment with the new groupe and the mode' do
      dossier = dossiers.en_construction

      dossier.assign_to_groupe_instructeur(other_groupe, DossierAssignment.modes.fetch(:manual), instructeur)

      expect(event_store).to have_published(
        an_event(Events::DossierRoute)
          .with_data(groupe_instructeur_id: other_groupe.id, mode: 'manual')
          .with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records nothing when the groupe does not change, nor for a brouillon' do
      dossier = dossiers.en_construction
      expect { dossier.assign_to_groupe_instructeur(dossier.groupe_instructeur, DossierAssignment.modes.fetch(:manual), instructeur) }
        .not_to change { events_of(dossier).size }

      brouillon = dossiers.brouillon
      expect { brouillon.assign_to_groupe_instructeur(other_groupe, DossierAssignment.modes.fetch(:auto)) }
        .not_to change { events_of(brouillon).size }
    end

    context 'when the routing reassigns the dossier' do
      before do
        allow(RoutingEngine).to receive(:compute) do |routed|
          routed.assign_to_groupe_instructeur(other_groupe, DossierAssignment.modes.fetch(:auto))
        end
      end

      it 'comes after dossier_depose at the deposit' do
        dossier = dossiers.brouillon

        dossier.passer_en_construction!

        expect(events_of(dossier).map(&:class)).to eq([Events::DossierDepose, Events::DossierRoute])
      end

      it 'comes after dossier_modifie on a submission by the usager' do
        dossier = dossiers.en_construction

        dossier.usager_submit_en_construction!

        expect(events_of(dossier).map(&:class)).to eq([Events::DossierModifie, Events::DossierRoute])
      end

      it 'comes after dossier_modifie on a submission by an instructeur' do
        dossier = dossiers.en_construction

        dossier.instructeur_submit_en_construction!(instructeur:, notify: false)

        expect(events_of(dossier).map(&:class)).to eq([Events::DossierModifie, Events::DossierRoute])
      end
    end
  end

  describe 'dossier deletions' do
    it 'records a deletion by the administration that hides the dossier from it' do
      dossier = dossiers.refuse

      dossier.hide_and_keep_track!(instructeur, :instructeur_request)

      expect(event_store).to have_published(
        an_event(Events::DossierSupprimeParAdministration)
          .with_data(reason: 'instructeur_request', hidden_from_administration: true)
          .with_metadata(actor: { type: 'Instructeur', id: instructeur.id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records a deletion by the usager of a terminated dossier, which the administration still sees' do
      dossier = dossiers.refuse

      dossier.hide_and_keep_track!(dossier.user, :user_request)

      expect(event_store).to have_published(
        an_event(Events::DossierSupprimeParUsager)
          .with_data(reason: 'user_request', hidden_from_administration: false)
          .with_metadata(actor: { type: 'User', id: dossier.user_id })
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records a deletion by the usager of a dossier en construction as hiding it from the administration' do
      dossier = dossiers.en_construction

      dossier.hide_and_keep_track!(dossier.user, :user_request)

      expect(event_store).to have_published(
        an_event(Events::DossierSupprimeParUsager).with_data(reason: 'user_request', hidden_from_administration: true)
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records the deletion of a brouillon, never visible by the administration' do
      dossier = dossiers.brouillon

      dossier.hide_and_keep_track!(dossier.user, :user_request)

      expect(event_store).to have_published(
        an_event(Events::DossierSupprimeParUsager).with_data(hidden_from_administration: false)
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records an expiration without actor' do
      dossier = dossiers.refuse

      dossier.hide_and_keep_track!(:automatic, :expired)

      expect(event_store).to have_published(
        an_event(Events::DossierExpire).with_data(reason: 'expired', hidden_from_administration: true)
      ).in_stream(Events.dossier_stream(dossier.id))
      expect(events_of(dossier).last.metadata.to_h).not_to have_key(:actor)
    end

    it 'records the second deletion of a hidden dossier as changing nothing for the administration' do
      dossier = dossiers.refuse
      dossier.hide_and_keep_track!(instructeur, :instructeur_request)

      dossier.hide_and_keep_track!(dossier.user, :user_request)

      expect(event_store).to have_published(
        an_event(Events::DossierSupprimeParUsager).with_data(hidden_from_administration: false)
      ).in_stream(Events.dossier_stream(dossier.id))
    end

    it 'records the removal of the démarche with its reason' do
      dossier = dossiers.en_construction

      procedure.discard_and_keep_track!(procedure.administrateurs.first)

      expect(event_store).to have_published(
        an_event(Events::DossierSupprimeParAdministration).with_data(reason: 'procedure_removed', hidden_from_administration: true)
      ).in_stream(Events.dossier_stream(dossier.id))
    end
  end

  describe 'request metadata' do
    it 'keeps the request id, not the remote ip' do
      env = Rack::MockRequest.env_for('/', 'REMOTE_ADDR' => '203.0.113.7', 'action_dispatch.request_id' => 'req-1')

      event_store.with_request_metadata(env) do
        expect(event_store.metadata).to eq(request_id: 'req-1')
      end
    end
  end
end
