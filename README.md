# BullWar

[中文](#中文) | [English](#english)

---

## 中文

OctoWoW / Turtle WoW（1.12 客户端）战士助手，支持狂暴战、武器战和防战。有单体和多目标两种模式，按天赋自动选择循环，并自动切换姿态。

- 不需要 SuperWoW。
- 按一次键只做一件事（放一个技能或切一次姿态），每一下都要你自己按。例外：不占公共冷却的技能（Heroic Strike、Cleave、Shield Block、可选的 Bloodrage）可能和另一个技能在同一下里一起放。
- 切姿态时会算怒气：只有亏得不多时才自动切，否则先把怒气用掉。

### 安装

1. 下载后把文件夹放进 `WoW\Interface\AddOns\`，文件夹名必须是 `BullWar`。从 GitHub 下载的 zip 解压出来叫 `BullWar-main`，要改名。
2. 完全退出游戏再重新打开（第一次装必须重启，`/reload` 不行）。
3. 在角色选择界面左下角的 AddOns 里确认 BullWar 已勾选。
4. 进游戏输入 `/bw`，看到设置信息就说明装好了。

### 天赋识别

插件看哪棵天赋树点数最多，就用对应的逻辑（武器 / 狂暴 / 防护）。也可以手动指定：`/bw spec arms`、`/bw spec fury`、`/bw spec prot`，改回自动用 `/bw spec auto`。

### 宏

在宏界面新建，拖到技能条上并绑键。三种天赋用同一套宏。

| 用途 | 宏内容 |
|---|---|
| 单体 | `/run BW.Main()` |
| 多目标 | `/run BW.AoE()` |
| 冲锋 | `/run BW.Charge()`（脱战时切 Battle Stance 冲锋，战斗中切 Berserker Stance 拦截） |
| 打断 | `/run BW.Pummel()`（Defensive Stance 拿盾时用 Shield Bash，否则用 Pummel） |
| 解恐惧 | `/run BW.Do("Berserker Rage","Berserker Stance",1)` |
| 爆发（狂暴战） | `/cast Bloodrage` 换行 `/cast Death Wish` |
| 爆发（武器战） | `/cast Bloodrage`（Death Wish 是狂暴天赋技能） |

其他需要特定姿态的技能可以套用 `/run BW.Do("技能名","姿态名")`，例如 `/run BW.Do("Thunder Clap","Battle Stance")`。第三个参数写 `1` 表示不管怒气直接切。

### 各天赋的优先级

**狂暴战**（主场 Berserker Stance）
- 单体：Battle Shout > Demoralizing Shout（只对精英和稀有怪）> Execute（目标 20% 血以下）> Bloodthirst > Whirlwind > Overpower（只在空档里切去打）> Heroic Strike（怒气 60 以上）
- 多目标：Battle Shout > Whirlwind > Demoralizing Shout > Overpower（空档）> Cleave > Bloodthirst

**武器战**（主场 Battle Stance，双手武器）
- 单体：Battle Shout > Demoralizing Shout（精英）> Execute > Overpower > Mortal Strike > Rend > 去 Berserker Stance 打一次 Whirlwind 再回来 > Slam（点了 Improved Slam 才用）> Heroic Strike
- 多目标：Battle Shout > Sweeping Strikes > Whirlwind > Demoralizing Shout > Cleave > Mortal Strike
- Master Strike 不自动放，伤害低，价值在控制效果，请自己按。

**防战**（主场 Defensive Stance，拿盾，适合高等级防护天赋，5 人本和团本）
- 单体：Battle Shout > Revenge（格挡、躲闪、招架后）> Shield Slam > Concussion Blow > Demoralizing Shout > Sunder Armor（叠满 5 层后继续当仇恨填充）。怒气 50 以上时同时排上 Heroic Strike。
- 多目标：Battle Shout > Revenge > Thunder Clap > Demoralizing Shout > Shield Slam > Concussion Blow > Sunder Armor。怒气 40 以上时同时排上 Cleave。
- Shield Block：本服务器的 Shield Block 只挡一次攻击，主要价值是必定格挡、触发 Revenge。所以在目标正在打你、Revenge 快转好但还没触发、怒气 30 以上时自动开。
- 战斗中不在 Defensive Stance 时会立刻切回去（怒气多的话先打一个 Shield Slam 再切）。坦克挨打会不断回怒气，等怒气降下来再切可能要等很久。
- 需要自己按的：嘲讽（Taunt、Mocking Blow、Challenging Shout）、切目标抢仇恨、保命（Shield Wall、Last Stand）、Disarm。打断用上面的打断宏，或者直接把 Shield Bash 拖到技能条自己按。

### 必须放在技能条上的技能

Heroic Strike 和 Cleave（任意一条、任意一页都行）。插件靠它们判断"是否已经排上"。其他技能不用放，插件直接从技能书施放。

### 使用要点

- 要一下一下地按，不能按住不放（1.12 按住只触发一次），每秒两三下就够。
- 屏幕上出现橙色的 `switching would waste X rage`，表示切姿态会亏怒气所以暂时没切，继续按就行。
- 紧急情况按住 Shift 再按，会强制切姿态。
- 身边有还没惹到的怪时别用多目标键，Whirlwind、Cleave、Thunder Clap 会把它们拉过来。
- 打断（打断宏）、减速（Hamstring）自己按。

### 设置命令

| 命令 | 作用 |
|---|---|
| `/bw` | 查看当前设置 |
| `/bw spec auto\|arms\|fury\|prot` | 天赋逻辑：自动识别或手动指定 |
| `/bw hs 60` | 输出天赋 Heroic Strike 的怒气阈值 |
| `/bw cleave 40` | 多目标 Cleave 的怒气阈值 |
| `/bw slack 10` | 切姿态时允许亏的怒气 |
| `/bw op on\|off` | 狂暴战在空档里切去打 Overpower |
| `/bw demo elite\|on\|off` | 输出天赋单体时的 Demoralizing Shout：只对精英 / 全部 / 不放 |
| `/bw br on\|off` | 战斗中自动 Bloodrage（自己血量 60% 以上才放） |
| `/bw ww on\|off` | 武器战单体时去 Berserker Stance 打 Whirlwind |
| `/bw slam auto\|on\|off` | 武器战 Slam，auto = 点了 Improved Slam 才用 |
| `/bw ths 50` | 防战 Heroic Strike 的怒气阈值 |
| `/bw sb on\|off` | 防战自动 Shield Block |

---

## English

Stance-aware warrior helper for OctoWoW / Turtle WoW (1.12 client), supporting Fury, Arms and Protection. Single-target and multi-target modes, picks the rotation from your talents and switches stances automatically.

- No SuperWoW needed.
- Each key press does one thing (one ability or one stance change), and every action needs your key press. Exception: abilities off the global cooldown (Heroic Strike, Cleave, Shield Block, optional Bloodrage) may go out in the same press as another ability.
- Stance changes are rage-aware: the addon switches automatically only when little rage is lost, otherwise it spends rage first.

### Installation

1. Put the folder in `WoW\Interface\AddOns\`. The folder must be named `BullWar`. A zip downloaded from GitHub extracts as `BullWar-main`, so rename it.
2. Fully exit and restart the game (required the first time, `/reload` is not enough).
3. On the character selection screen, open AddOns (bottom left) and make sure BullWar is enabled.
4. In game, type `/bw`. If the settings are printed, it is installed.

### Talent detection

The addon uses the logic of the talent tree with the most points (Arms / Fury / Protection). To override: `/bw spec arms`, `/bw spec fury`, `/bw spec prot`. Back to automatic: `/bw spec auto`.

### Macros

Create them in the macro window, drag them to an action bar and bind keys. All three specs use the same macros.

| Purpose | Macro |
|---|---|
| Single target | `/run BW.Main()` |
| Multi-target | `/run BW.AoE()` |
| Charge | `/run BW.Charge()` (out of combat: Battle Stance and Charge; in combat: Berserker Stance and Intercept) |
| Interrupt | `/run BW.Pummel()` (Shield Bash in Defensive Stance with a shield, otherwise Pummel) |
| Fear break | `/run BW.Do("Berserker Rage","Berserker Stance",1)` |
| Burst (Fury) | `/cast Bloodrage`, new line, `/cast Death Wish` |
| Burst (Arms) | `/cast Bloodrage` (Death Wish is a Fury talent) |

Any other stance-bound ability works with `/run BW.Do("Spell Name","Stance Name")`, for example `/run BW.Do("Thunder Clap","Battle Stance")`. A third argument of `1` switches regardless of rage.

### Priorities by spec

**Fury** (home: Berserker Stance)
- Single target: Battle Shout > Demoralizing Shout (elites and rares only) > Execute (target below 20%) > Bloodthirst > Whirlwind > Overpower (only in gaps) > Heroic Strike (60+ rage)
- Multi-target: Battle Shout > Whirlwind > Demoralizing Shout > Overpower (gaps) > Cleave > Bloodthirst

**Arms** (home: Battle Stance, two-handed weapon)
- Single target: Battle Shout > Demoralizing Shout (elites) > Execute > Overpower > Mortal Strike > Rend > one Whirlwind in Berserker Stance, then back > Slam (only with Improved Slam) > Heroic Strike
- Multi-target: Battle Shout > Sweeping Strikes > Whirlwind > Demoralizing Shout > Cleave > Mortal Strike
- Master Strike is not automated: low damage, its value is the control effect, so press it yourself.

**Protection** (home: Defensive Stance, shield, for high-level Protection builds in 5-player dungeons and raids)
- Single target: Battle Shout > Revenge (after a block, dodge or parry) > Shield Slam > Concussion Blow > Demoralizing Shout > Sunder Armor (keeps going after 5 stacks as the threat filler). Heroic Strike is queued at 50+ rage.
- Multi-target: Battle Shout > Revenge > Thunder Clap > Demoralizing Shout > Shield Slam > Concussion Blow > Sunder Armor. Cleave is queued at 40+ rage.
- Shield Block: on this server it blocks only one attack, so its main value is a guaranteed block that opens Revenge. It is used while the target is hitting you, Revenge is almost off cooldown but not yet open, and you have 30+ rage.
- In combat outside Defensive Stance, it switches back right away (with surplus rage, one Shield Slam first). Taking hits keeps refilling rage, so waiting for rage to drop could take a long time.
- Press these yourself: taunts (Taunt, Mocking Blow, Challenging Shout), target switching to hold threat, survival cooldowns (Shield Wall, Last Stand), Disarm. For interrupts use the interrupt macro above, or put Shield Bash on a bar.

### Abilities that must be on an action bar

Heroic Strike and Cleave (any bar, any page). The addon uses them to tell whether they are already queued. Everything else is cast straight from the spellbook.

### Tips

- Press repeatedly, do not hold the key (1.12 fires only once while held). Two or three presses per second is enough.
- An orange `switching would waste X rage` means a stance change would lose rage, so it waits. Keep pressing.
- Hold Shift while pressing to force a stance change in an emergency.
- Do not use the multi-target key near mobs you have not pulled yet; Whirlwind, Cleave and Thunder Clap will pull them.
- Interrupts (interrupt macro) and slows (Hamstring) are manual.

### Settings

| Command | Effect |
|---|---|
| `/bw` | Show current settings |
| `/bw spec auto\|arms\|fury\|prot` | Talent logic: automatic or fixed |
| `/bw hs 60` | Heroic Strike rage threshold (Fury / Arms) |
| `/bw cleave 40` | Cleave rage threshold (multi-target) |
| `/bw slack 10` | Rage you accept losing on a stance change |
| `/bw op on\|off` | Fury: switch to Battle Stance for Overpower in gaps |
| `/bw demo elite\|on\|off` | Fury / Arms single target Demoralizing Shout: elites only / always / never |
| `/bw br on\|off` | Automatic Bloodrage in combat (only above 60% health) |
| `/bw ww on\|off` | Arms single target: Whirlwind trips to Berserker Stance |
| `/bw slam auto\|on\|off` | Arms Slam, auto = only with Improved Slam |
| `/bw ths 50` | Protection Heroic Strike rage threshold |
| `/bw sb on\|off` | Protection automatic Shield Block |
