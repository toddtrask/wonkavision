Wonkavision
===========

Wonkavision is a lightweight Ruby library that allows you to easily define simple multi-dimensional data views on top of a [star](https://en.wikipedia.org/wiki/Star_schema) or [snowflake](https://en.wikipedia.org/wiki/Snowflake_schema) shaped relational database.

Wonkavision is not intended to replace more full featured OLAP servers such as [Mondrian](http://community.pentaho.com/projects/mondrian/) or [Analysis Services](http://www.microsoft.com/en-us/server-cloud/solutions/business-intelligence/analysis.aspx), but rather provides a fast, flexible way to perform the most common types of multi-dimensional queries needed in business dashboards. Wonkavision can be embedded in your Rails app and used directly or it easily be used to expose an HTTP API to allow external applications to query your apps Wonkavision cubes using HTTP or our [Ruby](https://github.com/sunfishtech/wonkavision-client) or [JavaScript](https://github.com/sunfishtech/wonkavision-js) clients.



Cube Definition DSL
===================
Wonkavision exposes a simple DSL that can be used to define data "cubes" that can be queried using the Wonkavision Query API. In [data warehousing](https://en.wikipedia.org/wiki/Data_warehouse) as with Wonkavision data points are called "[facts](https://en.wikipedia.org/wiki/Data_warehouse#Facts)" and stored in a "fact table," and descriptive data that we want to slice and dice by are called "[dimensions](https://en.wikipedia.org/wiki/Data_warehouse#Dimensional_vs._normalized_approach_for_storage_of_data)." 

```ruby
class RevenueAnalytics
  include Wonkavision::Analytics::Schema

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

  dimension :payer_sexiness do
    derived_from :payer

    calculate :payer_sexiness_key,
              "CASE WHEN payer_key < 100 THEN 'hot' ELSE 'bothered' END"

    caption :payer_sexiness_key
  end

  dimension :division
  dimension :provider

  cube :transport do
  	key :account_key

    sum :current_balance, :format=>:dollars, :precision=>2
    calc :avg_balance, :format=>:dollars do 
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
```

With these cubes and facts defined, we can now query the database:

```ruby
Wonkavision::Analytics::Query.new do
	from :transport
	columns :division, :provider
	rows :payer_type
	measures :avg_balance, :current_balance, :record_count
	where :dimensions.division.key = 150
end.execute
```

Convention over Configuration
=============================


How It Works
============

Contributing
============
