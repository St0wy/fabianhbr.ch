// Wraps the Typst posts and projects when generator.jai compiles them to HTML.
// The page to compile is passed with `--input path=/src/posts/<file>.typ`, and the show rules below are applied to it.

// Code blocks are left unhighlighted, so generator.jai can highlight them with highlight.js like the Markdown ones
#show raw.where(block: true): it => html.elem(
  "pre",
  html.elem("code", attrs: (data-lang: if it.lang == none { "" } else { it.lang }), it.text),
)
#show raw.where(block: false): it => html.elem("code", it.text)

// Images of the website are referenced from the root (e.g. "/public/assets/images/..."), so they also work when
// previewing the post with Typst. They are linked instead of being embedded in the page.
#show image: it => {
  if type(it.source) != str or not it.source.starts-with("/public/") { return it }
  let attrs = (src: it.source.slice("/public".len()))
  if it.alt != none { attrs.alt = it.alt }
  html.elem("img", attrs: attrs)
}

// Footnotes are shown as sidenotes, in the margin on wide screens or below their line when clicking their number.
// generator.jai removes the list of footnotes that Typst still adds at the end of the page.
#show footnote: it => {
  let number = context counter(footnote).display(it.numbering)
  html.elem("label", attrs: (class: "sidenote-number", tabindex: "0"), html.elem("sup", number))
  html.elem("span", attrs: (class: "sidenote", tabindex: "-1"), html.elem("span", attrs: (class: "sidenote-entry"), {
    html.elem("span", attrs: (class: "sidenote-mark"), number)
    [ ]
    it.body
  }))
}

#include sys.inputs.path
