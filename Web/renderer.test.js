import {describe, expect, it} from 'vitest'
import {renderMarkdown} from './renderer.js'
import {JSDOM} from 'jsdom'

describe('renderMarkdown', () => {
  it.each([
    ['![x](<images/中文 图.png>)', 'mdreader-file://document/images/%E4%B8%AD%E6%96%87%20%E5%9B%BE.png'],
    ['![x](images/a%20b.png)', 'mdreader-file://document/images/a%20b.png'],
    ['![x](</Users/test/My Project/中文 图.png>)', 'mdreader-file://image/Users/test/My%20Project/%E4%B8%AD%E6%96%87%20%E5%9B%BE.png'],
    ['<img src="/Users/test/My Project/picture.png">', 'mdreader-file://image/Users/test/My%20Project/picture.png'],
    ['![x](file:///Users/test/a%20b.png)', 'mdreader-file://image/Users/test/a%20b.png'],
    ['![x](file://localhost/Users/test/a%2520.png)', 'mdreader-file://image/Users/test/a%2520.png'],
    ['<img src="images/中文 图.png">', 'mdreader-file://document/images/%E4%B8%AD%E6%96%87%20%E5%9B%BE.png'],
    ['![x](images/100%25%23%3F.png)', 'mdreader-file://document/images/100%25%23%3F.png'],
    ['![x](images/a.png?v=1#preview)', 'mdreader-file://document/images/a.png?v=1#preview'],
    ['![x](//example.com/a.png)', 'https://example.com/a.png'],
    ['![x][pic]\n\n[pic]: images/a%20b.png', 'mdreader-file://document/images/a%20b.png']
  ])('normalizes image URLs exactly once: %s', async (markdown, expected) => {
    const document = new JSDOM(await renderMarkdown(markdown)).window.document
    expect(document.querySelector('img').getAttribute('src')).toBe(expected)
  })

  it('allows embedded raster images without permitting active data documents', async () => {
    const raster = 'data:image/png;base64,iVBORw0KGgo='
    const document = new JSDOM(await renderMarkdown([
      `![embedded](${raster})`,
      '<img src="data:text/html;base64,PHNjcmlwdD4=">',
      '<img src="data:image/svg+xml;base64,PHN2Zz4=">',
      '<img src="~/private.png">',
      '<img src="file://remote-server/private.png">'
    ].join('\n\n'))).window.document
    const images = [...document.querySelectorAll('img')]
    expect(images[0].getAttribute('src')).toBe(raster)
    expect(images.slice(1).every(image => !image.hasAttribute('src'))).toBe(true)
  })

  it('renders GFM, footnotes, highlighted code, and front matter', async () => {
    const markdown = [
      '---',
      'title: Demo',
      'author: Frank',
      '---',
      '# Heading',
      '',
      '- [x] done',
      '',
      '| A | B |',
      '| - | - |',
      '| 1 | 2 |',
      '',
      'Reference[^1].',
      '',
      '[^1]: Footnote text.',
      '',
      '```swift',
      'let value = 1',
      '```'
    ].join('\n')

    const html = await renderMarkdown(markdown)

    expect(html).toContain('class="frontmatter"')
    expect(html).toContain('<dt>title</dt><dd>Demo</dd>')
    expect(html).toContain('type="checkbox"')
    expect(html).toContain('<table>')
    expect(html).toContain('data-footnote-ref')
    expect(html).toContain('class="hljs language-swift"')
  })

  it('preserves inline, display, and fenced math for MathJax', async () => {
    const markdown = [
      'Inline $x_i^2$.',
      '',
      '$$',
      '\\frac{1}{2}',
      '$$',
      '',
      '```math',
      '\\begin{bmatrix}1&0\\\\0&1\\end{bmatrix}',
      '```'
    ].join('\n')

    const html = await renderMarkdown(markdown)

    expect(html).toContain('\\(x_i^2\\)')
    expect(html).toContain('\\[\\frac{1}{2}\\]')
    expect(html).toMatch(/\\\[\\begin\{bmatrix\}1(?:&amp;|&#x26;)0/)
  })

  it('recognizes LaTeX bracket display delimiters before Markdown escapes them', async () => {
    const markdown = String.raw`A common starting point is the standard Gaussian distribution:

\[
x_0\sim p_0=\mathcal N(0,I).
\]`

    const html = await renderMarkdown(markdown)

    expect(html).toContain(String.raw`\[x_0\sim p_0=\mathcal N(0,I).\]`)
    expect(html).not.toContain('<p>[')
  })

  it('recognizes LaTeX parenthesis inline delimiters before Markdown escapes them', async () => {
    const markdown = String.raw`Where:

- \(\mu(x_t,t)\): deterministic drift;
- \(\sigma(t)d w_t\): stochastic Brownian noise;
- \(p_0(x)=p_{\text{data}}(x)\).`

    const html = await renderMarkdown(markdown)

    expect(html).toContain(String.raw`<li>\(\mu(x_t,t)\): deterministic drift;</li>`)
    expect(html).toContain(String.raw`<li>\(\sigma(t)d w_t\): stochastic Brownian noise;</li>`)
    expect(html).toContain(String.raw`\(p_0(x)=p_{\text{data}}(x)\)`)
    expect(html).not.toContain(String.raw`<li>(\mu`)
  })

  it('keeps LaTeX-looking text inside inline code literal', async () => {
    const html = await renderMarkdown('Use `\\(\\mu(x_t,t)\\)` as an example.')

    expect(html).toContain(String.raw`<code>\(\mu(x_t,t)\)</code>`)
  })

  it('turns an explicit Mermaid fence into a diagram placeholder', async () => {
    const html = await renderMarkdown([
      '```mermaid',
      'sequenceDiagram',
      '  Reader->>Renderer: Render',
      '```'
    ].join('\n'))
    const document = new JSDOM(html).window.document
    const diagram = document.querySelector('.mermaid-diagram')

    expect(diagram?.getAttribute('data-diagram-source')).toBe(
      'sequenceDiagram\n  Reader->>Renderer: Render'
    )
    expect(document.querySelector('pre')).toBeNull()
  })

  it('recognizes an unlabelled fenced Mermaid flowchart', async () => {
    const html = await renderMarkdown([
      '```',
      'flowchart TD',
      '  A[Read] --> B[Understand]',
      '```'
    ].join('\n'))
    const document = new JSDOM(html).window.document

    expect(document.querySelector('.mermaid-diagram')?.getAttribute(
      'data-diagram-source'
    )).toBe('flowchart TD\n  A[Read] --> B[Understand]')
  })

  it('keeps ordinary unlabelled and language-tagged code as code blocks', async () => {
    const html = await renderMarkdown([
      '```',
      'const flowchart = true',
      '```',
      '',
      '```swift',
      'flowchart TD',
      '```'
    ].join('\n'))
    const document = new JSDOM(html).window.document

    expect(document.querySelectorAll('.mermaid-diagram')).toHaveLength(0)
    expect(document.querySelectorAll('pre')).toHaveLength(2)
  })

  it('removes executable content and rewrites relative images', async () => {
    const markdown = [
      '<script>alert(1)</script>',
      '<img src="images/a.png" onerror="alert(2)">',
      '<a href="javascript:alert(3)">bad</a>',
      '',
      '![remote](https://example.com/a.png)'
    ].join('\n')

    const html = await renderMarkdown(markdown)

    expect(html).not.toContain('<script')
    expect(html).not.toContain('onerror')
    expect(html).not.toContain('javascript:')
    expect(html).toContain('src="mdreader-file://document/images/a.png"')
    expect(html).toContain('src="https://example.com/a.png"')
  })
})
