import { Image } from '@moduix/react/image'
import overviewSrcSet from '@/assets/product/overview.png?w=580;1160;2320&format=webp&quality=90&effort=6&as=srcset'
import overviewPng from '@/assets/product/overview.png'
import cpuSrcSet from '@/assets/product/cpu.png?w=580;1160;2320&format=webp&quality=90&effort=6&as=srcset'
import cpuPng from '@/assets/product/cpu.png'
import memorySrcSet from '@/assets/product/memory.png?w=580;1160;2320&format=webp&quality=90&effort=6&as=srcset'
import memoryPng from '@/assets/product/memory.png'
import diskSrcSet from '@/assets/product/disk.png?w=580;1160;2320&format=webp&quality=90&effort=6&as=srcset'
import diskPng from '@/assets/product/disk.png'
import networkSrcSet from '@/assets/product/network.png?w=580;1160;2320&format=webp&quality=90&effort=6&as=srcset'
import networkPng from '@/assets/product/network.png'
import sensorsSrcSet from '@/assets/product/sensors.png?w=580;1160;2320&format=webp&quality=90&effort=6&as=srcset'
import sensorsPng from '@/assets/product/sensors.png'
import aiSrcSet from '@/assets/product/ai-limits.png?w=580;1160;2320&format=webp&quality=90&effort=6&as=srcset'
import aiPng from '@/assets/product/ai-limits.png'
import popoverSrcSet from '@/assets/product/popover.png?w=480;960&format=webp&quality=90&effort=6&as=srcset'
import popoverPng from '@/assets/product/popover.png'
import styles from './ProductImage.module.css'

const images = {
  overview: [overviewPng, overviewSrcSet],
  cpu: [cpuPng, cpuSrcSet],
  memory: [memoryPng, memorySrcSet],
  disk: [diskPng, diskSrcSet],
  network: [networkPng, networkSrcSet],
  sensors: [sensorsPng, sensorsSrcSet],
  ai: [aiPng, aiSrcSet],
  popover: [popoverPng, popoverSrcSet],
} as const

export function ProductImage({
  view,
  alt,
  eager = false,
  className,
  sizes,
}: {
  view: keyof typeof images
  alt: string
  eager?: boolean
  className?: string
  sizes?: string
}) {
  const [png, srcSet] = images[view]
  const isPopover = view === 'popover'
  return (
    <picture className={`${styles.picture} ${className ?? ''}`}>
      <source
        srcSet={srcSet}
        sizes={
          sizes ??
          (isPopover
            ? '(max-width: 700px) 360px, (max-width: 1440px) 33.35vw, 480px'
            : '(max-width: 700px) 100vw, (max-width: 1200px) calc(100vw - 40px), 1160px')
        }
        type="image/webp"
      />
      <Image
        src={png}
        width={isPopover ? 480 : 1160}
        height={isPopover ? 760 : 800}
        alt={alt}
        loading={eager ? 'eager' : 'lazy'}
        fetchPriority={eager ? 'high' : undefined}
        decoding="async"
      />
    </picture>
  )
}
