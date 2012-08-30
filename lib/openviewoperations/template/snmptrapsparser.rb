require_relative 'parser'

module OpenViewOperations; class Template

  class SNMPTrapsParser < Parser
    
    private
    
    def template_type
      :SNMP
    end
    
    def parse_core
      if parse_flag :CONDITION
        Core.new.tap do |result|
          (enterprise = parse_quoted :'$e') && \
          result[:enterprise] = enterprise
          
          (generic    = parse_naked :'$G')  && \
          result[:generic]    = Integer(generic)
          
          (specific   = parse_naked :'$S')  && \
          result[:specific]   = Integer(specific)
          
          (node       = parse_node)         && \
          result[:node]       = node
          
          (varbind    = parse_varbind)      && \
          result[:varbind]    = varbind
        end
      end
    end

    def parse_varbind
      result = {}
      
      while scan(/ +\$(\d+) "(.+?)(?<!\\)"/)
        binding_number = @scanner[1].to_i
        result[binding_number] = {:pattern => @scanner[2]}

        scan(/ +SEPARATORS "(.+?)(?<!\\)"/) && \
        result[binding_number][:SEPARATORS] = @scanner[1]
        
        scan(/ +ICASE/)              && \
        result[binding_number][:ICASE]      = true
        
        trim_blank
      end

      result.empty? ? nil : result
    end

  end

  SNMPParser = SNMPTrapsParser

end; end

require_relative 'snmptrapsparser/core'