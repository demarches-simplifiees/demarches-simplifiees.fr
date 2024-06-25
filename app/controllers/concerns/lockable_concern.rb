module LockableConcern
  extend ActiveSupport::Concern

  included do
    def lock_action(key)
      lock = Kredis.flag(key)
      head :locked and return if lock.marked?

      lock.mark(expires_in: 10.seconds)

      yield

      lock.remove
    end
  end
end
