# Copyright (C) 2011  Kenichi Kamiya

require 'forwardable'
require 'striuct'

module OpenViewOperations

  class Template < Striuct
    extend Forwardable
    
    SYNTAX_VERSION = '5'.freeze

    Condition = Striuct.define do
      member :mode, AND(Symbol, /\A[^\n]+\z/)
      member :description, AND(String, /\A[^\n]+\z/)
      member :supp_dupl_ident, OR(CAN(:each_pair), nil)
      member :supp_dupl_ident_output_msg, OR(CAN(:each_pair), nil)
      member :condition_id, AND(Symbol, /\A[^\n]+\z/)
      member :core, ->v{v.class.name.slice(/([^:]+)\z/, 1) == 'Core'}
      member :set, CAN(:each_pair)
    end

    Node = Striuct.define do
      member :ipaddress, AND(String, /\A(?:\d{1,3}\.){3}\d{1,3}\z/)
      member :hostname, AND(String, /\A\S+\z/)

      def inspect
        "IP: #{ipaddress} - Hostname: #{hostname}"
      end
    end
    
    member :name, AND(String, /\A[^\n]+\z/)
    member :description, AND(String, /\A[^\n]+\z/)
    member :set, CAN(:each_pair)
    member :conditions, GENERICS(Condition)
    close
    
    class << self
      def parse(str, type)
        instance_eval("self::Parser::#{type}").parse str
      end
      
      def load(path)
        str = File.read path
        
        if /\ASYNTAX_VERSION \d+\n+(?<type>\w+) "/ =~ str
          parse str, type
        else
          raise ArgumentError, 'Unknown format'
        end
      end
    end
    
    def_delegators :conditions, :each, :each_with_index
    
    def each_with_ovo_index
      return to_enum(__callee__) unless block_given?
      each_with_index {|v, i|yield v, i + 1}
    end
  end

end