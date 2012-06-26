# Copyright (C) 2011  Kenichi Kamiya

require 'striuct'

module OpenViewOperations; class Template; class Parser

  class SNMPTraps < self
    
    Core = Striuct.define do
      member :enterprise, String
      member :generic, Integer
      member :specific, Integer
      member :varbinds, CAN(:each_pair)
      alias_member :varbind, :varbinds
      member :nodes, GENERICS(Node)
      alias_member :node, :nodes
    end
    
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

  SNMP = SNMPTraps

end; end; end