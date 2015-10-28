module Elasticsearch
  module Model

    # Contains functionality for serializing model instances for the client
    #
    module Serializing

      module ClassMethods
      end

      module InstanceMethods

        # Serialize the record as a Hash, to be passed to the client.
        #
        # Re-define this method to customize the serialization.
        #
        # @return [Hash]
        #
        # @example Return the model instance as a Hash
        #
        #     Article.first.__elasticsearch__.as_indexed_json
        #     => {"title"=>"Foo"}
        #
        # @see Elasticsearch::Model::Indexing
        #
        def as_indexed_json(options={})
          build_indexed_json(
            target.class.mappings.instance_variable_get(:@mapping),
            target,
            {id: target.id.to_s}
          ).as_json(options.merge root: false)
        end

      private

        def build_indexed_json(mappings, model, json)
          return json unless model.respond_to? :[]

          if model.kind_of? Array
            build_array_json(mappings, model, json)
          else
            build_hash_json(mappings, model, json)
          end

          json
        end

        def build_array_json(mappings, model, json)
          return json unless model.respond_to?(:[]) && json.kind_of?(Array)

          model.each do |elem|
            elem_json = if elem.kind_of? Array then [] else {} end
            json << elem_json
            build_indexed_json(mappings, elem, elem_json)
          end
        end

        def build_hash_json(mappings, model, json)
          return json unless model.respond_to?(:[]) && json.kind_of?(Hash)

          mappings.each_pair do |field, option|

            # Custom transformer
            if option.has_key?(:as) && option[:as].kind_of?(Proc)
              json[field] = target.instance_exec(get_field(model, field), &option[:as])

            # A nested field
            elsif option.has_key?(:properties)
              json[field] = if get_field(model, field).kind_of? Array then [] else {} end
              build_indexed_json(option[:properties], get_field(model, field), json[field])

            # Normal case
            else
              json[field] = get_field(model, field)
            end
          end
        end

        def get_field(model, field_name)
          model.try(:[], field_name) || model.try(field_name)
        end
      end

    end
  end
end
