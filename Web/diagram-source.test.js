import {describe, expect, it} from 'vitest'
import {isMermaidSource} from './diagram-source.js'

describe('isMermaidSource', () => {
  it('recognizes supported diagram directives after comments and whitespace', () => {
    const supported = [
      'flowchart TD\nA --> B',
      'graph LR\nA --> B',
      'sequenceDiagram\nA->>B: Hello',
      'classDiagram\nA <|-- B',
      'stateDiagram-v2\n[*] --> Ready',
      'erDiagram\nUSER ||--o{ ORDER : places',
      'gantt\ntitle Plan',
      'pie title Languages',
      'mindmap\n  root((Reader))',
      '%% comment\n\n  timeline\n    2026 : Release',
      'architecture-beta\ngroup api(cloud)[API]',
      'swimlane\n  column Developer',
      'eventModeling\ntitle Order lifecycle',
      'treeView\nroot',
      'ishikawa\nrootCause: Delay',
      'venn-beta\nset A',
      'wardley\ntitle Evolution',
      'cynefin\nClear: Known',
      'packet-beta\n0-7: Header'
    ]

    for (const source of supported) {
      expect(isMermaidSource(source), source).toBe(true)
    }
  })

  it('does not infer diagrams from code or prose containing directive words', () => {
    const ordinary = [
      'const flowchart = true',
      'This flowchart explains the process.',
      'flowcharts are useful',
      'graphical result',
      ''
    ]

    for (const source of ordinary) {
      expect(isMermaidSource(source), source).toBe(false)
    }
  })
})
