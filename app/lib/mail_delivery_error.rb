# Inherit from `Exception` instead of `StandardError`
# because this error is raised in a `rescue_from StandardError`,
# so it would be shallowed otherwise.
#
# TODO: add a test which verify that the error will permit the job to retry
class MailDeliveryError < Exception; end # rubocop:disable Lint/InheritException
