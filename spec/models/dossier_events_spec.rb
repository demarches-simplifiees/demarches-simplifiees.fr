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

  describe 'request metadata' do
    it 'keeps the request id, not the remote ip' do
      env = Rack::MockRequest.env_for('/', 'REMOTE_ADDR' => '203.0.113.7', 'action_dispatch.request_id' => 'req-1')

      event_store.with_request_metadata(env) do
        expect(event_store.metadata).to eq(request_id: 'req-1')
      end
    end
  end
end
