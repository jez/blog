# blog

- Blog source is here on `master`.
- Blog compiled is on [`gh-pages`](https://github.com/jez/blog/tree/gh-pages).
- Blog rendered is at <https://blog.jez.io>.

## Setup

```
brew install pandoc
brew install pandoc-sidenote
```

## Using

You might have to `dropbox stop` on Linux for inotify problems.

```
bundle exec jekyll serve --drafts

bundle exec octopress new draft my-slug

bundle exec jekyll build
bundle exec octopress publish

bundle exec octopress new page

bundle exec jekyll build && bundle exec octopress deploy
```
