import {execFile} from 'node:child_process'
import {existsSync} from 'node:fs'
import {readFile} from 'node:fs/promises'
import {promisify} from 'node:util'
import {beforeAll, describe, expect, it} from 'vitest'

const execFileAsync = promisify(execFile)
const chromePath = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const describeWithBrowser = existsSync(chromePath) ? describe : describe.skip

let fixtureURL

beforeAll(async () => {
  const stylesheet = await readFile(new URL(
    '../Sources/MDReaderKit/Resources/Web/reader.css',
    import.meta.url
  ), 'utf8')
  const fixture = `<!doctype html>
    <html data-state="ready">
      <head><style>${stylesheet}</style></head>
      <body>
        <main id="reader">
          <article class="document">
            <p>Long-form reading sample <a href="#sample">Link</a> <code>inline()</code></p>
            <blockquote>Quoted content</blockquote>
            <pre><code>const answer = 42</code></pre>
            <div class="mermaid-diagram" role="img" aria-label="Mermaid diagram">
              <div class="mermaid-diagram__canvas">
                <svg class="landscape-diagram" viewBox="0 0 1200 480" width="1200" height="480"><rect width="1200" height="480"></rect></svg>
              </div>
            </div>
            <div class="mermaid-diagram portrait-diagram" role="img" aria-label="Portrait Mermaid diagram">
              <div class="mermaid-diagram__canvas">
                <svg viewBox="0 0 420 1800" width="420" height="1800"><rect width="420" height="1800"></rect></svg>
              </div>
            </div>
            <div class="mermaid-diagram mermaid-diagram--error">
              <p class="mermaid-diagram__error">Diagram could not be rendered</p>
              <pre><code>flowchart TD</code></pre>
            </div>
            <table><tbody><tr><td>Table content</td></tr></tbody></table>
          </article>
        </main>
        <output id="result"></output>
        <script>
          const article = document.querySelector('.document');
          const articleBox = article.getBoundingClientRect();
          const bodyStyle = getComputedStyle(document.body);
          const linkStyle = getComputedStyle(document.querySelector('a'));
          const inlineCodeStyle = getComputedStyle(document.querySelector('p code'));
          const codeBlockStyle = getComputedStyle(document.querySelector('pre'));
          const quoteStyle = getComputedStyle(document.querySelector('blockquote'));
          const diagram = document.querySelector('.mermaid-diagram:not(.mermaid-diagram--error)');
          const diagramCanvas = diagram.querySelector('.mermaid-diagram__canvas');
          const diagramSVG = diagram.querySelector('svg');
          const portraitSVG = document.querySelector('.portrait-diagram svg');
          const diagramStyle = getComputedStyle(diagram);
          const fallbackStyle = getComputedStyle(document.querySelector('.mermaid-diagram--error'));
          document.querySelector('#result').textContent = JSON.stringify({
            viewportWidth: document.documentElement.clientWidth,
            documentWidth: articleBox.width,
            background: bodyStyle.backgroundColor,
            foreground: bodyStyle.color,
            link: linkStyle.color,
            inlineCodeBackground: inlineCodeStyle.backgroundColor,
            codeBlockBackground: codeBlockStyle.backgroundColor,
            quote: quoteStyle.color,
            diagramWidth: diagram.getBoundingClientRect().width,
            diagramCanvasWidth: diagramCanvas.getBoundingClientRect().width,
            diagramSVGWidth: diagramSVG.getBoundingClientRect().width,
            portraitSVGWidth: portraitSVG.getBoundingClientRect().width,
            portraitSVGHeight: portraitSVG.getBoundingClientRect().height,
            diagramOverflow: diagramStyle.overflowX,
            diagramBackground: diagramStyle.backgroundColor,
            diagramBorder: diagramStyle.borderTopColor,
            fallbackColor: fallbackStyle.color,
            prefersDark: matchMedia('(prefers-color-scheme: dark)').matches,
            fontFamily: bodyStyle.fontFamily
          });
        </script>
      </body>
    </html>`
  fixtureURL = `data:text/html;charset=utf-8,${encodeURIComponent(fixture)}`
})

