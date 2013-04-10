module Wonkavision
  module Analytics
    class CellSet
      class Member
        attr_reader :dimension, :attributes
        def initialize(dimension,member_data)
          @dimension = dimension
          @attributes = member_data
        end

        def caption
          attributes["caption"] || attributes["key"] || "Unkown"
        end

        def key
          attributes["key"]
        end

        def sort
          attributes["sort"] || attributes["caption"] || attributes["key"] || "Unknown"
        end

        def <=>(other)
          sort <=> other.sort
        end

        def to_s
          key.to_s
        end

        def to_key
          key
        end

        def serializable_hash(options={})
          hash = {
            :key => key
          }
          #if the caption and the key are the same,
          #then we won't bother sending both over the 
          #wire. Client logic should be use fall back to the key
          #if either the caption or sort are nil
          hash[:caption] = caption unless caption == key
          hash[:attributes] = attributes if options[:include_member_attributes]
          hash
        end

      end

    end
  end
end
