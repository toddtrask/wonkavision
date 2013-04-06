class RevenueAnalytics
  include Wonkavision::Analytics::Schema

  dimension :aging_category do
    sort :min_age
  end

  dimension :payer do
    attribute :payer_type
  end

  dimension :division
  dimension :provider

  cube :transport do
    key :account_key

    sum :current_balance, :format=>:float, :precision=>2

    dimension :account_age_from_dos, :as => :aging_category
    dimension :primary_payer, :as => :payer
    dimension :current_payer, :as => :payer
    dimension :division
    dimension :provider

  end
end