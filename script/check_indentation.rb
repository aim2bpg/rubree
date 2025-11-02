#!/usr/bin/env ruby
require 'find'

exts = %w[.rb .erb .js .jsx .ts .tsx .scss .css .yml .yaml .html .slim .haml .coffee .md]
skip_dirs = %w[./.git ./build ./tmp ./public]

puts "Scanning repository for indentation issues..."

Find.find('.') do |path|
  next if File.directory?(path)
  # skip binary-like or irrelevant files quickly
  # skip paths that include these directories anywhere (covers nested node_modules, vendor, etc.)
  next if path.include?('/node_modules/') || path.include?('/vendor/')
  next if skip_dirs.any? { |d| path.start_with?(d) }
  next unless exts.include?(File.extname(path))

  begin
    File.foreach(path).with_index(1) do |line, ln|
      # detect leading tabs
      if line =~ /\A\t+/
        puts "#{path}:#{ln}: tab-indent(#{line[/\A\t+/].size}) => #{line.rstrip[0, 120].inspect}"
      end
      # detect leading spaces and check if count is multiple of 2
      if line =~ /\A +/
        cnt = $&.size
        if cnt % 2 == 1
          puts "#{path}:#{ln}: odd-space-indent(#{cnt}) => #{line.rstrip[0, 120].inspect}"
        end
      end
    end
  rescue => e
    warn "Failed to read #{path}: #{e.message}"
  end
end

puts "Scan complete."
