# Copyright (C) 2011  Kenichi Kamiya

require 'logger'
require_relative 'openviewoperations/template'
require_relative 'openviewoperations/template/parser'
require_relative 'ovo_templatesnmptraps_summarizer/csvformatter'

class String
  def pathable
    gsub(%r![/:*?"<>|\\]!, '!')
  end
end

module OVO_TemplateSNMPTraps_Summarizer

  VERSION = '0.0.1'.freeze

  include OpenViewOperations

  FORMATTER = CSVFormatter
  TITLE     = FORMATTER.title
  
  module_function
  
  def run
    unless ARGV.length >= 1
      abort "usage: #{$PROGRAM_NAME} trap.dat [*trap.dat]"
    end
    
    ARGV.each do |path|
      logger = Logger.new "#{path}.log"
      logger.progname = :'OVOTemplate(SNMPTraps)Summarizer'

      begin
        templates = Template.load path
      rescue Exception
        logger.fatal 'Error occurred'
        raise
      else
        encoding = 'Windows-31J' # for Excel
        csv_options = {
          headers: TITLE,
          write_headers: true
        }
        
        templates.each_pair do |name, template|
          base_path = "#{path}.#{name.pathable}"
          
          CSV.open "#{base_path}.csv", "w:#{encoding}", csv_options do |out|
          CSV.open "#{base_path}.oneline.csv", "w:#{encoding}", csv_options do |oneline|
          CSV.open "#{base_path}.db-table.main.csv", "w:#{encoding}", headers: FORMATTER::DBMain.headers, write_headers: true do |db_main|
          CSV.open "#{base_path}.db-table.match-pair.csv", "w:#{encoding}", headers: %w[MainKey Index ConditionID Description IPAddress], write_headers: true do |db_match_pair|
            db_match_pair_mainkey = 1
            
            template.each_with_ovo_index do |cond, idx|
              
              formatter = FORMATTER.new cond, idx, template
              oneline_formatter = FORMATTER::OneLine.new cond, idx, template
              db_main_formatter = FORMATTER::DBMain.new cond, idx, template
              
              out << formatter.row
              oneline << oneline_formatter.row
              db_main << db_main_formatter.row
              
              if cond.core.nodes && !(cond.core.nodes.empty?)
                cond.core.nodes.each do |node|
                  db_match_pair << [db_match_pair_mainkey, idx, cond.condition_id, cond.description, node.ipaddress]
                  db_match_pair_mainkey += 1
                end
              else
                db_match_pair << [db_match_pair_mainkey, idx, cond.condition_id, cond.description, nil]
                db_match_pair_mainkey += 1
              end
              
            end
          end
          end
          end
          end
        end

        logger.info 'Complete'
      end
    end
  end

end