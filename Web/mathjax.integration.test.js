import MathJax from 'mathjax'
import {afterAll, beforeAll, describe, expect, it} from 'vitest'

let mathJax

beforeAll(async () => {
  mathJax = await MathJax.init({
    loader: {load: ['input/tex', 'input/mml', 'output/chtml']},
    startup: {typeset: false}
  })
})

afterAll(async () => {
  await mathJax?.done()
})

describe('bundled MathJax', () => {
  it('typesets LaTeX into structured display math', async () => {
    const node = await mathJax.tex2chtmlPromise(
      String.raw`P(A \mid B) = \frac{P(B \mid A)P(A)}{P(B)}`,
      {display: true}
    )
    const html = mathJax.startup.adaptor.serializeXML(node)

    expect(html).toContain('<mjx-container')
    expect(html).toContain('display="true"')
    expect(html).toMatch(/<mjx-mfrac(?:\s|>)/)
  })

  it('typesets MathML into structured inline math', async () => {
    const node = await mathJax.mathml2chtmlPromise(
      '<math><msup><mi>x</mi><mn>2</mn></msup></math>'
    )
    const html = mathJax.startup.adaptor.serializeXML(node)

    expect(html).toContain('<mjx-container')
    expect(html).toContain('<mjx-msup>')
  })
})
