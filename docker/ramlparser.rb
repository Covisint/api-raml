#!/usr/bin/env ruby

require 'fileutils'
require 'yaml'
require File.join(File.dirname($0), 'raml')

$DEBUG = false
$VERSION = ''

def log(msg)
  return unless $DEBUG;
  STDERR.puts(msg)
end

inputdir = ARGV.shift
outputbase = ARGV.shift
manifest = ARGV.shift
if (not inputdir or not outputbase or not File.directory?(inputdir))
  abort "usage: #{$0} <raml-dir> <output-dir> [<release-manifest>]"
end

# Make sure output directories are empty
outputdir = File.join(outputbase, 'versions')
if (Dir.exists?(outputdir))
  abort "Output directory not empty: #{outputdir.sub(/^\/raml\//, '')}" \
    unless Dir["#{outputdir}/*"].empty?
else
  log "Creating directory: #{outputdir}"
  FileUtils.mkdir_p(outputdir) or abort "Failed to create directory: #{outputdir}"
end

# Get a list of all available "Since" values
versions = {}
ramlfiles = Dir[File.join(inputdir, '*.raml')]
ramlfiles.each do |ramlfile|
  raml = RAML.new(ramlfile)
  raml.walknodes do |node, keys|
    next unless node.has_key?('description')
    next unless node['description'].is_a?(String)
    since = node['description'].value_of('Since')
    versions[since] = true if since.length > 0
  end
end
abort 'No "Since:" tags found in any of the RAML files' if versions.empty?

puts "Generating RAMLs for versions: #{versions.keys.sort}"
versions.keys.sort.each do |version|
  ramlfiles.each do |inputfile|
    log "Processing file: #{inputfile}, version: #{version}" \
      if version.length > 0

    raml = RAML.new(inputfile)
    raml.filternodes do |node, keys|
      if (node.has_key?('description') and node['description'].is_a?(String))
        since = node['description'].value_of('Since')

        # Drop nodes with a "since" value greater than specified version
        since.greaterThanVersion(version)
      end
    end

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

if (manifest)
  abort "Manifest file not found: #{manifest}" unless File.exists?(manifest)
  puts "\nCopying RAMLs into release directories"
  releases = YAML.load(File.open(manifest))
  releases.keys.each do |rel|
    reldir = File.join(outputbase, 'releases', rel.to_s)
    FileUtils.mkdir_p(reldir)

    releases[rel].each do |r|
      api = r.keys.first
      vers = r[api]
      infile = File.join(outputbase, 'versions', vers.to_s, api + '.raml')
      outfile = File.join(reldir, api + '.raml')
      puts "Creating #{outfile} (version #{vers})"
      FileUtils.cp(infile, outfile)
    end
  end
end
