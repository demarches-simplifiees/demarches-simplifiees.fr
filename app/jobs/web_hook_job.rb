class WebHookJob < ApplicationJob
  TIMEOUT = 10

  def perform(procedure, dossier)
    body = {
      procedure_id: procedure.id,
      dossier_id: dossier.id,
      state: dossier.state,
      updated_at: dossier.updated_at
    }

    Typhoeus.post(procedure.web_hook_url, body: body, timeout: TIMEOUT)
  end
end
