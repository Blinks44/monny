import type { LocaleSeoContent } from './types'

export const zhHansSeoContent: LocaleSeoContent = {
  alternatives: {
    'istat-menus': {
      slug: 'istat-menus',
      path: '/alternatives/istat-menus/',
      breadcrumbLabel: 'iStat Menus',
      metaTitle: '免费的 Apple Silicon iStat Menus 替代方案（Swift 6）· Monny',
      metaDescription:
        '在 Apple Silicon 上对比 Monny 与 iStat Menus：免费 MIT 原生 Swift 6 监视器，内置 7 天历史图表、macOS 26.4+ 免 root 充电上限、端口/PID 搜索及 22 款 AI 额度监控。',
      headline: '专为 Apple Silicon 打造的免费开源 iStat Menus 替代方案。',
      subtitle:
        '在一款免费 MIT 开源的 SwiftUI 原生应用中，全面监控 CPU P/E 核心、内存、磁盘、网络、Apple Silicon SMC 传感器、本地端口、原生电池充电上限与 22 款 AI 编程额度。',
      highlights: [
        {
          value: 'Swift 6 · MIT 免费',
          label: 'Apple Silicon 原生 · 无付费许可，无遥测上报',
        },
        {
          value: '零 root 守护进程',
          label: 'macOS 26.4+ 原生充电上限由系统直接维持',
        },
        {
          value: '22 款 AI 额度 + 端口',
          label: '内置端口/PID 搜索与按需开启的本地 AI 额度',
        },
      ],
      competitorColumn: 'ISTAT MENUS',
      rows: [
        {
          criterion: '许可与价格',
          monny: '100% 免费，GitHub 上采用 MIT 开源协议',
          other: '付费应用或 Setapp 订阅',
        },
        {
          criterion: '电池充电上限',
          monny: '原生 macOS 26.4+ 80-100% 充电上限，无需 root 守护进程',
          other: '仅显示电池统计（无充电限制）',
        },
        {
          criterion: '端口与 PID 查找',
          monny: '按端口（localhost:3002）检索，查看工作目录并一键结束',
          other: '仅基础进程列表（不支持按端口搜索）',
        },
        {
          criterion: 'AI 编程额度',
          monny: '可选的本地额度条与重置倒计时，支持 22 款 AI 工具',
          other: '未内置',
        },
        {
          criterion: '7 天历史图表',
          monny: '完整 Swift Charts 面板（1 分钟-7 天），保留休眠断点',
          other: '菜单栏下拉中的紧凑折线图',
        },
        {
          criterion: '隐私与遥测',
          monny: '零统计分析、无需账号，所有读数仅留存在本地 Mac',
          other: '付费许可激活与可选更新检查',
        },
      ],
      chooseMonny: {
        label: '推荐用于 APPLE SILICON',
        title: '选择 Monny 的场景…',
        points: [
          '想要一款免费开源、带 7 天历史图表的 Apple Silicon 原生监视器',
          '同时需要免 root 充电上限、端口搜索与 22 款 AI 额度监控',
          '不想安装后台特权守护进程、注册账号或付费订阅',
        ],
      },
      stickWithOther: {
        label: '仍适合 ISTAT MENUS 的场景',
        title: '继续使用 iStat Menus 的场景…',
        points: [
          '需要支持 Intel Mac 或旧版 macOS（< 15）',
          '需要手动风扇转速曲线覆盖或天气小组件',
          '需要高度细粒度的菜单栏自定义图表主题',
        ],
      },
      steps: [
        {
          step: '步骤 01',
          title: '通过 Homebrew 或 DMG 安装',
          description:
            '运行 brew install --cask blinks44/tap/monny。无需管理员密码、系统扩展或登录账号。',
        },
        {
          step: '步骤 02',
          title: '在菜单栏固定精简指标',
          description: '按需选择 CPU、内存、网络或电池项，随时按 ⌥⌘M 呼出完整面板。',
        },
        {
          step: '步骤 03',
          title: '可选：开启 AI 额度与电池上限',
          description: '仅勾选你在用的 AI 工具，并在 macOS 26.4+ 上免 root 设定 80% 原生充电上限。',
        },
      ],
    },
    aldente: {
      slug: 'aldente',
      path: '/alternatives/aldente/',
      breadcrumbLabel: 'AlDente',
      metaTitle: '免费的免 root AlDente 替代方案（macOS 26.4+）· Monny',
      metaDescription:
        '对比 Monny 与 AlDente：在 macOS 26.4+ 上以普通用户身份启用原生 80-100% 充电上限，无需 root 守护进程，同时自带系统监控与 22 款 AI 额度。',
      headline: '一款零 root 守护进程的免费 AlDente 替代方案。',
      subtitle:
        '在 macOS 26.4+ 上以普通用户权限调用 Apple 原生充电上限，将 MacBook 电量限制在 80-100%。即使退出 Monny，系统也会继续维持该上限。',
      highlights: [
        {
          value: '零 root 守护进程',
          label: '无需特权 LaunchDaemon、内核扩展或直接写 SMC',
        },
        {
          value: '退出后持续生效',
          label: 'macOS 26.4+ 原生保持你的 80-100% 充电上限',
        },
        {
          value: '全能 Mac 监视器',
          label: '内置 CPU、SMC 温度、端口搜索与 22 款 AI 额度',
        },
      ],
      competitorColumn: 'ALDENTE / BATFI',
      rows: [
        {
          criterion: 'root 权限',
          monny: '仅需普通用户权限 - 零特权 root 守护进程',
          other: '需要特权 root 辅助进程直接写入 SMC 键值',
        },
        {
          criterion: '关闭应用后生效',
          monny: '支持 - macOS 26.4+ 在退出和重启后继续原生维持上限',
          other: '依赖后台辅助进程持续运行',
        },
        {
          criterion: '价格与许可',
          monny: '100% 免费，MIT 开源（无 Pro 付费墙）',
          other: '基础免费，高级模式需购买 Pro 许可或订阅',
        },
        {
          criterion: '电池遥测',
          monny: '健康度、循环次数、实时瓦数、电池温度与充电提醒',
          other: '充电控制及付费高温保护、校准功能',
        },
        {
          criterion: '额外开发工具',
          monny: '菜单栏监控、7 天图表、端口/PID 查找与 22 款 AI 额度',
          other: '单一电池工具',
        },
        {
          criterion: 'macOS 版本范围',
          monny: 'macOS 26.4+ 支持原生上限；macOS 15-26.3 提供只读电池监控',
          other: '通过特权 SMC 辅助进程兼容更旧版本 macOS',
        },
      ],
      chooseMonny: {
        label: '推荐用于 MACOS 26.4+',
        title: '选择 Monny 的场景…',
        points: [
          '使用 Apple Silicon + macOS 26.4+，想要免 root 的 80-100% 充电上限',
          '希望退出应用和重启后充电上限依然由系统维持',
          '想在一个应用里同时搞定电池、系统监控、端口和 AI 额度',
        ],
      },
      stickWithOther: {
        label: '仍适合 ALDENTE 的场景',
        title: '继续使用 AlDente 的场景…',
        points: [
          '目前仍在 macOS 15 至 26.3，且现在就需要主动限制充电',
          '需要航行模式、主动放电或电池校准等专用模式',
          '使用的是不支持 macOS 26.4+ 原生 API 的 Intel MacBook',
        ],
      },
      steps: [
        {
          step: '步骤 01',
          title: '清爽安装 Monny',
          description:
            '运行 brew install --cask blinks44/tap/monny 或拖入“应用程序”。全程无需管理员授权。',
        },
        {
          step: '步骤 02',
          title: '设定 80-100% 上限',
          description:
            '在 macOS 26.4+ 上打开 Monny 电池设置，通过系统原生 API 选定 80%（或最高 100%）。',
        },
        {
          step: '步骤 03',
          title: '卸载多余的 root 辅助进程',
          description:
            '待 macOS 原生接管上限后，即可卸载独立的电池守护进程，菜单栏只保留约 5 MB 的 Monny。',
        },
      ],
    },
  },
  guides: {
    'ai-coding-quotas': {
      slug: 'ai-coding-quotas',
      path: '/guides/ai-coding-quotas/',
      breadcrumbLabel: '22 款 AI 额度',
      metaTitle: '在 macOS 菜单栏本地监控 22 款 AI 编程额度 · Monny',
      metaDescription:
        '在 macOS 菜单栏本地实时查看 Claude Code、Codex、Cursor、GitHub Copilot、Gemini、Windsurf 等 22 款 AI 工具的会话与每周剩余额度。',
      headline: '在 macOS 菜单栏实时追踪 22 款 AI 编程额度。',
      subtitle:
        '在菜单栏直接查看 Claude Code、Codex、Cursor、GitHub Copilot、Gemini、Windsurf 及另外 16 款工具的会话与周额度。默认关闭，100% 本地读取。',
      secondaryCtaLabel: '延伸阅读：端口与 PID 查找',
      secondaryCtaTo: '/guides/port-pid-finder/',
      cardsTitle: '一款菜单栏应用，覆盖三大开发者场景',
      cards: [
        {
          label: 'VIBE CODING 与 AI',
          title: '22 款 AI 订阅额度',
          description: '在开始大任务前，一眼确认哪个编程代理还有充足余量。',
          items: [
            'Claude Code · Codex · Cursor',
            'GitHub Copilot · Gemini · Windsurf',
            'JetBrains AI · Cline · Kimi · +13',
          ],
          footer: '按需开启 · 默认关闭 · 100% 本地',
        },
        {
          label: '端口与进程',
          title: '监听端口与失控进程',
          description: '告别 lsof -i :3002，直接定位占用端口的项目目录。',
          items: [
            '搜索：3002 · localhost:3002',
            '展示：PID · CWD · CPU% · 内存',
            '操作：一键结束异常任务',
          ],
          footer: '在 ⌥⌘M 弹窗内直接使用',
        },
        {
          label: '电池与散热',
          title: '整夜充电与温度监控',
          description: '无需安装 root 守护进程，也能保护 MacBook 电池健康。',
          items: [
            '充电上限：80%（macOS 26.4+）',
            'SMC 传感器：芯片温度 · 风扇转速',
            '提醒：高温与低电量通知',
          ],
          footer: '退出 Monny 后仍由系统原生维持',
        },
      ],
      stepsTitle: 'Monny 如何兼顾速度与隐私',
      steps: [
        {
          step: '01 · 安装',
          title: '放入应用程序文件夹',
          description:
            '在 Apple Silicon（macOS 15+）上通过 Homebrew 或 DMG 安装，无需 root 或账号。',
        },
        {
          step: '02 · 按需开启',
          title: '勾选你使用的 AI 工具',
          description: 'AI 额度监测默认关闭，仅启用你已在本地登录的提供商。',
        },
        {
          step: '03 · 菜单栏',
          title: '按 ⌥⌘M 一眼查看',
          description: '无需切换窗口，即可看到实时额度条、重置倒计时、监听端口和核心负载。',
        },
        {
          step: '04 · 保持安静',
          title: '仅在必要时提醒',
          description: '只在 CPU 失控、内存压力过高、高温或到达充电上限时提醒，绝不打扰。',
        },
      ],
      guarantees: [
        {
          title: '复用各工具自有本地登录态',
          description: 'Monny 通过各提供商自身的 CLI/本地会话读取额度，绝不经过第三方代理服务器。',
        },
        {
          title: '零 root 守护进程',
          description:
            '与旧式电池工具不同，Monny 以普通用户身份调用 macOS 26.4+ 原生充电上限 API。',
        },
        {
          title: '零分析上报、无需账号',
          description: '所有遥测与 7 天历史数据仅保存在本地 Mac，不上传任何数据。',
        },
      ],
    },
    'port-pid-finder': {
      slug: 'port-pid-finder',
      path: '/guides/port-pid-finder/',
      breadcrumbLabel: '端口与进程',
      metaTitle: '无需 lsof 在 macOS 查找监听端口并结束进程 · Monny',
      metaDescription:
        '按端口号或本地 URL 检索监听中的 localhost 端口，查看 PID 与工作目录，并在 macOS 菜单栏一键结束卡死的开发服务器。',
      headline: '无需 lsof，快速定位占用端口与卡死的开发服务。',
      subtitle:
        '按 ⌥⌘M，输入 3000 或 localhost:5432，立即查看进程 PID、工作目录、CPU 和内存占用，一键结束异常任务，不必再背终端参数。',
      secondaryCtaLabel: '延伸阅读：22 款 AI 编程额度',
      secondaryCtaTo: '/guides/ai-coding-quotas/',
      cardsTitle: '端口被占用时所需的一切信息',
      cards: [
        {
          label: '瞬时端口检索',
          title: '输入端口号或本地 URL',
          description: '不再在每次端口冲突时回忆 lsof -nP -iTCP:3000 -sTCP:LISTEN。',
          items: [
            '按端口匹配：3000、5173、5432、8080',
            '按 URL 匹配：localhost:3002',
            '按进程名或 PID 筛选',
          ],
          footer: '在 ⌥⌘M 弹窗内即时搜索',
        },
        {
          label: '清晰上下文',
          title: '看清是哪个仓库占用了端口',
          description: '一眼分辨 3000 端口属于旧的 worktree 还是后台运行中的代理。',
          items: ['完整工作目录（CWD）路径', '实时 CPU% 与内存占用', '父进程与启动命令一目了然'],
          footer: '不再在多个 Node 或 Go 服务间盲猜',
        },
        {
          label: '安全结束任务',
          title: '干净停止失控进程',
          description: '直接从菜单栏停止遗留的开发服务器或卡死的监听进程。',
          items: [
            '一键停止正在监听的任务',
            '快速揪出高 CPU 死循环',
            '与 Docker 和本地数据库顺畅共存',
          ],
          footer: '零 root 守护进程 · 标准 macOS 用户权限',
        },
      ],
      stepsTitle: '几秒内从 EADDRINUSE 恢复干净端口',
      steps: [
        {
          step: '01 · 呼出',
          title: '随时按下 ⌥⌘M',
          description: '在编辑器或终端上方直接呼出 Monny 弹窗，不打断当前工作流。',
        },
        {
          step: '02 · 搜索',
          title: '输入端口号',
          description: '输入 3000、3002 或 localhost:8080，立刻锁定对应的监听进程。',
        },
        {
          step: '03 · 确认',
          title: '核对 PID 与项目目录',
          description: '结束前确认进程名、工作目录、CPU 与内存占用，避免误杀。',
        },
        {
          step: '04 · 清理',
          title: '停止并重新启动',
          description: '一键退出卡死进程，立刻回到终端或 AI 编程代理继续开发。',
        },
      ],
      guarantees: [
        {
          title: '点击退出前完全只读',
          description: 'Monny 绝不会自动结束后台进程，始终先向你展示 PID 和工作目录。',
        },
        {
          title: '原生 Swift 性能',
          description:
            '基于 Swift 6 为 Apple Silicon 构建（约 5 MB），相比 Electron 监视器几乎零闲置开销。',
        },
        {
          title: '与 Hearth 组成完整开发套装',
          description:
            'Monny 负责实时 macOS 遥测、端口、电池与 AI 额度；Hearth 负责运行时、Docker、K8s 与 AI 配置。',
        },
      ],
    },
  },
}
