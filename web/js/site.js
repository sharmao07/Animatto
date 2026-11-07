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
async hero(root){
  const panes=[...root.querySelectorAll('[data-pane]')],nav=[...root.querySelectorAll('[data-nav]')];
  const launch=$('[data-launch]',root),name=$('[data-name]',root),preview=$('[data-preview]',root),px=$('[data-px]',root),scale=$('[data-scale]',root);
  const badge=$('[data-roam]',root),catEl=$('[data-cat]',root),cat=catImg(catEl,RM),aq=$('[data-aq]',root),feed=$('[data-feed-mini]',root),dismiss=$('[data-dismiss]',root),back=$('[data-back]',root);
  const title=$('[data-stage-title]',root),copy=$('[data-stage-copy]',root),desk=$('.aw-desk',root);
  let section=root.dataset.open==='aquarium'?'aquarium':'library',seeingDesktop=section==='aquarium',roaming=false,picked=root.querySelector('[data-pet][aria-pressed=true]')||root.querySelector('[data-pet]');
  const tanks=[...root.querySelectorAll('.aw-desk canvas')];
  let tankApi=null,tanksReady=false;
  const ensureTanks=async()=>{if(tanksReady)return;tanksReady=true;const{initAquarium}=await import('./aquarium.js');tankApi=tanks.map(cv=>initAquarium(cv,{mini:true}))};
  const size=()=>{const n=+scale.value;px.textContent=n+' px';preview.style.width=Math.min(n,160)+'px';catEl.style.width=n+'px'};
  const paint=()=>{
    const stage=section==='aquarium'||seeingDesktop;
    panes.forEach(p=>p.hidden=p.dataset.pane!==(stage?'stage':section));
    nav.forEach(b=>b.dataset.nav===section?b.setAttribute('aria-current','true'):b.removeAttribute('aria-current'));
    badge.hidden=!roaming;
    launch.textContent=roaming?'Dismiss from Desktop':'Launch onto Desktop';
    dismiss.hidden=!roaming;
    back.hidden=section!=='library';
    catEl.classList.toggle('is-hidden',!roaming);
    title.textContent=section==='aquarium'?'Aquarium Mode':'On your desktop';
    copy.textContent=roaming?'Mochi is on the window. The aquarium switch only covers the widgets.':'Turn Aquarium Mode on to cover the Clock, Weather, Calendar, and Battery widgets.';
    if(stage)ensureTanks();
  };
  nav.forEach(b=>b.onclick=()=>{section=b.dataset.nav;if(section!=='library')seeingDesktop=false;if(section==='aquarium')seeingDesktop=true;paint();boot(section)});
  root.querySelectorAll('[data-pet]').forEach(b=>b.onclick=()=>{picked=b;root.querySelectorAll('[data-pet]').forEach(x=>x.setAttribute('aria-pressed','false'));b.setAttribute('aria-pressed','true');name.textContent=b.dataset.label;preview.src=b.querySelector('img').src;if(roaming)cat.set(RM?'sit':b.dataset.state)});
  launch.onclick=()=>{roaming=!roaming;seeingDesktop=roaming;if(roaming)cat.set(RM?'sit':picked.dataset.state);paint()};
  dismiss.onclick=()=>{roaming=false;paint()};
  back.onclick=()=>{seeingDesktop=false;section='library';paint()};
  aq.onclick=()=>{const on=desk.classList.toggle('on-aq');aq.setAttribute('aria-checked',on?'true':'false');if(on){feed.hidden=false;ensureTanks()}else feed.hidden=true};
  feed.onclick=()=>tankApi&&tankApi.forEach(t=>t.feed());
  scale.oninput=size;
  const mute=$('[data-mute]',root),muteLabel=$('[data-mute-label]',root);
  mute.onclick=()=>{const on=mute.getAttribute('aria-checked')!=='true';mute.setAttribute('aria-checked',on?'true':'false');muteLabel.textContent=on?'Sound Muted':'Sound On'};
  let started={};
  async function boot(id){
    if(started[id])return;started[id]=true;
    const pane=root.querySelector(`[data-pane="${id}"]`);
    if(id==='ambient')(await import('./ambient.js')).initAmbient(pane);
    if(id==='workshop')(await import('./personality.js')).initPersonality(pane);
    if(id==='productivity')(await import('./timer.js')).initTimer(pane);
  }
  size();paint();if(roaming)cat.set(picked.dataset.state);
  if(RM){catEl.style.left='58%';catEl.style.top='8%'}
  let x=54,dir=1;const tick=()=>{const move=roaming&&!RM&&(picked.dataset.state==='walk'||picked.dataset.state==='run');if(move){x+=dir*.08;if(x>72){dir=-1;catEl.style.transform='scaleX(-1)'}if(x<48){dir=1;catEl.style.transform=''}catEl.style.left=x+'%'}else{catEl.style.left='58%';catEl.style.top='4%';if(!move)catEl.style.transform=''}catEl.style.top='4%';requestAnimationFrame(tick)};tick();
  if(section==='ambient'||section==='workshop'||section==='productivity')boot(section);
},
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
