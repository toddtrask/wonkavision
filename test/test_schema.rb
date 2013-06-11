class RevenueAnalytics
  include Wonkavision::Analytics::Schema

  store :active_record_store

  dimension :aging_category do
    sort :min_age
  end

  dimension :payer do
    key :payer_source_key
    attribute :payer_type
    sort :payer_name
  end

  dimension :payer_type do
    derived_from :payer
    key :payer_type
    caption :payer_type
  end

  dimension :division
  dimension :provider


  cube :denial do
    link_to :transport, :foreign_key => :account_key

    sum :denial_balance
    
    dimension :payer
    dimension :division, :through => :transport
    dimension :provider, :through => :transport
  end

  cube :transport do
    key :account_key

    sum :current_balance, :format=>:float, :precision=>2
    calc :avg_balance, :format=>:float do |cell|
      current_balance / record_count
    end

    dimension :account_age_from_dos, :as => :aging_category
    dimension :primary_payer, :as => :payer
    dimension :primary_payer_type, :as => :payer_type, :via=> :primary_payer
    dimension :current_payer, :as => :payer
    dimension :current_payer_type, :as => :payer_type, :via=> :current_payer
    dimension :division
    dimension :provider
  end
end

class CellsetSchema
  include Wonkavision::Analytics::Schema

  dimension :color, :sort => :color_key, :caption => :color_key
  dimension :size, :sort => :size_key, :caption => :size_key
  dimension :shape, :sort => :shape_key, :caption => :shape_key

  cube :test do
    dimension :color
    dimension :size
    dimension :shape


    measure :weight, :default_aggregation => :average, :format => :float, :precision => 2
    measure :cost, :default_aggregation => :sum, :format => :float, :precision => 1
    calc :weight_cost do |cell|
      if cell && !cell.weight.value.nil? && !cell.cost.value.nil?
        cell.weight.value * cell.cost.value
      else 
        nil
      end
    end

  end
end

