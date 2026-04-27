function Image(img)
    local src = img.src
    local alt = img.alt or ""
    local html = '<a href="' .. src .. '" target="_blank">' ..
                 '<img src="' .. src .. '" alt="' .. alt .. '">' ..
                 '</a>'
    return pandoc.RawInline('html', html)
end