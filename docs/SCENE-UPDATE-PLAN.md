# 星空背景與場景拆分更新規劃

後續的元件重新繪製規格請見 [`SCENE-REDRAW-PLAN.md`](SCENE-REDRAW-PLAN.md)。

## 更新範圍

- 直接更新根目錄中的正式頁面。
- 不再建立新的版本資料夾。
- 保留現有題目、選項、作答、進度與完成流程。
- 所有 `font-size` 使用 `rem`。

## Body 動態星空背景

### 素材

```text
assets/backgrounds/
├─ stars-twinkle.png
└─ stars-static.png
```

- APNG 使用透明背景，疊加在現有深藍色 CSS 漸層上。
- 建議尺寸為 `512 × 512`。
- 動畫長度約 5–7 秒，共 10–14 個畫格。
- 約 35–50 顆星，其中只有 6–10 顆偶爾原地閃爍。
- 星星不位移，不讓整張背景同時明暗變化。
- APNG 設定為無限循環。
- 目標容量約 100–300 KB。
- `stars-static.png` 作為減少動態模式的備用圖。

### CSS 圖層

```css
body {
  position: relative;
  min-height: 100svh;
  background:
    radial-gradient(circle at 18% 12%, #3a4ab545, transparent 28rem),
    radial-gradient(circle at 84% 84%, #0878b93d, transparent 32rem),
    #020b24;
}

body::before {
  content: "";
  position: fixed;
  z-index: 0;
  inset: 0;
  pointer-events: none;
  background-image: url("../assets/backgrounds/stars-twinkle.png");
  background-repeat: repeat;
  background-position: center top;
  background-size: 32rem 32rem;
}

.app {
  position: relative;
  z-index: 1;
}
```

手機版可以將背景圖塊放大到 `38rem × 38rem`，降低重複排列的視覺感。

## Scene 圖層架構

原本的單張合成圖改成以下圖層：

```text
.scene
├─ .celestial-field       z-index: 10–39
│  ├─ .celestial
│  ├─ .celestial
│  └─ ...
├─ .scene-foreground      z-index: 50
├─ .scene-copy            z-index: 60
└─ .back-button           z-index: 70
```

- 星體永遠位於太空艙、人物、文字及按鈕後方。
- 前景、文字及控制項不可被星體遮擋。
- `.scene` 使用 `isolation: isolate`，避免圖層影響場景外元件。

## 場景素材拆分

每題建立獨立的場景素材：

```text
assets/scenes/q01/
├─ foreground.png
├─ foreground.webp
└─ celestial/
   ├─ planet-purple.png
   ├─ planet-purple.webp
   ├─ planet-blue.png
   ├─ planet-blue.webp
   ├─ moon-small.png
   ├─ moon-small.webp
   └─ asteroid-01.webp
```

### 前景圖

- 去除星空背景。
- 去除關卡標題、故事文字與其他排版文字。
- 保留人物、太空艙、控制台及關鍵故事物件。
- 透明 PNG 作為原始素材。
- 透明 WebP 作為網頁顯示素材。

### 星體

- 星球、月球、銀河、彗星與小行星分別輸出為透明素材。
- 一張圖片只包含一個星體或必須一起出現的星體群。
- 不包含文字、外框或背景色塊。
- 裝飾星體使用空白替代文字：`alt=""`。
- 第六題的四顆學習星屬於故事內容，保留在前景，不加入隨機星體。

## HTML 文字設計

移除圖片中的「孩子的學習星球」。關卡與故事文字改為：

```html
<div class="scene-copy">
  <p class="scene-level">第 1 關</p>
  <h2 class="scene-title">登上學習飛船</h2>
  <p class="scene-description">
    第一次登上太空船，孩子對眼前的一切充滿好奇……
  </p>
</div>
```

六題共用相同的：

- 關卡標籤
- 主標題位置
- 標題裝飾
- 文字背景
- 內距與最大寬度
- 字級與行距
- 手機和桌機斷點

### 字級

```css
.scene-level {
  font-size: 1.5rem;
}

.scene-title {
  font-size: 3rem;
}

.scene-description {
  font-size: 1.125rem;
  line-height: 1.65;
}
```

手機版透過媒體查詢套用較小的 `rem` 字級，不在 `font-size` 使用 `px`、`vw` 或 `em`。

### 防止文字溢出

```css
.scene-copy {
  width: min(90%, 42rem);
  min-width: 0;
  padding: 1rem 1.5rem;
}

.scene-copy p,
.scene-copy h2 {
  max-width: 100%;
  margin-inline: auto;
  overflow-wrap: anywhere;
  text-wrap: balance;
}
```

