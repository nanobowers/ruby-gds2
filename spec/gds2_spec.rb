
require_relative '../lib/gds2'

def dump_gds(prefix: 'test02', ext: 'txt', compact: false)
  ifname = "#{prefix}.gds"
  ofname = "#{prefix}.#{ext}"
  gds2File = GDS2.new(fileName: ifname);
  File.open(ofname, 'w') do |of|
    while gds2File.readGds2Record
      of.puts gds2File.returnRecordAsString(compact: compact);
    end
  end
  gds2File.close
end

def create_some_gds (fname)
  gds2File = GDS2.new(fileName: fname, mode: 'w')
  
  gds2File.printInitLib(name: 'testlib')
  gds2File.printBgnstr(name: 'test')
  gds2File.printPath(
    layer: 6,
    pathType: 0,
    width: 2.4,
    xy: [0, 0, 10.5, 0, 10.5, 3.3],
  )
  gds2File.printSref(
    name: 'contact',
    xy: [4, 5.5],
  )
  gds2File.printAref(
    name: 'contact',
    columns: 2,
    rows: 3,
    xy: [0,0, 10,0, 0,15],
  )
  gds2File.printEndstr
  gds2File.printBgnstr(name: 'contact')
  gds2File.printBoundary(
    layer: 10,
    xy: [0,0, 1,0, 1,1, 0,1],
  )
  gds2File.printEndstr
  gds2File.printEndlib
  return gds2File
end

describe GDS2 do
  
  it "creates and closes a gds2" do
    gds2File = GDS2.new(fileName: 'test01.gds', mode: 'w')
    gds2File.close
  end

  it "has some global variables" do
    # wonder if these will be same on all platforms?
    expect(GDS2.g_epsilon).to be_within(1e-12).of(1e-7)
    expect(GDS2.g_fltlen).to be_within(1e-12).of(6)
    expect(GDS2.isLittleEndian).to be true
  end
  
  it "creates a gds2 with some objects" do
    fname = 'test02.gds'
    gds2File = create_some_gds(fname)
    gds2File.close
    #sleep(2)
    expect(File.stat(fname).size).to be 362
  end

  it "creates a gds2 with some objects and pads to 2kB" do
    fname = 'test02pad.gds'
    gds2File = create_some_gds(fname)
    gds2File.close(pad: 2048)
    #sleep(2)
    expect(File.stat(fname).size).to be 2048
  end

  it "dumps gds as verbose-text" do
    dump_gds(ext: 'txt', compact: false)
  end

  it "dumps gds as GDT" do
    dump_gds(ext: 'gdt', compact: true)
  end
  
end
