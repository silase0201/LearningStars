"use strict";

const questions=LearningStarsQuestions;
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
const state={current:0,answers:Array(questions.length).fill(null),submissionId:null,resultToken:null,scores:null,resultId:null,resultStatus:null};
const startScreen=document.querySelector("#startScreen"),startButton=document.querySelector("#startButton"),quiz=document.querySelector("#quiz"),pageTitle=document.querySelector("#pageTitle"),sceneMidground=document.querySelector("#sceneMidground"),sceneForeground=document.querySelector("#sceneForeground"),sceneTitle=document.querySelector("#sceneTitle"),sceneDescription=document.querySelector("#sceneDescription"),sceneQuestion=document.querySelector("#sceneQuestion"),choices=[...document.querySelectorAll(".choice")],progressButtons=[...document.querySelectorAll("#progress button")],progressCount=document.querySelector("#progressCount"),backButton=document.querySelector("#backButton"),nextButton=document.querySelector("#nextButton"),nextText=document.querySelector("#nextText"),status=document.querySelector("#status");
const resultScreen=document.querySelector("#resultScreen"),resultHeading=document.querySelector("#resultHeading"),resultName=document.querySelector("#resultName"),resultSubtitle=document.querySelector("#resultSubtitle"),resultIntro=document.querySelector("#resultIntro"),resultTraits=document.querySelector("#resultTraits"),resultIcons=document.querySelector("#resultIcons"),resultContactButton=document.querySelector("#resultContactButton");
const contactScreen=document.querySelector("#contactScreen"),contactHeading=document.querySelector("#contactHeading"),contactBackButton=document.querySelector("#contactBackButton"),contactForm=document.querySelector("#contactForm"),contactSubmitButton=document.querySelector("#contactSubmitButton"),contactStatus=document.querySelector("#contactStatus"),finishScreen=document.querySelector("#finishScreen"),finishHeading=document.querySelector("#finishHeading");
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
  const question=questions[state.current],selected=state.answers[state.current],fullTitle=question.sceneTitle;
  pageTitle.textContent=fullTitle;
  sceneTitle.textContent=question.sceneTitle;sceneDescription.textContent=question.sceneDescription;sceneQuestion.textContent=question.question;renderSceneForeground(question);
  progressCount.textContent=`${state.current+1}/${questions.length}`;nextText.textContent=state.current===questions.length-1?"完成":"選好了";
  choices.forEach((button,index)=>{
    const {letter,title,subtitle,color}=question.options[index];
    button.dataset.option=letter;button.style.setProperty("--choice-color",color);button.style.setProperty("--choice-image",`url("../${questionAsset(question.id,`option-${letter.toLowerCase()}-art`,"webp")}")`);button.querySelector(".choice-letter").textContent=letter;button.querySelector(".choice-title").textContent=title;button.querySelector(".choice-description").textContent=subtitle;
    button.setAttribute("aria-label",`選項 ${letter}：${title}${subtitle?`。${subtitle}`:""}`);button.setAttribute("aria-checked",String(selected===letter));button.tabIndex=selected===letter||(!selected&&index===0)?0:-1;
  });
  progressButtons.forEach((button,index)=>{if(index===state.current)button.setAttribute("aria-current","step");else button.removeAttribute("aria-current");button.classList.toggle("is-answered",Boolean(state.answers[index]));button.setAttribute("aria-label",`前往第 ${index+1} 題${state.answers[index]?`，已選 ${state.answers[index]}`:"，尚未作答"}`);});
  backButton.setAttribute("aria-label",state.current===0?"已經是第一題":"上一題");nextButton.setAttribute("aria-label",state.current===questions.length-1?"完成測驗":"選好了，前往下一題");nextButton.classList.remove("needs-answer");preload(state.current+1);
  if(announce)showStatus(`${fullTitle}，${selected?`目前選擇 ${selected}`:"尚未選擇答案"}`);
}

function startQuiz(){
  state.current=0;
  startScreen.hidden=true;
  quiz.hidden=false;
  render({announce:false});
  scrollTo({top:0,behavior:"auto"});
  requestAnimationFrame(()=>pageTitle.focus({preventScroll:true}));
}

