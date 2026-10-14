# frozen_string_literal: true

describe 'Procedure events', type: :model do
  let(:event_store) { Events.store }
  let(:procedure) { procedures.individual }
  let(:administrateur) { administrateurs.default }

  def events_of(procedure)
    event_store.read.stream(Events.procedure_stream(procedure.id)).to_a
  end

  describe '#publish_event' do
    before { stub_const('Events::Probe', Class.new(Events::ProcedureEvent)) }

    it 'appends to the démarche stream with the actor in metadata' do
      procedure.publish_event(Events::Probe, author: administrateur, revision_id: 12)

      expect(event_store).to have_published(
        an_event(Events::Probe)
          .with_data(procedure_id: procedure.id, revision_id: 12)
          .with_metadata(actor: { type: 'Administrateur', id: administrateur.id })
      ).in_stream(Events.procedure_stream(procedure.id))
    end
  end
end
