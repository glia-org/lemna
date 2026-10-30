/* Lemna's website: the demo. An app window, then the use case as a loop: ⌃⌥Space, the dim and the box open, a
   sentence types itself on the gliding line, ⌘⏎, the hand-off, the sentence lands in the app. The reader can click
   into the box and write instead. The dim is plain there; Ambience ▸ Rain runs in its own smaller piece below. Every duration and curve is the app's (DESIGN.md F1, A1;
   app/Sources/LemnaCore/Effects.swift, Line.swift, Glide.swift, Handoff.swift, Scenes.swift). The page is complete
   without this file: it shows a still of the app instead. */
(function(){
'use strict';
var body=document.body,root=document.documentElement;
body.classList.remove('nojs');root.classList.add('js-on');
function $(id){return document.getElementById(id)}
var fit=$('fit'),stage=$('stage'),box=$('box'),dim=$('dim'),hint=$('hint'),ghost=$('ghost'),inp=$('ll-in'),pasted=$('pasted');
if(!fit||!stage||!box)return;
var reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
var Q='cubic-bezier(0.23, 1, 0.32, 1)',SW=1100,SH=620,rnd=Math.random;
var T={open:300,openScale:.87,close:200,glide:140,glyphFade:80,exit:200,stagger:7,staggerCap:120,lift:140,collapseAt:120,collapse:140,collapseScale:.9,paste:130};
function lerp(a,b,t){return a+(b-a)*t}
function logu(a,b){return a*Math.pow(b/a,rnd())}
/* easeOutQuint, cubic-bezier(0.23, 1, 0.32, 1): Glide.swift's Curve */
function ease(u){
  if(u<=0)return 0;if(u>=1)return 1;
  var x1=.23,y1=1,x2=.32,y2=1,cx=3*x1,bx=3*(x2-x1)-cx,ax=1-cx-bx,cy=3*y1,by=3*(y2-y1)-cy,ay=1-cy-by,t=u,i;
  function x(t){return((ax*t+bx)*t+cx)*t}function y(t){return((ay*t+by)*t+cy)*t}
  for(i=0;i<8;i++){var e=x(t)-u,s=(3*ax*t+2*bx)*t+cx;if(Math.abs(e)<1e-9)return y(t);if(Math.abs(s)<1e-6)break;t-=e/s}
  var lo=0,hi=1;t=u;for(i=0;i<60;i++){var v=x(t);if(Math.abs(v-u)<1e-9)break;if(v<u)lo=t;else hi=t;t=(lo+hi)/2}
  return y(t);
}
function anim(el,frames,o){return el.animate?el.animate(frames,o):null}

/* ---------- fit each 1100 × 620 stage into its place ---------- */
var fits=Array.prototype.slice.call(document.querySelectorAll('.fit'));
function scale(){fits.forEach(function(f){var st=f.querySelector('.stage'),s=Math.min(1,f.clientWidth/SW);st.style.transform=s<1?'scale('+s+')':''})}
scale();addEventListener('resize',scale);

/* ---------- the Ambience piece's rain on its dim: Ambience ▸ Rain (A1, pass 19b). Glyphs fixed in a grid of 18.5 px cells, lit by
   heads that step down a column a cell at a time, each cell dimming in place; born 20 s ahead at each show, falling
   until the close. One intensity, 0 at rest to 1 at 6 keys a second (keys of the last 2 s), rising with τ 0.25 s,
   settling with τ 1.2 s from 0.8 s after the last key. At rest / typing: 30 % / 70 % of the columns, 5–10 / 15–30 rows
   a second, trails 6–18 / 10–30 cells, head α 0.35 / 0.85 in the text colour, trail from 0.20 / 0.50 in the accent,
   0.3 / 1.5 glyph changes a second; 30 Hz at rest, 60 typing. A glyph key starts a head where its key is on the
   keyboard (an ANSI layout), the typed glyph at it at 0.95. */
var Rain=(function(){
  var cv=$('rain'),ctx=cv&&cv.getContext&&cv.getContext('2d');
  var none={start:function(){},stop:function(){},see:function(){},key:function(){},pulse:function(){}};
  if(!ctx)return none;
  var P=18.5,SET='012345789Zz:."=*+-<>|_',TEXT='#d8dce3',ACC='#7aa7f0';
  var KB=[['1234567890',1.5],['qwertyuiop',2],['asdfghjkl',2.25],['zxcvbnm',2.75]];
  var N=Math.ceil(SW/P),R=Math.ceil(SH/P),n=N*R,D=Math.min(window.devicePixelRatio||1,2);
  cv.width=SW*D;cv.height=SH*D;ctx.setTransform(D,0,0,D,0,0);
  ctx.textAlign='center';ctx.textBaseline='middle';ctx.font='14px '+getComputedStyle(body).fontFamily;
  var G=new Uint8Array(n),T0=new Float64Array(n),F=new Float32Array(n),TOP=new Float32Array(n),HD=new Uint8Array(n),u=[],drops=[];
  var I=0,C=0,now=0,last=-1e9,keys=[],raf=0,prev=0,on=false,seen=true;
  function light(c,r,d){if(r>=0&&r<R){var i=r*N+c;T0[i]=C;F[i]=d.L/(30*u[c]);TOP[i]=d.top}}
  function spawn(c,y,L,g,top){var d={y:y,L:L,g:g,top:top};drops[c].push(d);light(c,Math.floor(y),d)}
  function step(dt){
    now+=dt;
    while(keys.length&&now-keys[0]>=2)keys.shift();
    var tgt=Math.min(keys.length/2/6,1);
    if(tgt>I)I+=(tgt-I)*(1-Math.exp(-dt/.25));else if(now-last>=.8)I+=(tgt-I)*(1-Math.exp(-dt/1.2));
    var s=1/3+2/3*I,dc=dt*s,act=lerp(.3,.7,I),lo=lerp(6,10,I),hi=lerp(18,30,I),gap=I<.5?3:2,c,k,j,i;
    C+=dc;
    var lam=act*N*22.5*s/(R+(hi-lo)/Math.log(hi/lo));  // new heads a second: active × columns × speed ÷ (rows + trail)
    for(var q=lam*dt;rnd()<q;q--)for(var t=0;t<4;t++){c=rnd()*N|0;var ok=true;
      for(j=0;j<drops[c].length;j++)if(drops[c][j].y-drops[c][j].L<gap){ok=false;break}
      if(ok){spawn(c,0,logu(lo,hi),null,0);break}}
    for(c=0;c<N;c++){var v=30*u[c],keep=[];
      for(k=0;k<drops[c].length;k++){var d=drops[c][k],r0=Math.floor(d.y);d.y+=v*dc;
        for(var r=r0+1;r<=Math.floor(d.y);r++)light(c,r,d);
        if(d.y-d.L<R)keep.push(d)}
      drops[c]=keep}
    var m=lerp(.3,1.5,I)*dt;
    for(i=0;i<n;i++)if(C-T0[i]<F[i]&&rnd()<m)G[i]=rnd()*SET.length|0;
  }
  function draw(){
    ctx.clearRect(0,0,SW,SH);
    var tt=lerp(.2,.5,I),ha=lerp(.35,.85,I),i,c,k,d,r;
    HD.fill(0);
    for(c=0;c<N;c++)for(k=0;k<drops[c].length;k++){r=Math.floor(drops[c][k].y);if(r>=0&&r<R)HD[r*N+c]=1}
    ctx.fillStyle=ACC;
    for(i=0;i<n;i++){if(HD[i])continue;var a=(TOP[i]||tt)*(1-(C-T0[i])/F[i]);
      if(a>.02){ctx.globalAlpha=a;ctx.fillText(SET[G[i]],(i%N+.5)*P,((i/N|0)+.5)*P)}}
    ctx.fillStyle=TEXT;
    for(c=0;c<N;c++)for(k=0;k<drops[c].length;k++){d=drops[c][k];r=Math.floor(d.y);if(r<0||r>=R)continue;
      ctx.globalAlpha=d.g?.95:ha;ctx.fillText(d.g||SET[G[r*N+c]],(c+.5)*P,(r+.5)*P)}
    ctx.globalAlpha=1;
  }
  function birth(){
    for(var i=0;i<n;i++)G[i]=rnd()*SET.length|0;
    T0.fill(-1e9);F.fill(1);TOP.fill(0);u=[];drops=[];
    for(var c=0;c<N;c++){u.push(.5+.5*rnd());drops.push([])}
    I=0;C=0;now=0;last=-1e9;keys=[];
    for(var k=0;k<600;k++)step(1/30);  // 20 s ahead, undrawn: the box finds it falling
  }
  function frame(t){
    if(!on||!seen){raf=0;return}
    raf=requestAnimationFrame(frame);
    if(prev&&t-prev<1000/(I>.05?60:30)-4)return;
    var dt=prev?Math.min((t-prev)/1000,.1):1/60;prev=t;step(dt);draw();
  }
  function go(){if(on&&seen&&!reduced&&!raf){prev=0;raf=requestAnimationFrame(frame)}}
  return {
    start:function(){birth();draw();on=true;go()},
    stop:function(){on=false;if(raf)cancelAnimationFrame(raf);raf=0},
    see:function(v){seen=v;go()},
    key:function(ch){
      keys.push(now);last=now;
      var low=ch.toLowerCase(),at=null;
      KB.forEach(function(row,ri){var i=row[0].indexOf(low);if(i>=0)at={across:(row[1]+i)/15,down:ri/4}});
      if(at&&on&&!reduced)spawn(Math.min(N-1,Math.floor(N*(.1+.8*at.across))),Math.floor(R*(.05+.4*at.down)),logu(8,20),ch,.55);
    },
    pulse:function(){keys.push(now);last=now}
  };
})();

/* ---------- the key sounds: the Keychron pack's (CC0), played as lib/LemnaClicks plays them: never the same sample
   twice in a row, the rate within ±3 %, volume 0.6; the send at ⌘⏎. Off until the reader turns them on. Web Audio
   where the files can be fetched, audio elements where they cannot (a page opened from disk). */
var Sound=(function(){
  var btn=$('snd');
  var FILES={letter:['letter-1','letter-3','letter-5'],space:['space-1'],backspace:['backspace-1'],send:['send-1']};
  var on=false,ac=null,gain=null,buf={},els={},lastPick={},loaded=false;
  function src(n){return 'assets/snd/'+n+'.wav'}
  function load(){
    if(loaded)return;loaded=true;
    var names=[];Object.keys(FILES).forEach(function(k){names=names.concat(FILES[k])});
    names.forEach(function(n){var a=new Audio(src(n));a.preload='auto';els[n]=a});
    var AC=window.AudioContext||window.webkitAudioContext;if(!AC||!window.fetch)return;
    try{ac=new AC();gain=ac.createGain();gain.gain.value=.6;gain.connect(ac.destination)}catch(e){ac=null;return}
    names.forEach(function(n){
      fetch(src(n)).then(function(r){if(!r.ok)throw 0;return r.arrayBuffer()})
        .then(function(b){return new Promise(function(ok,no){ac.decodeAudioData(b,ok,no)})})
        .then(function(d){buf[n]=d},function(){});
    });
  }
  function label(){btn.textContent=on?'sound: on':'sound: off';btn.setAttribute('aria-pressed',String(on))}
  if(btn){btn.addEventListener('click',function(){on=!on;if(on){load();if(ac&&ac.state==='suspended')ac.resume()}label()});label()}
  return {play:function(kind){
    if(!on)return;var list=FILES[kind],n=list.length,p=0;
    if(n>1){p=rnd()*(lastPick[kind]==null?n:n-1)|0;if(lastPick[kind]!=null&&p>=lastPick[kind])p++}
    lastPick[kind]=p;var name=list[p],rate=1+(2*rnd()-1)*.03;
    if(ac&&buf[name]){var s=ac.createBufferSource();s.buffer=buf[name];s.playbackRate.value=rate;s.connect(gain);s.start();return}
    var a=els[name]&&els[name].cloneNode();if(!a)return;
    a.volume=.6;a.preservesPitch=false;a.webkitPreservesPitch=false;a.playbackRate=rate;
    var pr=a.play();if(pr&&pr.catch)pr.catch(function(){});
  }};
})();

/* ---------- the line: the band and its glide (Line.swift, Glide.swift). Two offsets: the edit's moves only the text
   before the caret (an insertion pushes it left, a deletion glides it back), the caret move's moves both parts; each
   restarts from what remains of it plus the new step, a remainder in the same direction capped at one step, and eases
   to 0 over 140 ms. The newest glyph fades in over 80 ms. Reduced motion jumps. */
var Line=(function(){
  var bEl=box.querySelector('.ll-b>span'),aEl=box.querySelector('.ll-a>span');
  var text=[],caret=0,adv=0,edit={from:0,start:0},move={from:0,start:0},raf=0;
  function measure(){var s=document.createElement('span');s.textContent='MMMMMMMMMM';
    s.style.cssText='position:absolute;visibility:hidden;white-space:pre';box.appendChild(s);
    adv=s.getBoundingClientRect().width/10/(fit.clientWidth/SW>=1?1:fit.clientWidth/SW);box.removeChild(s)}
  function off(g,t){return g.from*(1-ease((t-g.start)/T.glide))}
  function add(g,dw,t){if(reduced){g.from=0;return}
    var r=off(g,t),c=Math.abs(dw);if(r*dw>0)r=dw>0?Math.min(r,c):Math.max(r,-c);g.from=r+dw;g.start=t}
  function esc(ch){return ch==='<'?'&lt;':ch==='>'?'&gt;':ch==='&'?'&amp;':ch}
  function render(fresh){
    var h='',i;
    for(i=Math.max(0,caret-120);i<caret;i++)h+=fresh&&i===caret-1?'<span class="new">'+esc(text[i])+'</span>':esc(text[i]);
    bEl.innerHTML=h;var a='';for(i=caret;i<Math.min(text.length,caret+120);i++)a+=esc(text[i]);aEl.innerHTML=a;
  }
  function paint(t){var m=off(move,t),e=off(edit,t);
    bEl.style.transform='translateX('+(e+m).toFixed(2)+'px)';aEl.style.transform='translateX('+m.toFixed(2)+'px)';
    return t<edit.start+T.glide||t<move.start+T.glide}
  function loop(t){raf=paint(t)?requestAnimationFrame(loop):0}
  function moved(){if(paint(performance.now())&&!raf)raf=requestAnimationFrame(loop)}  // drawn on the key event
  measure();
  return {
    text:function(){return text.join('')},
    set:function(s){text=Array.from(s);caret=text.length;edit.from=move.from=0;render(false);moved()},
    insert:function(ch){text.splice(caret,0,ch);caret++;add(edit,adv,performance.now());render(true);moved()},
    back:function(){if(!caret)return;text.splice(caret-1,1);caret--;add(edit,-adv,performance.now());render(false);moved()},
    left:function(){if(!caret)return;caret--;add(move,-adv,performance.now());render(false);moved()},
    right:function(){if(caret>=text.length)return;caret++;add(move,adv,performance.now());render(false);moved()},
    /* the glyphs as they show, for the hand-off (Handoff.pieces): x in the box, the V2 fade's alpha, the rank from the
       caret outwards (the text after the caret sets off at once) */
    pieces:function(W){
      var t=performance.now(),e=off(edit,t),m=off(move,t),out=[],i,x,mid,a,k=0,cx=.6*W;
      var right=cx+e+m;
      for(i=caret-1;i>=0;i--){x=right-adv;mid=x+adv/2;a=Math.min(Math.max((mid-.25*W)/(.2*W),0),1);
        if(x+adv<=0||a<=0)break;if(x<cx)out.push({x:x,ch:text[i],a:a,rank:k});k++;right=x}
      x=cx+2+m;
      for(i=caret;i<text.length;i++){mid=x+adv/2;a=Math.min(Math.max((.95*W-mid)/(.15*W),0),1);
        if(x>=.95*W||a<=0)break;out.push({x:x,ch:text[i],a:a,rank:0});x+=adv}
      return out;
    }
  };
})();

/* ---------- the box: open, close, hand-off (F1: P1, H1) ---------- */
var up=false,gen=0;
function cancelAnims(){[box,dim].forEach(function(el){if(el.getAnimations)el.getAnimations().forEach(function(a){a.cancel()})})}
function show(){
  cancelAnims();up=true;box.classList.add('up');box.classList.remove('off');dim.classList.add('up');
  if(!reduced){  // 300 ms from 87 % with a fade, the dim with it
    anim(box,[{opacity:0,transform:'scale('+T.openScale+')'},{opacity:1,transform:'none'}],{duration:T.open,easing:Q});
    anim(dim,[{opacity:0},{opacity:1}],{duration:T.open,easing:Q});
  }
}
function hideNow(){cancelAnims();up=false;box.classList.remove('up');box.classList.remove('off');dim.classList.remove('up');ghost.innerHTML=''}
function closeFade(){  // Esc, a click outside: a 200 ms fade, the dim with it
  if(!up)return;if(reduced)return hideNow();
  up=false;var g=++gen;
  anim(box,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'});
  anim(dim,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'});
  setTimeout(function(){if(g===gen)hideNow()},T.close);
}
/* R1, the fixed pass applied to what goes out: runs of spaces become one, no trailing space, a capital at the start
   and after a sentence's end, a lone i becomes I */
function tidy(s){
  return s.replace(/ {2,}/g,' ').trim().replace(/(^|[.!?] )([a-z])/g,function(m,a,b){return a+b.toUpperCase()})
    .replace(/(^| )i(?=[ ,.;:!?]|$)/g,'$1I');
}
function paste(s){
  if(!s)return;var cur=pasted.textContent;
  pasted.textContent=(cur?cur+' ':'')+s;
  if(pasted.textContent.length>300)pasted.textContent='…'+pasted.textContent.slice(-300);
}
/* ⌘⏎: the send sound at the key-down; from the caret outwards each glyph leaves off the box's right edge, travelling
   the box's width on the curve over 200 ms, each 7 ms after its neighbour nearer the caret, those past 120 ms with the
   last; the caret goes at once; the dim lifts over 140 ms; from 120 ms the box shrinks to 90 % and fades over 140 ms,
   260 ms in all. The ⌘V lands at about 130 ms (Return's key-up and the 30 ms settle) and waits for none of it. */
function handOff(){
  var s=tidy(Line.text());if(!s||!up)return false;
  Sound.play('send');
  var g=++gen;
  if(reduced){hideNow();paste(s);Line.set('');return true}
  var W=box.clientWidth,ps=Line.pieces(W);
  box.classList.add('off');ghost.innerHTML='';cancelAnims();
  ps.forEach(function(p){
    var el=document.createElement('span');el.textContent=p.ch;el.style.left=p.x.toFixed(2)+'px';el.style.opacity=p.a;ghost.appendChild(el);
    anim(el,[{transform:'translateX(0)'},{transform:'translateX('+W+'px)'}],{duration:T.exit,delay:Math.min(p.rank*T.stagger,T.staggerCap),easing:Q,fill:'forwards'});
  });
  anim(dim,[{opacity:1},{opacity:0}],{duration:T.lift,easing:Q,fill:'forwards'});
  anim(box,[{opacity:1,transform:'none'},{opacity:0,transform:'scale('+T.collapseScale+')'}],{duration:T.collapse,delay:T.collapseAt,easing:Q,fill:'forwards'});
  setTimeout(function(){paste(s)},T.paste);
  setTimeout(function(){if(g!==gen)return;hideNow();Line.set('')},T.collapseAt+T.collapse);
  return true;
}

/* ---------- key hints ---------- */
function hintShow(html){hint.innerHTML=html;if(reduced){hint.style.opacity=1;return}
  if(hint.getAnimations)hint.getAnimations().forEach(function(a){a.cancel()});
  anim(hint,[{opacity:0},{opacity:1}],{duration:T.glide,easing:Q,fill:'forwards'})}
function hintHide(){if(hint.getAnimations)hint.getAnimations().forEach(function(a){a.cancel()});
  if(reduced){hint.style.opacity=0;return}
  anim(hint,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'})}

/* ---------- keys, from the loop or the reader ---------- */
function key(ch){
  if(ch==='\b'){Line.back();Sound.play('backspace');return}
  Line.insert(ch);Sound.play(ch===' '?'space':'letter');
}

/* ---------- the loop: about 17 s ---------- */
var SEQ='Move the review to Thursday at ten and send teh\b\bhe draft first.';
var timers=[],mode='auto',idleT=0;
function later(ms,f){var id=setTimeout(function(){var i=timers.indexOf(id);if(i>=0)timers.splice(i,1);f()},ms);timers.push(id)}
function cancelTimers(){timers.forEach(clearTimeout);timers=[]}
function gap(prev,ch){  // a human pace: 90–200 ms a key, longer after a space or a full stop, a pause before fixing a typo
  if(ch==='\b')return prev==='\b'?130:420;
  var g=90+rnd()*110;if(prev===' ')g+=rnd()*150;if(prev==='.'||prev===',')g+=260;return g;
}
function loop(){
  mode='auto';pasted.textContent='';if(pasted.getAnimations)pasted.getAnimations().forEach(function(a){a.cancel()});
  var t=600;later(t,function(){hintShow('<kbd>⌃⌥Space</kbd>')});
  t+=600;later(t,show);
  later(t+300,hintHide);
  t+=T.open+500;
  var prev='';Array.from(SEQ).forEach(function(ch){t+=gap(prev,ch);prev=ch;later(t,function(){key(ch)})});
  t+=900;later(t,function(){hintShow('<kbd>⌘⏎</kbd>')});
  t+=600;later(t,handOff);
  later(t+500,hintHide);
  t+=T.collapseAt+T.collapse+2000;
  later(t,function(){anim(pasted,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'})});
  later(t+T.close,loop);
}
function still(){  // reduced motion: one frame of the box over the dimmed app, the key hints as labels
  mode='still';pasted.textContent='';show();Line.set(SEQ.replace('teh\b\bhe','the'));
  hintShow('<kbd>⌃⌥Space</kbd><span>opens the box</span><kbd>⌘⏎</kbd><span>sends the text into the app</span>');
}
function idle(){clearTimeout(idleT);idleT=setTimeout(resume,10000)}
function resume(){  // 10 s without the reader: the loop again, unless a sentence of theirs is still in the box
  if(document.activeElement===inp&&Line.text()){idle();return}
  inp.blur();hideNow();Line.set('');reduced?still():loop();
}
function takeOver(){  // the reader's turn: the loop stops, the box is theirs and empty
  if(mode!=='user'){
    cancelTimers();gen++;hintHide();mode='user';
    if(up&&!box.classList.contains('off')){cancelAnims();box.classList.add('up');dim.classList.add('up')}  // open already: it stays
    else{hideNow();show()}
    Line.set('');
  }else if(!up)show();
  inp.focus({preventScroll:true});idle();
}

stage.addEventListener('pointerdown',function(e){
  if(mode==='user'&&up&&!box.contains(e.target)){closeFade();inp.blur();idle();e.preventDefault();return}  // a click outside hides it
  if(e.target!==inp)e.preventDefault();
  takeOver();
});
stage.addEventListener('keydown',function(e){if(e.target===stage&&(e.key==='Enter'||e.key===' ')){e.preventDefault();takeOver()}});
inp.addEventListener('focus',function(){if(mode!=='user')takeOver()});
inp.addEventListener('keydown',function(e){
  if(e.isComposing)return;idle();
  if(e.key==='Enter'){e.preventDefault();if(handOff())inp.blur();return}  // ⏎ or ⌘⏎ sends
  if(e.metaKey||e.ctrlKey||e.altKey)return;
  if(e.key==='Backspace'){e.preventDefault();key('\b')}
  else if(e.key==='ArrowLeft'){e.preventDefault();Line.left()}
  else if(e.key==='ArrowRight'){e.preventDefault();Line.right()}
  else if(e.key==='Escape'){e.preventDefault();closeFade();inp.blur()}
});
function typed(){var v=inp.value;inp.value='';Array.from(v).forEach(function(ch){if(ch>=' ')key(ch)})}
inp.addEventListener('input',function(e){if(!e.isComposing)typed()});
inp.addEventListener('compositionend',typed);

/* start the loop when the demo is first in view */
var started=false;
function begin(){if(started)return;started=true;reduced?still():loop()}
if('IntersectionObserver' in window)new IntersectionObserver(function(es){if(es[0].isIntersecting)begin()}).observe(fit);
else begin();

/* ---------- the Ambience piece: Rain at rest on the dim around a box with a still sentence, raised every 7 s by
   ten keys at about 6 a second, as if a few words were typed, so it shows how it reacts. It draws only while in
   view; under reduced motion one still frame. */
(function(){
  var f2=$('fit2');if(!f2)return;
  var LET='qwertyuiopasdfghjklzxcvbnm',seen=false,born=false;
  function burst(){if(!seen||document.hidden)return;var i=0;
    (function next(){if(i++>=10)return;Rain.key(LET[rnd()*LET.length|0]);setTimeout(next,140+rnd()*60)})()}
  function view(v){seen=v;if(v&&!born){born=true;Rain.start();if(!reduced){setTimeout(burst,2500);setInterval(burst,7000)}}Rain.see(v)}
  if('IntersectionObserver' in window)new IntersectionObserver(function(es){view(es[0].isIntersecting)}).observe(f2);
  else view(true);
})();
})();
