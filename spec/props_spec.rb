require_relative '../lib/gds2'
describe GDS2 do

  
  it "gets and sets strSpace" do
    gds = GDS2.new(fileName: 'tempX0.gds', mode: 'w')
    gds.putStrSpace(' x ')
    expect(gds.getStrSpace).to eq ' x '
    gds.close
  end
  
  it "gets and sets elmSpace" do
    gds = GDS2.new(fileName: 'tempX0.gds', mode: 'w')
    gds.putElmSpace(' y ')
    expect(gds.getElmSpace).to eq ' y '
    gds.close
  end
  
end
