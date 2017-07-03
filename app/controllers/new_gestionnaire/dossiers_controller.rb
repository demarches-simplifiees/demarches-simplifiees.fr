module NewGestionnaire
  class DossiersController < ProceduresController
    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    private

    def dossier
      Dossier.find(params[:dossier_id])
    end
  end
end
