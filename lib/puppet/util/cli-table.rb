class Puppet::Util::Clitable

  attr_accessor :col_labels, :row_data

  def initialize(col_labels, row_data = [])
    @col_labels = col_labels
    @row_data   = row_data
    @columns = col_labels.each_with_object({}) { |(col,label),h|
      h[col] = { label: label,
                 width: [@row_data.map { |g| g[col].size }.max, label.size].max } }
  end

  def write_header
    puts "| #{ @columns.map { |_,g| g[:label].ljust(g[:width]) }.join(' | ') } |"
  end

  def write_divider
    puts "+-#{ @columns.map { |_,g| "-"*g[:width] }.join("-+-") }-+"
  end

  def write_line(h)
    str = h.keys.map { |k| h[k].ljust(@columns[k][:width]) }.join(" | ")
    puts "| #{str} |"
  end

  def print
    write_divider
    write_header
    write_divider
    @row_data.each { |h| write_line(h) }
    write_divider
  end
end
