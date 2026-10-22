/** The app icon: a graphite tile with the CPU, memory and battery bars, drawn from `AppIcon.icon`. */
export function Logo({ size }: { size: number }) {
  return <img src="/favicon.svg" alt="" width={size} height={size} />
}
