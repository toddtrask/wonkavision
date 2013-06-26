module Wonkavision
  module Analytics
    module Schema
      class LinkedCube
        attr_reader :cube, :name, :linked_cube_name, :options

        def initialize(cube, linked_cube_name, options={},&block)
          @cube = cube
          @name = options[:as] || linked_cube_name
          @linked_cube_name = linked_cube_name
          @options = options
          @foreign_key = options[:foreign_key]
          @join_on = options[:join_on]

          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
        end

        def schema
          @cube.schema
        end

        def foreign_key(key = nil)
          return @foreign_key || "#{linked_cube.table_name}_key" unless key
          @foreign_key = key
        end

        def linked_cube
          unless @linked_cube ||= schema.cubes[linked_cube_name]
            raise "Cannot linke to #{linked_cube_name} because it does not exist"
          end
          @linked_cube
        end

        def through(linked_cube_name=nil)
          return linked_cube unless linked_cube_name
          @linked_cube = nil
          @linked_cube_name = linked_cube_name
        end

        def join_on(join_hash = nil)
          if join_hash
            @join_on = join_hash
          else
            @join_on ||= {foreign_key => linked_cube.key}
          end
        end
      end
    end
  end
end

