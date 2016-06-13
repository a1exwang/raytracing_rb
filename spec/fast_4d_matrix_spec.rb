require_relative '../lib/fast_4d_matrix/fast_4d_matrix'
require 'rspec'

include Fast4DMatrix
RSpec.describe Fast4DMatrix do
  it 'can create Vec3 objects' do
    vec3 = Fast4DMatrix::Vec3.from_a(1.0, 2.0, 3.0)
    expect(vec3.to_a).to eq([1.0, 2.0, 3.0])
  end

  it 'can convert to string' do
    vec3 = Fast4DMatrix::Vec3.from_a(1.0, 2.0, 3.0)
    expect(vec3.to_s).to eq('[1.0, 2.0, 3.0]')
  end
  
  it 'can dot' do
    a = Vec3.from_a(1.0, 2.0, 3.0)
    b = Vec3.from_a(3.0, 2.0, 1.0)
    expect(a.dot(b)).to eq(10.0)
  end

  it 'can cos' do
    a = Vec3.from_a(1.0, 2.0, 3.0)
    b = Vec3.from_a(3.0, 2.0, 1.0)
    expect(a.cos(b)).to eq(10.0/14.0)
  end

  it 'can cross' do
    a = Vec3.from_a(0.0, 1.0, 0.0)
    b = Vec3.from_a(0.0, 0.0, 1.0)
    res = [1, 0, 0]
    expect(a.cross(b).to_a).to eq(res)
  end

  it 'can add' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    b = Vec3.from_a(1.0, 2.0, 3.0)
    res = [2.0, 3.0, 4.0]
    expect((a + b).to_a).to eq(res)
  end
  it 'can sub' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    b = Vec3.from_a(1.0, 2.0, 3.0)
    res = [0, -1.0, -2.0]
    expect((a - b).to_a).to eq(res)
  end
  it 'can multiply' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    b = Vec3.from_a(1.0, 2.0, 3.0)
    res = [1.0, 2.0, 3.0]
    expect((a * b).to_a).to eq(res)
  end
  it 'can multiply by scaler value' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    res = [3.0, 3.0, 3.0]
    expect((a * 3.0).to_a).to eq(res)
  end

  it 'can divide by scalar value' do
    a = Vec3.from_a(10.0, 10.0, 10.0)
    res = [1.0, 1.0, 1.0]
    expect((a / 10.0).to_a).to eq(res)
  end

  it 'can add bang' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    b = Vec3.from_a(1.0, 2.0, 3.0)
    a.add!(b)
    res = [2.0, 3.0, 4.0]
    expect(a.to_a).to eq(res)
  end
  it 'can sub bang' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    b = Vec3.from_a(1.0, 2.0, 3.0)
    a.sub!(b)
    res = [0, -1.0, -2.0]
    expect(a.to_a).to eq(res)
  end
  it 'can use unary operator' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    res = [1.0, 1.0, 1.0]
    expect((+a).to_a).to eq(res)
    expect((-a).to_a).to eq(res.map { |x| -x })
  end

  it 'can multiply bang' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    b = Vec3.from_a(1.0, 2.0, 3.0)
    a.mul!(b)
    res = [1.0, 2.0, 3.0]
    expect(a.to_a).to eq(res)
  end

  it 'can multiply bang by scalar value' do
    a = Vec3.from_a(1.0, 1.0, 1.0)
    a.mul!(3.0)
    res = [3.0, 3.0, 3.0]
    expect(a.to_a).to eq(res)
  end

  it 'can get r' do
    a = Vec3.from_a(1.0, 2.0, 2.0)
    expect(a.r).to eq(3.0)
  end
  it 'can get r2' do
    a = Vec3.from_a(1.0, 2.0, 2.0)
    expect(a.r2).to eq(9.0)
  end

  it 'can normlize' do
    a = Vec3.from_a(1.0, 2.0, 2.0)
    expect(a.normalize.to_a.map { |x| x.round(3) }).to eq([0.333, 0.667, 0.667])
  end

end
