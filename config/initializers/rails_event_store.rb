Rails.configuration.to_prepare do
  repository = RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
  dispatcher = RubyEventStore::ComposedDispatcher.new(
    RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: RubyEventStore::NULL)),
    RubyEventStore::Dispatcher.new
  )
  pipeline = RubyEventStore::Mappers::Pipeline.new(
    RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
    RubyEventStore::Transformations::WithIndifferentAccess.new
  )
  mapper = RubyEventStore::Mappers::PipelineMapper.new(pipeline)

  Rails.configuration.event_store = RailsEventStore::Client.new(repository:, dispatcher:, mapper:)

  Rails.configuration.event_store.tap do |store|
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByMetadata.new(key: :user_id))
    store.subscribe_to_all_events(LinkByData.new(event_store: store, key: :demarche_id))
    store.subscribe_to_all_events(LinkByData.new(event_store: store, key: :dossier_id))

  end
end

class LinkByData
  def initialize(event_store:, key:, prefix: nil)
    @event_store = event_store
    @key = key
    @prefix = prefix || ["$by", key, nil].join("_")
  end

  def call(event)
    return unless event.data.has_key?(@key)

    stream_name = "#{@prefix}#{event.data.fetch(@key)}"
    return if @event_store.event_in_stream?(event.event_id, stream_name)

    @event_store.link([event.event_id], stream_name:)
  end
end
