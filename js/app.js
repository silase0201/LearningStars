"use strict";

const questions = [
  {
    id: "q01", title: "第 1 關：登上學習飛船", icon: "🚀",
    lead: "如果是你的孩子，", highlight: "他最可能先做什麼？",
    options: [
      ["A", "看說明／任務", "我要先知道怎麼完成。", "#1769ba"],
      ["B", "研究機關", "這到底是怎麼運作的？", "#ee8500"],
      ["C", "直接動手", "不管，先玩玩看！", "#15863b"],
      ["D", "自己想一個玩法", "我可以這樣玩嗎？", "#6339a7"]
    ]
  },
  {
    id: "q02", title: "第 2 關：神秘星球", icon: "🔍",
    lead: "如果是你的孩子，", highlight: "他最可能會……",
    options: [
      ["A", "尋找線索", "一定有方法可以找到答案。", "#1769ba"],
      ["B", "研究原因", "為什麼會這樣？", "#16833e"],
      ["C", "自己試試看", "我先做做看！", "#f07800"],
      ["D", "想像其他可能", "會不會其實是另外一種答案？", "#6339a7"]
    ]
  },
  {
    id: "q03", title: "第 3 關：遇到學習風暴", icon: "🌪️",
    lead: "如果是你的孩子，", highlight: "他最可能會……",
    options: [
      ["A", "換一條路試試", "這條走不通，我換一條！", "#1769ba"],
      ["B", "找找哪裡出了問題", "到底是哪裡不對？", "#16833e"],
      ["C", "想辦法繼續完成", "我還是想把它完成！", "#f07800"],
      ["D", "先停一下想想", "我等一下再試一次。", "#6339a7"]
    ]
  },
  {
    id: "q04", title: "第 4 關：四顆神秘星球", icon: "🪐",
    lead: "如果可以選一顆星球探索，", highlight: "你覺得孩子最想去哪裡？",
    options: [
      ["A", "火山星球", "完成一個挑戰！", "#bd2026"],
      ["B", "發現星球", "裡面藏著什麼？", "#16833e"],
      ["C", "冒險星球", "我想去看看會遇到什麼！", "#1769ba"],
      ["D", "創造星球", "做出一個屬於自己的東西！", "#6339a7"]
    ]
  },
  {
    id: "q05", title: "第 5 關：星際圖書館", icon: "📖",
    lead: "如果讓孩子自己選一本，", highlight: "他最可能拿哪一本？",
    options: [
      ["A", "挑戰任務書", "看看我能不能完成！", "#ae1d23"],
      ["B", "神秘探索書", "這裡面到底藏了什麼？", "#16833e"],
      ["C", "實驗冒險書", "我想試試看會發生什麼！", "#e56d00"],
      ["D", "創意故事書", "我要自己創造一個故事！", "#6339a7"]
    ]
  },
  {
    id: "q06", title: "第 6 關：找到孩子的學習星", icon: "⭐",
    lead: "如果只能帶一種星際能力回家，", highlight: "你覺得孩子最想要哪一種？",
    options: [
      ["A", "完成任務的能力", "不管什麼任務，我都想辦法完成！", "#ae1d23"],
      ["B", "解開謎題的能力", "我想知道問題的答案！", "#16833e"],
      ["C", "越挫越勇的能力", "不怕失敗，我想變得更厲害！", "#df6b00"],
      ["D", "創造新方法的能力", "我想試試不一樣的方法！", "#6339a7"]
    ]
  }
];

const state = { current: 0, answers: Array(questions.length).fill(null) };
const quiz = document.querySelector("#quiz");
const pageTitle = document.querySelector("#pageTitle");
const sceneWebp = document.querySelector("#sceneWebp");
const sceneImage = document.querySelector("#sceneImage");
const promptIcon = document.querySelector("#promptIcon");
const promptLead = document.querySelector("#promptLead");
const promptHighlight = document.querySelector("#promptHighlight");
const choices = [...document.querySelectorAll(".choice")];
const progressButtons = [...document.querySelectorAll("#progress button")];
const progressCount = document.querySelector("#progressCount");
const backButton = document.querySelector("#backButton");
const nextButton = document.querySelector("#nextButton");
const nextText = document.querySelector("#nextText");
const status = document.querySelector("#status");
const completion = document.querySelector("#completion");
const answerSummary = document.querySelector("#answerSummary");
const reviewButton = document.querySelector("#reviewButton");
const restartButton = document.querySelector("#restartButton");
let statusTimer;

const asset = (questionId, name, extension) => `assets/questions/${questionId}/${name}.${extension}`;

function preload(index) {
  if (index < 0 || index >= questions.length) return;
  const { id } = questions[index];
  ["scene", "option-a-art", "option-b-art", "option-c-art", "option-d-art"].forEach((name) => {
    const image = new Image();
    image.src = asset(id, name, "webp");
  });
}

