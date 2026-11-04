import{catImg}from'./sprites.js';
const RM=matchMedia('(prefers-reduced-motion:reduce)').matches;
const PR=[['5 min',5,0],['15 min',15,0],['30 min',30,0],['60 min',60,0],['Pomodoro 25/5',25,5],['Long Focus 50/10',50,10]];
export function initTimer(root){
  const $=s=>root.querySelector(s),cat=catImg($('img'),RM),tt=$('[data-time]'),st=$('[data-status]'),go=$('[data-go]'),rs=$('[data-reset]'),bar=$('[data-bar]');
  let i=4,phase='ready',left=PR[i][1]*60,end=0,iv=0,total=left;
  const fmt=s=>String(Math.floor(s/60)).padStart(2,'0')+':'+String(s%60).padStart(2,'0');
  const MSG={ready:'Ready. Choose a preset and start.',focus:'Focusing. Your companion rests.',paused:'Paused.',break:'Break time. Your companion celebrates.',done:'Session complete.'};
  function paint(){tt.textContent=fmt(Math.max(0,left));st.textContent=MSG[phase];bar.style.width=(100*(1-left/total))+'%';go.textContent=phase=='focus'||phase=='break'?'Pause':phase=='paused'?'Resume':'Start';go.disabled=phase=='done';
    cat.set(phase=='focus'?'sleep':phase=='break'?'jump':phase=='done'?'sit':'idle')}
  const stop=()=>{clearInterval(iv);iv=0};
  const tick=()=>{left=Math.round((end-Date.now())/1000);if(left<=0){stop();const b=PR[i][2];if(phase=='focus'&&b){phase='break';left=total=b*60;end=Date.now()+left*1000;iv=setInterval(tick,250)}else{phase='done';left=0}}paint()};
  let was='focus';
  go.onclick=()=>{if(phase=='focus'||phase=='break'){was=phase;stop();phase='paused';paint();return}
    if(phase=='paused'){phase=was}else{phase='focus';left=total=PR[i][1]*60}end=Date.now()+left*1000;iv=setInterval(tick,250);paint()};
  rs.onclick=()=>{stop();phase='ready';left=total=PR[i][1]*60;paint()};
  const box=$('[data-presets]');PR.forEach((p,k)=>{const b=document.createElement('button');b.className='chip';b.textContent=p[0];b.setAttribute('aria-pressed',k==i);b.onclick=()=>{box.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed','false'));b.setAttribute('aria-pressed','true');i=k;rs.onclick()};box.append(b)});
  paint();
}
