Rails.configuration.to_prepare do
  repository = RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
  dispatcher = RubyEventStore::ComposedDispatcher.new(
    RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: RubyEventStore::NULL)),
    RubyEventStore::Dispatcher.new
  )
  key_repository = DossierEncryptionKeyRepository.new
  pipeline = RubyEventStore::Mappers::Pipeline.new(
    RubyEventStore::Mappers::Transformation::Encryption.new(key_repository, serializer: RubyEventStore::NULL, forgotten_data: RubyEventStore::Mappers::ForgottenData.new),
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

    store.subscribe(Dossier::NotificationService, to: [
      DossierDepose,
      DossierPasseEnInstruction,
      DossierAccepte,
      DossierRefuse,
      DossierClasseSansSuite,
      DossierRepasseEnInstruction
    ])

    store.subscribe(Dossier::RemoveTitreIdentiteJob, to: [
      DossierAccepte,
      DossierRefuse,
      DossierClasseSansSuite
    ])
    store.subscribe(Dossier::SendDecisionToExpertsJob, to: [
      DossierAccepte,
      DossierRefuse,
      DossierClasseSansSuite
    ])
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

class DossierEncryptionKeyRepository
  def initialize
    @keys = {}
  end

  def key_of(identifier, cipher: ActiveSupport::MessageEncryptor.default_cipher)
    @keys[identifier] ||= DossierEncryptionKey.new(cipher: cipher, key: find_or_create_key(identifier, cipher))
    @keys[identifier]
  end

  private

  def find_or_create_key(identifier, cipher)
    dossier = Dossier.find_by(uuid: identifier)
    return nil if dossier.nil?

    len = ActiveSupport::MessageEncryptor.key_len(cipher)
    event_encryption_key = dossier.event_encryption_key
    if event_encryption_key.nil?
      event_encryption_key = SecureRandom.hex(len)
      dossier.update_columns(event_encryption_key:)
    end

    Rails.application
      .key_generator
      .generate_key(event_encryption_key, len)
  end
end

class DossierEncryptionKey
  attr_reader :cipher

  def initialize(cipher:, key:)
    @cipher = cipher
    @crypt = ActiveSupport::MessageEncryptor.new(key, cipher: cipher)
  end

  def encrypt(message, iv)
    @crypt.encrypt_and_sign(message, purpose: iv)
  end

  def decrypt(message, iv)
    @crypt.decrypt_and_verify(message, purpose: iv)
  end

  def random_iv
    SecureRandom.hex(6)
  end
end
