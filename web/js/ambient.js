const RM=matchMedia('(prefers-reduced-motion:reduce)').matches;
const V={rainy_day:['#56677d','#1d2733','rain',1,'#c9dcff'],enchanted_forest:['#12342a','#050d0a','fly',.5,'#d9ff7a'],winter_calm:['#a9c3dd','#4b6482','snow',1,'#ffffff'],sunset:['#ffb36b','#5a3a78','cloud',.12,'#ffe3b8'],cosmic_dream:['#1a1040','#05030f','star',1,'#ffffff'],sakura_garden:['#f7d4dc','#b9788c','petal',.5,'#ff9fb8'],cozy_cafe:['#3a2a22','#17100c','steam',.2,'#ffffff'],ocean:['#7ec3e6','#164b73','wave',.1,'#ffffff']};
const Q=[['Low Power',40],['Balanced',110],['High Quality',260]];
const hx=h=>[1,3,5].map(i=>parseInt(h.slice(i,i+2),16)),mix=(a,b,k)=>{const x=hx(a),y=hx(b);return`rgb(${x.map((v,i)=>Math.round(v+(y[i]-v)*k))})`};
export async function initAmbient(root){
  const presets=await(await fetch('/data/presets.json')).json(),cv=root.querySelector('canvas'),c=cv.getContext('2d'),desc=root.querySelector('[data-desc]');
  let key=presets[0].key,prev=V[key],n=110,ps=[],fade=1,t=0,raf=0,vis=true,W=1,H=1;
  const R=Math.random,count=()=>Math.round(n*V[key][3]*(V[key][3]>.2?1:2));
  const reset=()=>{ps=Array.from({length:Math.max(8,count())},()=>({x:R(),y:R(),r:R(),p:R()*9}))};
  const size=()=>{const d=devicePixelRatio||1;W=cv.clientWidth||1;H=cv.clientHeight||1;cv.width=W*d;cv.height=H*d;c.setTransform(d,0,0,d,0,0);draw()};
  function draw(){const v=V[key],k=Math.min(1,fade);const g=c.createLinearGradient(0,0,0,H);g.addColorStop(0,mix(prev[0],v[0],k));g.addColorStop(1,mix(prev[1],v[1],k));c.fillStyle=g;c.fillRect(0,0,W,H);
    c.globalAlpha=k;c.fillStyle=c.strokeStyle=v[4];const s=v[2];
    if(s=='wave'){c.globalAlpha=.35*k;for(let j=0;j<4;j++){c.beginPath();for(let x=0;x<=W;x+=8)c.lineTo(x,H*(.55+j*.1)+Math.sin(x*.02+t*.002+j)*6);c.stroke()}c.globalAlpha=k}
    if(s=='cloud'){c.globalAlpha=.25*k;ps.slice(0,6).forEach(p=>{c.beginPath();c.ellipse(p.x*W,H*(.15+p.r*.3),90,22,0,0,7);c.fill()})}
    ps.forEach(p=>{const x=p.x*W,y=p.y*H;c.beginPath();
      if(s=='rain'){c.lineWidth=1;c.globalAlpha=.7*k;c.moveTo(x,y);c.lineTo(x-3,y+14);c.stroke()}
      else if(s=='petal'){c.globalAlpha=.85*k;c.ellipse(x,y,5,3,t*.003+p.p,0,7);c.fill()}
      else if(s=='star'||s=='fly'){c.globalAlpha=(.3+.7*Math.abs(Math.sin(t*.002+p.p)))*k;c.arc(x,y,s=='fly'?2.5:1.2+p.r,0,7);c.fill()}
      else if(s=='steam'){c.globalAlpha=.12*k;c.arc(x,y,14+p.r*18,0,7);c.fill()}
      else if(s=='snow'){c.globalAlpha=.85*k;c.arc(x,y,1.2+p.r*2.5,0,7);c.fill()}
      else return});
    c.globalAlpha=1}
  function step(){t+=16;fade=Math.min(1,fade+.03);const s=V[key][2];ps.forEach(p=>{const q=.6+p.r;
    if(s=='rain'){p.y+=.012*q;p.x-=.002*q}else if(s=='snow'){p.y+=.0016*q;p.x+=Math.sin(t*.001+p.p)*.0004}else if(s=='petal'){p.y+=.0012*q;p.x+=.0008*q+Math.sin(t*.002+p.p)*.0004}
    else if(s=='steam'){p.y-=.0012*q;p.x+=Math.sin(t*.002+p.p)*.0004}else if(s=='fly'){p.x+=Math.sin(t*.0008+p.p)*.0005;p.y+=Math.cos(t*.0009+p.p)*.0004}else if(s=='cloud'){p.x+=.0002*q}else if(s=='star'){p.x+=.00005}
    if(p.y>1)p.y=0;if(p.y<0)p.y=1;if(p.x>1)p.x=0;if(p.x<0)p.x=1})}
  const loop=()=>{raf=0;if(!vis)return;step();draw();if(!RM||fade<1)raf=requestAnimationFrame(loop)};
  const go=()=>{if(!raf)raf=requestAnimationFrame(loop)};
  const chips=(box,items,cb,start)=>{const el=root.querySelector(box);items.forEach((x,i)=>{const b=document.createElement('button');b.className='chip';b.textContent=x;b.setAttribute('aria-pressed',i==start);b.onclick=()=>{el.querySelectorAll('button').forEach(y=>y.setAttribute('aria-pressed','false'));b.setAttribute('aria-pressed','true');cb(i)};el.append(b)})};
  const pick=i=>{prev=V[key];key=presets[i].key;fade=0;reset();if(desc)desc.textContent=presets[i].description;go()};
  chips('[data-presets]',presets.map(p=>p.name),pick,0);chips('[data-quality]',Q.map(q=>q[0]),i=>{n=Q[i][1];reset();draw();go()},1);
  new IntersectionObserver(e=>{vis=e[0].isIntersecting;if(vis)go()}).observe(cv);new ResizeObserver(size).observe(cv);
  reset();if(desc)desc.textContent=presets[0].description;size();go();
}
