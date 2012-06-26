# Copyright (C) 2011  Kenichi Kamiya

require 'strscan'
require 'forwardable'

module OpenViewOperations; class Template

  class Parser
    module TextUtil
      module_function
    
      def generate_naked_pattern(prefix)
        /^ +#{Regexp.escape prefix} (\S+)\n/
      end
      
      def generate_quoted_pattern(prefix)
        /^ +#{Regexp.escape prefix} "(.+?)(?<!\\)"\n/
      end

      def generate_mquoted_pattern(prefix)
        /^ +#{Regexp.escape prefix} "(.+?)(?<!\\)"\n/m
      end
      
      def generate_flag_pattern(prefix)
        /^ +#{Regexp.escape prefix}\n/
      end
    end
    
    extend Forwardable
    extend TextUtil
    include TextUtil

    class MalformedSourceError < StandardError
    end

    SET_DEFINES = [
      [:SERVERLOGONLY,               :flag],
      [:SEVERITY,                    :naked], 
      [:SEPARATORS,                  :quoted],
      [:ICASE,                       :flag],
      [:NODE,                        :specific], 
      [:APPLICATION,                 :quoted],
      [:MSGGRP,                      :quoted], 
      [:OBJECT,                      :quoted],
      [:FORWARDUNMATCHED,            :flag],
      [:MSGTYPE,                     :quoted],
      [:SERVICE_NAME,                :quoted],
      [:MSGKEY,                      :quoted  ],
      [:MSGKEYRELATION,              :specific],
      [:TEXT,                        :mquoted ], 
      [:AUTOACTION,                  :specific],
      [:OPACTION,                    :specific],
      [:NOTIFICATION,                :flag    ],
      [:TROUBLETICKET,               :specific],
      [:MPI_SV_DIVERT_MSG,           :flag],
      [:MPI_SV_COPY_MSG,             :flag],
      [:MPI_AGT_DIVERT_MSG,          :flag],
      [:MPI_AGT_COPY_MSG,            :flag],
      [:MPI_IMMEDIATE_LOCAL_ACTIONS, :flag],
      [:HELPTEXT,                    :mquoted],
      [:HELP,                        :specific]
    ].each(&:freeze).freeze
    
    class << self
      def parse(str)
        new(str).parse
      end
    end
    
    def initialize(str)
      @scanner = StringScanner.new str
      @version = nil
      @templates = {}
    end

    def parse
      @version = parse_template_version
      
      $stderr.puts 'Unknown version' unless @version == SYNTAX_VERSION
      
      trim_blank
      
      while name = parse_template_name
        @templates[name] = Template.new name, parse_description, parse_set, []
        template = @templates[name]
        
        while mode = parse_entering_condtions
          while (condition = parse_condition) && condition.mode = mode
            template.conditions << condition 
          end
        end
        
        trim_blank
      end
      
      eos? ? @templates : error('Rest is.')
    end
    
    # easy access to scanner
    def_delegators :@scanner, :scan, :scan_until, :eos?, :rest, :terminate
    private :scan, :scan_until, :eos?, :rest, :terminate

    private
    
    # Alert and Dubbuging
    
    def error(message=nil)
      raise(MalformedSourceError,
        [ "\n",
          "Message: #{message}", 
          "Scanner: #{@scanner.inspect}",
          "Rest: \n#{rest[0..200].inspect}",
        ].join("\n")
      )
    end

    # Parse Template Parameter
    
    def template_type
      raise 'Override this method.'
    end
    
    def parse_template_name
      scan(/^#{template_type} "(.+)"\n/) && @scanner[1]
    end

    def parse_template_version
      scan(/\ASYNTAX_VERSION (\d+)\n/) && @scanner[1]
    end
    
    def parse_entering_condtions
      if scan(/ +((?:MSG|SUPPRESS|SUPP_UNM_)CONDITION)S\n/)
        @scanner[1].downcase.to_sym
      end
    end
    
    # Parse Common Format
    
    # define parse methods for common format
    %w[naked quoted mquoted].each do |type|
      define_method "parse_#{type}" do |prefix|
        scan(__send__ "generate_#{type}_pattern", prefix) && \
        @scanner[1].gsub(/\\(")/){$1}.gsub(/\\(\\)/){$1}
      end
    end

    def parse_flag(prefix)
      scan(generate_flag_pattern prefix) && true
    end
    
    def parse_id(prefix)
      (str = parse_quoted prefix) && str.to_sym
    end

    def parse_node
      if scan(/ +NODE /)
        [].tap do |result|
          while scan(/IP (\S+)  "(.+?)"/)
            result << Node.new(@scanner[1], @scanner[2])
          end
          
          trim_blank
        end
      end
    end
    
    def trim_blank
      scan(/^\n+/m)
    end

    # Parse Core Parameter
    
    def parse_core
      raise 'Override this method.'
    end
    
    def parse_condition
      if description = parse_description
        Condition.new.tap do |condition|
          condition.description     = description
          condition.supp_dupl_ident = parse_supp_dupl_ident
          condition.supp_dupl_ident_output_msg = \
          parse_supp_dupl_ident_output_msg
          condition.condition_id    = parse_id :CONDITION_ID
          condition.core            = parse_core
          
          if parse_flag :SET
            condition.set = parse_set
          end
        end
      end
    end
    
    def parse_description
      parse_quoted :DESCRIPTION
    end

    def parse_supp_dupl_ident
      if parse_flag :SUPP_DUPL_IDENT
        parse_common_supp_dupl_ident
      end
    end
    
    def parse_supp_dupl_ident_output_msg
      if parse_flag :SUPP_DUPL_IDENT_OUTPUT_MSG
        parse_common_supp_dupl_ident
      end
    end
    
    def parse_common_supp_dupl_ident
      {}.tap do |result|
        scan(/ +"(.+?)"/)                   && result[:time1] = @scanner[1]
        scan(/ +RESEND "(.+)"\n/)           && result[:resend] = @scanner[1]
        trim_blank
        scan(/ +"(.+)"\n/)                  && result[:time2] = @scanner[1]
        scan(/ +COUNTER_THRESHOLD (\d+)\n/) && \
        result[:counter_threshold] = @scanner[1]
      end
    end

    #  Parse Set Parameter
    
    def parse_set
      {}.tap do |result|
        SET_DEFINES.each do |prefix, type|
          name = prefix.downcase
          value = __send__ "parse_set_#{name}"
          result[name] = value if value
        end
      end
    end
    
    # define parse methods of SET-Parameter
    SET_DEFINES.each do |prefix, type|
      name = "parse_set_#{prefix.downcase}"

      case type
      when :specific
        next
      when :quoted, :mquoted, :naked
        pattern = __send__ "generate_#{type}_pattern", prefix

        define_method name do
          scan(pattern) && @scanner[1]
        end
      when :flag
        pattern = generate_flag_pattern prefix
        
        define_method name do
          scan(pattern) && true
        end
      else 
        raise 'must not happen'
      end
    end

    def parse_set_msgkeyrelation
      if scan(/^ +MSGKEYRELATION/)
        {}.tap do |result|
          scan(/ ACK/)                 && result[:ACK]        = true
          scan(/ +"(.+?)(?<!\\)"/)            && result[:body]       = @scanner[1]
          scan(/ +SEPARATORS "(.+?)(?<!\\)"/) && result[:SEPARATORS] = @scanner[1]
          scan(/ +ICASE/)              && result[:ICASE]      = true
          trim_blank
        end
      end
    end
    
    alias_method :parse_set_node, :parse_node
    
    def parse_set_opaction
      if scan(/^ +OPACTION "(.+?)(?<!\\)"/)
        parse_set_action({command: @scanner[1]})
      end
    end
    
    def parse_set_autoaction
      if scan(/^ +AUTOACTION "(.+?)(?<!\\)"/)
        parse_set_action({command: @scanner[1]})
      end
    end
    
    set_action_flag_patterns = %w[
      ANNOTATE
      ACK
      SEND_MSG_AFTER_LOC_AA
      SEND_OK_MSG
      LOGONLY
      SEND_FAILED_MSG
    ].map{|flag|[flag.to_sym, /^ +#{Regexp.escape flag}/]}

    define_method :parse_set_action do |container={}|
      container.tap do |result|
        scan(/ ACTIONNODE IP (\S+)  "(.+?)(?<!\\)"/) && \
        result[:node] = Node.new(@scanner[1], @scanner[2])
        
        set_action_flag_patterns.each do |flag, pattern|
          scan(pattern) && result[flag] = true
          trim_blank
        end
      end
    end
    
    def parse_set_troubleticket
      if scan(/ +TROUBLETICKET/)
        {}.tap do |result|
          scan(/ +ANNOTATE/) && result[:ANNOTATE] = true 
          scan(/ +ACK/)      && result[:ACK] = true
          trim_blank
        end
      end
    end
    
    def parse_set_help
      parse_id :HELP
    end
  
  end
  
end; end

require_relative 'parser/snmptraps'