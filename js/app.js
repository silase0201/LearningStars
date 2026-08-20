"use strict";

const questions = [
  { id:"q01", level:"第 1 關", sceneTitle:"登上學習飛船", icon:"🚀", description:"第一次登上太空船，孩子對眼前的一切充滿好奇。這趟神秘旅程，就要開始了……眼前，一個從沒見過的控制台，旁邊還有四個按鈕……", lead:"如果是你的孩子，", highlight:"他最可能先做什麼？", options:[["A","看說明／任務","我要先知道怎麼完成。","#1769ba"],["B","研究機關","這到底是怎麼運作的？","#ee8500"],["C","直接動手","不管，先玩玩看！","#15863b"],["D","自己想一個玩法","我可以這樣玩嗎？","#6339a7"]] },
  { id:"q02", level:"第 2 關", sceneTitle:"神秘星球", icon:"🔍", description:"飛船緩緩降落在神秘星球。忽然，一個從未見過的神秘盒子出現在眼前，盒子上沒有說明，也打不開……", lead:"如果是你的孩子，", highlight:"他最可能會……", options:[["A","尋找線索","一定有方法可以找到答案。","#1769ba"],["B","研究原因","為什麼會這樣？","#16833e"],["C","自己試試看","我先做做看！","#f07800"],["D","想像其他可能","會不會其實是另外一種答案？","#6339a7"]] },
  { id:"q03", level:"第 3 關", sceneTitle:"遇到學習風暴", icon:"🌪️", description:"飛船飛向下一個星球時，突然遇上星際風暴。轟——！前方的航線被巨大的岩石擋住了，這趟旅程似乎遇到了第一個難題……", lead:"如果是你的孩子，", highlight:"他最可能會……", options:[["A","換一條路試試","這條走不通，我換一條！","#1769ba"],["B","找找哪裡出了問題","到底是哪裡不對？","#16833e"],["C","想辦法繼續完成","我還是想把它完成！","#f07800"],["D","先停一下想想","我等一下再試一次。","#6339a7"]] },
  { id:"q04", level:"第 4 關", sceneTitle:"四顆神秘星球", icon:"🪐", description:"穿越星際風暴後，飛船終於來到一片陌生的星域。眼前同時出現四顆神秘星球，每一顆都傳來不同的訊號……", lead:"如果可以選一顆星球探索，", highlight:"你覺得孩子最想去哪裡？", options:[["A","火山星球","完成一個挑戰！","#bd2026"],["B","發現星球","裡面藏著什麼？","#16833e"],["C","冒險星球","我想去看看會遇到什麼！","#1769ba"],["D","創造星球","做出一個屬於自己的東西！","#6339a7"]] },
  { id:"q05", level:"第 5 關", sceneTitle:"星際圖書館", icon:"📖", description:"穿過四顆神秘星球後，飛船來到宇宙深處。一座漂浮在星海中的星際圖書館，緩緩出現在孩子眼前，四本不同的書，同時亮了起來。", lead:"如果讓孩子自己選一本，", highlight:"他最可能拿哪一本？", options:[["A","挑戰任務書","看看我能不能完成！","#ae1d23"],["B","神秘探索書","這裡面到底藏了什麼？","#16833e"],["C","實驗冒險書","我想試試看會發生什麼！","#e56d00"],["D","創意故事書","我要自己創造一個故事！","#6339a7"]] },
  { id:"q06", level:"第 6 關", sceneTitle:"找到孩子的學習星", icon:"⭐", description:"穿越一站又一站的星際旅程後，飛船終於來到最後一站。星際地圖緩緩展開，四顆閃耀的學習星，正在前方等待著孩子……", lead:"如果只能帶一種星際能力回家，", highlight:"你覺得孩子最想要哪一種？", options:[["A","完成任務的能力","不管什麼任務，我都想辦法完成！","#ae1d23"],["B","解開謎題的能力","我想知道問題的答案！","#16833e"],["C","越挫越勇的能力","不怕失敗，我想變得更厲害！","#df6b00"],["D","創造新方法的能力","我想試試不一樣的方法！","#6339a7"]] }
];
const sceneMidgrounds={
  q01:[
    ["components/celestial-planet-purple",15,25,17,54,-17,.7,.35,1],
    ["midground-rocket",27,39,7.5,38,-9,1,-.55,1.5],
    ["components/celestial-planet-blue-moon",86,24,15,61,-28,-.8,.45,-1]
  ],
  q02:[
    ["components/celestial-planet-blue",15,33,16,57,-21,.65,.4,1],
    ["components/celestial-galaxy-moon",85,31,25,63,-33,-.7,.5,-1]
  ],
  q03:[
    ["components/celestial-storm-vortex",14,43,22,50,-18,.65,.45,1],
    ["components/celestial-asteroid-group",87,43,19,44,-11,-.75,.55,-1],
    ["components/story-main-asteroid",76,64,24,48,-26,-.5,.35,-.7]
  ],
  q04:[
    ["components/story-planet-volcano",34,68,17,44,-6,.35,.28,-.6],
    ["components/story-planet-discovery",51,68,17,47,-15,-.3,.3,.5],
    ["components/story-planet-adventure",68,68,17,45,-23,.32,.25,-.5],
    ["components/story-planet-create",85,68,17,48,-31,-.28,.32,.6]
  ],
  q05:[
    ["components/environment-library",80,48,34,58,-24,-.45,.3,-.5]
  ],
  q06:[
    ["components/story-star-task",34,68,15,43,-5,.3,.28,-.5],
    ["components/story-star-puzzle",51,68,15,46,-13,-.28,.3,.5],
    ["components/story-star-growth",68,68,15,44,-21,.3,.25,-.5],
    ["components/story-star-creative",85,68,15,47,-29,-.26,.32,.5]
  ]
};
const foregroundHeights={q01:573,q02:737,q03:434,q04:775,q05:652,q06:639};
const state={current:0,answers:Array(questions.length).fill(null)};
const quiz=document.querySelector("#quiz"),pageTitle=document.querySelector("#pageTitle"),sceneMidground=document.querySelector("#sceneMidground"),sceneForeground=document.querySelector("#sceneForeground"),sceneLevel=document.querySelector("#sceneLevel"),sceneTitle=document.querySelector("#sceneTitle"),sceneDescription=document.querySelector("#sceneDescription"),prompt=document.querySelector("#prompt"),promptIcon=document.querySelector("#promptIcon"),promptLead=document.querySelector("#promptLead"),promptHighlight=document.querySelector("#promptHighlight"),choices=[...document.querySelectorAll(".choice")],progressButtons=[...document.querySelectorAll("#progress button")],progressCount=document.querySelector("#progressCount"),backButton=document.querySelector("#backButton"),nextButton=document.querySelector("#nextButton"),nextText=document.querySelector("#nextText"),status=document.querySelector("#status"),completion=document.querySelector("#completion"),answerSummary=document.querySelector("#answerSummary"),reviewButton=document.querySelector("#reviewButton"),restartButton=document.querySelector("#restartButton");
let statusTimer;
const questionAsset=(id,name,ext)=>`assets/questions/${id}/${name}.${ext}`;
const sceneAsset=(id,name,ext)=>`assets/scenes/${id}/${name}.${ext}`;
function renderSceneForeground(question){
  sceneMidground.replaceChildren(...sceneMidgrounds[question.id].map(([name,x,y,width,duration,delay,driftX,driftY,rotate])=>{
    const picture=document.createElement("picture"),source=document.createElement("source"),image=document.createElement("img");
    picture.className="scene-midground-item";
    picture.style.cssText=`left:${x}%;top:${y}%;width:${width}%;--drift-duration:${duration}s;--drift-delay:${delay}s;--drift-x:${driftX}rem;--drift-y:${driftY}rem;--drift-rotate:${rotate}deg`;
    source.type="image/webp";source.srcset=sceneAsset(question.id,name,"webp");
    image.src=sceneAsset(question.id,name,"png");image.alt="";
    picture.append(source,image);return picture;
  }));
  sceneForeground.dataset.scene=question.id;
  sceneForeground.style.aspectRatio=`1400/${foregroundHeights[question.id]}`;
  sceneForeground.querySelector("source").srcset=sceneAsset(question.id,"foreground","webp");
  const image=sceneForeground.querySelector("img");
  image.src=sceneAsset(question.id,"foreground","png");
  image.width=1400;image.height=foregroundHeights[question.id];
}

