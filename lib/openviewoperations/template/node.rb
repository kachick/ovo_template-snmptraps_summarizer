require 'striuct'

module OpenViewOperations; class Template

  Node = Striuct.define do

    member :ipaddress, AND(String, /\A(?:\d{1,3}\.){3}\d{1,3}\z/)
    member :hostname, AND(String, /\A\S+\z/)

    def inspect
      "IP: #{ipaddress} - Hostname: #{hostname}"
    end

  end

end; end
