module Administrations
  class StatsController < ApplicationController
    before_action :authenticate_administration!

    def index
      procedures = Procedure.where(created_at: Time.current.all_quarter).group("date_trunc('day', created_at)").count
      dossiers = Dossier.where(created_at: Time.current.all_quarter).group("date_trunc('day', created_at)").count
      @procedures = clean_hash(procedures)
      @dossiers = clean_hash(dossiers)
    end

    private

    def clean_hash h
      h.keys.each{ |key| h[key.to_date] = h[key]; h.delete(key) }
      min_date = h.keys.min
      max_date = h.keys.max
      (min_date..max_date).each do |date|
        h[date] = 0 if h[date].nil?
      end
      h
    end
  end
end
