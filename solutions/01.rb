class Integer
  def prime?
    return false if self < 2
    2.upto(pred).all? { |divisor| remainder(divisor).nonzero? }
  end

  def prime_factors
    return [] if abs == 1
    divisor = 2.upto(abs).find { |divisor| abs.remainder(divisor).zero? }
    [divisor] + (abs / divisor).prime_factors
  end

  def harmonic
    1.upto(self).map { |number| 1 / number.to_r }.reduce(:+)
  end

  def digits
    abs.to_s.chars.map(&:to_i)
  end
end

class Array
  def frequencies
    each_with_object Hash.new(0) do |element, frequencies|
      frequencies[element] += 1
    end
  end

  def average
    reduce(:+) / size.to_f
  end

  def drop_every(n)
    1.upto(size).reject { |x| x.remainder(n).zero? }.map { |index| at(index-1) }
  end

  def combine_with(other)
    common   = [size, other.size].min
    combined = first(common).zip(other.first(common)).flatten 1
    rest     = other.size - size
    combined + (rest > 0 ? other.slice(common, rest) : slice(common, rest.abs))
  end
end
