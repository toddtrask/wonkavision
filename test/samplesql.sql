select 
  account_age_from_dos.aging_category_name as account_age_from_dos_aging_category_name,
  primary_payer_type.payer_type as primary_payer_type_payer_type,
  primary_payer.payer_name as primary_payer_payer_name,
  min(account_age_from_dos.min_age) as account_age_from_dos_min_age,
  sum(current_balance) as current_balance_sum,
  count(current_balance) as current_balance_count,
  min(current_balance) as current_balance_min,
  max(current_balance) as current_balance_max,
  count(*) as record_count
from
  fact_transport as transports
  
join dim_aging_category as account_age_from_dos on account_age_from_dos.aging_category_key = transports.account_age_from_dos_key
join dim_payer as primary_payer on primary_payer.payer_key = transports.primary_payer_key
join dim_payer as primary_payer_type on primary_payer_type.payer_key = transports.primary_payer_key
join dim_division as division on division.division_key = transports.division_key
join dim_provider as provider on provider.provider_key  = transports.provider_key
where
  (division.division_key in (1))
  AND (provider.provider_name = 'REACH') 
  --AND transports.current_balance > 0
group by account_age_from_dos.aging_category_name, primary_payer_type.payer_type, primary_payer.payer_name
order by account_age_from_dos_min_age, primary_payer_type.payer_type

query do
   columns :account_age_from_dos
   rows :primary_payer_type, :primary_payer
   measures :current_balance
   where :division => 1, :provider.caption => 'REACH', :current_balance.gt => 0
end
