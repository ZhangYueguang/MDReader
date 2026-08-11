import {build} from 'esbuild'
import {copyFile, cp, mkdir, rm} from 'node:fs/promises'
import path from 'node:path'
import {fileURLToPath} from 'node:url'

const repositoryRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..'
)
const generatedRoot = path.join(
  repositoryRoot,
  'Sources/MDReaderKit/GeneratedResources'
)
const appRoot = path.join(generatedRoot, 'app')
const mathJaxRoot = path.join(generatedRoot, 'mathjax')
const mathJaxFontRoot = path.join(
  mathJaxRoot,
  'output/fonts/mathjax-newcm'
)

await rm(appRoot, {recursive: true, force: true})
await rm(mathJaxRoot, {recursive: true, force: true})
await mkdir(appRoot, {recursive: true})

await build({
  entryPoints: [path.join(repositoryRoot, 'Web/renderer.js')],
  bundle: true,
  format: 'iife',
  globalName: 'MDReaderRenderer',
  outfile: path.join(appRoot, 'renderer.js'),
  platform: 'browser',
  target: ['safari17'],
  minify: true,
  legalComments: 'none'
})

for (const filename of ['index.html', 'reader.css', 'boot.js']) {
  await copyFile(
    path.join(repositoryRoot, 'Sources/MDReaderKit/Resources/Web', filename),
    path.join(appRoot, filename)
  )
}

await cp(
  path.join(repositoryRoot, 'node_modules/mathjax'),
  mathJaxRoot,
  {
    recursive: true,
    filter(source) {
      const base = path.basename(source)
      return !base.endsWith('.map')
        && base !== 'README.md'
        && base !== 'CONTRIBUTING.md'
        && base !== 'package.json'
    }
  }
)

await cp(
  path.join(repositoryRoot, 'node_modules/@mathjax/mathjax-newcm-font/chtml'),
  path.join(mathJaxFontRoot, 'chtml'),
  {
    recursive: true,
    filter(source) {
      return !source.endsWith('.map')
    }
  }
)
await copyFile(
  path.join(repositoryRoot, 'node_modules/@mathjax/mathjax-newcm-font/chtml.js'),
  path.join(mathJaxFontRoot, 'chtml.js')
)

console.log(`Renderer staged at ${path.relative(repositoryRoot, generatedRoot)}`)
