#!/usr/bin/env ruby
require_relative "./lib/gds2"
gds2File = GDS2.new(fileName: 'test.gds', mode: 'w');
gds2File.printInitLib(name: 'testlib');
gds2File.printBgnstr(name: 'test');
gds2File.printPath(
  layer: 6,
  pathType: 0,
  width: 2.4,
  xy: [0,0, 10.5,0, 10.5,3.3],
);
gds2File.printSref(
  name: 'contact',
  xy: [4,5.5],
);
gds2File.printAref(
  name: 'contact',
  columns: 2,
  rows: 3,
  xy: [0,0, 10,0, 0,15],
);
gds2File.printEndstr;
gds2File.printBgnstr(name: 'contact');
gds2File.printBoundary(
  layer: 10,
  xy: [0,0, 1,0, 1,1, 0,1],
);
gds2File.printEndstr;
gds2File.printEndlib();
