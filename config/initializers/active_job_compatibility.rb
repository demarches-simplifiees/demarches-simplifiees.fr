# The following jobs were renamed, but instances using the old name
# were still scheduled to run on the job queue.
#
# To ensure the job queue can instantiate these jobs using the previous
# names, this file defines retro-compatibility aliases.
#
# Once all jobs running using the previous name will have run, this
# file can be safely deleted.
#
# (That probably means a few hours after deploying the rename in production
# - but let's keep these for a while to make external integrators's life easier.
# To keep some margin, let's say this file can be safely deleted in May 2021.)

Rails.application.reloader.to_prepare do
  if !defined?(ApiEntreprise)
    require 'excon'

    module ApiEntreprise
      Job = APIEntreprise::Job
      AssociationJob = APIEntreprise::AssociationJob
      AttestationFiscaleJob = APIEntreprise::AttestationFiscaleJob
      AttestationSocialeJob = APIEntreprise::AttestationSocialeJob
      BilansBdfJob = APIEntreprise::BilansBdfJob
      EffectifsAnnuelsJob = APIEntreprise::EffectifsAnnuelsJob
      EffectifsJob = APIEntreprise::EffectifsJob
      EntrepriseJob = APIEntreprise::EntrepriseJob
      ExercicesJob = APIEntreprise::ExercicesJob
    end

    module Cron
      FixMissingAntivirusAnalysis = FixMissingAntivirusAnalysisJob
    end
  end

  if !defined?(ApiParticulier)
    require 'excon'

    module ApiParticulier
      Job = APIParticulier::Job
      DossierJob = APIParticulier::DossierJob
    end
  end
end
