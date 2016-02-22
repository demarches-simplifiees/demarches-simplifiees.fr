class API::V1::DossiersController < APIController
  swagger_controller :dossiers, "Dossiers"

  swagger_api :index do
    summary "Récupérer la liste de ses dossiers."
    notes <<-EOS
<pre>
<code>
{
  "dossiers": [
    {
      "id": 1,
      "nom_projet": "Dossier un",
      "updated_at": "2016-02-18T12:49:41.105Z"
    },
    {
      "id": 2,
      "nom_projet": "Dossier de test",
      "updated_at": "2016-02-08T18:36:49.394Z"
    }
  ],
  "pagination": {
    "page": 1,
    "resultats_par_page": 12,
    "nombre_de_page": 1
  }
}
</code>
</pre>
    EOS
    param :path, :procedure_id, :integer, :required, "Procédure ID"
    param :query, :token, :integer, :required, "Admin TOKEN"
    response :ok, "Success", :Dossier
    response :unauthorized
    response :not_found
  end

  swagger_api :show do
    summary "Récupérer le détails d'un dossier."
    notes <<-EOS
<pre>
<code>
{
  "dossier": {
    "id": 2,
    "nom_projet": "Projet de test",
    "description": "Description de test",
    "created_at": "2016-02-08T18:33:23.779Z",
    "updated_at": "2016-02-08T18:36:49.394Z",
    "archived": false,
    "entreprise": {
      "siren": "418166096",
      "capital_social": 459356,
      "numero_tva_intracommunautaire": "FR16418166096",
      "forme_juridique": "SA à directoire (s.a.i.)",
      "forme_juridique_code": "5699",
      "nom_commercial": "OCTO-TECHNOLOGY",
      "raison_sociale": "OCTO-TECHNOLOGY",
      "siret_siege_social": "41816609600051",
      "code_effectif_entreprise": "31",
      "date_creation": "1998-03-31T22:00:00.000Z",
      "nom": null,
      "prenom": null
    },
    "etablissement": {
      "siret": "41816609600051",
      "siege_social": true,
      "naf": "6202A",
      "libelle_naf": "Conseil en systèmes et logiciels informatiques",
      "adresse": "OCTO-TECHNOLOGY\\r\\n50 AV DES CHAMPS ELYSEES\\r\\n75008 PARIS 8\\r\\n",
      "numero_voie": "50",
      "type_voie": "AV",
      "nom_voie": "DES CHAMPS ELYSEES",
      "complement_adresse": null,
      "code_postal": "75008",
      "localite": "PARIS 8",
      "code_insee_localite": "75108"
    }
  }
}
</code>
</pre>
    EOS
    param :path, :procedure_id, :integer, :required, "Procédure ID"
    param :path, :id, :integer, :required, "Dossier ID"
    param :query, :token, :integer, :required, "Admin TOKEN"
    param_list :query, :format, :string, :optional, "Format de retour", [:json, :csv]
    response :ok, "Success", :Dossier
    response :unauthorized
    response :not_found
    response :not_acceptable
  end

  def index
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    dossiers = procedure.dossiers.where.not(state: :draft).paginate(page: params[:page])
    render json: dossiers, each_serializer: DossiersSerializer, meta: pagination(dossiers), meta_key: 'pagination', status: 200
  rescue ActiveRecord::RecordNotFound => e
    render json: {}, status: 404
  end

  def show
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    dossier = procedure.dossiers.find(params[:id])
    respond_to do |format|
      format.json { render json: dossier, status: 200 }
      format.csv  { render  csv: dossier, status: 200 }
    end
  rescue ActionController::UnknownFormat
    render json: {}, status: 406

  rescue ActiveRecord::RecordNotFound => e
    render json: {}, status: 404
  end

  def pagination(dossiers)
    {
        page: dossiers.current_page,
        resultats_par_page: dossiers.per_page,
        nombre_de_page: dossiers.total_pages
    }
  end
end