class Champs::SiretController < Champs::ChampController
  def show
    if @champ.fetch_etablissement!(read_param_value(@champ.input_name, 'value'), current_user)
      @siret = @champ.etablissement.siret
    else
      @siret = @champ.etablissement_fetch_error_key
    end
  end
end