function showStatus(message){clearTimeout(statusTimer);status.textContent=message;status.classList.add("is-visible");statusTimer=setTimeout(()=>status.classList.remove("is-visible"),1800);}
function formatSubmissionError(response,fallback){
  const context=[];
  if(response&&response.status)context.push(`HTTP ${response.status}`);
  if(response&&response.code)context.push(`code: ${response.code}`);
  if(response&&response.details)context.push(`details: ${JSON.stringify(response.details)}`);
  return `${response&&response.message||fallback}${context.length?` ｜ ${context.join(" ｜ ")}`:""}`;
}
function showSubmissionError(response,fallback){
  clearTimeout(statusTimer);
  status.textContent=formatSubmissionError(response,fallback);
  status.classList.add("is-visible");
  console.error("[LearningStars API]",response);
}
function goTo(index,announce=true){if(index<0||index>=questions.length||index===state.current)return;quiz.classList.add("is-changing");setTimeout(()=>{state.current=index;render({announce});requestAnimationFrame(()=>quiz.classList.remove("is-changing"));scrollTo({top:0,behavior:"smooth"});},160);}
function select(letter,focus=false){state.answers[state.current]=letter;choices.forEach(button=>{const active=button.dataset.option===letter;button.setAttribute("aria-checked",String(active));button.tabIndex=active?0:-1;if(active&&focus)button.focus();});progressButtons[state.current].classList.add("is-answered");nextButton.classList.remove("needs-answer");const option=questions[state.current].options.find(item=>item.letter===letter);showStatus(`已選擇 ${letter}：${option.title}`);}
function showStage(target,focusTarget){
  [startScreen,quiz,resultScreen,contactScreen,finishScreen].forEach(screen=>{screen.hidden=screen!==target;});
  scrollTo({top:0,behavior:"auto"});
  if(focusTarget)requestAnimationFrame(()=>focusTarget.focus({preventScroll:true}));
}

function assetPicture(folder,name){
  const picture=document.createElement("picture"),source=document.createElement("source"),image=document.createElement("img");
  source.type="image/webp";source.srcset=`assets/${folder}/${name}.webp`;image.src=`assets/${folder}/${name}.png`;image.alt="";
  picture.append(source,image);return picture;
}

function renderResult(){
  const data=LearningStarsResults[state.resultId];
  const leaders=[["target",state.scores.target],["explore",state.scores.explore],["growth",state.scores.growth]];
  const maximum=Math.max(...leaders.map(([,score])=>score));
  resultIcons.replaceChildren(...leaders.filter(([,score])=>score===maximum).map(([name])=>assetPicture("result/icons",name)));
  resultName.textContent=data.name.replace(/[🎯🔍🌱]\s*/gu,"");resultSubtitle.textContent=data.subtitle;resultIntro.textContent=data.intro;
  resultName.classList.toggle("is-long",data.type!=="單星");
  const traitAssets=["flag","trophy","rocket"];
  resultTraits.replaceChildren(...data.traits.map((trait,index)=>{
    const item=document.createElement("li"),picture=assetPicture("result/traits",traitAssets[index]),text=document.createElement("strong");
    text.textContent=trait.replace(/^\S+\s*/u,"");item.append(picture,text);return item;
  }));
}

async function completeQuiz(){
  nextButton.disabled=true;showStatus("正在整理孩子的探索結果…");
  state.submissionId=state.submissionId||LearningStarsSubmission.createSubmissionId();
  const payload={schema_version:1,submission_id:state.submissionId,assessment:{answers:[...state.answers]},submitted_at:new Date().toISOString()};
  state.resultStatus=await LearningStarsSubmission.submitResult(payload);
  if(!state.resultStatus.ok){
    nextButton.disabled=false;
    showSubmissionError(state.resultStatus,"測驗結果未能送出，請檢查連線後再試一次");
    return;
  }
  const result=state.resultStatus.data,scores=result.scores||{};
  state.resultToken=result.result_token;
  state.scores={target:Number(scores.T)||0,explore:Number(scores.E)||0,growth:Number(scores.G)||0};
  state.resultId=result.result_code;
  if(!/^[a-f0-9]{32}$/.test(state.resultToken||"")||!LearningStarsResults[state.resultId]){
    nextButton.disabled=false;
    showSubmissionError({code:"invalid_response",details:result},"測驗結果回應格式錯誤，請稍後再試一次");
    return;
  }
  renderResult();nextButton.disabled=false;showStage(resultScreen,resultHeading);
}

