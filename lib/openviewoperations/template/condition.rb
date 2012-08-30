require 'striuct'

module OpenViewOperations; class Template

  Condition = Striuct.define do

    member :mode, AND(Symbol, /\A[^\n]+\z/)
    member :description, AND(String, /\A[^\n]+\z/)
    member :supp_dupl_ident, OR(CAN(:each_pair), nil)
    member :supp_dupl_ident_output_msg, OR(CAN(:each_pair), nil)
    member :condition_id, AND(Symbol, /\A[^\n]+\z/)
    member :core, ->v{v.class.name.slice(/([^:]+)\z/, 1) == 'Core'}
    member :set, CAN(:each_pair)

  end

end; end
