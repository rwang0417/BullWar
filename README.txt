BullWar 战士输出助手（OctoWoW / 1.12 客户端，武器战和狂暴战通用）

不需要 SuperWoW。按一次键最多做一件事（放一个技能，或者切一次姿态），每一下都要你自己按。

【安装】
1. 把 BullWar 文件夹放进 WoW\Interface\AddOns\
2. 完全退出游戏再重新打开（第一次装必须重启，/reload 不行）
3. 角色选择界面左下角 AddOns 里确认 BullWar 已勾选
4. 进游戏输入 /bw，能看到设置说明就装好了

【天赋识别】
自动看你哪棵天赋树点数多：武器多就用武器战逻辑，狂暴多就用狂暴战逻辑。
想手动指定：/bw spec arms 或 /bw spec fury，改回自动：/bw spec auto

【宏】（宏界面新建，拖到技能条，绑键）
单体    /run BW.Main()
AOE     /run BW.AoE()
冲锋    /run BW.Charge()        脱战时切战斗姿态冲锋，战斗中切狂暴姿态拦截
狂暴之怒 /run BW.Do("Berserker Rage","Berserker Stance",1)
爆发    /cast Bloodrage
        /cast Death Wish        （武器战没有 Death Wish，换成 /cast Recklessness 或去掉这行）

【武器战的单体顺序】（主场是战斗姿态）
Battle Shout > Demoralizing Shout（只对精英和稀有怪）> Execute（目标 20% 血以下）
> Overpower（目标躲闪后）> Mortal Strike > Rend（目标身上没有时）
> 去狂暴姿态打一次 Whirlwind 再回来（只在 Mortal Strike 不会马上好、而且切姿态亏不了多少怒气时）
> Slam（点了 Improved Slam 才用）> Heroic Strike（怒气 60 以上）

【武器战的 AOE 顺序】
Battle Shout > Sweeping Strikes > Whirlwind > Demoralizing Shout > Cleave > Mortal Strike

【一定要放在技能条上的】
Heroic Strike 和 Cleave（任何一条、任何一页都行），插件靠它们判断"是否已经排上"。
其他技能不用放，插件直接从技能书施放。

【使用要点】
- 要一下一下按，不能按住不放（1.12 按住只触发一次）
- 屏幕出现橙色 "switching would waste X rage"，表示切姿态会亏怒气所以没切，继续按就行
- 紧急情况按住 Shift 再按，会强制切姿态
- 身边有没惹到的怪时别用 AOE 键，Whirlwind 会把它们拉过来
- 打断（Pummel）、减速（Hamstring）、Master Strike 自己按

【设置命令】
/bw                    查看当前设置
/bw hs 60              Heroic Strike 的怒气阈值
/bw cleave 40          AOE 里 Cleave 的怒气阈值
/bw slack 10           切姿态时允许亏的怒气
/bw op on|off          狂暴战在空档里切去打 Overpower
/bw demo elite|on|off  单体时 Demoralizing Shout：只对精英 / 全部 / 不放
/bw br on|off          战斗中自动 Bloodrage（自己血量 60% 以上才放）
/bw ww on|off          武器战单体时去狂暴姿态打 Whirlwind
/bw slam auto|on|off   武器战 Slam：auto = 点了 Improved Slam 才用
