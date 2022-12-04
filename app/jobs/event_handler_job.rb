class EventHandlerJob < ApplicationJob
  prepend RailsEventStore::CorrelatedHandler

  private

  def event_store
    Rails.configuration.event_store
  end

  def dossier
    @dossier ||= Dossier.find_by!(uuid: @event.data.fetch(:dossier_id))
  end

  def demarche
    @demarche ||= Procedure.find_by!(uuid: @event.data.fetch(:demarche_id))
  end

  def user
    @user ||= User.find_by!(uuid: @event.metadata.fetch(:user_id))
  end

  def deserialize_arguments(serialized_args)
    payload = super.first
    @event = event_store.deserialize(serializer: RubyEventStore::NULL, **payload.symbolize_keys)
    [@event]
  end
end