async function measureReader(windowWidth, colorScheme = 'light') {
  const argumentsList = [
    '--headless=new',
    '--disable-background-networking',
    '--disable-gpu',
    '--no-sandbox',
    '--no-first-run',
    '--no-default-browser-check',
    `--blink-settings=preferredColorScheme=${colorScheme === 'dark' ? 0 : 1}`,
    `--window-size=${windowWidth},900`,
    '--dump-dom',
    fixtureURL
  ]
  const {stdout} = await execFileAsync(chromePath, argumentsList, {
    timeout: 10_000,
    maxBuffer: 2_000_000
  })
  const payload = stdout.match(/<output id="result">([^<]+)<\/output>/)?.[1]
  if (!payload) throw new Error('The reader layout could not be measured.')
  return JSON.parse(payload.replaceAll('&quot;', '"'))
}

describeWithBrowser('reader visual layout', () => {
  it('uses a pure white reading surface and an elegant local serif stack', async () => {
    const layout = await measureReader(1_000)

    expect(layout.background).toBe('rgb(255, 255, 255)')
    expect(layout.prefersDark).toBe(false)
    expect(layout.fontFamily).toContain('Iowan Old Style')
    expect(layout.fontFamily).toContain('Songti SC')
  }, 30_000)

  it('uses a warm charcoal palette when the system prefers dark mode', async () => {
    const layout = await measureReader(1_000, 'dark')

    expect(layout.prefersDark).toBe(true)
    expect(layout.background).toBe('rgb(28, 27, 25)')
    expect(layout.foreground).not.toBe(layout.background)
    expect(layout.link).not.toBe(layout.foreground)
    expect(layout.inlineCodeBackground).not.toBe(layout.background)
    expect(layout.codeBlockBackground).not.toBe(layout.background)
    expect(layout.quote).not.toBe(layout.background)
  }, 30_000)

  it('grows the reading column with the window without exceeding 80 percent', async () => {
    const small = await measureReader(900)
    const large = await measureReader(1_400)

    expect(small.documentWidth).toBeLessThanOrEqual(small.viewportWidth * 0.8 + 1)
    expect(large.documentWidth).toBeLessThanOrEqual(large.viewportWidth * 0.8 + 1)
    expect(large.documentWidth).toBeGreaterThan(small.documentWidth * 1.45)
  }, 30_000)

  it('contains wide diagrams inside a responsive local surface', async () => {
    const layout = await measureReader(900)

    expect(layout.diagramWidth).toBeLessThanOrEqual(layout.documentWidth + 1)
    expect(layout.diagramCanvasWidth).toBeLessThanOrEqual(layout.diagramWidth + 1)
    expect(layout.diagramSVGWidth).toBeLessThanOrEqual(layout.diagramCanvasWidth + 1)
    expect(layout.diagramOverflow).toBe('auto')
    expect(layout.diagramBackground).not.toBe(layout.background)
    expect(layout.diagramBorder).not.toBe(layout.diagramBackground)
  }, 30_000)

  it('does not shrink tall flowcharts to the viewport height', async () => {
    const layout = await measureReader(900)

    expect(layout.portraitSVGWidth).toBeGreaterThan(300)
    expect(layout.portraitSVGHeight).toBeGreaterThan(1_200)
  }, 30_000)

  it('keeps diagrams and their source fallback readable in dark mode', async () => {
    const layout = await measureReader(1_000, 'dark')

    expect(layout.diagramBackground).not.toBe(layout.background)
    expect(layout.diagramBorder).not.toBe(layout.diagramBackground)
    expect(layout.fallbackColor).not.toBe(layout.diagramBackground)
  }, 30_000)
})
