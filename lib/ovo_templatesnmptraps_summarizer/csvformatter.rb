#  Copyright (C) 2011  Kenichi Kamiya

require 'forwardable'
require 'csv'

module OVO_TemplateSNMPTraps_Summarizer

  class CSVFormatter
    
    extend Forwardable
    
    module ParameterFormattable
    
      attr_accessor :param_separator
    
      def to_s
        [].tap { |list|
          each_pair do |key, value|
            list << "#{key}: #{value}"
          end
        }.join param_separator
      end
      
    end
    
    COLUMNS = [
      %w[Index                   index],
      %w[c/Description           description],
      %w[c/Condition_ID          condition_id],
      %w[c/Enterprise            core.enterprise],
      %w[c/Generic               core.generic],
      %w[c/Specific              core.specific],
      %w[c/Varbinds              core.varbinds],
      %w[c/Nodes                 core.nodes],
      %w[!/Mode                  mode],
      %w[s/ServerLogOnly         set_serverlogonly],
      %w[j/Enable?               enable?],
      %w[s/Severity              set_severity],
      %w[s/MessageGroup          set_msggrp],
      %w[s/Application           set_application],
      %w[s/Object                set_object],
      %w[s/MessageType           set_msgtype],
      %w[s/AutoAction            set_autoaction],
      %w[s/Text                  set_text],
      %w[s/HelpText              set_helptext],
      %w[[!|c|s]/OtherParameters other_parameters]
    ]
    
    OTHER_SET_PARAMETERS = %w[
      SEPARATORS
      ICASE
      NODE
      FORWARDUNMATCHED
      SERVICE_NAME
      MSGKEY
      MSGKEYRELATION
      OPACTION
      NOTIFICATION
      TROUBLETICKET
      MPI_SV_DIVERT_MSG
      MPI_SV_COPY_MSG
      MPI_AGT_DIVERT_MSG
      MPI_AGT_COPY_MSG
      MPI_IMMEDIATE_LOCAL_ACTIONS 
      HELP
    ]
    
    class << self
      
      def columns
        COLUMNS
      end
      
      def headers
        COLUMNS.map(&:first)
      end
      
      def title
        headers.to_csv
      end
    end
    
    attr_reader :index
    
    def initialize(condition, index, template)
      @condition, @index, @template = condition, index, template
    end
    
    def_delegators :@condition,
                    :mode, :description, :supp_dupl_ident,
                    :supp_dupl_ident_output_msg, :condition_id, :core, :set
                    
    def_delegators :self.class, :headers, :title
    
    def row
      self.class.columns.map{|*, mname|instance_eval mname}
    end
    
    def to_s
      row.to_csv
    end
    
    OpenViewOperations::Template::Parser::SET_DEFINES.each do |prefix, *|
      key = prefix.downcase
      
      define_method "set_#{key}" do
        (set ? set[key] : nil) || \
        (@template.set[key] && "t/#{@template.set[key]}")
      end
    end
    
    def enable?
      case mode
      when :suppresscondition
        false
      else
        !set_serverlogonly
      end
    end
    
    def other_parameters
      result = {}
      
      %w(SUPP_DUPL_IDENT SUPP_DUPL_IDENT_OUTPUT_MSG).each do |name|
        value = __send__ name.downcase
        result["c/#{name}"] = value unless value == nil
      end
      
      OTHER_SET_PARAMETERS.each do |name|
        value = __send__ "set_#{name.downcase}"
        result["s/#{name}"] = value unless value == nil
      end
      
      if result.empty?
        nil
      else
        result.extend ParameterFormattable
        result.param_separator = param_separator
        result
      end
    end
    
    private
    
    def param_separator
      "\n"
    end
    
    class OneLine < self    
      
      def row
        super.map{|field|
          if field.kind_of? String
            field.gsub("\n"){'\n'}
          else
            field
          end
        }
      end
      
      private
      
      def param_separator
        ' | '
      end
      
    end
    
    class DBMain < self
      
      class << self
        
        def columns
          super.reject{|pair|pair.first == 'c/Nodes'}
        end
        
      end
      
    end

  end

end