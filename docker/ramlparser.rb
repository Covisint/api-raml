#!/usr/bin/env ruby

require 'fileutils'
require File.join(File.dirname($0), 'raml')

$DEBUG = false
$VERSION = ''

def log(msg)
  return unless $DEBUG;
  STDERR.puts(msg)
end

inputdir = ARGV.shift
outputdir = ARGV.shift
if (not inputdir or not outputdir or not File.directory?(inputdir))
  abort "usage: #{$0} <raml-dir> <output-dir>"
end

# Make sure output directory is empty
if (Dir.exists?(outputdir))
  abort "Output directory not empty: #{outputdir}" \
    unless Dir["#{outputdir}/*"].empty?
else
  log "Creating directory: #{outputdir}"
  Dir.mkdir(outputdir) or abort "Failed to create directory: #{outputdir}"
end

versions = [ '' ]
while (version = versions.shift)
  seen_versions = {}
  Dir[File.join(inputdir, "*.raml")].each do |inputfile|
    log "Processing file: #{inputfile}, version: #{version}" \
      if version.length > 0

    raml = RAML.new(inputfile)
    v = raml.filternodes(version)
    seen_versions.merge!(v)

    if (version.length > 0)
      # Generate version-specific RAML file
      outversdir = File.join(outputdir, version)
      Dir.mkdir(outversdir) unless Dir.exists?(outversdir)

      outvers = File.join(outversdir, File.basename(inputfile))
      puts "Generating file: #{outvers}"
      File.open(outvers, 'w') do |f|
        f.write raml.dump
      end
    end
  end

  if (version.length < 1)
    # First run -- populate versions list with seen versions
    versions = seen_versions.keys.sort
    puts "Generating RAMLs for versions: #{versions}"
  end
end
