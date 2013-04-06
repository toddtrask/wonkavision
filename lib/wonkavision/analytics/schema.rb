module Wonkavision
  module Analytics
    module Schema
      extend ActiveSupport::Concern

      included do
        class_attribute :schema_options, :instance_writer => false
        self.schema_options = {}

        class_attribute :dimensions, :instance_writer => false
        self.dimensions = {}

        class_attribute :cubes, :instance_write => false
        self.cubes = {}
      end

      module ClassMethods
        
        def dimension(name, options={}, &block)
          dimensions[name] = Dimension.new(self, name,options,&block)
        end

        def cube(name, options={}, &block)
          cubes[name] = Cube.new(self, name,options,&block)
        end

      end

    end
  end
end