// Offline unit harness for generated renderer; no browser, networking, or native UI.
const fs=require('fs'),vm=require('vm'),assert=require('assert');
class Element{
 constructor(tag){this.tagName=tag;this.children=[];this.className='';this.attrs={};this.style={};this.disabled=false;this._html='';this.listeners={};this.classList={contains:c=>this.className.split(' ').includes(c),add:(...c)=>this.className=[...new Set([...this.className.split(' '),...c])].join(' ').trim(),remove:(...c)=>this.className=this.className.split(' ').filter(x=>!c.includes(x)).join(' '),toggle:c=>{const on=!this.classList.contains(c);on?this.classList.add(c):this.classList.remove(c);return on;}};}
 set innerHTML(s){this._html=s;this.children=[];}get innerHTML(){return this._html;}
 get firstChild(){return this.children[0]||null;}
 appendChild(n){n.parent=this;this.children.push(n);return n;}
 insertBefore(n,target){n.parent=this;const i=this.children.indexOf(target);if(i<0)this.children.push(n);else this.children.splice(i,0,n);return n;}
 insertAdjacentHTML(_,html){this._html+=html;}
 remove(){if(this.parent)this.parent.children=this.parent.children.filter(c=>c!==this);}
 setAttribute(k,v){this.attrs[k]=v;}
 addEventListener(k,cb){this.listeners[k]=cb;}
 querySelectorAll(s){const match=n=>s.startsWith('.')?n.classList.contains(s.slice(1)):n.tagName===s;const found=[];const walk=n=>{for(const c of n.children){if(match(c))found.push(c);walk(c);}};walk(this);return found;}
 querySelector(s){return this.querySelectorAll(s)[0]||null;}
 click(){if(!this.disabled&&this.onclick)this.onclick();}
}
function load(content, initial=[]){
 const root=new Element('main'), body=new Element('body');body.appendChild(root);const storage=new Map(initial);
 const ctx={document:{createElement:t=>new Element(t),createElementNS:(_,t)=>new Element(t),getElementById:()=>root,body,title:''},window:{addEventListener:()=>{}},location:{reload:()=>{ctx.reloaded=true}},localStorage:{setItem:(k,v)=>storage.set(k,v),getItem:k=>storage.get(k),removeItem:k=>storage.delete(k)},setTimeout:cb=>cb()};
 vm.createContext(ctx);const script=content.match(/<script>([\s\S]*?)<\/script>/)[1];new vm.Script(script).runInContext(ctx);return {ctx,root,data:vm.runInContext('DATA',ctx)};
}

const path=require('path');
const template=fs.readFileSync(path.join(__dirname,'../assets/template.html'),'utf8');
let run=load(template), data=run.data;
function custom(d,initial=[]){
 const start=template.indexOf('const DATA = '), end=template.indexOf('\n/* ============================================================================\n   RENDER',start);
 return load(template.slice(0,start)+'const DATA = '+JSON.stringify(d)+';\n'+template.slice(end),initial);
}
const key='de-expl:'+data.meta.slug;
let saved=custom(data,[[key,JSON.stringify([true,true,false,null,null])]]);
assert.equal(saved.ctx.localStorage.getItem(key),'[true,true,false,null,null]');
assert(saved.root.querySelectorAll('div').some(n=>n.innerHTML.includes('Прошлый результат: 2/5')));
saved.root.querySelector('.score').children[1].click();
assert.equal(saved.ctx.localStorage.getItem(key),undefined);
data.quiz[4]={typ:'ordnen',frage:'Test',teile:['A','B','A'],loesung:['A','B','A'],loesungen:[['A','B','A'],['B','A','A']],warum:'test'};
run=custom(data);let q=run.root.querySelectorAll('.q')[4],pool=q.querySelector('.chips');
for(const t of ['A','B','A'])pool.children.find(b=>b.innerHTML===t&&!b.disabled).click();
q.querySelector('.slots').children[2].click(); // remove second A, not first
assert.deepEqual(q.querySelector('.slots').children.map(n=>n.innerHTML),['A','B']);
pool.children.find(b=>b.innerHTML==='A'&&!b.disabled).click();q.querySelector('.btn').click();
assert(q.querySelector('.feedback').classList.contains('ok'));
run=custom(data);q=run.root.querySelectorAll('.q')[4];pool=q.querySelector('.chips');
for(const t of ['B','A','A'])pool.children.find(b=>b.innerHTML===t&&!b.disabled).click();
q.querySelector('.btn').click();assert(q.querySelector('.feedback').classList.contains('ok'));
data.reference=[{titel:'Reference',kopf:['Verb','Form'],zeilen:[['gehen','gegangen']]}];
data.solutions=[{titel:'Solutions',text:'Answer'}];
run=custom(data);assert.equal(run.root.querySelectorAll('details').length,2);
console.log('Renderer: previous result retained; reset; repeated tokens; alternative order; appendices OK.');

for(const file of process.argv.slice(2)){
 const content=fs.readFileSync(file,'utf8'), r=load(content);
 assert.equal(r.root.querySelectorAll('.fig').length,r.data.figuren.length,'every figure rendered');
 assert.equal(r.root.querySelectorAll('.analyse-step').filter(n=>n.querySelector('.fig')).length,r.data.figuren.length,'figures stay beside their analysis step');
 assert(r.root.querySelectorAll('.quiz-figure').length>=1,'quiz links to a figure');
 assert.equal(r.root.querySelectorAll('.merk')[0].children.length,r.data.merksatz.length,'every mnemonic rendered');
 for(const fig of r.root.querySelectorAll('.fig')){
  for(const b of fig.querySelectorAll('button'))b.click();
 }
 const qs=r.root.querySelectorAll('.q');
 r.data.quiz.forEach((question,i)=>{
  const box=qs[i];
  if(question.typ==='wahl')box.querySelectorAll('.opt')[question.optionen.findIndex(o=>o.ok)].click();
  else if(question.typ==='eingabe'){box.querySelector('input').value=question.antworten[0];box.querySelector('.btn').click();}
  else{const pool=box.querySelector('.chips');for(const t of question.loesung)pool.children.find(b=>b.innerHTML===t&&!b.disabled).click();box.querySelector('.btn').click();}
 });
 assert(r.root.querySelector('.score').children[0].innerHTML.includes('<b>5 / 5</b>'));
 console.log(file+': inline figures, figure controls, figure-linked quiz and all five correct answers OK (no browser layout test).');
}
