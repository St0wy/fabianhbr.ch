# fabianhbr.ch

Repository containing the code of my portfolio / blog website.
It requires the [Jai](https://github.com/Ivo-Balbaert/The_Way_to_Jai/blob/main/book/01A_What_is_Jai.md) compiler, which is currently in closed beta.
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

The website is deployed on GitHub Pages when pushing to `main`.
Since the CI can't run Jai, `public/` is committed: regenerate the website before committing.

## License

- The code is licensed under the [MIT license](LICENSE).
- The writing (blog posts, project pages and the text of the website) is licensed under [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/). See [LICENSE-CONTENT](LICENSE-CONTENT).
  The website's [`robots.txt`](public/robots.txt) also asks AI crawlers not to use it for training.
- `public/modern-normalize.css` and `public/scripts/nushell.min.js` are third-party files under their own licenses.

## AI disclosure

I wrote the site generator, the templating system, the Markdown parser and the content of the website myself.
Later on, I used an LLM to review the code and help with the following changes:

- Fixing the RSS feed dates and adding the `/subscribe` page
- Escaping the values inserted in the templates and fixing invalid HTML on the about page
- Adding the page descriptions and Open Graph tags
- Writing the alt texts of the images
- Replacing the per-struct frontmatter parsers with a single reflection-based one
- Fixing bugs in the Markdown parser
- Updating the "custom site generator" blog post to match the new code of the generator
