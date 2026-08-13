import {JSDOM} from 'jsdom'
import {describe, expect, it, vi} from 'vitest'
import {
  createMermaidConfig,
  renderMermaidDiagrams
} from './mermaid-renderer.js'

function diagramDocument(sources) {
  const dom = new JSDOM('<!doctype html><article id="content"></article>')
  const content = dom.window.document.getElementById('content')
  for (const source of sources) {
    const diagram = dom.window.document.createElement('div')
    diagram.className = 'mermaid-diagram'
    diagram.dataset.diagramSource = source
    content.append(diagram)
  }
  return {dom, content}
}

describe('renderMermaidDiagrams', () => {
  it('renders every placeholder as inline SVG with deterministic identifiers', async () => {
    const {content} = diagramDocument(['flowchart TD\nA --> B', 'pie\n"A" : 1'])
    const mermaidAPI = {
      initialize: vi.fn(),
      render: vi.fn(async id => ({
        svg: `<svg aria-labelledby="${id}-title"><title id="${id}-title">Diagram</title></svg>`
      }))
    }

    await renderMermaidDiagrams(content, {mermaidAPI, darkMode: false})

    expect(content.querySelectorAll('.mermaid-diagram__canvas svg')).toHaveLength(2)
    expect(mermaidAPI.render.mock.calls.map(call => call[0])).toEqual([
      'mdreader-diagram-1',
      'mdreader-diagram-2'
    ])
    expect(mermaidAPI.render.mock.calls.map(call => call[1])).toEqual([
      'flowchart TD\nA --> B',
      'pie\n"A" : 1'
    ])
    expect(content.querySelector('.mermaid-diagram')?.hasAttribute(
      'data-diagram-source'
    )).toBe(false)
  })

  it('isolates syntax failures and preserves the failed source', async () => {
    const {content} = diagramDocument(['broken diagram', 'flowchart LR\nA --> B'])
    const mermaidAPI = {
      initialize: vi.fn(),
      render: vi.fn(async (id, source) => {
        if (source === 'broken diagram') throw new Error('Parse error')
        return {svg: `<svg id="${id}"></svg>`}
      })
    }

    await renderMermaidDiagrams(content, {mermaidAPI, darkMode: false})

    const failed = content.querySelector('.mermaid-diagram--error')
    expect(failed?.querySelector('.mermaid-diagram__error')?.textContent)
      .toBe('Diagram could not be rendered')
    expect(failed?.querySelector('code')?.textContent).toBe('broken diagram')
    expect(content.querySelectorAll('.mermaid-diagram__canvas svg')).toHaveLength(1)
  })

  it('falls back locally when the runtime is unavailable', async () => {
    const {content} = diagramDocument(['flowchart TD\nA --> B'])

    await renderMermaidDiagrams(content, {mermaidAPI: undefined, darkMode: false})

    expect(content.querySelector('.mermaid-diagram--error code')?.textContent)
      .toBe('flowchart TD\nA --> B')
  })
})

describe('createMermaidConfig', () => {
  it('uses strict offline-safe configuration and an editorial light theme', () => {
    expect(createMermaidConfig(false)).toMatchObject({
      startOnLoad: false,
      securityLevel: 'strict',
      suppressErrorRendering: true,
      deterministicIds: true,
      theme: 'base',
      themeVariables: {
        background: '#ffffff',
        primaryColor: '#eaf0f3',
        primaryTextColor: '#18242c',
        lineColor: '#315d71'
      }
    })
  })

  it('uses warm high-contrast values in dark mode', () => {
    expect(createMermaidConfig(true).themeVariables).toMatchObject({
      background: '#1c1b19',
      primaryColor: '#35322e',
      primaryTextColor: '#e8e3da',
      lineColor: '#8fb4c2'
    })
  })
})
