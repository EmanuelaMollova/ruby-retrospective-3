class Integer
  def prime?
    return false if self < 2
    2.upto(pred).all? { |divisor| remainder(divisor).nonzero? }
  end

  def prime_factors
    return [] if abs == 1
    divisor = 2.upto(abs).find { |x| x.prime? and abs.remainder(x).zero? }
    [divisor] + (abs / divisor).prime_factors
  end

  def harmonic
    denumerator = 1.upto(self).reduce(:*)
    numerator   = 1.upto(self).map { |x| denumerator / x }.reduce(:+)
    Rational(numerator, denumerator)
  end

  def digits
    abs.to_s.chars.map { |char| char.to_i }
  end
end

class Array
  def frequencies
    frequencies = {}
    uniq.each { |element| frequencies[element] = count(element) }
    frequencies
  end

  def average
    reduce(:+) / size.to_f
  end

  def drop_every(n)
    1.upto(size).select { |x| x.remainder(n).nonzero? }.map { |x| self[x-1] }
  end

  def combine_with(other)
    return other if empty?
    combined = zip(other).reduce(:concat).compact
    difference = other.size - size
    difference > 0 ? combined + other.slice(size, difference) : combined
  end
end
