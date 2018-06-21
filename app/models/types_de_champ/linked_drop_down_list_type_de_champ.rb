class TypesDeChamp::LinkedDropDownListTypeDeChamp < TypeDeChamp
  MASTER_PATTERN = /^--(.*)--$/

  def master_options
    master_options = unpack_options.map(&:first)
    if master_options.present?
      master_options.unshift('')
    end
    master_options
  end

  def slave_options
    slave_options = unpack_options.to_h
    if slave_options.present?
      slave_options[''] = []
    end
    slave_options
  end

  private

  def unpack_options
    _, *options = drop_down_list.options
    chunked = options.slice_before(MASTER_PATTERN)
    chunked.map do |chunk|
      master, *slave = chunk
      slave.unshift('')
      [MASTER_PATTERN.match(master)[1], slave]
    end
  end
end
