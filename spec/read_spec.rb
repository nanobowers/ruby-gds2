
require_relative '../lib/gds2'

def write_a_gds(fname)
  gds2File = GDS2.new(fileName: fname, mode: 'w')
  gds2File.printInitLib(name: 'testlib')
  gds2File.printBgnstr(name: 'test')
  gds2File.printPath(layer: 6, pathType: 0, width: 2.4, xy: [0,0,1,1,2,2,3,3])
  gds2File.printEndlib
  gds2File.close
  
end

describe GDS2 do
  before do
    fname = 'readtest01.gds'
    write_a_gds(fname)
  end
  
  it "gets recordSize for various records" do
    gds = GDS2.new(fileName: 'readtest01.gds')
    sizelist = []
    while gds.readGds2Record
      sizelist << gds.recordSize

    end
    gds.close
    expect(sizelist).to eq [6, 28, 12, 20, 28, 8, 4, 6, 6, 8, 36, 4, 4]
  end
  
  it "gets recordData for various records" do
    gds = GDS2.new(fileName: 'readtest01.gds')
    sizelist = []
    while gds.readGds2Record
      sizelist << gds.getRecordData
    end
    gds.close
    expect(sizelist[0].first).to eq '3'
    expect(sizelist[1].first.to_i).to eq Time.now.year-1900
    expect(sizelist[2]).to eq 'testlib'

  end

  it "gets number of coords" do
    gds = GDS2.new(fileName: 'readtest01.gds')
    while gds.readGds2Record
      pathcoords = gds.returnNumCoords if gds.returnNumCoords
    end
    gds.close
    expect(pathcoords).to be 4 # Eight numbers, Four xy-coords
  end
 
end
