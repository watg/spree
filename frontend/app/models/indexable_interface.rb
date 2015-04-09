module IndexableInterface
  PER_PAGE = Spree::Config[:products_per_page].to_i
  SHOW_ALL = 999

  def suites
    raise NotImplementedError
  end

  def num_pages
    raise NotImplementedError
  end

  def context
    raise NotImplementedError
  end

  def title
    ""
  end

  def meta_description
    ""
  end

  def meta_keywords
    ""
  end

  def meta_title
    ""
  end

  def show_all
    SHOW_ALL.to_s
  end
end
