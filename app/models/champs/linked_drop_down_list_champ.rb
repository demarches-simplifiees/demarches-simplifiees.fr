class Champs::LinkedDropDownListChamp < Champ
  attr_reader :master_value, :slave_value
  delegate :master_options, :slave_options, to: :type_de_champ

  after_initialize :unpack_value

  def unpack_value
    if value.present?
      master, slave = JSON.parse(value)
    else
      master = slave = ''
    end
    @master_value ||= master
    @slave_value ||= slave
  end

  def master_value=(value)
    @master_value = value
    pack_value
  end

  def slave_value=(value)
    @slave_value = value
    pack_value
  end

  def main_value_name
    :master_value
  end

  private

  def pack_value
    self.value = JSON.generate([ master_value, slave_value ])
  end
end
