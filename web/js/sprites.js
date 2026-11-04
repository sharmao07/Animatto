// Loads the licensed Animatto sprite frames (see sprites/*/LICENSE.txt).
export const CAT={idle:[6,100],walk:[8,83],run:[6,55],sit:[4,125],sleep:[4,166],grooming:[6,100],jump:[4,66],fall:[4,83],land:[3,66]};
export const FISH={swim_idle:[6,100],swim_active:[8,71],dart:[4,50],feed:[4,83],rest:[4,166]};
const cache=new Map();
export function frames(dir,state,n){
  const k=dir+state;
  if(!cache.has(k))cache.set(k,Array.from({length:n},(_,i)=>{const im=new Image();im.decoding='async';im.src=`/sprites/${dir}/${state}/${state}_${String(i).padStart(2,'0')}.png`;return im}));
  return cache.get(k);
}
export const frameAt=(list,ms,t)=>list[Math.floor(t/ms)%list.length];
export const catFrames=s=>frames('cat',s,CAT[s][0]);
export const fishFrames=(sp,s)=>frames('aquarium/'+sp,s,FISH[s][0]);
// Animates an <img> with a cat state; returns {set(state), stop()}.
export function catImg(img,reduced){
  let st='idle',raf=0;
  const loop=t=>{const[n,ms]=CAT[st];const f=catFrames(st);const im=f[Math.floor(t/ms)%n];if(im.complete&&im.naturalWidth)img.src=im.src;raf=reduced?0:requestAnimationFrame(loop)};
  const set=s=>{st=s;cancelAnimationFrame(raf);const f=catFrames(s)[0];if(f.complete&&f.naturalWidth)img.src=f.src;else f.addEventListener('load',()=>{if(st==s)img.src=f.src},{once:true});if(!reduced)raf=requestAnimationFrame(loop)};
  set('idle');return{set,stop:()=>cancelAnimationFrame(raf)};
}
