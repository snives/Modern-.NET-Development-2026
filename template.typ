// Modern technical-book template for Pandoc + Typst.
//
// Recommended Pandoc invocation:
//   pandoc book.md \
//     --from markdown \
//     --to typst \
//     --output book.pdf \
//     --toc --toc-depth=3 \
//     --number-sections \
//     -V template=template.typ \
//     -V papersize=us-letter \
//     -V mainfont="Libertinus Serif" \
//     -V fontsize=10.5pt
//
// This file is imported by Pandoc's default Typst writer template and must
// expose a function named `conf`.

#let accent = rgb("#5b2c83")
#let accent-dark = rgb("#351650")
#let accent-light = rgb("#f1eaf6")
#let ink = rgb("#242124")
#let muted = rgb("#666166")
#let rule-color = rgb("#d9d3dc")
#let code-bg = rgb("#f5f3f6")
#let table-head-bg = rgb("#eee8f2")
#let authors = ("Steve Snively",)
#let date = "7/22/2026"
#let abstract = none
#let cols = 1

#set document(
  title: "Modern .Net Development 2026",
  author: "Steve Snively",
  keywords: ".NET, Development, C#, Application, Design,",
)

#set text(
  lang: "en",
  region: "US",
  font: ("Libertinus Serif", "Times New Roman"),
  size: 10.5pt,
  fill: ink,
)

#set page(
  paper: "us-letter",
  margin: (top: 0.85in, bottom: 0.8in, left: 0.9in, right: 0.8in),
  numbering: "1",
  header: context {

    let page-number = counter(page).get().first()
    if page-number > 1 {
      let chapters = query(heading.where(level: 1).before(here()))
      let current-page = here().page()
      let chapter-on-this-page = query(heading.where(level: 1)).any(heading => heading.location().page() == current-page)
      let chapter-title = if chapters.len() > 0 {
        if chapter-on-this-page {
          none
        } else {
          chapters.last().body
        }
      } else if title != none {
        title
      } else {
        []
      }

      block(
        width: 100%,
        below: 0.35em,
        stroke: (bottom: 0.5pt + rule-color),
      )[
        #grid(
          columns: (1fr, auto),
          column-gutter: 1em,
          align(left)[#text(size: 8pt, fill: muted)[#chapter-title]],
          align(right)[#text(size: 8pt, weight: "semibold", fill: accent-dark)[#page-number]],
        )
      ]
    }
  },
  footer: context {
    let page-number = counter(page).get().first()
    if page-number > 1 {
      align(center)[
        #text(size: 7.5pt, fill: muted)[Modern .NET Development]
      ]
    }
  },
)

#set par(
  justify: true,
  leading: 0.68em,
  spacing: 0.72em,
  first-line-indent: 0em,
)

#set heading(numbering: "1.1")
#set list(indent: 1.25em, body-indent: 0.55em, spacing: 0.6em)
#set enum(indent: 1.25em, body-indent: 0.55em, spacing: 0.6em)
#set terms(indent: 1.25em, hanging-indent: 0.7em, spacing: 0.4em)
#set table(
  stroke: 0.45pt + rule-color,
  inset: (x: 0.55em, y: 0.45em),
  align: left,
)

//Add vertical padding before and after lists and enums
#show list: it => [
  #v(0.8em)
  #it
  #v(0.8em)
]
#show enum: it => [
  #v(0.8em)
  #it
  #v(0.8em)
]



// Links are visible on screen but remain readable in grayscale print.
#show link: set text(fill: accent-dark)

// Inline code.
#show raw.where(block: false): it => box(
  inset: (x: 0.28em, y: 0.08em),
  radius: 2pt,
  fill: code-bg,
  text(font: ("Cascadia Mono", "Consolas", "DejaVu Sans Mono"), size: 0.88em)[#it.text],
)

// Fenced code blocks.
#show raw.where(block: true): it => block(
  width: 100%,
  breakable: true,
  inset: 0.75em,
  above: 0.8em,
  below: 0.9em,
  radius: 3pt,
  fill: code-bg,
  stroke: (left: 2.5pt + accent, rest: 0.4pt + rule-color),
)[
  #text(
    font: ("Cascadia Mono", "Consolas", "DejaVu Sans Mono"),
    size: 8.5pt,
    fill: ink,
  )[#it.text]
]

