class Champs::RNFChamp < Champ
  store_accessor :data, :title, :email, :phone, :createdAt, :updatedAt, :dissolvedAt, :address, :status

  def rnf_id
    external_id
  end

  def fetch_external_data
    RNFService.new.(rnf_id:)
  end

  def fetch_external_data?
    true
  end

  def poll_external_data?
    true
  end

  def blank?
    rnf_id.blank?
  end
end
