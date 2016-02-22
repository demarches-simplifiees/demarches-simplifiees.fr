class API::V1::ProceduresController < APIController

  swagger_controller :procedures, "Procédures"

  swagger_api :show do
    summary "Récupérer la liste de ses procédures."
    notes <<-EOS
<pre>
  <code>
{
  "procedure": {
    "label": "zklenkgnjzk",
    "link": "",
    "id": 2,
    "description": "nzgjenjkgzenkn",
    "organisation": "",
    "direction": "",
    "archived": false,
    "geographic_information": {
      "use_api_carto": true,
      "quartiers_prioritaires": false,
      "cadastre": false
    },
    "types_de_champ": [
      {
        "id": 1,
        "libelle": "fzeknfezkz",
        "type_champ": "text",
        "order_place": 0,
        "description": "zgezgze"
      },
      {
        "id": 2,
        "libelle": "gzzgeez",
        "type_champ": "text",
        "order_place": 1,
        "description": "zgezeg"
      },
      {
        "id": 3,
        "libelle": "zgezgzeg",
        "type_champ": "text",
        "order_place": 2,
        "description": "gezgzeg"
      }
    ],
    "types_de_piece_justificative": [
      {
        "id": 1,
        "libelle": "gzeezgzg",
        "description": "gzeegz"
      },
      {
        "id": 2,
        "libelle": "gzgzeg",
        "description": "gzeegz"
      }
    ]
  }
}
</code>
</pre>
    EOS
    param :path, :id, :integer, :required, "Procédure ID"
    param :query, :token, :integer, :required, "Admin TOKEN"
    response :ok, "Success", :Procedure
    response :unauthorized
    response :not_found
  end

  def show
    @procedure = current_administrateur.procedures.find(params[:id]).decorate

    render json: @procedure
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error(e.message)
    render json: {}, status: 404
  end
end
