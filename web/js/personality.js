import{catImg}from'./sprites.js';
const RM=matchMedia('(prefers-reduced-motion:reduce)').matches,DIM=[['energy','Energy'],['curiosity','Curiosity'],['playfulness','Playfulness'],['laziness','Laziness'],['sociability','Sociability'],['mischief','Mischief']];
export async function initPersonality(root){
  const data=await(await fetch('/data/personalities.json')).json(),box=root.querySelector('[data-chips]'),bars=root.querySelector('[data-bars]'),sum=root.querySelector('[data-summary]'),q=root.querySelector('[data-quote]'),cat=catImg(root.querySelector('img'),RM);
  // Illustrative mapping from traits to a sprite state; the real engine also uses needs and context.
  const state=t=>t.laziness>=.7?'sleep':t.energy>=.85?'run':t.laziness>=.5?'sit':t.curiosity>=.8?'walk':t.playfulness>=.9?'jump':'idle';
  data.forEach((p,i)=>{const b=document.createElement('button');b.className='chip';b.textContent=p.name;b.setAttribute('aria-pressed',i==0);b.onclick=()=>{box.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed','false'));b.setAttribute('aria-pressed','true');show(p)};box.append(b)});
  function show(p){sum.textContent=p.summary;q.textContent=p.greeting?`“${p.greeting}”`:'(No sample greeting for this archetype in the dialogue library.)';
    bars.innerHTML='';DIM.forEach(([k,l])=>{const v=Math.round(p.traits[k]*100),d=document.createElement('div');d.className='bar';d.innerHTML=`<label></label><span><i></i></span><b></b>`;d.firstChild.textContent=l;d.querySelector('i').style.width=v+'%';d.lastChild.textContent=v;bars.append(d)});cat.set(state(p.traits))}
  show(data[0]);
}
