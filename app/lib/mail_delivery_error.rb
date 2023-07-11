# Inherit from `Exception` instead of `StandardError`
# because this error is raised in a `rescue_from StandardError`,
# so it would be shallowed otherwise.
#
# TODO: add a test which verify that the error will permit the job to retry
class MailDeliveryError < Exception # rubocop:disable Lint/InheritException
  def initialize(original_exception)
    super(original_exception.message)

    set_backtrace(original_exception.backtrace)
  end
end
