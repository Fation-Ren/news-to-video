# GSAP 过渡模式库

8种命名过渡模式，每场景间轮换使用，避免重复。格式：`tl.to` 退出当前场景 + `tl.fromTo` 进入下一场景 + `tl.set visibility:hidden` 清理。

## 模式速查

| # | 名称 | 适用场景 | 视觉感受 |
|---|------|---------|---------|
| 1 | slam-zoom | 封面→正文 | 冲击力强，适合开场 |
| 2 | whip-pan | 正文→正文 | 快节奏，方向感 |
| 3 | fade-blur | 正文→强调 | 柔和过渡，适合情绪转折 |
| 4 | slide-left | 列表→详情 | 推进感 |
| 5 | slide-up | 数据→结论 | 上升感 |
| 6 | zoom-blur | 强调→数据 | 聚焦感 |
| 7 | fade-black | 高潮→收束 | 沉淀感 |
| 8 | scale-reveal | 收束→CTA | 仪式感 |

## 模式定义

### 1. slam-zoom
```js
tl.to("#FROM", { scale:1.06, opacity:0, duration:0.4, ease:"power3.in" }, T.TO);
tl.fromTo("#TO", { scale:0.93, opacity:0 }, { scale:1, opacity:1, duration:0.55, ease:"back.out(1.4)" }, T.TO);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.45);
```

### 2. whip-pan
```js
tl.to("#FROM", { x:-80, opacity:0, duration:0.4, ease:"power3.in" }, T.TO);
tl.fromTo("#TO", { x:80, opacity:0 }, { x:0, opacity:1, duration:0.55, ease:"power3.out" }, T.TO);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.45);
```

### 3. fade-blur
```js
tl.to("#FROM", { opacity:0, filter:"blur(8px)", duration:0.5, ease:"power2.in" }, T.TO);
tl.fromTo("#TO", { opacity:0, filter:"blur(8px)" }, { opacity:1, filter:"blur(0px)", duration:0.6, ease:"power2.out" }, T.TO);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.50);
```

### 4. slide-left
```js
tl.to("#FROM", { x:80, opacity:0, duration:0.4, ease:"power3.in" }, T.TO);
tl.fromTo("#TO", { x:-80, opacity:0 }, { x:0, opacity:1, duration:0.55, ease:"power3.out" }, T.TO);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.45);
```

### 5. slide-up
```js
tl.to("#FROM", { y:-60, opacity:0, duration:0.4, ease:"power3.in" }, T.TO);
tl.fromTo("#TO", { y:60, opacity:0 }, { y:0, opacity:1, duration:0.55, ease:"power3.out" }, T.TO);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.45);
```

### 6. zoom-blur
```js
tl.to("#FROM", { scale:1.08, opacity:0, duration:0.4, ease:"power3.in" }, T.TO);
tl.fromTo("#TO", { scale:0.92, opacity:0 }, { scale:1, opacity:1, duration:0.55, ease:"back.out(1.5)" }, T.TO);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.45);
```

### 7. fade-black
```js
tl.to("#FROM", { opacity:0, duration:0.35, ease:"power3.in" }, T.TO);
tl.fromTo("#TO", { opacity:0 }, { opacity:1, duration:0.5, ease:"power2.out" }, T.TO+0.1);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.40);
```

### 8. scale-reveal
```js
tl.to("#FROM", { scale:0.94, opacity:0, duration:0.4, ease:"power3.in" }, T.TO);
tl.fromTo("#TO", { scale:1.06, opacity:0 }, { scale:1, opacity:1, duration:0.55, ease:"back.out(1.4)" }, T.TO);
tl.set("#FROM", { visibility:"hidden" }, T.TO+0.45);
```

## 使用方式

Stage 6 生成 composition 时，按场景顺序分配模式：
```
S1→S2: slam-zoom (冲击开场)
S2→S3: whip-pan (快速推进)
S3→S4: zoom-blur (聚焦方案)
S4→S5: fade-blur (情绪转折)
S5→S6: fade-black (沉淀收束)
```

Agent 只需将 `#FROM`、`#TO`、`T.TO` 替换为实际值，不重写过渡代码。
