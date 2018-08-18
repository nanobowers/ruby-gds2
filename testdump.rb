#!/usr/bin/env ruby
require_relative "./lib/gds2"
gds2File = GDS2.new(fileName: ARGV.first);
while gds2File.readGds2Record
    puts gds2File.returnRecordAsString(compact: false);
end