function preload(index){
  if(index<0||index>=questions.length)return;
  const question=questions[index];
  [sceneAsset(question.id,"foreground","webp"),...sceneMidgrounds[question.id].map(([name])=>sceneAsset(question.id,name,"webp")),...["a","b","c","d"].map(letter=>questionAsset(question.id,`option-${letter}-art`,"webp"))].forEach(src=>{const image=new Image();image.src=src;});
}

function render({announce=true}={}){
  const question=questions[state.current],selected=state.answers[state.current],fullTitle=`${question.level}：${question.sceneTitle}`;
  pageTitle.textContent=fullTitle;
  sceneLevel.textContent=question.level;sceneTitle.textContent=question.sceneTitle;sceneDescription.textContent=question.description;renderSceneForeground(question);
  prompt.dataset.question=question.id;promptIcon.textContent=question.icon;promptLead.textContent=question.lead;promptHighlight.textContent=question.highlight;progressCount.textContent=`${state.current+1}/${questions.length}`;nextText.textContent=state.current===questions.length-1?"完成":"選好了";
  choices.forEach((button,index)=>{
    const [letter,title,description,color]=question.options[index];
    button.dataset.option=letter;button.style.setProperty("--choice-color",color);button.querySelector(".choice-letter").textContent=letter;button.querySelector(".choice-title").textContent=title;button.querySelector(".choice-description").textContent=`「${description}」`;
    button.querySelector("source").srcset=questionAsset(question.id,`option-${letter.toLowerCase()}-art`,"webp");const image=button.querySelector("img");image.src=questionAsset(question.id,`option-${letter.toLowerCase()}-art`,"png");image.alt="";
    button.setAttribute("aria-label",`選項 ${letter}：${title}。${description}`);button.setAttribute("aria-checked",String(selected===letter));button.tabIndex=selected===letter||(!selected&&index===0)?0:-1;
  });
  progressButtons.forEach((button,index)=>{if(index===state.current)button.setAttribute("aria-current","step");else button.removeAttribute("aria-current");button.classList.toggle("is-answered",Boolean(state.answers[index]));button.setAttribute("aria-label",`前往第 ${index+1} 題${state.answers[index]?`，已選 ${state.answers[index]}`:"，尚未作答"}`);});
  backButton.setAttribute("aria-label",state.current===0?"已經是第一題":"上一題");nextButton.setAttribute("aria-label",state.current===questions.length-1?"完成測驗":"選好了，前往下一題");nextButton.classList.remove("needs-answer");preload(state.current+1);
  if(announce)showStatus(`${fullTitle}，${selected?`目前選擇 ${selected}`:"尚未選擇答案"}`);
}

