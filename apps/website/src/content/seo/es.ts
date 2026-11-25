import type { LocaleSeoContent } from './types'

export const esSeoContent: LocaleSeoContent = {
  alternatives: {
    'istat-menus': {
      slug: 'istat-menus',
      path: '/alternatives/istat-menus/',
      breadcrumbLabel: 'iStat Menus',
      metaTitle: 'Alternativa gratuita a iStat Menus para Apple Silicon (Swift 6) · Monny',
      metaDescription:
        'Compara Monny frente a iStat Menus en Apple Silicon: monitor MIT gratuito en Swift 6 con gráficos de 7 días, límite de carga sin root en macOS 26.4+, buscador de puertos y 22 cuotas de IA.',
      headline: 'Una alternativa gratuita y open source a iStat Menus para Apple Silicon.',
      subtitle:
        'Supervisa núcleos P/E de CPU, memoria, disco, red, sensores SMC de Apple Silicon, puertos locales, límite nativo de batería y 22 cuotas de IA en una app SwiftUI gratuita bajo MIT.',
      highlights: [
        {
          value: 'Swift 6 · MIT Gratis',
          label: 'Nativo en Apple Silicon · sin licencias ni telemetría',
        },
        {
          value: 'Sin helper root',
          label: 'Límite nativo en macOS 26.4+ aplicado por el sistema',
        },
        {
          value: '22 cuotas IA + puertos',
          label: 'Buscador de puertos/PID y límites locales de IA opcionales',
        },
      ],
      competitorColumn: 'ISTAT MENUS',
      rows: [
        {
          criterion: 'Licencia y precio',
          monny: '100 % gratis y MIT open source en GitHub',
          other: 'App de pago o suscripción a Setapp',
        },
        {
          criterion: 'Límite de carga de batería',
          monny: 'Límite nativo 80-100 % en macOS 26.4+ sin helper root',
          other: 'Solo estadísticas de batería (sin limitador de carga)',
        },
        {
          criterion: 'Buscador de puertos y PID',
          monny: 'Busca por puerto (localhost:3002), ve la carpeta y cierra la tarea',
          other: 'Solo lista básica de procesos (sin búsqueda por puerto)',
        },
        {
          criterion: 'Cuotas de IA para código',
          monny: 'Barras locales opcionales y temporizadores para 22 herramientas de IA',
          other: 'No integrado',
        },
        {
          criterion: 'Gráficos de 7 días',
          monny: 'Panel Swift Charts completo (1m-7d) conservando pausas de reposo',
          other: 'Gráficos desplegables compactos en la barra de menú',
        },
        {
          criterion: 'Privacidad y telemetría',
          monny: 'Cero analíticas, sin cuentas, todo se queda en tu Mac',
          other: 'Activación de licencia de pago y comprobaciones opcionales',
        },
      ],
      chooseMonny: {
        label: 'RECOMENDADO PARA APPLE SILICON',
        title: 'Elige Monny cuando…',
        points: [
          'Quieres un monitor MIT gratuito para Apple Silicon con historial de 7 días',
          'También quieres límite de batería sin root, búsqueda de puertos y 22 cuotas IA',
          'Prefieres cero demonios en segundo plano, cuentas ni suscripciones',
        ],
      },
      stickWithOther: {
        label: 'CUÁNDO ISTAT MENUS SIGUE ENCAJANDO',
        title: 'Quédate con iStat Menus cuando…',
        points: [
          'Necesitas soporte para Mac Intel o macOS anterior a 15',
          'Buscas curvas manuales de ventilador o widgets del clima',
          'Quieres temas de gráficos hiperpersonalizados en la barra de menú',
        ],
      },
      steps: [
        {
          step: 'PASO 01',
          title: 'Instala con Homebrew o DMG',
          description:
            'Ejecuta brew install --cask blinks44/tap/monny. Sin contraseña de administrador, extensión ni cuenta.',
        },
        {
          step: 'PASO 02',
          title: 'Fija métricas en la barra de menú',
          description:
            'Elige CPU, RAM, red o batería para tu barra de menú y abre el popover cuando quieras con ⌥⌘M.',
        },
        {
          step: 'PASO 03',
          title: 'Opcional: activa cuotas IA y límite de carga',
          description:
            'Activa solo las herramientas de IA que usas y fija un límite nativo del 80 % en macOS 26.4+ sin helper root.',
        },
      ],
    },
    aldente: {
      slug: 'aldente',
      path: '/alternatives/aldente/',
      breadcrumbLabel: 'AlDente',
      metaTitle: 'Alternativa gratuita a AlDente sin helper root (macOS 26.4+) · Monny',
      metaDescription:
        'Compara Monny y AlDente: límite nativo de batería del 80-100 % en macOS 26.4+ como usuario normal sin demonios root, más monitor completo y 22 cuotas de IA.',
      headline: 'Una alternativa gratuita a AlDente sin demonios root.',
      subtitle:
        'Limita la carga del MacBook al 80-100 % en macOS 26.4+ usando el ajuste nativo de Apple como usuario estándar. macOS mantiene el límite incluso al cerrar Monny.',
      highlights: [
        {
          value: 'Sin helper root',
          label: 'Sin LaunchDaemon privilegiado, kexts ni escritura directa en SMC',
        },
        {
          value: 'Persiste al cerrar',
          label: 'macOS 26.4+ mantiene tu límite del 80-100 % de forma nativa',
        },
        {
          value: 'Monitor completo',
          label: 'Incluye CPU, sensores SMC, puertos y 22 cuotas IA en una app',
        },
      ],
      competitorColumn: 'ALDENTE / BATFI',
      rows: [
        {
          criterion: 'Permisos root',
          monny: 'Solo usuario estándar - cero helpers root privilegiados',
          other: 'Requiere demonio root privilegiado escribiendo claves SMC',
        },
        {
          criterion: 'Funciona con la app cerrada',
          monny: 'Sí - macOS 26.4+ mantiene el límite nativo tras cerrar y reiniciar',
          other: 'Necesita un demonio activo permanentemente en segundo plano',
        },
        {
          criterion: 'Precio y licencia',
          monny: '100 % gratis y MIT open source (sin muro de pago Pro)',
          other: 'Freemium con licencia Pro de pago o suscripción',
        },
        {
          criterion: 'Telemetría de batería',
          monny: 'Salud, ciclos, vatios en vivo, temperatura y alertas de carga',
          other: 'Controles de carga más protección térmica y calibración de pago',
        },
        {
          criterion: 'Herramientas extra',
          monny: 'Telemetría en menú, gráficos 7d, buscador puertos/PID y 22 cuotas IA',
          other: 'Utilidad enfocada solo en batería',
        },
        {
          criterion: 'Compatibilidad macOS',
          monny: 'Límite nativo en macOS 26.4+; lectura de batería en macOS 15-26.3',
          other: 'Soporta versiones anteriores mediante helper SMC con root',
        },
      ],
      chooseMonny: {
        label: 'RECOMENDADO EN MACOS 26.4+',
        title: 'Elige Monny cuando…',
        points: [
          'Usas Apple Silicon con macOS 26.4+ y buscas un límite 80-100 % sin root',
          'Quieres que el límite siga vigente al cerrar la app y reiniciar',
          'Prefieres reunir batería, monitoreo del sistema, puertos y cuotas IA',
        ],
      },
      stickWithOther: {
        label: 'CUÁNDO ALDENTE SIGUE ENCAJANDO',
        title: 'Quédate con AlDente cuando…',
        points: [
          'Aún estás en macOS 15 a 26.3 y necesitas limitar la carga hoy mismo',
          'Usas modos específicos como sailing mode, descarga o calibración',
          'Tienes un MacBook Intel sin acceso a la API nativa de macOS 26.4+',
        ],
      },
      steps: [
        {
          step: 'PASO 01',
          title: 'Instala Monny limpiamente',
          description:
            'Ejecuta brew install --cask blinks44/tap/monny o arrastra Monny.dmg a Aplicaciones. Sin avisos de admin.',
        },
        {
          step: 'PASO 02',
          title: 'Configura tu límite 80-100 %',
          description:
            'Abre los ajustes de batería en Monny sobre macOS 26.4+ y elige 80 % mediante la API nativa de macOS.',
        },
        {
          step: 'PASO 03',
          title: 'Retira helpers root extra',
          description:
            'Con macOS aplicando el límite de forma nativa, puedes quitar demonios separados y quedarte con una app de ~5 MB.',
        },
      ],
    },
  },
  guides: {
    'ai-coding-quotas': {
      slug: 'ai-coding-quotas',
      path: '/guides/ai-coding-quotas/',
      breadcrumbLabel: '22 cuotas de IA',
      metaTitle: 'Controla 22 cuotas de IA en la barra de menú de macOS · Monny',
      metaDescription:
        'Consulta las cuotas de sesión y semanales de Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf y 16 herramientas más en local desde la barra de menú.',
      headline: 'Controla 22 cuotas de IA en tu barra de menú de macOS.',
      subtitle:
        'Revisa límites de sesión y semanales de Claude Code, Codex, Cursor, GitHub Copilot, Gemini, Windsurf y 16 herramientas más desde la barra de menú. Desactivado por defecto y 100 % local.',
      secondaryCtaLabel: 'Leer también: Buscador de puertos y PID',
      secondaryCtaTo: '/guides/port-pid-finder/',
      cardsTitle: 'Tres flujos de desarrollo en una app de barra de menú',
      cards: [
        {
          label: 'VIBE CODING E IA',
          title: '22 cuotas de suscripción IA',
          description: 'Descubre qué agente tiene margen antes de empezar una tarea grande.',
          items: [
            'Claude Code · Codex · Cursor',
            'GitHub Copilot · Gemini · Windsurf',
            'JetBrains AI · Cline · Kimi · +13',
          ],
          footer: 'Opcional · Apagado por defecto · 100 % local',
        },
        {
          label: 'PUERTOS Y PROCESOS',
          title: 'Puertos y procesos bloqueados',
          description: 'Olvida lsof -i :3002 y ve al instante la carpeta que ocupa un puerto.',
          items: [
            'Busca: 3002 · localhost:3002',
            'Muestra: PID · CWD · CPU% · RAM',
            'Acción: cerrar proceso en 1 clic',
          ],
          footer: 'Directamente desde el popover ⌥⌘M',
        },
        {
          label: 'BATERÍA Y TÉRMICA',
          title: 'Carga nocturna y temperatura',
          description: 'Cuida la batería del MacBook sin instalar demonios root.',
          items: [
            'Límite de carga: 80 % (macOS 26.4+)',
            'Sensores SMC: temp. chip · RPM ventilador',
            'Alertas: calor alto y batería baja',
          ],
          footer: 'Se mantiene nativamente al cerrar Monny',
        },
      ],
      stepsTitle: 'Cómo Monny se mantiene rápido y privado',
      steps: [
        {
          step: '01 · INSTALAR',
          title: 'Arrastra a Aplicaciones',
          description:
            'Instala vía Homebrew o DMG en Apple Silicon (macOS 15+). Sin helper root ni cuentas.',
        },
        {
          step: '02 · ACTIVAR',
          title: 'Elige tus herramientas IA',
          description:
            'El seguimiento de IA está apagado por defecto. Activa solo los proveedores donde ya iniciaste sesión en local.',
        },
        {
          step: '03 · BARRA DE MENÚ',
          title: 'Un vistazo con ⌥⌘M',
          description:
            'Ve barras de cuota, cuentas atrás, puertos abiertos y carga por núcleo sin cambiar de ventana.',
        },
        {
          step: '04 · CALMA',
          title: 'Solo alertas útiles',
          description:
            'Recibe avisos por CPU desbocada, presión de memoria, calor o límite de carga sin ruido.',
        },
      ],
      guarantees: [
        {
          title: 'Usa la sesión local de cada herramienta',
          description:
            'Monny lee el estado de cuotas en local vía la CLI/sesión de cada proveedor. Sin proxies de terceros.',
        },
        {
          title: 'Sin demonio helper root',
          description:
            'A diferencia de limitadores heredados, Monny usa la API nativa de macOS 26.4+ como usuario estándar.',
        },
        {
          title: 'Cero analíticas ni cuentas',
          description:
            'Toda la telemetría y el historial de 7 días permanecen en tu Mac. Nada se sube a la nube.',
        },
      ],
    },
    'port-pid-finder': {
      slug: 'port-pid-finder',
      path: '/guides/port-pid-finder/',
      breadcrumbLabel: 'Puertos y procesos',
      metaTitle: 'Encuentra puertos abiertos y mata procesos en macOS sin lsof · Monny',
      metaDescription:
        'Busca puertos localhost activos por número o URL, inspecciona PID y carpeta de trabajo y detén servidores bloqueados en un clic desde la barra de menú.',
      headline: 'Encuentra puertos abiertos y servidores colgados sin lsof.',
      subtitle:
        'Pulsa ⌥⌘M, escribe 3000 o localhost:5432, revisa PID, carpeta de trabajo, CPU y RAM y cierra tareas bloqueadas sin memorizar banderas de terminal.',
      secondaryCtaLabel: 'Leer también: 22 cuotas de IA',
      secondaryCtaTo: '/guides/ai-coding-quotas/',
      cardsTitle: 'Todo lo que necesitas cuando un puerto ya está ocupado',
      cards: [
        {
          label: 'BÚSQUEDA INSTANTÁNEA',
          title: 'Escribe un puerto o URL local',
          description:
            'Deja de recordar lsof -nP -iTCP:3000 -sTCP:LISTEN cada vez que choca un servidor.',
          items: [
            'Por puerto: 3000, 5173, 5432, 8080',
            'Por URL: localhost:3002',
            'Filtra por nombre de proceso o PID',
          ],
          footer: 'Búsqueda inmediata dentro del popover ⌥⌘M',
        },
        {
          label: 'CONTEXTO REAL',
          title: 'Ve qué repositorio ocupa el puerto',
          description:
            'Identifica si el puerto 3000 pertenece a un worktree viejo o a un agente en segundo plano.',
          items: [
            'Ruta del directorio de trabajo (CWD)',
            'Consumo de CPU% y memoria en vivo',
            'Visibilidad de proceso padre y comando',
          ],
          footer: 'Sin confusiones entre varios servidores Node o Go',
        },
        {
          label: 'CIERRE SEGURO',
          title: 'Detén tareas bloqueadas con limpieza',
          description: 'Cierra servidores huérfanos o watchers atascados desde la barra de menú.',
          items: [
            'Cierre en un clic para tareas escuchando',
            'Detecta bucles con CPU alta al instante',
            'Convive bien con Docker y BD locales',
          ],
          footer: 'Sin demonio root · permisos estándar de usuario macOS',
        },
      ],
      stepsTitle: 'De EADDRINUSE a puerto libre en segundos',
      steps: [
        {
          step: '01 · ABRIR',
          title: 'Pulsa ⌥⌘M en cualquier lugar',
          description:
            'Abre el popover de Monny sobre tu editor o terminal sin perder el contexto.',
        },
        {
          step: '02 · BUSCAR',
          title: 'Escribe el número de puerto',
          description:
            'Introduce 3000, 3002 o localhost:8080 para aislar al instante el proceso exacto.',
        },
        {
          step: '03 · REVISAR',
          title: 'Comprueba PID y carpeta',
          description:
            'Verifica nombre del proceso, directorio de trabajo, CPU y memoria antes de detenerlo.',
        },
        {
          step: '04 · LIMPIAR',
          title: 'Detén y reinicia sin fricción',
          description:
            'Cierra la tarea bloqueada con un clic y vuelve directo a tu terminal o agente IA.',
        },
      ],
      guarantees: [
        {
          title: 'Solo lectura hasta que haces clic',
          description:
            'Monny nunca cierra procesos automáticamente. Siempre revisas PID y carpeta primero.',
        },
        {
          title: 'Rendimiento nativo en Swift',
          description:
            'Creado en Swift 6 para Apple Silicon (~5 MB) con impacto mínimo frente a monitores Electron.',
        },
        {
          title: 'Pareja ideal con Hearth',
          description:
            'Usa Monny para telemetría macOS, puertos, batería y cuotas IA, y Hearth para runtimes, Docker, K8s y configs IA.',
        },
      ],
    },
  },
}
