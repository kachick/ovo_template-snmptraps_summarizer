require 'striuct'

module OpenViewOperations; class Template; class SNMPTrapsParser

  Core = Striuct.define do

    member :enterprise, String
    member :generic, Integer
    member :specific, Integer
    member :varbinds, CAN(:each_pair)
    alias_member :varbind, :varbinds
    member :nodes, GENERICS(Node)
    alias_member :node, :nodes

  end

end; end; end