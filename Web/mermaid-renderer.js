import mermaid from 'mermaid'

const lightTheme = {
  background: '#ffffff',
  primaryColor: '#eaf0f3',
  primaryTextColor: '#18242c',
  primaryBorderColor: '#9eb2bc',
  secondaryColor: '#f5f7f8',
  tertiaryColor: '#dde7eb',
  lineColor: '#315d71',
  textColor: '#18242c',
  mainBkg: '#eaf0f3',
  nodeBorder: '#9eb2bc',
  clusterBkg: '#f5f7f8',
  clusterBorder: '#cbd8de',
  edgeLabelBackground: '#ffffff',
  noteBkgColor: '#f7f4ed',
  noteTextColor: '#18242c',
  noteBorderColor: '#b9aa8f'
}

const darkTheme = {
  background: '#1c1b19',
  primaryColor: '#35322e',
  primaryTextColor: '#e8e3da',
  primaryBorderColor: '#6e7778',
  secondaryColor: '#282724',
  tertiaryColor: '#3d3a35',
  lineColor: '#8fb4c2',
  textColor: '#e8e3da',
  mainBkg: '#35322e',
  nodeBorder: '#6e7778',
  clusterBkg: '#282724',
  clusterBorder: '#514d47',
  edgeLabelBackground: '#1c1b19',
  noteBkgColor: '#3a342a',
  noteTextColor: '#e8e3da',
  noteBorderColor: '#8e8068'
}

export function createMermaidConfig(darkMode) {
  return {
    startOnLoad: false,
    securityLevel: 'strict',
    suppressErrorRendering: true,
    deterministicIds: true,
    deterministicIDSeed: 'mdreader',
    theme: 'base',
    themeVariables: darkMode ? darkTheme : lightTheme,
    fontFamily: '"Iowan Old Style", "Songti SC", "STSong", Georgia, serif',
    flowchart: {
      htmlLabels: true,
      useMaxWidth: false
    }
  }
}

export async function renderMermaidDiagrams(
  content,
  {
    mermaidAPI = mermaid,
    darkMode = globalThis.matchMedia?.('(prefers-color-scheme: dark)').matches ?? false
  } = {}
) {
  const diagrams = [...content.querySelectorAll('.mermaid-diagram')]
  if (diagrams.length === 0) return

  if (!mermaidAPI?.initialize || typeof mermaidAPI.render !== 'function') {
    for (const diagram of diagrams) installDiagramFallback(diagram)
    return
  }

  mermaidAPI.initialize(createMermaidConfig(darkMode))

  for (const [index, diagram] of diagrams.entries()) {
    const source = diagram.dataset.diagramSource ?? ''
    try {
      const {svg} = await mermaidAPI.render(
        `mdreader-diagram-${index + 1}`,
        source
      )
      const canvas = diagram.ownerDocument.createElement('div')
      canvas.className = 'mermaid-diagram__canvas'
      canvas.innerHTML = svg
      diagram.replaceChildren(canvas)
      diagram.removeAttribute('data-diagram-source')
      diagram.setAttribute('role', 'img')
      diagram.setAttribute('aria-label', 'Mermaid diagram')
    } catch {
      installDiagramFallback(diagram, source)
    }
  }
}

function installDiagramFallback(
  diagram,
  source = diagram.dataset.diagramSource ?? ''
) {
  const document = diagram.ownerDocument
  const message = document.createElement('p')
  message.className = 'mermaid-diagram__error'
  message.textContent = 'Diagram could not be rendered'

  const pre = document.createElement('pre')
  const code = document.createElement('code')
  code.textContent = source
  pre.append(code)

  diagram.replaceChildren(message, pre)
  diagram.removeAttribute('data-diagram-source')
  diagram.classList.add('mermaid-diagram--error')
  diagram.setAttribute('role', 'group')
  diagram.setAttribute('aria-label', 'Diagram source fallback')
}
