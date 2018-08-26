
def flt_to_real8ary (num)
  packnum = GDS2.float_to_packed_real8(num)
  packnum.split(//).map(&:ord)
end

describe GDS2 do

  it "can floats to a REAL_8" do
    expect(flt_to_real8ary(0.0)).to eq [ 64,0,0,0,0,0,0,0 ]
    expect(flt_to_real8ary(1.0)).to eq [ 65,16,0,0,0,0,0,0 ]
    expect(flt_to_real8ary(2.0)).to eq [ 65,32,0,0,0,0,0,0 ]
    expect(flt_to_real8ary(-2.0)).to eq [ 193,32,0,0,0,0,0,0 ]
  end
  it "converts float back to float" do
    [0.0, 3.14159, 1.01834e-8, 3e20, 2e-20].each do |num|
      expect(GDS2.packed_real8_to_float(GDS2.float_to_packed_real8(num))).to be(num)
    end
  end
  it "converts packed back to packed" do
    ["ABCDEFGH","\x129\x19\x0\x0\x0EAT"].each do |pnum|
      expect(GDS2.float_to_packed_real8(GDS2.packed_real8_to_float(pnum))).to eq pnum
    end
  end
end