- 不使用 `text-overflow: ellipsis` 隱藏描述。
- 不使用固定單行高度。
- 文字較長時允許自然換行。
- 場景高度應隨文字內容增加，不能裁切文字。

## 星體資料

```js
{
  id: "q01",
  celestial: [
    { image: "planet-purple.webp", radius: 11 },
    { image: "planet-blue.webp", radius: 9 },
    { image: "moon-small.webp", radius: 5 },
    { image: "asteroid-01.webp", radius: 4 }
  ]
}
```

`radius` 為碰撞檢查使用的相對半徑，不是固定像素尺寸。

## 隨機位置與防碰撞

每次重新載入頁面時：

1. 在場景有效區域隨機產生星體的 `x`、`y`。
2. 排除文字安全區。
3. 排除前景人物及主要故事物件區域。
4. 計算與已放置星體的距離。
5. 距離不足時重新取樣。
6. 每顆星體最多嘗試約 40 次。
7. 無法找到空位時縮小星體或略過該星體。

碰撞條件：

```js
distance >= radiusA + radiusB + safeGap
```

同一次瀏覽期間保存生成結果。使用者跳題後再返回時，星體位置保持不變；重新整理頁面後才重新產生。

## 景深、圖層與尺寸

```js
const depth = randomInteger(10, 39);
const scale = 0.55 + ((depth - 10) / 29) * 0.55;
```

- `z-index` 越小，星體越遠、越小、越暗。
- `z-index` 越大，星體越近、越大、越亮。
- 星體最大 `z-index` 為 39。
- 前景固定使用 `z-index: 50`。
- 文字固定使用 `z-index: 60`。

```html
<span
  class="celestial"
  style="--x:74%; --y:22%; --scale:0.83; --depth:26; --duration:52s;"
>
  <img src="planet-blue.webp" alt="">
</span>
```

## 緩慢漂移動畫

位置與縮放設定在外層，漂移動畫設定在內層圖片，避免 `transform` 互相覆蓋。

```css
.celestial {
  position: absolute;
  left: var(--x);
  top: var(--y);
  z-index: var(--depth);
  transform: translate(-50%, -50%) scale(var(--scale));
}

.celestial img {
  animation: celestial-drift var(--duration) ease-in-out
    var(--delay) infinite alternate;
}

@keyframes celestial-drift {
  from {
    transform: translate3d(-0.8rem, -0.3rem, 0) rotate(-1deg);
  }

  to {
    transform: translate3d(1rem, 0.5rem, 0) rotate(1deg);
  }
}
```

整個星體群另外使用 40–70 秒的緩慢位移及微幅旋轉，模擬太空艙自旋。星體不能快速飛過畫面。

## 減少動態模式

```css
@media (prefers-reduced-motion: reduce) {
  body::before {
    background-image: url("../assets/backgrounds/stars-static.png");
  }

  .celestial-field,
  .celestial img {
    animation: none;
  }
}
```

## 實作順序

1. 產生透明 APNG 星空背景與靜態備用圖。
2. 拆分六題前景，移除星空與文字。
3. 輸出獨立透明星體 PNG/WebP。
4. 將關卡、標題與描述整理至 JavaScript 資料。
5. 建立統一的 `.scene-copy` 元件。
6. 實作星體隨機位置及防碰撞。
7. 實作隨機景深與大小。
8. 加入群組自旋和個別漂移。
9. 加入減少動態模式。
10. 驗證手機、桌機及所有六題。

## 驗收條件

- 原場景圖中的星空及文字不再出現在前景素材。
- 六題關卡標籤、標題及描述使用統一 HTML/CSS 排版。
- 描述文字不溢出、不被裁切、不被星體或前景遮住。
- 所有 `font-size` 使用 `rem`。
- 星體位置每次重新載入會改變。
- 同一次瀏覽返回題目時位置不變。
- 星體之間不明顯重疊或擠在一起。
- 星體大小符合隨機景深。
- 星體永遠位於前景及文字後方。
- 漂移速度緩慢，不影響閱讀與操作。
- 減少動態模式不播放 APNG及星體動畫。

## 不再使用檔案的整理規劃

完成場景拆分後，正式執行用的 `assets` 只保留 HTML、CSS 與 JavaScript 仍會載入的素材。不再使用的原圖、舊切圖、預覽圖及舊產生器不刪除，統一移至 `source-images` 封存。

### 目標目錄

```text
source-images/
├─ originals/                    # 最初提供的 7 張完整設計圖
├─ legacy-assets/
│  ├─ scenes/                    # 被透明前景與獨立星體取代的舊 scene
│  ├─ prompts/                   # 已改為 HTML/CSS 的問題圖
│  └─ option-cards/              # 含文字、ABCD、框線與色帶的舊選項圖
├─ previews/                     # q01-art、q01-overview 等檢查圖
└─ generators/
   └─ slice_assets.py            # 只會產生舊版含文字素材的腳本
```

