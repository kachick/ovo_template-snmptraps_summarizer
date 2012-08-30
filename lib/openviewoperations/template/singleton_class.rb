require_relative 'parser'
require_relative 'snmptrapsparser'

module OpenViewOperations; class Template

  class << self

    # @return [Hash<Template>]
    def parse(str, type)
      const_get(:"#{type}Parser").parse str
    end

    # @return [Hash<Template>]
    def load(path)
      str = File.read path
      
      if /\ASYNTAX_VERSION \d+\n+(?<type>\w+) "/ =~ str
        parse str, type
      else
        raise ArgumentError, 'Unknown format'
      end
    end

  end

end; end