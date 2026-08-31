"use strict";

(function(root){
  const localhost=new Set(["localhost","127.0.0.1","::1"]);
  const mockEnabled=localhost.has(location.hostname)&&new URLSearchParams(location.search).get("mockSubmission")==="1";
  const testApiEndpoint="https://lite2.ceoschool.app/KTKP/CEO/app/learning-stars";
  const defaultEndpoint=location.origin==="https://silase0201.github.io"?testApiEndpoint:"/KTKP/CEO/app/learning-stars";
  const endpoint=(typeof root.LEARNING_STARS_API_ENDPOINT==="string"?root.LEARNING_STARS_API_ENDPOINT:defaultEndpoint).replace(/\/$/,"");

  function createSubmissionId(){
    return crypto.randomUUID?crypto.randomUUID():`ls-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  }

  async function post(path,payload){
    if(mockEnabled){
      await new Promise(resolve=>setTimeout(resolve,350));
      if(path==="/result.php"){
        const scores=root.LearningStarsScoring.calculateScores(payload.assessment.answers);
        return {ok:true,mock:true,data:{result_token:"00000000000000000000000000000000",result_code:root.LearningStarsScoring.resolveResultId({target:scores.T,explore:scores.E,growth:scores.G}),scores}};
      }
      return {ok:true,mock:true,data:{contact_id:1,mail_status:"sent"}};
    }
    const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),20000);
    const url=new URL(endpoint+path,location.href).href;
    try{
      const credentials=new URL(url).origin===location.origin?"same-origin":"omit";
      const response=await fetch(url,{method:"POST",headers:{"Content-Type":"application/json","X-Idempotency-Key":payload.submission_id},body:JSON.stringify(payload),signal:controller.signal,credentials});
      const rawBody=await response.text();
      let body=null;
      try{body=rawBody?JSON.parse(rawBody):null;}catch(error){/* Keep the raw server response in details below. */}
      if(!response.ok||!body||body.ok!==true){
        return {ok:false,code:body&&body.error&&body.error.code||"http_error",message:body&&body.error&&body.error.message||"伺服器回應錯誤",details:{url,method:"POST",response_body:rawBody||null,api_details:body&&body.error&&body.error.details||null},status:response.status};
      }
      return {ok:true,data:body.data||{}};
    }catch(error){
      return {ok:false,code:error&&error.name==="AbortError"?"timeout":"network_error",message:error&&error.name==="AbortError"?"API 連線逾時":error&&error.message||"API 連線失敗",details:error?{url,method:"POST",name:error.name,message:error.message,stack:error.stack}:{url,method:"POST"}};
    }finally{clearTimeout(timer);}
  }

  root.LearningStarsSubmission={
    createSubmissionId,
    submitResult:payload=>post("/result.php",payload),
    submitContact:payload=>post("/contact.php",payload),
    isMock:mockEnabled
  };
})(globalThis);
