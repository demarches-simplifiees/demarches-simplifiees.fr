# frozen_string_literal: true

KeyableModel = Struct.new(:model_name, :to_key, :param_key, keyword_init: true)
