#!/usr/bin/env ruby

# This file reads a directory and transforms the files (generated by
# the SensorLogger android app) to Octave-readable files and png plots.
#
# The first argument of the file requires the directory with the raw csv files
# from the SensorLogger app to transform and plot.
# The second argument indicates whether the files should be plotted (default true)
#
# Example: $ ./transform_logs_to_directory logs/stand-sit-walk-stand-sit
#
# Roemer Vlasveld (roemer.vlasveld@gmail.com)


require 'fileutils'
include FileUtils

suffix_to_filename = %w[accelerometer magnetic_field orientation proximity light gravity lin_acceleration rotation]

directory = ARGV[0]
exit if directory.nil?

puts "Directory to scan: " + directory.inspect

all_files = Dir.entries(directory).select {|f| f if (f.split('.').last == 'csv') }

# Get first file to determine subdir name (timestamp)
unless all_files.empty?
  filename = all_files.first
  filename_parts = filename.split('_')
  new_directory_name = File.join( directory, filename_parts[0] + '_' + filename_parts[1])
else
  # No original csv files, assume the directory with modified files is already created
  new_directory_name = File.join( directory, Dir.entries(directory).select { |d| File.directory? File.join(directory,d) and !(d =='.' || d == '..') }.first )
end

puts "New directory name: " + new_directory_name.inspect
mkdir_p( new_directory_name )

all_files.each do |filename|
  new_file_name = suffix_to_filename[ filename.split('_').last[0].to_i ] + '.csv'

  origin = File.join(directory, filename)
  destination = File.join(new_directory_name, new_file_name)

  # Replace ";" by ",", remove "," on end of line and escape comments
  text = File.read(origin)
  text.gsub!(/;/, ',')
  text.gsub!(/,\n/, "\n" )
  text.gsub!(/(Start|Unixtime)/, '#\1' )

  # Write new file
  File.open(destination, 'w') { |file| file.puts text }
end

# Call the octave plotter for all the generated files
plot_octave = ARGV[1] || true

if plot_octave == true
  `./plot_sensors.m #{new_directory_name}`
end