// Block quotes double as restrained technical callouts.
#show quote.where(block: true): it => block(
  width: 100%,
  breakable: true,
  inset: (left: 0.85em, right: 0.75em, top: 0.65em, bottom: 0.65em),
  above: 0.8em,
  below: 0.8em,
  radius: 3pt,
  fill: accent-light,
  stroke: (left: 3pt + accent),
)[
  #text(fill: accent-dark)[#it.body]
]

// Tables: shade the first row and prevent oversized typography.
#show table: it => {
  set text(size: 9.1pt)
  it
}
#show table.cell.where(y: 0): it => {
  set text(weight: "semibold", fill: accent-dark)
  block(fill: table-head-bg, inset: 0.5em)[#it.body]
}

// Figure captions.
#show figure.caption: set text(size: 8.5pt, fill: muted)

// Chapter openings.
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  block(
    width: 100%,
    above: 0.2in,
    below: 0.32in,
    breakable: false,
  )[
    #if it.numbering != none {
      text(size: 10pt, weight: "bold", fill: accent, tracking: 0.12em)[
        CHAPTER #counter(heading).display("1")
      ]
      v(0.18in)
    }
    #text(size: 25pt, weight: "bold", fill: accent-dark)[#it.body]
    #v(0.16in)
    #line(length: 100%, stroke: 2pt + accent)
  ]
}

#show heading.where(level: 2): it => block(
  above: 2.0em,
  below: 1.3em,
  breakable: false,
)[
  #text(size: 16pt, weight: "bold", fill: accent-dark)[#it.body]
]

#show heading.where(level: 3): it => block(
  above: 0.95em,
  below: 0.3em,
  breakable: false,
)[
  #text(size: 12.5pt, weight: "bold", fill: accent-dark)[#it.body]
]

#show heading.where(level: 4): it => block(
  above: 0.75em,
  below: 0.2em,
  breakable: false,
)[
  #text(size: 10.5pt, weight: "bold", fill: accent)[#it.body]
]

// Title page.
#if title != none {
  set page(header: none, footer: none)

  align(center + horizon)[
    #block(width: 82%)[
      #text(size: 10pt, weight: "bold", tracking: 0.16em, fill: accent)[
        PROFESSIONAL DEVELOPMENT GUIDE
      ]
      #v(0.35in)
      #text(size: 34pt, weight: "bold", fill: accent-dark)[#title]
      #v(0.25in)
      #line(length: 70%, stroke: 3pt + accent)

      #if authors.len() > 1 {
        v(0.45in)
        text(size: 13pt, fill: muted)[
          #authors.map(author => author.name).join(" · ")
        ]
      }

      #if date != none {
        v(0.18in)
        text(size: 10pt, fill: muted)[#date]
      }
    ]
  ]

  pagebreak()
  counter(page).update(1)

  set page(
    header: context {
      let chapters = query(heading.where(level: 1).before(here()))
      let chapter-title = if chapters.len() > 0 { chapters.last().body } else { title }
      block(width: 100%, below: 0.35em, stroke: (bottom: 0.5pt + rule-color))[
        #grid(
          columns: (1fr, auto),
          align(left)[#text(size: 8pt, fill: muted)[#chapter-title]],
          align(right)[#text(size: 8pt, weight: "semibold", fill: accent-dark)[#counter(page).display("1")]],
        )
      ]
    },
    footer: align(center)[#text(size: 7.5pt, fill: muted)[Modern .NET Development]],
  )
}

// Optional abstract, used as a short book description.
#if abstract != none {
  block(
    width: 100%,
    inset: 0.85em,
    above: 0.4em,
    below: 1em,
    radius: 3pt,
    fill: accent-light,
    stroke: 0.5pt + rule-color,
  )[
    #text(weight: "bold", fill: accent-dark)[About this book]
    #v(0.25em)
    #abstract
  ]
}




// Cover



// ----------------------
// Copyright
// ----------------------

Copyright © 2026 Steve Snively

#pagebreak()

// ----------------------
// Table of Contents
// ----------------------

#outline()

#pagebreak()

// ----------------------
// Book Contents
// ----------------------

#include "./generated/book.typ"