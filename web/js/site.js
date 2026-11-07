import{catImg}from'./sprites.js';
const $=(s,r=document)=>r.querySelector(s),RM=matchMedia('(prefers-reduced-motion:reduce)').matches;
const mb=$('#mb'),nv=$('#nv');
mb.onclick=()=>mb.setAttribute('aria-expanded',nv.classList.toggle('open'));
nv.onclick=e=>{if(e.target.tagName=='A'){nv.classList.remove('open');mb.setAttribute('aria-expanded','false')}};
addEventListener('keydown',e=>{if(e.key=='Escape'&&nv.classList.contains('open')){nv.classList.remove('open');mb.setAttribute('aria-expanded','false');mb.focus()}});
const chips=(el,items,cb,start=0)=>{items.forEach((x,i)=>{const b=document.createElement('button');b.className='chip';b.textContent=x;b.setAttribute('aria-pressed',i==start);b.onclick=()=>{el.querySelectorAll('button').forEach(y=>y.setAttribute('aria-pressed','false'));b.setAttribute('aria-pressed','true');cb(i)};el.append(b)});cb(start)};
const ALLOWED_DOWNLOAD_HOSTS = new Set([
  'github.com',
  'api.github.com',
  'raw.githubusercontent.com',
  'objects.githubusercontent.com'
]);
const demos={
async hero(root){const{initAquarium}=await import('./aquarium.js');
  root.querySelectorAll('.tile canvas').forEach(cv=>initAquarium(cv,{mini:true}));
  const c=$('[data-cat]',root),cat=catImg(c,RM),spawn=$('[data-spawn]',root),aq=$('[data-aq]',root),count=$('[data-count]',root);
  let roaming=true;
  const paint=()=>{c.classList.toggle('is-hidden',!roaming);count.textContent=roaming?'1 roaming':'0 roaming';spawn.textContent=roaming?'Dismiss companion':'Spawn companion';spawn.setAttribute('aria-pressed',roaming?'true':'false')};
  spawn.onclick=()=>{roaming=!roaming;paint();if(roaming)cat.set(RM?'sit':'walk')};
  aq.onclick=()=>{const on=root.classList.toggle('on-aq');aq.setAttribute('aria-pressed',on?'true':'false')};
  paint();cat.set(RM?'sit':'walk');
  if(RM){c.style.left='58%';c.style.top='16%';return}
  let x=54,d=1;const tick=()=>{if(!roaming){requestAnimationFrame(tick);return}x+=d*.06;if(x>78){d=-1;c.style.transform='scaleX(-1)'}if(x<54){d=1;c.style.transform=''}c.style.left=x+'%';c.style.top='16%';requestAnimationFrame(tick)};tick()},
async aquarium(root){const A=await import('./aquarium.js'),q=A.initAquarium($('canvas',root));
  const live=document.querySelector('[data-say]');q.onSay(m=>live.textContent=m);
  chips($('#aq-themes'),A.THEMES.map(t=>t[0]),i=>q.theme(i));
  chips($('#aq-sizes'),A.SIZES.map(s=>s[0]),i=>{root.style.aspectRatio=A.SIZES[i][1];root.style.maxWidth=A.SIZES[i][2]+'%'},1);
  document.querySelector('[data-feed]').onclick=()=>q.feed()},
async ambient(root){(await import('./ambient.js')).initAmbient(root)},
async personality(root){(await import('./personality.js')).initPersonality(root)},
async timer(root){(await import('./timer.js')).initTimer(root)},
async studio(root){const data=await(await fetch('/data/personalities.json')).json(),cat=catImg($('[data-cat]',root),RM),img=$('[data-cat]',root),stage=$('[data-stage]',root);
  const ST=['idle','walk','run','sit','sleep','jump'];
  chips($('[data-states]',root),ST,i=>cat.set(ST[i]));
  chips($('[data-pers]',root),data.map(p=>p.name),i=>{$('[data-quote]',root).textContent=data[i].greeting?`“${data[i].greeting}”`:data[i].summary});
  $('#st-size').oninput=e=>img.style.width=e.target.value+'px';img.style.width='140px';img.style.imageRendering='pixelated';
  $('#st-bg').onchange=e=>stage.style.background=e.target.value},
async release(root){const st=$('[data-state]',root),out=$('[data-out]',root);
  const fail=m=>{st.textContent=m};
  try{let r=await fetch('https://api.github.com/repos/sharmao07/Animatto/releases/latest',{headers:{Accept:'application/vnd.github+json'}});
    let j;
    if(r.status==404){
      const rPre=await fetch('https://api.github.com/repos/sharmao07/Animatto/releases?per_page=5',{headers:{Accept:'application/vnd.github+json'}});
      if(rPre.ok){const list=await rPre.json();if(Array.isArray(list)&&list.length>0)j=list[0]}
      if(!j)return fail('No published release yet. Use the GitHub Releases link below.');
    }else if(r.status==403||r.status==429){
      return fail('GitHub rate limit reached. Use the GitHub Releases link below.');
    }else if(!r.ok){
      return fail('Release information is unavailable. Use the GitHub Releases link below.');
    }else{
      j=await r.json();
    }
    st.hidden=true;out.hidden=false;
    const isPre=Boolean(j.prerelease);
    $('[data-tag]',root).textContent=(j.name||j.tag_name)+(isPre?' (Nightly Prerelease)':'');
    $('[data-date]',root).textContent=(isPre?'Nightly Prerelease · ':'')+'Released '+new Date(j.published_at).toLocaleDateString(undefined,{year:'numeric',month:'long',day:'numeric'})+' · macOS 14.6 or later';
    $('[data-notes]',root).textContent=(j.body||'No release notes published.').slice(0,4000);
    const ul=$('[data-assets]',root),notes=j.body||'';
    const ok=u=>{try{const p=new URL(u);return p.protocol==='https:'&&ALLOWED_DOWNLOAD_HOSTS.has(p.hostname.toLowerCase())}catch{return false}};
    const assets=(j.assets||[]).filter(a=>ok(a.browser_download_url));
    if(!assets.length){const li=document.createElement('li');li.textContent='This release has no downloadable assets. Use the GitHub Releases link below.';ul.append(li)}
    assets.forEach(a=>{const li=document.createElement('li'),b=document.createElement('b'),l=document.createElement('a'),m=document.createElement('span');
      l.href=a.browser_download_url;l.textContent=a.name;l.rel='noopener';b.append(l);
      const mb=(a.size/1048576).toFixed(1)+' MB';
      let sha=(a.digest||'').startsWith('sha256:')?a.digest.slice(7):'';
      if(!sha){const mm=notes.split('\n').find(x=>x.includes(a.name)&&/[a-f0-9]{64}/i.test(x));if(mm)sha=mm.match(/[a-f0-9]{64}/i)[0]}
      m.textContent=mb+' · SHA-256: '+(sha||'not published for this asset');
      li.append(b,m);ul.append(li)})
  }catch{fail('Couldn’t reach GitHub. Use the GitHub Releases link below.')}}
};
document.querySelectorAll('[data-demo]').forEach(el=>demos[el.dataset.demo]?.(el));
