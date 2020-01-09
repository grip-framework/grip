require "json"

module Grip::DB
  macro parent(path)
    Grip::DB::Connections << Grip::DB::Base.new({{path}})
  end

  def storage(path, &block)
    yield Grip::DB::Connections[path]
  end

  macro store(key, value)
    db.set({{key}}, {{value}}.to_json)
  end

  macro retrieve(key)
    db.get({{key}}).to_s
  end

  macro schema(_properties_, strict = false)
        {% for key, value in _properties_ %}
            {% _properties_[key] = {type: value} unless value.is_a?(HashLiteral) || value.is_a?(NamedTupleLiteral) %}
        {% end %}
    
        {% for key, value in _properties_ %}
            {% _properties_[key][:key_id] = key.id.gsub(/\?$/, "") %}
        {% end %}
    
        {% for key, value in _properties_ %}
            @{{value[:key_id]}} : {{value[:type]}}{{ (value[:nilable] ? "?" : "").id }}
    
            {% if value[:setter] == nil ? true : value[:setter] %}
                def {{value[:key_id]}}=(_{{value[:key_id]}} : {{value[:type]}}{{ (value[:nilable] ? "?" : "").id }})
                    @{{value[:key_id]}} = _{{value[:key_id]}}
                end
            {% end %}
    
            {% if value[:getter] == nil ? true : value[:getter] %}
                def {{key.id}} : {{value[:type]}}{{ (value[:nilable] ? "?" : "").id }}
                    @{{value[:key_id]}}
                end
            {% end %}
    
            {% if value[:presence] %}
                @{{value[:key_id]}}_present : Bool = false
    
                def {{value[:key_id]}}_present?
                    @{{value[:key_id]}}_present
                end
            {% end %}
        {% end %}
    
        def initialize(%pull : JSON::PullParser)
            {% for key, value in _properties_ %}
                %var{key.id} = nil
                %found{key.id} = false
            {% end %}
    
            %location = %pull.location
            begin
                %pull.read_begin_object
            rescue exc : JSON::ParseException
                raise JSON::MappingError.new(exc.message, self.class.to_s, nil, *%location, exc)
            end
            until %pull.kind.end_object?
                %key_location = %pull.location
                key = %pull.read_object_key
                case key
                {% for key, value in _properties_ %}
                    when {{value[:key] || value[:key_id].stringify}}
                    %found{key.id} = true
                    begin
                        %var{key.id} =
                        {% if value[:nilable] || value[:default] != nil %} %pull.read_null_or { {% end %}
    
                        {% if value[:root] %}
                            %pull.on_key!({{value[:root]}}) do
                        {% end %}
    
                        {% if value[:converter] %}
                            {{value[:converter]}}.from_json(%pull)
                        {% elsif value[:type].is_a?(Path) || value[:type].is_a?(Generic) %}
                            {{value[:type]}}.new(%pull)
                        {% else %}
                            ::Union({{value[:type]}}).new(%pull)
                        {% end %}
    
                        {% if value[:root] %}
                            end
                        {% end %}
    
                        {% if value[:nilable] || value[:default] != nil %} } {% end %}
                    rescue exc : JSON::ParseException
                        raise JSON::MappingError.new(exc.message, self.class.to_s, {{value[:key] || value[:key_id].stringify}}, *%key_location, exc)
                    end
                {% end %}
                else
                    {% if strict %}
                        raise JSON::MappingError.new("Unknown JSON attribute: #{key}", self.class.to_s, nil, *%key_location, nil)
                    {% else %}
                        %pull.skip
                    {% end %}
                end
            end
            %pull.read_next
    
            {% for key, value in _properties_ %}
                {% unless value[:nilable] || value[:default] != nil %}
                    if %var{key.id}.nil? && !%found{key.id} && !::Union({{value[:type]}}).nilable?
                        raise JSON::MappingError.new("Missing JSON attribute: {{(value[:key] || value[:key_id]).id}}", self.class.to_s, nil, *%location, nil)
                    end
                {% end %}
    
                {% if value[:nilable] %}
                    {% if value[:default] != nil %}
                        @{{value[:key_id]}} = %found{key.id} ? %var{key.id} : {{value[:default]}}
                    {% else %}
                        @{{value[:key_id]}} = %var{key.id}
                    {% end %}
                {% elsif value[:default] != nil %}
                    @{{value[:key_id]}} = %var{key.id}.nil? ? {{value[:default]}} : %var{key.id}
                {% else %}
                    @{{value[:key_id]}} = (%var{key.id}).as({{value[:type]}})
                {% end %}
    
                {% if value[:presence] %}
                    @{{value[:key_id]}}_present = %found{key.id}
                {% end %}
            {% end %}
        end
    
        def to_json(json : JSON::Builder)
            json.object do
                {% for key, value in _properties_ %}
                    _{{value[:key_id]}} = @{{value[:key_id]}}
    
                    {% unless value[:emit_null] %}
                        unless _{{value[:key_id]}}.nil?
                    {% end %}
    
                    json.field({{value[:key] || value[:key_id].stringify}}) do
                        {% if value[:root] %}
                            {% if value[:emit_null] %}
                                if _{{value[:key_id]}}.nil?
                                    nil.to_json(json)
                                else
                            {% end %}
    
                            json.object do
                            json.field({{value[:root]}}) do
                        {% end %}
    
                        {% if value[:converter] %}
                            if _{{value[:key_id]}}
                                {{ value[:converter] }}.to_json(_{{value[:key_id]}}, json)
                            else
                                nil.to_json(json)
                            end
                        {% else %}
                            _{{value[:key_id]}}.to_json(json)
                        {% end %}
    
                        {% if value[:root] %}
                            {% if value[:emit_null] %}
                                end
                            {% end %}
                            end
                        end
                        {% end %}
                    end
    
                    {% unless value[:emit_null] %}
                        end
                    {% end %}
                {% end %}
            end
        end
    
        def to_safe
            string = JSON.build do |json|
                json.object do
                    {% for key, value in _properties_ %}
                        if !{{value[:hidden]}}
                            _{{value[:key_id]}} = @{{value[:key_id]}}
    
                            {% unless value[:emit_null] %}
                                unless _{{value[:key_id]}}.nil?
                            {% end %}
    
                            json.field({{value[:key] || value[:key_id].stringify}}) do
                                {% if value[:root] %}
                                    {% if value[:emit_null] %}
                                        if _{{value[:key_id]}}.nil?
                                            nil.to_json(json)
                                        else
                                    {% end %}
    
                                    json.object do
                                    json.field({{value[:root]}}) do
                                {% end %}
    
                                {% if value[:converter] %}
                                    if _{{value[:key_id]}}
                                        {{ value[:converter] }}.to_json(_{{value[:key_id]}}, json)
                                    else
                                        nil.to_json(json)
                                    end
                                {% else %}
                                    _{{value[:key_id]}}.to_json(json)
                                {% end %}
    
                                {% if value[:root] %}
                                    {% if value[:emit_null] %}
                                        end
                                    {% end %}
                                    end
                                end
                                {% end %}
                            end
    
                            {% unless value[:emit_null] %}
                                end
                            {% end %}
                        end
                    {% end %}
                end
            end
            JSON.parse(string)
        end
    end

  # This is a convenience method to allow invoking `JSON.mapping`
  # with named arguments instead of with a hash/named-tuple literal.
  macro schema(**_properties_)
        schema({{_properties_}})
    end

  class MappingError < JSON::ParseException
    getter klass : String
    getter attribute : String?

    def initialize(message : String?, @klass : String, @attribute : String?, line_number : Int32, column_number : Int32, cause)
      message = String.build do |io|
        io << message
        io << "\n  parsing "
        io << klass
        if attribute = @attribute
          io << '#' << attribute
        end
      end
      super(message, line_number, column_number, cause)
      if cause
        @line_number, @column_number = cause.location
      end
    end
  end
end
