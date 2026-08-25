"use strict";

(function(root,factory){
  const scoring=factory();
  if(typeof module==="object"&&module.exports)module.exports=scoring;
  root.LearningStarsScoring=scoring;
})(typeof globalThis!=="undefined"?globalThis:this,function(){
  const dimensions={
    main:[
      {key:"T",label:"目標"},
      {key:"E",label:"探索"},
      {key:"G",label:"成長"}
    ],
    detail:[
      {key:"GD",label:"目標驅動"},
      {key:"ET",label:"探索思考"},
      {key:"GT",label:"持續嘗試"},
      {key:"PS",label:"問題解決"},
      {key:"CE",label:"創意表達"},
      {key:"OU",label:"觀察理解"}
    ]
  };

  const answerScores={
    Q1A:{T:2,E:0,G:0,GD:2,ET:0,GT:0,PS:0,CE:0,OU:1},
    Q1B:{T:0,E:2,G:0,GD:0,ET:2,GT:0,PS:0,CE:0,OU:1},
    Q1C:{T:0,E:0,G:2,GD:0,ET:0,GT:2,PS:1,CE:0,OU:0},
    Q1D:{T:0,E:1,G:1,GD:0,ET:0,GT:1,PS:0,CE:2,OU:0},
    Q2A:{T:2,E:0,G:0,GD:1,ET:0,GT:0,PS:2,CE:0,OU:0},
    Q2B:{T:0,E:2,G:0,GD:0,ET:2,GT:0,PS:0,CE:0,OU:1},
    Q2C:{T:0,E:0,G:2,GD:0,ET:0,GT:1,PS:0,CE:2,OU:0},
    Q2D:{T:0,E:1,G:1,GD:0,ET:2,GT:0,PS:0,CE:0,OU:1},
    Q3A:{T:0,E:0,G:2,GD:0,ET:0,GT:0,PS:2,CE:1,OU:0},
    Q3B:{T:0,E:2,G:0,GD:0,ET:0,GT:0,PS:2,CE:0,OU:1},
    Q3C:{T:2,E:0,G:0,GD:2,ET:0,GT:0,PS:1,CE:0,OU:0},
    Q3D:{T:1,E:0,G:1,GD:1,ET:0,GT:2,PS:0,CE:0,OU:0},
    Q4A:{T:2,E:0,G:0,GD:2,ET:0,GT:0,PS:1,CE:0,OU:0},
    Q4B:{T:0,E:2,G:0,GD:0,ET:2,GT:0,PS:0,CE:0,OU:1},
    Q4C:{T:0,E:0,G:2,GD:0,ET:0,GT:2,PS:0,CE:1,OU:0},
    Q4D:{T:1,E:0,G:1,GD:1,ET:0,GT:0,PS:0,CE:2,OU:0},
    Q5A:{T:2,E:0,G:0,GD:2,ET:0,GT:0,PS:1,CE:0,OU:0},
    Q5B:{T:0,E:2,G:0,GD:0,ET:2,GT:0,PS:0,CE:0,OU:1},
    Q5C:{T:0,E:0,G:2,GD:0,ET:2,GT:1,PS:0,CE:0,OU:0},
    Q5D:{T:1,E:1,G:0,GD:0,ET:1,GT:0,PS:0,CE:2,OU:0},
    Q6A:{T:2,E:0,G:0,GD:2,ET:0,GT:0,PS:1,CE:0,OU:0},
    Q6B:{T:0,E:2,G:0,GD:0,ET:1,GT:0,PS:2,CE:0,OU:0},
    Q6C:{T:0,E:0,G:2,GD:1,ET:0,GT:2,PS:0,CE:0,OU:0},
    Q6D:{T:1,E:1,G:0,GD:0,ET:0,GT:0,PS:1,CE:2,OU:0}
  };

  function calculateScores(answers){
    const scores=Object.fromEntries([...dimensions.main,...dimensions.detail].map(({key})=>[key,0]));
    answers.forEach((answer,index)=>{
      const row=answerScores[`Q${index+1}${answer}`];
      if(!row)return;
      Object.entries(row).forEach(([key,value])=>{scores[key]+=value;});
    });
    return scores;
  }

  function calculateMainScores(answers){
    const all=calculateScores(answers);
    return {target:all.T,explore:all.E,growth:all.G};
  }

  function resolveResultId(scores){
    const entries=[["target",scores.target],["explore",scores.explore],["growth",scores.growth]];
    const highest=Math.max(...entries.map(([,value])=>value));
    const leaders=entries.filter(([,value])=>value===highest).map(([key])=>key).join("+");
    return {target:"R01",explore:"R02",growth:"R03","target+explore":"R04","target+growth":"R05","explore+growth":"R06","target+explore+growth":"R07"}[leaders];
  }

  return {dimensions,answerScores,calculateScores,calculateMainScores,resolveResultId};
});
