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

  describe 'demarche_publiee and demarche_republiee' do
    let(:draft_procedure) { create(:procedure, administrateurs: [administrateur], zones: [zones.default]) }

    it 'records the first publication, then a new revision, a close and a reopening' do
      draft_procedure.publish_or_reopen!(administrateur, 'demarche-evenements')
      first_revision_id = draft_procedure.published_revision_id

      draft_procedure.draft_revision.add_type_de_champ(type_champ: 'text', libelle: 'Nouveau champ')
      draft_procedure.publish_revision!(administrateur)
      second_revision_id = draft_procedure.published_revision_id

      draft_procedure.close!
      draft_procedure.publish_or_reopen!(administrateur, 'demarche-evenements')

      expect(event_store).to have_published(
        an_event(Events::DemarchePubliee).with_data(revision_id: first_revision_id).with_metadata(actor: { type: 'Administrateur', id: administrateur.id }),
        an_event(Events::DemarcheRepubliee).with_data(revision_id: second_revision_id),
        an_event(Events::DemarcheRepubliee).with_data(revision_id: second_revision_id)
      ).in_stream(Events.procedure_stream(draft_procedure.id))
      expect(events_of(draft_procedure).map(&:class).tally).to include(Events::DemarchePubliee => 1, Events::DemarcheRepubliee => 2)
    end

    it 'records a new revision published through publish_or_reopen! once' do
      procedure.draft_revision.add_type_de_champ(type_champ: 'text', libelle: 'Nouveau champ')

      expect { procedure.publish_or_reopen!(administrateur, procedure.path) }
        .to change { events_of(procedure).size }.by(1)
      expect(events_of(procedure).last).to be_an_instance_of(Events::DemarcheRepubliee)
    end
  end
end
