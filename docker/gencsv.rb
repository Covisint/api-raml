#!/usr/bin/env ruby

require 'csv'
require File.join(File.dirname($0), 'raml')

inputdir = ARGV.shift
outputdir = ARGV.shift
if (not inputdir or not outputdir or not File.directory?(inputdir))
  abort "usage: #{$0} <raml-dir> <output-dir>"
end

# Make sure output directory is empty
if (Dir.exists?(outputdir))
  abort "Output directory not empty: #{outputdir.sub(/^\/raml\//, '')}" \
    unless Dir["#{outputdir}/*"].empty?
else
  puts "Creating directory: #{outputdir}"
  Dir.mkdir(outputdir) or abort "Failed to create directory: #{outputdir}"
end

Dir[File.join(inputdir, '*.raml')].each do |inputfile|
  outputfile = File.join(outputdir, File.basename(inputfile, '.raml') + '.csv')

  raml = RAML.new(inputfile)

  list = []
  raml.all_resources.each do |res|
    res.actions.each do |act|
      entitlement = act.value_of('entitlement')
      list.push([ act.type.upcase, res.uri, act.description, act.since, act.visibility, entitlement ])
    end
  end

  headers = %w( Action URI Description Since Visibility Entitlement )
  CSV.open(outputfile, 'w', :headers => headers, :write_headers => true) do |csv|
    list.each do |row|
      csv << row
    end
  end
end
