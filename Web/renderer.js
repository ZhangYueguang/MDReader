import rehypeHighlight from 'rehype-highlight'
import rehypeMathjaxBrowser from 'rehype-mathjax/browser'
import rehypeRaw from 'rehype-raw'
import rehypeSanitize, {defaultSchema} from 'rehype-sanitize'
import rehypeStringify from 'rehype-stringify'
import remarkFrontmatter from 'remark-frontmatter'
import remarkGfm from 'remark-gfm'
import remarkMath from 'remark-math'
import remarkParse from 'remark-parse'
import remarkRehype from 'remark-rehype'
import {unified} from 'unified'

const mathMLTags = [
  'math', 'semantics', 'annotation', 'annotation-xml', 'mi', 'mn', 'mo',
  'mtext', 'mspace', 'ms', 'mglyph', 'mrow', 'mfrac', 'msqrt', 'mroot',
  'mstyle', 'merror', 'mpadded', 'mphantom', 'mfenced', 'menclose', 'msub',
  'msup', 'msubsup', 'munder', 'mover', 'munderover', 'mmultiscripts',
  'mprescripts', 'none', 'mtable', 'mlabeledtr', 'mtr', 'mtd',
  'maligngroup', 'malignmark', 'maction'
]

const mathMLAttributes = [
  'accent', 'accentunder', 'actiontype', 'align', 'columnalign',
  'columnlines', 'columnspacing', 'columnspan', 'denomalign', 'depth',
  'dir', 'display', 'displaystyle', 'encoding', 'fence', 'frame',
  'height', 'href', 'linethickness', 'lspace', 'mathbackground',
  'mathcolor', 'mathsize', 'mathvariant', 'maxsize', 'minsize', 'movablelimits',
  'notation', 'numalign', 'open', 'rowalign', 'rowlines', 'rowspacing',
  'rowspan', 'rspace', 'scriptlevel', 'scriptminsize', 'scriptsizemultiplier',
  'selection', 'separator', 'separators', 'shift', 'side', 'src', 'stackalign',
  'stretchy', 'subscriptshift', 'superscriptshift', 'symmetric', 'voffset',
  'width', 'xmlns'
]

const sanitizeSchema = {
  ...defaultSchema,
  tagNames: [
    ...defaultSchema.tagNames,
    'aside', 'dl', 'dt', 'dd', 'input', ...mathMLTags
  ],
  attributes: {
    ...defaultSchema.attributes,
    '*': [
      ...(defaultSchema.attributes['*'] || []),
      'className', 'id', 'title', ...mathMLAttributes
    ],
    code: [
      ...(defaultSchema.attributes.code || []),
      ['className', /^language-./, 'math-inline', 'math-display']
    ],
    input: ['type', 'checked', 'disabled'],
    ol: [...(defaultSchema.attributes.ol || []), 'className'],
    section: [...(defaultSchema.attributes.section || []), 'className'],
    a: [...(defaultSchema.attributes.a || []), 'dataFootnoteRef', 'ariaDescribedBy'],
    aside: ['className'],
    dl: ['className']
  },
  protocols: {
    ...defaultSchema.protocols,
    href: ['http', 'https', 'mailto'],
    src: ['http', 'https', 'mdreader-file']
  }
}

function frontmatterHandler(_state, node) {
  const rows = node.value
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(Boolean)
    .map(line => {
      const separator = line.indexOf(':')
      const key = separator >= 0 ? line.slice(0, separator).trim() : line
      const value = separator >= 0 ? line.slice(separator + 1).trim() : ''
      return [key, value]
    })

  return {
    type: 'element',
    tagName: 'aside',
    properties: {className: ['frontmatter']},
    children: [{
      type: 'element',
      tagName: 'dl',
      properties: {},
      children: rows.flatMap(([key, value]) => [
        {type: 'element', tagName: 'dt', properties: {}, children: [{type: 'text', value: key}]},
        {type: 'element', tagName: 'dd', properties: {}, children: [{type: 'text', value}]}
      ])
    }]
  }
}

function rehypeRelativeImages() {
  return tree => {
    walk(tree, node => {
      if (node.type !== 'element' || node.tagName !== 'img') return
      const source = node.properties?.src
      if (typeof source !== 'string' || isExternalURL(source)) return
      if (source.startsWith('/') || source.startsWith('~')) {
        delete node.properties.src
        node.properties.dataBlockedSource = source
        return
      }
      const normalized = source.replaceAll('\\', '/')
      const encoded = normalized
        .split('/')
        .map(segment => encodeURIComponent(segment))
        .join('/')
      node.properties.src = `mdreader-file://document/${encoded}`
    })
  }
}

