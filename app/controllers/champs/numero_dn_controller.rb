class Champs::NumeroDnController < Champs::ChampController
  def show
    @dn = params[:dn]
    @ddn = params[:ddn]

    @status = dn_empty? || bad_dn_format? || bad_ddn_format?
    return if @status
    check_dn
  end

  private

  def dn_empty?
    @dn.empty? ? :empty : nil
  end

  def bad_dn_format?
    /\d{6,7}/.match?(@dn) ? nil : :bad_dn_format
  end

  def bad_ddn_format?
    begin
      @ddn = Date.parse(@ddn)
      # don't even call CPS WS if user has not finished giving the year (0196)
      return :bad_ddn_format if @ddn.year < 1900
    rescue
      return :bad_ddn_format
    end
  end

  def set_dn_ddn
    # @champ = policy_scope(Champ).find(params[:champ_id])
    # @linked_dossier_id = read_param_value(@champ.input_name, 'value')
    @base_id = "dossier_"
    champs   = params[:dossier]
    loop do
      key = champs.keys[0]
      champs = champs[key]
      @base_id += key + '_'
      return if champs.empty?
      break if champs.key?(:numero_dn) || champs.key?(:date_de_naissance)
    end
    @ddn = champs[:date_de_naissance] || params[:ddn]
    @dn  = champs[:numero_dn] || params[:dn]
  end

  def check_dn
    result = APICps::API.new().verify({ @dn => @ddn })
    case result[@dn]
    when 'true'
      @status = :good_dn
    when 'false'
      @status = :bad_ddn
    else
      @status = :bad_dn
    end
  rescue APIEntreprise::API::Error::RequestFailed
    @status = :network_error
  end
end