function showStatus(message){clearTimeout(statusTimer);status.textContent=message;status.classList.add("is-visible");statusTimer=setTimeout(()=>status.classList.remove("is-visible"),1800);}
function goTo(index,announce=true){if(index<0||index>=questions.length||index===state.current)return;quiz.classList.add("is-changing");setTimeout(()=>{state.current=index;render({announce});requestAnimationFrame(()=>quiz.classList.remove("is-changing"));scrollTo({top:0,behavior:"smooth"});},160);}
function select(letter,focus=false){state.answers[state.current]=letter;choices.forEach(button=>{const active=button.dataset.option===letter;button.setAttribute("aria-checked",String(active));button.tabIndex=active?0:-1;if(active&&focus)button.focus();});progressButtons[state.current].classList.add("is-answered");nextButton.classList.remove("needs-answer");const option=questions[state.current].options.find(([item])=>item===letter);showStatus(`已選擇 ${letter}：${option[1]}`);}
function finish(){answerSummary.replaceChildren(...state.answers.map((answer,index)=>{const item=document.createElement("span");item.textContent=answer;item.title=`第 ${index+1} 題：${answer}`;return item;}));completion.hidden=false;reviewButton.focus();}

choices.forEach((button,index)=>{button.addEventListener("click",()=>select(button.dataset.option));button.addEventListener("keydown",event=>{if(!["ArrowRight","ArrowDown","ArrowLeft","ArrowUp"].includes(event.key))return;event.preventDefault();const direction=event.key==="ArrowRight"||event.key==="ArrowDown"?1:-1,nextIndex=(index+direction+choices.length)%choices.length;select(choices[nextIndex].dataset.option,true);});});
progressButtons.forEach(button=>button.addEventListener("click",()=>goTo(Number(button.dataset.question),false)));backButton.addEventListener("click",()=>state.current===0?showStatus("目前已經是第一題"):goTo(state.current-1));
nextButton.addEventListener("click",()=>{if(!state.answers[state.current]){nextButton.classList.remove("needs-answer");void nextButton.offsetWidth;nextButton.classList.add("needs-answer");showStatus("請先選擇一個選項");return;}if(state.current<questions.length-1)return goTo(state.current+1);const missing=state.answers.findIndex(answer=>!answer);if(missing!==-1){showStatus(`第 ${missing+1} 題尚未作答，將為你跳回該題`);setTimeout(()=>goTo(missing),650);}else finish();});
reviewButton.addEventListener("click",()=>{completion.hidden=true;state.current=0;render();});restartButton.addEventListener("click",()=>{state.answers.fill(null);completion.hidden=true;state.current=0;render();});render({announce:false});
