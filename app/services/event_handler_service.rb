class EventHandlerService
  def call(event)
    @event = event
    event_store.with_metadata(
      correlation_id: event.correlation_id || event.event_id,
      causation_id: event.event_id
    ) { perform(event) }
  end

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
end
