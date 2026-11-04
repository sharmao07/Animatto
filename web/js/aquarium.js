import{FISH,fishFrames,frameAt}from'./sprites.js';
export const THEMES=[['Tropical Coral Reef','#1c8ca0','#0b3550','#3aa874'],['Freshwater Riverbed','#6aa58a','#26443a','#9bc27a'],['Midnight Abyss','#2a2f6b','#070a20','#6b5bd6'],['Sunset Lagoon','#f08a5d','#4a2c63','#7acb86']];
export const SIZES=[['Small',1.15,56],['Medium',1.6,78],['Large',2.1,100],['Panoramic',3.2,100]];
const SP=[['sunfin','Finny',.3],['puffer','Pip',.26],['tetra','Glow',.2],['tetra','Glow',.2],['tetra','Glow',.2],['hermitcrab','Barnaby',.24]];
export function initAquarium(cv,o={}){
  const c=cv.getContext('2d'),RM=matchMedia('(prefers-reduced-motion:reduce)').matches,R=Math.random;
  let W=1,H=1,th=THEMES[0],pel=[],bub=[],rip=[],m=null,t=0,raf=0,until=0,vis=true,say=()=>{};
  const fish=SP.map(([sp,name,sz],i)=>({sp,name,sz,x:.15+R()*.7,y:.25+R()*.4,vx:(R()<.5?-1:1)*(.0012+R()*.001),vy:0,ph:R()*9,dart:0,eat:0,crab:sp=='hermitcrab'}));
  const size=()=>{const d=devicePixelRatio||1;W=cv.clientWidth||1;H=cv.clientHeight||1;cv.width=W*d;cv.height=H*d;c.setTransform(d,0,0,d,0,0);draw()};
  function step(){t+=16;const g=fish.filter(f=>f.sp=='tetra'),cx=g.reduce((a,f)=>a+f.x,0)/g.length,cy=g.reduce((a,f)=>a+f.y,0)/g.length;
    for(const f of fish){f.dart=Math.max(0,f.dart-16);f.eat=Math.max(0,f.eat-16);
      if(f.crab){f.y=.86;f.x+=f.vx*.3;if(f.x<.08||f.x>.92)f.vx*=-1;continue}
      let ax=0,ay=Math.sin(t*.002+f.ph)*.00003;const p=pel.filter(q=>q.y<.85).sort((a,b)=>Math.hypot(a.x-f.x,a.y-f.y)-Math.hypot(b.x-f.x,b.y-f.y))[0];
      if(p){ax+=(p.x-f.x)*.0007;ay+=(p.y-f.y)*.0007;if(Math.hypot((p.x-f.x)*W,(p.y-f.y)*H)<H*.1){pel.splice(pel.indexOf(p),1);f.eat=400;say(f.name+' ate a pellet.')}}
      else if(m){const dx=m.x-f.x,dy=m.y-f.y,d=Math.hypot(dx,dy);
        if(f.sp=='puffer'&&d<.25){ax-=dx*.0006;ay-=dy*.0006}
        else if(f.sp=='sunfin'&&d<.5){const k=d>.14?.0005:-.0003;ax+=dx*k;ay+=dy*k}
        else if(f.sp=='tetra'&&d<.4){ax+=dx*.0002;ay+=dy*.0002}}
      if(f.sp=='tetra'){ax+=(cx-f.x)*.00005;ay+=(cy-f.y)*.00005}
      f.vx=Math.max(-.005,Math.min(.005,(f.vx+ax)*.998));f.vy=Math.max(-.003,Math.min(.003,(f.vy+ay)*.99));
      if(Math.abs(f.vx)<.0008)f.vx=(f.vx<0?-1:1)*.0008;f.x+=f.vx;f.y+=f.vy;
      if(f.x<.06){f.x=.06;f.vx=Math.abs(f.vx)}if(f.x>.94){f.x=.94;f.vx=-Math.abs(f.vx)}f.y=Math.max(.14,Math.min(.72,f.y))}
    pel.forEach(q=>q.y+=.0016);pel=pel.filter(q=>q.y<.9);
    if(R()<.04)bub.push({x:.1+R()*.8,y:.92,r:1+R()*2.5});bub.forEach(b=>b.y-=.0028);bub=bub.filter(b=>b.y>0);
    rip.forEach(r=>r.a+=.02);rip=rip.filter(r=>r.a<1)}
  function draw(){const u=H/200;let g=c.createLinearGradient(0,0,0,H);g.addColorStop(0,th[1]);g.addColorStop(1,th[2]);c.fillStyle=g;c.fillRect(0,0,W,H);
    c.fillStyle='#ffffff10';[.2,.5,.75].forEach((x,i)=>{c.beginPath();c.moveTo(x*W,0);c.lineTo(x*W+W*.06,0);c.lineTo(x*W-W*.1+Math.sin(t*.0004+i)*10,H);c.lineTo(x*W-W*.2,H);c.fill()});
    c.fillStyle='#d8c28f88';c.fillRect(0,H*.93,W,H*.07);c.strokeStyle=th[3];c.lineWidth=3*u;
    [.07,.19,.8,.92].forEach((x,i)=>{const s=Math.sin(t*.002+i)*8*u;c.beginPath();c.moveTo(x*W,H*.95);c.quadraticCurveTo(x*W+s,H*.8,x*W+s*1.4,H*(.66+i%2*.08));c.stroke()});
    c.fillStyle='#6b6f78';c.beginPath();c.ellipse(W*.52,H*.96,20*u,9*u,0,0,7);c.fill();
    c.strokeStyle='#fff8';c.lineWidth=1;bub.forEach(b=>{c.beginPath();c.arc(b.x*W,b.y*H,b.r*u,0,7);c.stroke()});
    c.fillStyle='#c58a4a';pel.forEach(q=>{c.beginPath();c.arc(q.x*W,q.y*H,2.2*u,0,7);c.fill()});
    fish.slice().sort((a,b)=>a.sz-b.sz).forEach(f=>{const st=f.dart?'dart':f.eat?'feed':f.crab?'swim_idle':Math.abs(f.vx)>.0022?'swim_active':'swim_idle';
      const[,ms]=FISH[st],im=frameAt(fishFrames(f.sp,st),ms,t+f.ph*100),s=f.sz*H*(o.mini?1.25:1);
      if(!(im.complete&&im.naturalWidth))return;c.save();c.translate(f.x*W,f.y*H);if(f.vx<0)c.scale(-1,1);c.drawImage(im,-s/2,-s/2,s,s);c.restore()});
    rip.forEach(r=>{c.strokeStyle=`rgba(255,255,255,${.5*(1-r.a)})`;c.lineWidth=2;c.beginPath();c.arc(r.x*W,r.y*H,r.a*W*.25,0,7);c.stroke()});
    g=c.createLinearGradient(0,0,W,H);g.addColorStop(0,'#ffffff26');g.addColorStop(.3,'#ffffff00');c.fillStyle=g;c.fillRect(0,0,W,H)}
  const loop=()=>{raf=0;if(!vis)return;step();draw();if(!RM||performance.now()<until)raf=requestAnimationFrame(loop);};
  const go=ms=>{until=performance.now()+ms;if(!raf)raf=requestAnimationFrame(loop)};
  new IntersectionObserver(e=>{vis=e[0].isIntersecting;if(vis&&!RM&&!raf)go(0)}).observe(cv);
  new ResizeObserver(size).observe(cv);size();
  cv.addEventListener('pointermove',e=>{const r=cv.getBoundingClientRect();m={x:(e.clientX-r.left)/W,y:(e.clientY-r.top)/H};if(RM)go(1500)});
  cv.addEventListener('pointerleave',()=>m=null);
  const tap=(x=.5,y=.5)=>{rip.push({x,y,a:0});fish.forEach(f=>{f.dart=500;if(!f.crab){f.vx+=(f.x<x?-1:1)*.003;f.vy+=(f.y<y?-1:1)*.0015}});say('Glass tap! Everyone darts away.');go(1500)};
  cv.addEventListener('click',e=>{const r=cv.getBoundingClientRect();tap((e.clientX-r.left)/W,(e.clientY-r.top)/H)});
  size();go(RM?400:Infinity);
  return{theme:i=>{th=THEMES[i];draw()},feed(){for(let i=0;i<5;i++)pel.push({x:.2+R()*.6,y:.05+i*.03});say('Food pellets dropped.');go(5000)},tap,onSay:f=>say=f};
}
