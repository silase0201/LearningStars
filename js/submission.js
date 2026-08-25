"use strict";

(function(root){
  const localhost=new Set(["localhost","127.0.0.1","::1"]);
  const mockEnabled=localhost.has(location.hostname)&&new URLSearchParams(location.search).get("mockSubmission")==="1";
  const endpoint=typeof root.LEARNING_STARS_API_ENDPOINT==="string"?root.LEARNING_STARS_API_ENDPOINT.replace(/\/$/,""):"";

  function createSubmissionId(){
    return crypto.randomUUID?crypto.randomUUID():`ls-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  }

  async function post(path,payload){
    if(mockEnabled){
      await new Promise(resolve=>setTimeout(resolve,350));
      return {ok:true,mock:true};
    }
    if(!endpoint)return {ok:false,code:"not_configured"};
    const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),10000);
    try{
      const response=await fetch(endpoint+path,{method:"POST",headers:{"Content-Type":"application/json","X-Idempotency-Key":payload.submission_id},body:JSON.stringify(payload),signal:controller.signal,credentials:"same-origin"});
      if(!response.ok)return {ok:false,code:"http_error",status:response.status};
      return {ok:true};
    }catch(error){
      return {ok:false,code:error&&error.name==="AbortError"?"timeout":"network_error"};
    }finally{clearTimeout(timer);}
  }

  root.LearningStarsSubmission={
    createSubmissionId,
    submitStatistics:payload=>post("/assessment-statistics",payload),
    submitContact:payload=>post("/contact",payload),
    isMock:mockEnabled
  };
})(globalThis);
