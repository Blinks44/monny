import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import { ProductImage } from '../components/product-image'

describe('product image SSR with moduix', () => {
  it('preserves local responsive sources, intrinsic dimensions and lazy loading', () => {
    const html = renderToStaticMarkup(
      createElement(ProductImage, { view: 'overview', alt: 'Overview' }),
    )
    expect(html).toContain('data-slot="image-root"')
    expect(html).toMatch(/<source[^>]+srcSet="[^"]+ 580w, [^"]+ 1160w, [^"]+ 2320w"/)
    expect(html).toContain('type="image/webp"')
    expect(html).toMatch(/<img[^>]+src="[^"]+overview.png"/)
    expect(html).toContain('width="1160" height="800"')
    expect(html).toContain('alt="Overview"')
    expect(html).toContain('loading="lazy"')
    expect(html).not.toMatch(/(?:layout|priority|unstyled)=/)
  })

  it('keeps the hero eager with high fetch priority and its padded aspect ratio', () => {
    const html = renderToStaticMarkup(
      createElement(ProductImage, { view: 'popover', alt: 'Popover', eager: true }),
    )
    expect(html).toMatch(/<source[^>]+srcSet="[^"]+ 480w, [^"]+ 960w"/)
    expect(html).toContain('width="480" height="760"')
    expect(html).toContain('loading="eager"')
    expect(html).toContain('fetchPriority="high"')
    expect(html).not.toContain('loading="lazy"')
  })
})
