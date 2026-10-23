import overviewWebp from '@/assets/product/overview.webp'
import overviewPng from '@/assets/product/overview.png'
import cpuWebp from '@/assets/product/cpu.webp'
import cpuPng from '@/assets/product/cpu.png'
import memoryWebp from '@/assets/product/memory.webp'
import memoryPng from '@/assets/product/memory.png'
import diskWebp from '@/assets/product/disk.webp'
import diskPng from '@/assets/product/disk.png'
import networkWebp from '@/assets/product/network.webp'
import networkPng from '@/assets/product/network.png'
import sensorsWebp from '@/assets/product/sensors.webp'
import sensorsPng from '@/assets/product/sensors.png'
import aiWebp from '@/assets/product/ai-limits.webp'
import aiPng from '@/assets/product/ai-limits.png'
import popoverWebp from '@/assets/product/popover.webp'
import popoverPng from '@/assets/product/popover.png'
import popoverSmall from '@/assets/product/popover-small.webp'
import cpuSmall from '@/assets/product/cpu-small.webp'
import styles from './ProductImage.module.css'

const images = {
  overview: [overviewWebp, overviewPng, 1040, 662],
  cpu: [cpuWebp, cpuPng, 1160, 800],
  memory: [memoryWebp, memoryPng, 1160, 820],
  disk: [diskWebp, diskPng, 1160, 820],
  network: [networkWebp, networkPng, 1160, 820],
  sensors: [sensorsWebp, sensorsPng, 1160, 820],
  ai: [aiWebp, aiPng, 740, 510],
  popover: [popoverWebp, popoverPng, 380, 640],
} as const

export function ProductImage({
  view,
  alt,
  eager = false,
  className,
}: {
  view: keyof typeof images
  alt: string
  eager?: boolean
  className?: string
}) {
  const [webp, png, width, height] = images[view]
  return (
    <picture className={`${styles.picture} ${className ?? ''}`}>
      <source
        srcSet={
          view === 'popover'
            ? `${popoverSmall} 380w, ${webp} 760w`
            : view === 'cpu'
              ? `${cpuSmall} 1160w, ${webp} 2320w`
              : webp
        }
        sizes={
          view === 'popover'
            ? '(max-width: 700px) 350px, 380px'
            : '(max-width: 700px) 100vw, 1160px'
        }
        type="image/webp"
      />
      <img
        src={png}
        width={width}
        height={height}
        alt={alt}
        loading={eager ? 'eager' : 'lazy'}
        fetchPriority={eager ? 'high' : undefined}
        decoding="async"
      />
    </picture>
  )
}
