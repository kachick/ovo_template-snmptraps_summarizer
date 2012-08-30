require 'forwardable'
require 'striuct'

module OpenViewOperations

  class Template < Striuct

    extend Forwardable
    
    SYNTAX_VERSION = '5'.freeze
    
    member :name, AND(String, /\A[^\n]+\z/)
    member :description, AND(String, /\A[^\n]+\z/)
    member :set, CAN(:each_pair)
    member :conditions, GENERICS(Condition)
    close_member
    
    def_delegators :conditions, :each, :each_with_index
    
    def each_with_ovo_index
      return to_enum(__callee__) unless block_given?
      each_with_index {|v, i|yield v, i + 1}
    end

  end

end

require_relative 'template/condition'
require_relative 'template/node'
require_relative 'template/singleton_class'