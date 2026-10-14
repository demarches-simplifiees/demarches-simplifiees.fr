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
end
