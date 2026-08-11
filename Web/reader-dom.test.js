import {readFile} from 'node:fs/promises'
import {JSDOM} from 'jsdom'
import {afterEach, describe, expect, it, vi} from 'vitest'
import {renderDocument} from './renderer.js'

const originalDocument = globalThis.document
const originalMathJax = globalThis.MathJax

afterEach(() => {
  globalThis.document = originalDocument
  globalThis.MathJax = originalMathJax
})

describe('reader host', () => {
  it('uses only local application scripts and exposes loading and content regions', async () => {
    const html = await readFile(
      new URL('../Sources/MDReaderKit/Resources/Web/index.html', import.meta.url),
      'utf8'
    )
    const dom = new JSDOM(html)
    const document = dom.window.document
    const scriptSources = [...document.querySelectorAll('script[src]')]
      .map(script => script.getAttribute('src'))

    expect(document.querySelector('#loading')).not.toBeNull()
    expect(document.querySelector('#content')).not.toBeNull()
    expect(document.querySelector('meta[http-equiv="Content-Security-Policy"]')).not.toBeNull()
    expect(scriptSources).toEqual([
      'mdreader-resource://app/renderer.js',
      'mdreader-resource://mathjax/tex-mml-chtml.js',
      'mdreader-resource://app/boot.js'
    ])
    expect(html).not.toMatch(/cdn|jsdelivr|unpkg/i)
  })

  it('pins MathJax dynamic fonts to bundled reader resources', async () => {
    const html = await readFile(
      new URL('../Sources/MDReaderKit/Resources/Web/index.html', import.meta.url),
      'utf8'
    )
    const dom = new JSDOM(html, {runScripts: 'dangerously'})

    expect(dom.window.MathJax.loader.paths).toMatchObject({
      mathjax: 'mdreader-resource://mathjax',
      fonts: 'mdreader-resource://mathjax/output/fonts',
      'mathjax-newcm': 'mdreader-resource://mathjax/output/fonts/mathjax-newcm'
    })
    expect(dom.window.MathJax.chtml.dynamicPrefix)
      .toBe('mdreader-resource://mathjax/output/fonts/mathjax-newcm/chtml/dynamic')
    expect(dom.window.MathJax.chtml.fontURL)
      .toBe('mdreader-resource://mathjax/output/fonts/mathjax-newcm/chtml/woff2')
    expect(dom.window.MathJax.options).toMatchObject({
      enableMenu: false,
      enableEnrichment: false,
      enableSpeech: false,
      enableBraille: false,
      enableExplorer: false,
      enableComplexity: false,
      enableAssistiveMml: false
    })
    expect(dom.window.MathJax.options.menuOptions.settings).toMatchObject({
      enrich: false,
      speech: false,
      braille: false,
      collapsible: false,
      assistiveMml: false
    })
  })

  it('reveals content after math layout and replaces failed images locally', async () => {
    const dom = new JSDOM(
      '<!doctype html><html data-state="loading"><body><article id="content"></article></body></html>',
      {url: 'https://mdreader.test/'}
    )
    const typesetPromise = vi.fn(async () => {})
    globalThis.document = dom.window.document
    globalThis.MathJax = {
      startup: {promise: Promise.resolve()},
      typesetPromise
    }

    await renderDocument({
      source: '# Heading\n\n![Diagram](images/missing.png)',
      title: 'Demo.md'
    })
    const image = dom.window.document.querySelector('img')
    image.dispatchEvent(new dom.window.Event('error'))

    expect(typesetPromise).toHaveBeenCalledOnce()
    expect(dom.window.document.documentElement.dataset.state).toBe('ready')
    expect(dom.window.document.querySelector('.broken-image')?.textContent)
      .toContain('Diagram')
  })

  it('does not reveal the document when the math engine is unavailable', async () => {
    const dom = new JSDOM(
      '<!doctype html><html data-state="loading"><body><article id="content"></article></body></html>',
      {url: 'https://mdreader.test/'}
    )
    globalThis.document = dom.window.document
    globalThis.MathJax = undefined

    await expect(renderDocument({source: '$x^2$', title: 'Math.md'}))
      .rejects.toThrow('The math typesetting component failed to start')

    expect(dom.window.document.documentElement.dataset.state).toBe('loading')
  })
})