### 繼續放在正式 assets 的檔案

```text
assets/
├─ backgrounds/
│  ├─ stars-twinkle.png
│  └─ stars-static.png
├─ questions/q01/
│  ├─ option-a-art.png
│  ├─ option-a-art.webp
│  └─ ...
└─ scenes/q01/
   ├─ foreground.png
   ├─ foreground.webp
   └─ celestial/
      └─ ...
```

- `option-*-art.png` 與 `option-*-art.webp` 仍由選項卡使用，不移動。
- 新的透明前景與星體放在 `assets/scenes`。
- 星空 APNG 與靜態圖放在 `assets/backgrounds`。
- PNG 為備用格式，WebP 為主要載入格式，兩者都屬於正式資產。

### 可立即列為舊素材的檔案

目前程式已不再引用以下檔案：

- `assets/questions/q*/option-a.png` 至 `option-d.png`
- `assets/questions/q*/option-a.webp` 至 `option-d.webp`
- `assets/questions/q*/prompt.png`
- `assets/questions/q*/prompt.webp`
- `assets/previews/q*-overview.jpg`
- `assets/previews/q*-art.jpg`
- `scripts/slice_assets.py`

上述檔案在實作整理時移至相對應的 `source-images` 子目錄，不直接刪除。

### 必須延後移動的檔案

```text
assets/questions/q*/scene.png
assets/questions/q*/scene.webp
```

這 12 個檔案目前仍由 `js/app.js` 載入。必須依序完成以下工作後才能移至 `source-images/legacy-assets/scenes`：

1. 產生新的透明 `foreground`。
2. 產生獨立星體素材。
3. 更新 HTML 與 JavaScript 的圖片路徑。
4. 確認六題都能載入新的場景圖層。
5. 確認瀏覽器沒有 404 或圖片載入錯誤。
6. 再移動舊 `scene.png` 與 `scene.webp`。

### 腳本整理

- `scripts/generate_assets.py` 繼續保留，但要更新為新的素材來源路徑。
- 原圖移至 `source-images/originals` 後，腳本也必須改讀取該目錄。
- `scripts/slice_assets.py` 只會產生舊版問題圖與含文字選項，因此移至 `source-images/generators`。
- 新的前景去背與星體拆分若使用腳本處理，正式腳本放在 `scripts`，不可放在 `assets`。

### 文件整理

- 規劃文件不屬於圖片來源，不放進 `source-images`。
- 本文件已集中到 `docs/SCENE-UPDATE-PLAN.md`。
- 不再建立新的版本資料夾。

### 安全整理流程

1. 先搜尋 HTML、CSS、JavaScript 與產生器中的檔案引用。
2. 產生一份「仍被引用」與「未被引用」清單。
3. 先更新程式路徑，再移動檔案。
4. 所有移動操作都使用明確的檔案清單，不使用廣泛萬用字元刪除。
5. 不刪除來源素材，只移至 `source-images`。
6. 重新執行 JavaScript、UTF-8、圖片尺寸及路徑檢查。

### 整理完成驗收

- `assets` 內沒有未被頁面或正式腳本使用的舊素材。
- `source-images` 具有 originals、legacy-assets、previews 及 generators 分類。
- 六題的選項插圖、前景及星體全部正常載入。
- HTML/CSS 問題與選項文字不依賴舊圖片。
- 瀏覽器沒有 404、圖片載入失敗或錯誤路徑。
- `generate_assets.py` 能從新的 `source-images/originals` 路徑重新產生正式素材。

## 2026-08-20 實作紀錄

- 已產生 `512 × 512` 的循環動畫 PNG 星空與靜態備用圖。
- 已拆分六題透明前景，以及 23 組獨立 PNG/WebP 星體素材。
- 場景標題、關卡與描述已改為 HTML 文字，並移除「孩子的學習星球」圖片標題。
- 已實作星體隨機位置、防碰撞、隨機景深、景深縮放與緩慢漂移。
- 同次瀏覽使用快取配置；重新載入頁面才重新產生星體位置。
- 已加入 `prefers-reduced-motion` 靜態背景與停止漂移處理。
- 舊場景、問題圖、含文字選項卡、預覽圖與舊切圖腳本已移至 `source-images` 分類封存。
- `scripts/generate_assets.py` 已改讀取 `source-images/originals`，不再輸出舊合成場景。
- 所有 CSS `font-size` 仍使用 `rem`。