function render({ announce = true } = {}) {
  const question = questions[state.current];
  const selected = state.answers[state.current];
  pageTitle.textContent = question.title;
  sceneWebp.srcset = asset(question.id, "scene", "webp");
  sceneImage.src = asset(question.id, "scene", "png");
  sceneImage.alt = question.title;
  promptIcon.textContent = question.icon;
  promptLead.textContent = question.lead;
  promptHighlight.textContent = question.highlight;
  progressCount.textContent = `${state.current + 1}/${questions.length}`;
  nextText.textContent = state.current === questions.length - 1 ? "完成" : "選好了";

  choices.forEach((button, index) => {
    const [letter, title, description, color] = question.options[index];
    const source = button.querySelector("source");
    const image = button.querySelector("img");
    button.dataset.option = letter;
    button.style.setProperty("--choice-color", color);
    button.querySelector(".choice-letter").textContent = letter;
    button.querySelector(".choice-title").textContent = title;
    button.querySelector(".choice-description").textContent = `「${description}」`;
    source.srcset = asset(question.id, `option-${letter.toLowerCase()}-art`, "webp");
    image.src = asset(question.id, `option-${letter.toLowerCase()}-art`, "png");
    image.alt = "";
    button.setAttribute("aria-label", `選項 ${letter}：${title}。${description}`);
    button.setAttribute("aria-checked", String(selected === letter));
    button.tabIndex = selected === letter || (!selected && index === 0) ? 0 : -1;
  });

  progressButtons.forEach((button, index) => {
    if (index === state.current) button.setAttribute("aria-current", "step");
    else button.removeAttribute("aria-current");
    button.classList.toggle("is-answered", Boolean(state.answers[index]));
    const answer = state.answers[index] ? `，已選 ${state.answers[index]}` : "，尚未作答";
    button.setAttribute("aria-label", `前往第 ${index + 1} 題${answer}`);
  });
  backButton.setAttribute("aria-label", state.current === 0 ? "已經是第一題" : "上一題");
  nextButton.setAttribute("aria-label", state.current === questions.length - 1 ? "完成測驗" : "選好了，前往下一題");
  nextButton.classList.remove("needs-answer");
  preload(state.current + 1);
  if (announce) showStatus(`${question.title}，${selected ? `目前選擇 ${selected}` : "尚未選擇答案"}`);
}

function showStatus(message) {
  clearTimeout(statusTimer);
  status.textContent = message;
  status.classList.add("is-visible");
  statusTimer = setTimeout(() => status.classList.remove("is-visible"), 1800);
}

function goTo(index) {
  if (index < 0 || index >= questions.length || index === state.current) return;
  quiz.classList.add("is-changing");
  setTimeout(() => {
    state.current = index;
    render();
    requestAnimationFrame(() => quiz.classList.remove("is-changing"));
    scrollTo({ top: 0, behavior: "smooth" });
  }, 160);
}

function select(letter, focus = false) {
  state.answers[state.current] = letter;
  choices.forEach((button) => {
    const active = button.dataset.option === letter;
    button.setAttribute("aria-checked", String(active));
    button.tabIndex = active ? 0 : -1;
    if (active && focus) button.focus();
  });
  progressButtons[state.current].classList.add("is-answered");
  nextButton.classList.remove("needs-answer");
  const option = questions[state.current].options.find(([item]) => item === letter);
  showStatus(`已選擇 ${letter}：${option[1]}`);
}

function finish() {
  answerSummary.replaceChildren(...state.answers.map((answer, index) => {
    const item = document.createElement("span");
    item.textContent = answer;
    item.title = `第 ${index + 1} 題：${answer}`;
    return item;
  }));
  completion.hidden = false;
  reviewButton.focus();
}

choices.forEach((button, index) => {
  button.addEventListener("click", () => select(button.dataset.option));
  button.addEventListener("keydown", (event) => {
    if (!["ArrowRight", "ArrowDown", "ArrowLeft", "ArrowUp"].includes(event.key)) return;
    event.preventDefault();
    const direction = event.key === "ArrowRight" || event.key === "ArrowDown" ? 1 : -1;
    const nextIndex = (index + direction + choices.length) % choices.length;
    select(choices[nextIndex].dataset.option, true);
  });
});
progressButtons.forEach((button) => button.addEventListener("click", () => goTo(Number(button.dataset.question))));
backButton.addEventListener("click", () => state.current === 0 ? showStatus("目前已經是第一題") : goTo(state.current - 1));
nextButton.addEventListener("click", () => {
  if (!state.answers[state.current]) {
    nextButton.classList.remove("needs-answer");
    void nextButton.offsetWidth;
    nextButton.classList.add("needs-answer");
    showStatus("請先選擇一個選項");
    return;
  }
  if (state.current < questions.length - 1) return goTo(state.current + 1);
  const missing = state.answers.findIndex((answer) => !answer);
  if (missing !== -1) {
    showStatus(`第 ${missing + 1} 題尚未作答，將為你跳回該題`);
    setTimeout(() => goTo(missing), 650);
  } else finish();
});
reviewButton.addEventListener("click", () => { completion.hidden = true; state.current = 0; render(); });
restartButton.addEventListener("click", () => { state.answers.fill(null); completion.hidden = true; state.current = 0; render(); });
render({ announce: false });
