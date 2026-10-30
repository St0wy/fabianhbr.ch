# fabianhbr.ch

Repository containing the code of my portfolio / blog website.
It requires the [Jai](https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/01A_What_is_Jai.md) compiler, which is currently in closed beta,
and [Bun](https://bun.sh/), which runs [highlight.js](https://highlightjs.org/) during the build so the code blocks are served already highlighted
(see [`tools/highlight/`](tools/highlight/)).
The pages written in Typst also need the [Typst](https://typst.app/) CLI (0.15 or newer, for its HTML export).
To regenerate the website, run

```
jai generator.jai
```

The output is then in `public/`.
The links are absolute, so to preview the website locally, serve that folder with any static server, for example:

```
python -m http.server 8000 --directory public
```

Blog posts are located in [`src/posts/`](https://github.com/St0wy/fabianhbr.ch/tree/main/src/posts)
and projects in [`src/projects/`](https://github.com/St0wy/fabianhbr.ch/tree/main/src/projects).
Their frontmatter keys are the members of the `Post` and `Project` structs in `generator.jai`.

They can be written in Markdown (`.md`) or in [Typst](https://typst.app/) (`.typ`).
The frontmatter of a Typst file is a `/* */` comment at its start, containing the same `key: value` lines as the Markdown files.
They are compiled through [`src/typst_page.typ`](src/typst_page.typ), which sets up the show rules of the website,
and images should be referenced from the root of the repository (e.g. `/public/assets/images/...`) so they are linked instead of embedded.

The website is deployed on GitHub Pages when pushing to `main`.
Since the CI can't run Jai, `public/` is committed: regenerate the website before committing.

## License

- The code is licensed under the [MIT license](LICENSE).
- The writing (blog posts, project pages and the text of the website) is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/). See [LICENSE-CONTENT](LICENSE-CONTENT).
- `public/modern-normalize.css` and the files in `tools/highlight/vendor/` are third-party files under their own licenses.

## AI disclosure

I wrote the site generator, the templating system, the Markdown parser and the content of the website myself.
Later on, I used an LLM to review the code and help with the following changes:

- Fixing the RSS feed dates and adding the `/subscribe` page
- Escaping the values inserted in the templates and fixing invalid HTML on the about page
- Adding the page descriptions and Open Graph tags
- Writing the alt texts of the images
- Replacing the per-struct frontmatter parsers with a single reflection-based one
- Fixing bugs in the Markdown parser
- Highlighting the code blocks at build time instead of in the browser
- Updating the "custom site generator" blog post to match the new code of the generator
- Showing only the featured projects and the most recent posts on the index
- Supporting pages written in Typst, and writing the example Typst post
