function md2pdf --description 'Markdown to PDF next to the source: cmark-gfm renders it, headless chromium prints it'
    # Relative image paths don't resolve (the HTML is rendered from /tmp), and chromium
    # leaves out backgrounds when printing, so code blocks lose their grey box.
    set -l html (mktemp --suffix=.html)
    begin
        echo '<meta charset="utf-8"><style>body{font-family:sans-serif;max-width:46em;margin:auto;line-height:1.5}table{border-collapse:collapse}td,th{border:1px solid #ccc;padding:.3em .6em}</style>'
        cmark-gfm -e table -e strikethrough -e autolink -e tasklist $argv[1]
    end >$html
    chromium --headless --no-pdf-header-footer --print-to-pdf=(path change-extension pdf $argv[1]) $html 2>/dev/null
    rm $html
end
