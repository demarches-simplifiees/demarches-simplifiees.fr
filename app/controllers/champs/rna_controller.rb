class Champs::RNAController < Champs::ChampController
  def show
    rna = read_param_value(@champ.input_name, 'value')

    unless @champ.fetch_association!(rna)
      @error = @champ.association_fetch_error_key
    end
  end
end
