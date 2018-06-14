class Champs::DateChamp < Champ
  before_save :format_before_save

  private

  def format_before_save
    self.value =
      begin
        Date.parse(value).iso8601
      rescue
        nil
      end
  end
end
