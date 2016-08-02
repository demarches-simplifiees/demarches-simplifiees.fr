class TypeDeChampPrivate < TypeDeChamp
  after_initialize :force_private_value

  default_scope { where(private: true) }

  def force_private_value
    self.private = true
  end
end