function showContact(){
  contactStatus.textContent="";
  showStage(contactScreen,contactHeading);
}

function validateContact(){
  let valid=true;
  contactForm.querySelectorAll("small").forEach(item=>item.textContent="");
  [...contactForm.elements].forEach(field=>field.removeAttribute&&field.removeAttribute("aria-invalid"));
  const required=[["parent_name","請輸入家長姓名"],["phone","請輸入聯絡電話"],["contact_period","請選擇方便聯絡時間"],["child_name","請輸入孩子姓名"],["child_age","請選擇孩子年齡"],["county_city","請選擇縣市"]];
  required.forEach(([name,message])=>{
    const fields=[...contactForm.elements].filter(field=>field.name===name),hasValue=fields.some(field=>field.type==="radio"?field.checked:Boolean(field.value.trim()));
    if(hasValue)return;
    valid=false;fields.forEach(field=>field.setAttribute("aria-invalid","true"));
    const host=fields[0].type==="radio"?fields[0].closest(".contact-field"):fields[0].closest("label");
    const error=host.querySelector("small");if(error)error.textContent=message;
  });
  const phone=contactForm.elements.phone;
  if(phone.value&&!/^[0-9+()#\-\s]{8,20}$/.test(phone.value)){
    valid=false;phone.setAttribute("aria-invalid","true");phone.closest("label").querySelector("small").textContent="請輸入有效的聯絡電話";
  }
  return valid;
}

async function submitContact(event){
  event.preventDefault();
  if(!validateContact()){contactStatus.textContent="請確認標示的欄位。";contactForm.querySelector("[aria-invalid=true]").focus();return;}
  contactSubmitButton.disabled=true;contactForm.setAttribute("aria-busy","true");contactStatus.textContent="資料送出中…";
  const form=new FormData(contactForm),payload={
    schema_version:1,submission_id:state.submissionId,result_token:state.resultToken,source:"learningstars-web",
    contact:{parent_name:String(form.get("parent_name")).trim(),phone:String(form.get("phone")).trim(),contact_period:form.get("contact_period"),child_name:String(form.get("child_name")).trim(),child_age:form.get("child_age"),county_city:form.get("county_city")},
    consent:{education_consultant_contact:true,copy_version:1,consented_at:new Date().toISOString()}
  };
  const response=await LearningStarsSubmission.submitContact(payload);
  contactSubmitButton.disabled=false;contactForm.removeAttribute("aria-busy");
  if(!response.ok){
    contactStatus.textContent=formatSubmissionError(response,"資料未送出，請檢查連線後再試一次。");
    console.error("[LearningStars API]",response);
    return;
  }
  contactForm.reset();showStage(finishScreen,finishHeading);
}

choices.forEach((button,index)=>{button.addEventListener("click",()=>select(button.dataset.option));button.addEventListener("keydown",event=>{if(!["ArrowRight","ArrowDown","ArrowLeft","ArrowUp"].includes(event.key))return;event.preventDefault();const direction=event.key==="ArrowRight"||event.key==="ArrowDown"?1:-1,nextIndex=(index+direction+choices.length)%choices.length;select(choices[nextIndex].dataset.option,true);});});
startButton.addEventListener("click",startQuiz);
progressButtons.forEach(button=>button.addEventListener("click",()=>goTo(Number(button.dataset.question),false)));backButton.addEventListener("click",()=>state.current===0?showStatus("目前已經是第一題"):goTo(state.current-1));
nextButton.addEventListener("click",()=>{if(!state.answers[state.current]){nextButton.classList.remove("needs-answer");void nextButton.offsetWidth;nextButton.classList.add("needs-answer");showStatus("請先選擇一個選項");return;}if(state.current<questions.length-1)return goTo(state.current+1);const missing=state.answers.findIndex(answer=>!answer);if(missing!==-1){showStatus(`第 ${missing+1} 題尚未作答，將為你跳回該題`);setTimeout(()=>goTo(missing),650);}else void completeQuiz();});
resultContactButton.addEventListener("click",showContact);
contactBackButton.addEventListener("click",()=>showStage(resultScreen,resultHeading));
contactForm.addEventListener("submit",submitContact);
preload(0);