function isExternalURL(value) {
  return /^[a-zA-Z][a-zA-Z\d+.-]*:/.test(value) || value.startsWith('//')
}

function walk(node, visitor) {
  visitor(node)
  if (!Array.isArray(node.children)) return
  for (const child of node.children) walk(child, visitor)
}

function normalizeInlineMathDelimiters(line) {
  let result = ''
  let codeSpanLength = 0
  let index = 0

  while (index < line.length) {
    if (line[index] === '`') {
      let runLength = 1
      while (line[index + runLength] === '`') runLength += 1
      if (codeSpanLength === 0) {
        codeSpanLength = runLength
      } else if (runLength === codeSpanLength) {
        codeSpanLength = 0
      }
      result += line.slice(index, index + runLength)
      index += runLength
      continue
    }

    if (codeSpanLength === 0
        && line[index] === '\\'
        && line[index + 1] === '('
        && !isEscapedBackslash(line, index)) {
      const closingIndex = findInlineMathEnd(line, index + 2)
      if (closingIndex >= 0) {
        result += `$${line.slice(index + 2, closingIndex)}$`
        index = closingIndex + 2
        continue
      }
    }

    result += line[index]
    index += 1
  }

  return result
}

function findInlineMathEnd(line, startIndex) {
  for (let index = startIndex; index < line.length - 1; index += 1) {
    if (line[index] === '\\'
        && line[index + 1] === ')'
        && !isEscapedBackslash(line, index)) {
      return index
    }
  }
  return -1
}

function isEscapedBackslash(line, index) {
  let precedingBackslashes = 0
  for (let cursor = index - 1; cursor >= 0 && line[cursor] === '\\'; cursor -= 1) {
    precedingBackslashes += 1
  }
  return precedingBackslashes % 2 === 1
}

function normalizeMathDelimiters(source) {
  const lines = source.split(/\r?\n/)
  let fence

  return lines.map(line => {
    const fenceMatch = line.match(/^ {0,3}(`{3,}|~{3,})/)
    if (fenceMatch) {
      const marker = fenceMatch[1]
      if (!fence) {
        fence = {character: marker[0], length: marker.length}
      } else if (marker[0] === fence.character && marker.length >= fence.length) {
        fence = undefined
      }
      return line
    }
    if (fence) return line
    if (/^ {0,3}\\\[[ \t]*$/.test(line) || /^ {0,3}\\\][ \t]*$/.test(line)) {
      return '$$'
    }
    return normalizeInlineMathDelimiters(line)
  }).join('\n')
}

function createProcessor() {
  return unified()
    .use(remarkParse)
    .use(remarkGfm)
    .use(remarkMath)
    .use(remarkFrontmatter, ['yaml'])
    .use(remarkRehype, {
      allowDangerousHtml: true,
      handlers: {yaml: frontmatterHandler}
    })
    .use(rehypeRaw)
    .use(rehypeSanitize, sanitizeSchema)
    .use(rehypeMathjaxBrowser, {
      tex: {
        inlineMath: [['\\(', '\\)']],
        displayMath: [['\\[', '\\]']]
      }
    })
    .use(rehypeHighlight, {detect: false, plainText: ['math']})
    .use(rehypeRelativeImages)
    .use(rehypeStringify)
}

export async function renderMarkdown(source) {
  const result = await createProcessor().process(normalizeMathDelimiters(source))
  return String(result)
}

export async function renderDocument({source, title}) {
  const content = document.getElementById('content')
  if (!content) throw new Error('The reader page is not ready.')
  document.title = title || 'MDReader'
  content.innerHTML = await renderMarkdown(source)
  installImageFallbacks(content)
  const mathJax = globalThis.MathJax
  if (!mathJax?.startup?.promise || typeof mathJax.typesetPromise !== 'function') {
    throw new Error('The math typesetting component failed to start.')
  }
  await mathJax.startup.promise
  await mathJax.typesetPromise([content])
  document.documentElement.dataset.state = 'ready'
}

function installImageFallbacks(content) {
  for (const image of content.querySelectorAll('img')) {
    image.addEventListener('error', () => {
      const fallback = document.createElement('span')
      fallback.className = 'broken-image'
      fallback.setAttribute('role', 'img')
      const label = image.getAttribute('alt')?.trim() || 'Untitled image'
      const source = image.getAttribute('src')
        || image.getAttribute('data-blocked-source')
        || ''
      fallback.textContent = source
        ? `Image could not be displayed · ${label} · ${source}`
        : `Image could not be displayed · ${label}`
      image.replaceWith(fallback)
    }, {once: true})
  }
}

if (typeof window !== 'undefined') {
  window.MDReader = {render: renderDocument}
}
