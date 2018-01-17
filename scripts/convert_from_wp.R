xml_file = 'plussixone.xml'

old_url = 'https?://plussixoneblog.com'
new_url = 'https://plussixone.netlify.com'


# use the new domain
blogdown:::process_file(xml_file, function(x) {
  # replace possible invalid dates with a random date
  x = gsub('0000-00-00 00:00:00', '2017-07-28 00:00:00', x)
  x = gsub(old_url, new_url, x)
  # move possible images out of <pre></pre>
  x = gsub('^(\\s*)(<a .*<img .*)(</code></pre>\\s*)$', '\\1\\3\n\\2\n', x)
  x
})

# rename *.markdown to *.md
files = list.files(
  'content/post/', '[.](md|markdown)$', full.names = TRUE,
  recursive = TRUE
)

file.rename(files, sub('[.]markdown$', '.md', files))

files = list.files('content/post/', '[.]md$', full.names = TRUE)

# all possible authors
blogdown:::collect_yaml('author', 'post')

# map author id's to author names
authors = c(
  jamesday87 = 'jamesday87'
)


for (f in files) {
  message('Processing ', f)
  # possible Unicode characters that yaml::yaml.load cannot handle (e.g. emoji)
  blogdown:::process_file(f, function(x) {
    gsub('(\\\\u[A-Z0-9]{4})+', '', x)
  })
  
  # clean up YAML
  blogdown:::modify_yaml(f, author = function(old, yaml) {
    if (!is.character(old)) return(authors[1])
    if (old %in% authors) return(old)
    if (is.na(a <- authors[old])) stop('Cannot find the author ', old, ' in ', f)
    a
  }, slug = function(old, yaml) {
    if (length(old) == 1) return(old)
    # YYYY-mm-dd-name.md -> name
    gsub('^\\d{4}-\\d{2}-\\d{2}-|[.]md', '', f)
  }, date = function(old, yaml) {
    # extract actual date from permalink if exists
    r = '^.*/(\\d{4}/\\d{2}/\\d{2})/.*$'
    if (is.character(link <- yaml$link) && grepl(r, link)) {
      gsub('/', '-', gsub(r, '\\1', link))
    } else {
      gsub(' .*', '', old)  # remove time after the space, e.g. 2015-05-28 15:52:54+00:00
    }
  }, .keep_fields = c(
    'title', 'author', 'date', 'categories', 'tags', 'slug'
  ), .keep_empty = FALSE)
  
  blogdown:::process_bare_urls(f)
  blogdown:::normalize_chars(f)
  blogdown:::remove_highlight_tags(f)
  blogdown:::fix_img_tags(f)
  blogdown:::remove_extra_empty_lines(f)
  
  blogdown:::process_file(f, function(x) {
    # <a><img></a> to [![]()]()
    x = gsub(
      '^( {4,})<a href="([^"]+)"[^>]*><img src="\\2[^"]*" alt="([^"]*)"[^>]*></a>',
      '\n\n[![\\3](\\2)](\\2)\n\n\\1', x
    )
    # do not scale images to a certain width
    x = gsub('([.][a-z]+)[?]w=[0-9]+', '\\1', x)
    # [![](link)](link) to ![](link)
    x = gsub('\\[!\\[([^]]*)]\\(([^)]+)\\)]\\(\\2\\)', '![\\1](\\2)', x)
    x = gsub('\\[!\\[([^]]*)]\\(([^)]+)([.][a-z]+)\\)]\\([^)]+\\3\\)', '![\\1](\\2\\3)', x)
    # WP shortcode [caption] to <p class="caption">
    x = gsub('^\\[caption[^]]*](.*\\)) (.*)\\[/caption]$', '\\1\n\n<p class="caption">\\2</p>', x)
    # WP shortcode [sourcecode] to ````lang
    x = gsub('^\\[sourcecode language="([^"]+)"]', '````\\1', x)
    x = gsub('^\\[sourcecode[^]]*]', '````', x)
    x = gsub('^\\[code lang=([a-z]+)]', '````\\1', x)
    x = gsub('^\\[code[^]]+]', '````', x)
    x = gsub('^\\[/(source)?code]$', '````', x)
    x = gsub('^(\\s*)</code>(.*)', '\\1\\2', x)
    # possible images in section headings
    x = gsub('^#+ (!\\[[^]]*]\\([^)]+\\))\\s*$', '\\1', x)
    # unbalanced **
    z = grep('^[*]{2}[^*]+$', x); n = length(z)
    if (n > 1 && n %% 2 == 0) {
      for (i in seq(1, n, by = 2)) {
        z2 = z[i + 1]; z1 = z[i]
        if (z2 - z1 != 1) next
        x[z1] = paste0(x[z1], '**\n')
        x[z2] = gsub('^[*]{2}', '', x[z2])
      }
    }
    # **_foo_** -> _foo_
    x = gsub('[*]{2}(_[^_]+_)[*]{2}', '\\1', x)
    # extra space before the closing **
    x = gsub('(^| )([*]{2}[^*]+?)\\s+([*]{2})\\s*', '\\1\\2\\3 ', x)
    x
  })
  
  # genius ideas to decide whether we add ```r to indented code blocks
  blogdown:::process_file(f, function(x) {
    maybe_code = function(x) grepl('^ {4}', x)
    is_blank = function(x) grepl('^\\s*$', x)
    # enclose R code in backtick fences
    if (!any(maybe_code(x)) || length(grep('^```r?$', x)) >= 2) return(x)
    r = rle(maybe_code(x) | is_blank(x))  # run lengths of c(T, T, T, F, F, T, ...)
    blocks = split(x, rep(seq_along(r$values), r$lengths))
    x = unlist(lapply(blocks, function(b) {
      if (all(i <- is_blank(b)) || !any(maybe_code(b))) return(b)
      # if not valid R syntax (after text output with the leading [n] is removed), may not be R code
      if (!highr:::try_parse(grep('^\\s*\\[[0-9]+] ', b, invert = TRUE, value = TRUE))) return(b)
      if (all(i | grepl('^\\s*cat ', b))) return(b)  # an exception of shell scripts
      if (length(grep('^\\s*[a-z_]+:( [a-z]+)?$', b))) return(b)  # an exception of YAML
      b = gsub('^ {4}', '', b)
      i = which(!i)
      # apply fences to the first and last non-empty line
      b = append(b, '```r', i[1] - 1)
      b = append(b, '```', i[length(i)] + 1)
      b
    }))
    x
  })
  
  # move inline images ![]() to separate paragraphs
  blogdown:::process_file(f, function(x) {
    i = grep('^\\s*[[!]', x, invert = TRUE)
    x[i] = gsub('(!\\[[^]]*]\\([^)]+\\))', '\n\n\\1\n\n', x[i])
    x
  })
  
  blogdown:::remove_extra_empty_lines(f)
}

# old permalinks
links1 = local({
  x = readLines(xml_file)
  r = paste0('\\s*<link>', new_url, '/(.*)</link>\\s*')
  i = grep(r, x)
  gsub(r, '\\1', x[i])
})

# new permalinks
links2 = local({
  res = blogdown:::collect_yaml(c('date', 'slug'), 'post', sort = FALSE, uniq = FALSE)
  mapply(function(d, s) {
    paste0(gsub('-', '/', d), '/', s, '/')
  }, res$date, res$slug, USE.NAMES = FALSE)
})

links3 = setdiff(links2, links1)
if (length(links3)) {
  message('These links on the new website cannot be mapped back to the old website:')
  cat(links3, sep = '\n')
}

local({
  if (!dir.exists(d <- '../kbroman-blog/content/')) return()
  # unlink(file.path(d, 'post'), recursive = TRUE)
  file.copy('post', d, recursive = TRUE)
})