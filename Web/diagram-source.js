const diagramDirective = /^(?:flowchart|graph)(?:\s|$)|^(?:sequenceDiagram|classDiagram|stateDiagram(?:-v2)?|erDiagram|gantt|pie|journey|gitGraph|mindmap|timeline|quadrantChart|requirementDiagram|C4(?:Context|Container|Component|Dynamic|Deployment)|block-beta|packet-beta|architecture-beta|kanban|sankey-beta|xychart-beta|radar-beta|treemap-beta|swimlane|eventModeling|treeView|ishikawa|venn-beta|wardley|cynefin)(?:\s|$)/

export function isMermaidSource(source) {
  const firstDirective = source
    .split(/\r?\n/)
    .map(line => line.trim())
    .find(line => line && !line.startsWith('%%'))

  return typeof firstDirective === 'string'
    && diagramDirective.test(firstDirective)
}

export function rehypeMermaidBlocks() {
  return tree => {
    transformChildren(tree)
  }
}

function transformChildren(parent) {
  if (!Array.isArray(parent.children)) return

  parent.children = parent.children.map(node => {
    const diagram = diagramPlaceholder(node)
    if (diagram) return diagram
    transformChildren(node)
    return node
  })
}

function diagramPlaceholder(node) {
  if (node.type !== 'element' || node.tagName !== 'pre') return undefined
  const code = node.children?.length === 1 ? node.children[0] : undefined
  if (code?.type !== 'element' || code.tagName !== 'code') return undefined

  const source = textContent(code).replace(/\n$/, '')
  const language = code.properties?.className
    ?.find(value => typeof value === 'string' && value.startsWith('language-'))
    ?.slice('language-'.length)
    ?.toLowerCase()
  const isExplicit = language === 'mermaid'
  const isUnlabelled = language === undefined

  if (!isExplicit && !(isUnlabelled && isMermaidSource(source))) {
    return undefined
  }

  return {
    type: 'element',
    tagName: 'div',
    properties: {
      className: ['mermaid-diagram'],
      dataDiagramSource: source
    },
    children: []
  }
}

function textContent(node) {
  if (node.type === 'text') return node.value
  if (!Array.isArray(node.children)) return ''
  return node.children.map(textContent).join('')
}
