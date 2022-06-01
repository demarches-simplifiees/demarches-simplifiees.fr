class WebHookJob < ApplicationJob
  queue_as :webhooks_v1

  TIMEOUT = 10

  def perform(procedure_id, dossier_id, state, updated_at)
    body = {
      procedure_id: procedure_id,
      dossier_id: dossier_id,
      state: state,
      updated_at: updated_at
    }

    Typhoeus.post(procedure.web_hook_url, body: body, timeout: TIMEOUT)
  end
end
