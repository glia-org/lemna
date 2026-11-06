/* Lemna's website: the demo, as a fresh install looks (passes 32-34: the Still theme by the system's appearance, Code
   on the dim, the Lab bed, every effect on). An app window, then the use case as a loop: ⌃⌥Space, the dim and the box
   fade in, Code builds in on the dim, a sentence and a second paragraph type themselves on the gliding line, ⌘⏎, the
   box fades while MO1's ring leaves its outline and the wash lifts, the text lands in the app. The reader can click
   into the box and write instead. Below, Ambience ▸ Code and Still water run in their own smaller pieces. Every
   duration, curve and magnitude is the app's (DESIGN.md TH1, F1, A1; app/Sources/LemnaCore/Theme.swift, Effects.swift,
   Line.swift, Glide.swift, Handoff.swift, Ambience.swift's Tuning, Scenes.swift), the scenes ported from Scenes.swift
   to a 2D canvas at the stage's own resolution. The page is complete without this file: it shows stills of the app's
   renders instead. */
(function(){
'use strict';
var body=document.body,root=document.documentElement;
body.classList.remove('nojs');root.classList.add('js-on');
function $(id){return document.getElementById(id)}
var fit=$('fit'),stage=$('stage'),box=$('box'),dim=$('dim'),ringEl=$('ring'),hint=$('hint'),inp=$('ll-in'),pasted=$('pasted');
if(!fit||!stage||!box)return;
var reduced=matchMedia('(prefers-reduced-motion: reduce)').matches,darkQ=matchMedia('(prefers-color-scheme: dark)');
var Q='cubic-bezier(0.23, 1, 0.32, 1)',SW=1100,SH=620,rnd=Math.random;
/* Effects.Tuning: the open and the close (Still's P1, fades), the glide, the glyph and paragraph fades; the paste about
   130 ms after ⌘⏎'s key-down, Return's key-up before it; MO1's ring */
var T={open:300,close:200,glide:140,paste:130,keyUp:100,ringLife:1.2,ringSpeed:60,ringOnset:.18};
/* Theme.still's ink (A1's C1): one colour for heads and trails, laid over at 0.6 by day, added at 0.5 by night; MO1's
   ring peak by day and by night */
var STILL={day:{ink:'#3f4a3c',add:false,inkA:.6,ringPeak:.18},night:{ink:'#c9d3c4',add:true,inkA:.5,ringPeak:.08}};
function palette(){return darkQ.matches?STILL.night:STILL.day}
var SERIF='Literata, Charter, "Iowan Old Style", Georgia, serif';
var MONO='Menlo, ui-monospace, "SF Mono", SFMono-Regular, Consolas, "DejaVu Sans Mono", monospace';
var KANAF='"Hiragino Sans", "Hiragino Kaku Gothic ProN", "Yu Gothic", "Noto Sans JP", "Noto Sans CJK JP", Meiryo, sans-serif';
function lerp(a,b,t){return a+(b-a)*t}
function mix(r,u){return r[0]+(r[1]-r[0])*u}
function logu(a,b){return a*Math.pow(b/a,rnd())}
function smooth(u){u=Math.min(Math.max(u,0),1);return u*u*(3-2*u)}
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
function cancel(el){if(el.getAnimations)el.getAnimations().forEach(function(a){a.cancel()})}

/* ---------- the Ambience tiles: each a copy of the same stage (the dimmed note, the box, a still sentence) ---------- */
var tpl=$('tile-stage');
Array.prototype.forEach.call(document.querySelectorAll('.tile'),function(t){if(tpl&&tpl.content)t.appendChild(tpl.content.cloneNode(true))});
function tileCanvas(mode){var t=document.querySelector('.tile[data-mode="'+mode+'"]');return t&&t.querySelector('canvas')}

/* ---------- fit each 1100 × 620 stage into its place; each scene's canvas at the pixels it shows ---------- */
var fits=Array.prototype.slice.call(document.querySelectorAll('.fit')),scenes=[];
function scale(){
  fits.forEach(function(f){var st=f.querySelector('.stage'),s=Math.min(1,f.clientWidth/SW);f.fitScale=s;st.style.transform=s<1?'scale('+s+')':''});
  scenes.forEach(function(sc){sc.resize()});
}
function pixels(cv){var f=cv.closest('.fit');return (f&&f.fitScale||1)*Math.min(window.devicePixelRatio||1,2)}

/* where a key is on a MacBook's main block (Keyboard.swift, ANSI): its row (0 the number row, 4 the space bar's) and
   the middle of its column in key units (0 to 15) */
var KEYPOS=(function(){var t={};
  function row(r,keys,first){keys.split('').forEach(function(c,i){t[c]={row:r,column:first+i,width:1}})}
  row(0,'1234567890',1.5);row(1,'qwertyuiop',2);row(2,'asdfghjkl',2.25);row(3,'zxcvbnm,.',2.75);
  t[' ']={row:4,column:6.75,width:5};return t})();
function keyAt(ch){return KEYPOS[ch.toLowerCase()]||null}
/* the box on the stage (BoxFrame.line: 60 % of a 1512 pt screen, 4 × Literata 30, its centre two thirds down), the
   caret's x in it */
var B={x:96,y:353,w:907,h:120},CARET=B.x+1+.6*(B.w-2),SPAN=[.1,.9];
function screenX(k){return k?SW*mix(SPAN,k.column/15):null}

/* ---------- Ambience ▸ Code (A1; pass 27 the dense curtain, pass 27b its build-in and lift), Scenes.swift's
   Code: glyphs of K1's set and 46 half-width katakana, mirrored, fixed in a grid of square cells half the atlas cell
   high (Menlo at the line's 30, 19.5 px), at 0.6 of the line's size; a nearer sheet over it 1.6 times larger, sampled
   1.5 mipmap levels softer (here an atlas drawn at 2^-1.5 of its pixels, scaled up) and 1.6 times brighter. Heads step
   down the columns a cell at a time, each column at its own 8–16 rows a second, about 0.8 heads a column for each
   1,000 px of height at rest and 1.6 typing, some starting lower down; each cell a head enters lit in the ink and
   dimming in place over its trail of 30–150 cells (40–200 typing), at its stream's gain and its own brightness, the
   two right behind the head at 0.7 and 0.49 of it; a halo under each head where light adds (Still by night). One
   intensity, 0 at rest, 1 at 6 keys a second, up with τ 0.15 s, down with τ 1.5 s from 0.8 s after the last key,
   sets heads, trails, brightness and glyph changes, never speed; each glyph key starts a head where it is on the
   keyboard, the typed glyph at it as typed. Born 20 s stepped ahead at each show, veiled, and built in over 4 s on a
   smoothstep while new heads fall in at once. 30 Hz at rest, 60 typing; at most `cap` glyphs a frame, the dimmest
   going first. */
var KANA=[0xFF66];for(var u=0xFF71;u<=0xFF9D;u++)KANA.push(u);
var CODESET='012345789Zz:."=*+-<>|_'.split('').concat(KANA.map(function(u){return String.fromCharCode(u)})),NSET=CODESET.length;
var LINE=30,CELLW=LINE*.602+4,CELLH=LINE*1.164+4;  // Menlo's advance and its ascent + descent at the line's size, 2 px pad round each
var C={speed:[8,16],active:[.8,1.6],height:1000,most:3,gap:[8,5],wait:[.5,1.5],high:.3,highRows:[.05,.6],
  trail:[[30,150],[40,200]],head:[.8,1],neck:.7,top:[.5,.9],gain:[.3,2],level:[.3,1],skew:1.5,halo:[.22,.4],haloW:.8,
  change:[.5,3],near:1.6,nearActive:[.06,.15],nearBright:1.6,nearBlur:1.5,keyHead:1,keyHalo:.7,keyTop:1,keyTrail:[20,60],
  fast:6,rise:.15,settle:1.5,hold:.8,ahead:20,idleRate:30,calm:.05,shown:.02,buildIn:4,keyRows:[.55,.95]};
function level(){return mix(C.level,Math.pow(rnd(),C.skew))}
function Sheet(depth,blur,bright,active){
  var p=CELLH*.5*depth,cols=Math.max(1,Math.floor(SW/p)),rows=Math.max(1,Math.ceil(SH/p)),n=cols*rows,i,c;
  this.pitch=p;this.columns=cols;this.rows=rows;this.left=(SW-cols*p)/2;this.scale=.6*depth;this.blur=blur;this.bright=bright;
  this.active=active;
  this.xs=new Float32Array(cols);for(c=0;c<cols;c++)this.xs[c]=this.left+(c+.5)*p;
  this.ys=new Float32Array(rows);for(i=0;i<rows;i++)this.ys[i]=(i+.5)*p;
  this.glyph=new Uint8Array(n);this.level=new Float32Array(n);this.lit=new Float64Array(n);this.trail=new Float32Array(n);
  this.top=new Float32Array(n);this.gain=new Float32Array(n);this.under=new Uint8Array(n);this.veiled=new Uint8Array(n);
  for(i=0;i<n;i++){this.glyph[i]=rnd()*NSET|0;this.level[i]=level();this.lit[i]=-Infinity;this.trail[i]=1;this.gain[i]=1}
  this.speed=new Float32Array(cols);this.travel=new Float64Array(cols);this.moved=new Float32Array(cols);
  this.falling=new Int16Array(cols);this.due=new Float32Array(cols);this.wait=new Float32Array(cols);
  for(c=0;c<cols;c++){this.speed[c]=mix(C.speed,rnd());this.wait[c]=mix(C.wait,rnd());this.due[c]=this.wait[c]*rnd()}
  this.heads=[];this.veiling=true;
  this.most=Math.max(C.most,Math.round(C.most*rows*p/C.height));this.limit=(this.most+1)*cols;
}
Sheet.prototype.light=function(c,r,t,a,g,v){var x=c*this.rows+r;
  this.lit[x]=this.travel[c];this.trail[x]=t;this.top[x]=a;this.gain[x]=g;this.veiled[x]=v?1:0};
Sheet.prototype.advance=function(dt,I){
  var cols=this.columns,rows=this.rows,hs=this.heads,c,k,h,r;
  for(c=0;c<cols;c++){this.moved[c]=this.speed[c]*dt;this.travel[c]+=this.moved[c]}
  for(k=0;k<hs.length;){h=hs[k];var from=Math.floor(h.row);h.row+=this.moved[h.column];var to=Math.floor(h.row);
    if(to>from&&from+1<rows)for(r=from+1;r<=Math.min(to,rows-1);r++)this.light(h.column,r,h.trail,h.key?C.keyTop:0,h.gain,h.veiled);
    if(to>=rows){if(!h.key)this.falling[h.column]--;hs[k]=hs[hs.length-1];hs.pop();continue}  // its trail lingers
    k++}
  var lo=lerp(C.trail[0][0],C.trail[1][0],I),hi=lerp(C.trail[0][1],C.trail[1][1],I),gap=lerp(C.gap[0],C.gap[1],I);
  var act=lerp(this.active[0],this.active[1],I)*rows*this.pitch/C.height;
  var fall=rows*(1-C.high*(C.highRows[0]+C.highRows[1])/2);
  for(c=0;c<cols;c++){this.due[c]+=act*this.speed[c]/fall*dt;
    if(this.due[c]<this.wait[c]||this.falling[c]>=this.most||hs.length>=this.limit)continue;
    var row=rnd()<C.high?Math.floor(mix(C.highRows,rnd())*rows):0,clash=false;
    for(k=0;k<hs.length;k++){h=hs[k];if(h.column===c&&Math.abs(h.row-row)<gap){clash=true;break}}
    if(clash)continue;
    var t=logu(lo,hi),g=logu(C.gain[0],C.gain[1]);
    this.due[c]=0;this.wait[c]=mix(C.wait,rnd());this.falling[c]++;
    hs.push({column:c,row:row,trail:t,gain:g,glyph:null,key:false,veiled:this.veiling});
    this.light(c,row,t,0,g,this.veiling)}
};
function makeCode(cv,cap){
  var ctx=cv&&cv.getContext&&cv.getContext('2d');
  var none={show:function(){},close:function(){},still:function(){},see:function(){},key:function(){},pulse:function(){},resize:function(){},recolour:function(){}};
  if(!ctx)return none;
  var main=null,near=null,I=0,sinceKey=1e9,age=0,cut=C.shown,keys=[],now=0,raf=0,prev=0,on=false,seen=true,K=0,A=null;
  /* the atlases: every code glyph mirrored, in the ink, one cell each, for both sheets (the nearer one at 2^-blur of
     its pixels, so it comes out soft when scaled up); a halo, the shader's ring of radius 0 (a Gaussian, e^-2 one
     width out, nothing at two); the typed glyphs as typed, drawn when first typed */
  function atlas(sc,k){  // k: the atlas's pixels per stage px
    var fs=LINE*sc,w=Math.ceil(CELLW*sc*k),h=Math.ceil(CELLH*sc*k),a=document.createElement('canvas'),x=a.getContext('2d');
    a.width=16*w;a.height=Math.ceil(NSET/16)*h;x.fillStyle=palette().ink;x.textAlign='center';x.textBaseline='alphabetic';
    CODESET.forEach(function(g,i){var kana=g.charCodeAt(0)>=0xFF00;x.font=(kana?'600 ':'400 ')+(fs*k).toFixed(2)+'px '+(kana?KANAF:MONO);
      x.save();x.translate((i%16+.5)*w,((i>>4)+.5)*h);x.scale(-1,1);x.fillText(g,0,.346*fs*k);x.restore()});
    return {cv:a,w:w,h:h,cw:CELLW*sc,ch:CELLH*sc};
  }
  function halo(){
    var n=Math.max(16,Math.ceil(4*C.haloW*CELLH*.5*C.near*K)),a=document.createElement('canvas'),x=a.getContext('2d');a.width=a.height=n;
    var g=x.createRadialGradient(n/2,n/2,0,n/2,n/2,n/2),ink=palette().ink;
    [[0,1],[.125,.969],[.25,.882],[.375,.755],[.5,.607],[.625,.458],[.75,.325],[.875,.216],[1,.135],[1.25,.044],[1.5,.011],[2,0]].forEach(function(s){
      g.addColorStop(s[0]/2,hexA(ink,s[1]))});
    x.fillStyle=g;x.fillRect(0,0,n,n);return a;
  }
  function typed(ch){
    if(A.typed[ch])return A.typed[ch];
    var w=A.main.w,h=A.main.h,a=document.createElement('canvas'),x=a.getContext('2d');a.width=w;a.height=h;
    x.fillStyle=palette().ink;x.textAlign='center';x.font='400 '+(2*LINE).toFixed(2)+'px '+MONO;x.fillText(ch,w/2,h/2+.346*2*LINE);
    return A.typed[ch]=a;
  }
  /* the main sheet's atlas as the app's: drawn once at twice the line's size and scaled down to each glyph's with
     mipmapped smoothing (its strokes as soft as the app's sampled atlas); the nearer one at 2^-1.5 of its pixels */
  function build(){A={main:atlas(.6,2/.6),near:atlas(.6*C.near,K*Math.pow(2,-C.nearBlur)),halo:halo(),typed:{}}}
  function resize(){
    var k=pixels(cv);if(Math.abs(k-K)<.02*K&&A)return;
    K=k;cv.width=Math.round(SW*K);cv.height=Math.round(SH*K);build();if(main&&!raf)paint(0);
  }
  function advance(dt){
    now+=dt;while(keys.length&&now-keys[0]>=2)keys.shift();
    var target=Math.min(keys.length/2/C.fast,1);  // up at once, down only after a pause
    if(target>I)I+=(target-I)*(1-Math.exp(-dt/C.rise));else if(sinceKey>=C.hold)I+=(target-I)*(1-Math.exp(-dt/C.settle));
    sinceKey+=dt;main.advance(dt,I);near.advance(dt,I);
  }
  function birth(){
    main=new Sheet(1,0,1,C.active);near=new Sheet(C.near,C.nearBlur,C.nearBright,C.nearActive);
    I=0;sinceKey=1e9;age=0;cut=C.shown;keys=[];now=0;
    for(var k=0;k<C.ahead*C.idleRate;k++)advance(1/C.idleRate);  // 20 s ahead, undrawn and veiled
    main.veiling=near.veiling=false;
  }
  var shown=0,drawn=0;
  function sheet(sh,at,look,veil,p,glow,inkA){
    var rows=sh.rows,cols=sh.columns,b=sh.bright,cw=at.cw,ch=at.ch,hw=cw/2,hh=ch/2,hs=sh.heads,pass,k,h,r,x,v,a,X,Y,c;
    for(pass=0;pass<2;pass++)for(k=0;k<hs.length;k++){h=hs[k];if(h.key!==(pass===0))continue;  // a key's heads first
      r=Math.floor(h.row);x=h.column*rows+r;if(sh.under[x])continue;sh.under[x]=1;
      v=h.veiled?veil:1;if(v<=cut)continue;
      X=sh.xs[h.column];Y=sh.ys[r];shown++;if(drawn>=cap)continue;drawn++;
      if(glow){var hw2=2*C.haloW*sh.pitch;ctx.globalAlpha=Math.min((h.key?C.keyHalo:look.halo)*b*v,1)*inkA;ctx.drawImage(A.halo,X-hw2,Y-hw2,2*hw2,2*hw2)}
      ctx.globalAlpha=Math.min((h.key?C.keyHead:look.head)*b*v,1)*inkA;
      if(h.glyph)ctx.drawImage(typed(h.glyph),X-hw,Y-hh,cw,ch);
      else{var g=sh.glyph[x];ctx.drawImage(at.cv,(g&15)*at.w,(g>>4)*at.h,at.w,at.h,X-hw,Y-hh,cw,ch)}
    }
    var odds=Math.log(1-Math.min(Math.max(p,1e-9),.5)),skip=Math.floor(Math.log(1-rnd())/odds);
    for(c=0;c<cols;c++){var tr=sh.travel[c];X=sh.xs[c];
      for(r=0;r<rows;r++){x=c*rows+r;var age2=tr-sh.lit[x],t=sh.trail[x];if(!(age2<t))continue;
        if(skip>0)skip--;else{sh.glyph[x]=rnd()*NSET|0;sh.level[x]=level();skip=Math.floor(Math.log(1-rnd())/odds)}
        if(sh.under[x]){sh.under[x]=0;continue}
        if(age2<3)a=(sh.top[x]>0?C.keyHead:look.head)*Math.pow(C.neck,Math.floor(age2))*b;  // right behind a head
        else{a=(sh.top[x]>0?sh.top[x]:look.top*sh.gain[x])*sh.level[x]*(1-age2/t)*b;if(a<=cut)continue}
        if(sh.veiled[x]){a*=veil;if(a<=cut)continue}
        shown++;if(drawn>=cap)continue;drawn++;
        var gg=sh.glyph[x];ctx.globalAlpha=Math.min(a,1)*inkA;
        ctx.drawImage(at.cv,(gg&15)*at.w,(gg>>4)*at.h,at.w,at.h,X-hw,sh.ys[r]-hh,cw,ch)}}
  }
  /* one frame: moved on by dt (none: drawn again as it is), then drawn */
  function paint(dt){
    if(dt>0){advance(dt);age+=dt}
    var L=palette(),veil=smooth(age/C.buildIn),look={head:lerp(C.head[0],C.head[1],I),top:lerp(C.top[0],C.top[1],I),halo:lerp(C.halo[0],C.halo[1],I)};
    var p=lerp(C.change[0],C.change[1],I)*dt;
    ctx.setTransform(1,0,0,1,0,0);ctx.globalCompositeOperation='source-over';ctx.globalAlpha=1;ctx.clearRect(0,0,cv.width,cv.height);
    ctx.setTransform(K,0,0,K,0,0);ctx.globalCompositeOperation=L.add?'lighter':'source-over';ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';
    shown=0;drawn=0;
    sheet(main,A.main,look,veil,p,L.add,L.inkA);sheet(near,A.near,look,veil,p,L.add,L.inkA);
    ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';
    if(dt>0){if(shown>cap)cut=Math.min(cut*1.25,.25);else if(shown<cap*.75)cut=Math.max(cut/1.05,C.shown)}
  }
  function frame(t){
    if(!on||!seen){raf=0;return}
    raf=requestAnimationFrame(frame);
    var fast=I>C.calm||sinceKey<C.hold;
    if(prev&&t-prev<1000/(fast?60:C.idleRate)-4)return;
    var dt=prev?Math.min((t-prev)/1000,.1):1/60;prev=t;paint(dt);
  }
  function go(){if(on&&seen&&!reduced&&!raf){prev=0;raf=requestAnimationFrame(frame)}}
  function startHead(ch){
    if(main.heads.length>=main.limit)return;
    var k=keyAt(ch),spread=(rnd()*.8-.4)*SW*(SPAN[1]-SPAN[0])/15*(k?k.width:0);
    var along=k?screenX(k)+spread:CARET,height=k?mix(C.keyRows,1-k.row/4):mix(C.keyRows,rnd());
    var c=Math.min(Math.max(Math.floor((along-main.left)/main.pitch),0),main.columns-1);
    var r=Math.min(Math.max(Math.floor((1-height+(rnd()*.06-.03))*SH/main.pitch),0),main.rows-1),t=logu(C.keyTrail[0],C.keyTrail[1]);
    main.heads.push({column:c,row:r,trail:t,gain:1,glyph:ch,key:true,veiled:false});main.light(c,r,t,C.keyTop,1,false);
  }
  var sc={
    show:function(){resize();birth();paint(0);on=true;go()},
    close:function(){on=false;if(raf)cancelAnimationFrame(raf);raf=0},
    still:function(){resize();birth();for(var k=0;k<4*C.idleRate;k++){advance(1/C.idleRate);age+=1/C.idleRate}paint(0)},  // the rest, built in
    see:function(v){seen=v;go()},
    key:function(ch){if(!main)return;keys.push(now);sinceKey=0;if(on&&!reduced&&ch.trim())startHead(ch)},
    pulse:function(){if(!main)return;keys.push(now);sinceKey=0},
    resize:resize,
    recolour:function(){if(!K)return;build();if(main&&!raf)paint(0)}
  };
  scenes.push(sc);return sc;
}
function hexA(hex,a){var n=parseInt(hex.slice(1),16);return 'rgba('+(n>>16&255)+','+(n>>8&255)+','+(n&255)+','+a.toFixed(4)+')'}

/* ---------- Ambience ▸ Still water (A1; pass 31 rain on still water as busy as Code), Scenes.swift's Water: drops land
   at random on the dim at least 48 px from the box, Poisson in time at 380 a second on a 1512 × 982 pt screen, 620
   typing, scaled to this stage's area (175 and 285), swaying in gusts of 0.5–1.5 of the rate over 5–20 s; the rate
   builds in over 3 s from the show, when one large drop lands above the box. A drop's size is exponential as rain's
   are (slope 4 at rest, 3 typing): it sets one to three crests 2.5–5 px apart, the lead's speed (24–34 px/s), the
   rings' width (1.2–3 px, thinning to 0.6 of it far out), the crater out to which a ring keeps its peak (8–20 px,
   ~1/r beyond), the peak's share (0.3–1) and the fade (τ 0.5–1.8 s); each further crest at half the alpha of the one
   before; a splash at each landing, gone in 0.15 s. Code's intensity raises the rate, the sizes and the brightness;
   one large drop for each word, where its last key is. 30 Hz. Each ring is drawn as one stroke its Gaussian's
   half-power width, in batches of one alpha and width. */
var Wt={rate:[380,620],clear:48,summon:48,gust:[.5,1.5],gustTime:[5,20],buildIn:3,drops:1800,size:[4,3],speed:[24,34],
  jitter:.1,spread:.06,gap:[2.5,5],width:[1.2,3],near:[8,20],bright:[.3,1],fade:[.5,1.8],follow:.5,lift:[1,1.2],onset:.08,
  peak:{over:1,add:.9},thin:.6,splash:.15,splashW:[1.2,3.5],splashB:1.5,shown:.01,life:6,wordGap:.8,top:40,word:1.5};
function makeWater(cv){
  var ctx=cv&&cv.getContext&&cv.getContext('2d');
  var none={show:function(){},still:function(){},see:function(){},key:function(){},resize:function(){},recolour:function(){}};
  if(!ctx)return none;
  var area=SW*SH/(1512*982),drops=[],I=0,sinceKey=1e9,sinceWord=1e9,inWord=false,lastKey=null,age=0,gust=null,due=0,keys=[],now=0;
  var raf=0,prev=0,on=false,seen=false,K=0,born=false;
  function drop(x,y,s,bright,a){
    if(drops.length>=Wt.drops)return;
    var speed=mix(Wt.speed,s)*(1+(2*rnd()-1)*Wt.jitter);
    drops.push({x:x,y:y,age:a,crests:s>=.6?3:s>=.3?2:1,speed:speed,width:mix(Wt.width,s),near:mix(Wt.near,s),
      peak:mix(Wt.bright,s)*bright,decay:mix(Wt.fade,s),lag:mix(Wt.gap,s)/speed,splash:mix(Wt.splashW,s)});
  }
  function size(){var slope=lerp(Wt.size[0],Wt.size[1],I);return -Math.log(1-rnd()*(1-Math.exp(-slope)))/slope}
  function restDrop(a){
    for(var i=0;i<20;i++){var x=rnd()*SW,y=rnd()*SH;
      if(x>B.x-Wt.clear&&x<B.x+B.w+Wt.clear&&y>B.y-Wt.clear&&y<B.y+B.h+Wt.clear)continue;
      return drop(x,y,size(),lerp(Wt.lift[0],Wt.lift[1],I),a)}
  }
  function wordDrop(k){var low=B.y-Wt.clear,high=Wt.top;drop(k?screenX(k):CARET,low-(1-(k?k.row/4:1))*Math.max(low-high,0),1,Wt.word,0)}
  function birth(){
    drops=[];I=0;sinceKey=1e9;sinceWord=1e9;inWord=false;lastKey=null;age=0;keys=[];now=0;
    gust={from:mix(Wt.gust,rnd()),to:mix(Wt.gust,rnd()),over:mix(Wt.gustTime,rnd())};gust.at=gust.over*rnd();
    due=-Math.log(1-rnd());drop(B.x+B.w/2,B.y-Wt.summon,1,Wt.word,0);born=true;
  }
  function step(dt){
    now+=dt;sinceWord+=dt;while(keys.length&&now-keys[0]>=2)keys.shift();
    var target=Math.min(keys.length/2/C.fast,1);
    if(target>I)I+=(target-I)*(1-Math.exp(-dt/C.rise));else if(sinceKey>=C.hold)I+=(target-I)*(1-Math.exp(-dt/C.settle));
    sinceKey+=dt;age+=dt;gust.at+=dt;
    while(gust.at>=gust.over){gust.from=gust.to;gust.to=mix(Wt.gust,rnd());gust.at-=gust.over;gust.over=mix(Wt.gustTime,rnd())}
    for(var i=0;i<drops.length;i++)drops[i].age+=dt;
    var g=gust.from+(gust.to-gust.from)*smooth(gust.at/gust.over),rate=lerp(Wt.rate[0],Wt.rate[1],I)*area*g*smooth(age/Wt.buildIn);
    if(rate>0){var left=rate*dt;while(left>=due){left-=due;restDrop(left/rate);due=-Math.log(1-rnd())}due-=left}
  }
  function draw(){
    var L=palette(),scaleA=(L.add?Wt.peak.add:Wt.peak.over),inkA=L.inkA,rings={},dots={},keep=[],q,key,i,k;
    for(i=0;i<drops.length;i++){var d=drops[i];if(d.age>=Wt.life)continue;
      var alive=d.age<(d.crests-1)*d.lag+Wt.onset;
      if(d.age<Wt.splash){var f=1-d.age/Wt.splash,dot=d.peak*scaleA*Wt.splashB*f*f;
        if(dot>=Wt.shown){alive=true;q=Math.round(Math.min(dot*.85,1)*inkA*96);
          if(q>0){(dots[q]||(dots[q]=new Path2D())).moveTo(d.x+.75*d.splash,d.y);dots[q].arc(d.x,d.y,.75*d.splash,0,2*Math.PI)}}}
      for(k=0;k<d.crests;k++){var a=d.age-k*d.lag;if(a<=0)continue;
        var r=d.speed*(1-Wt.spread*k)*a,on2=a<Wt.onset?ease(a/Wt.onset):1;
        var al=d.peak*scaleA*(k?Math.pow(Wt.follow,k):1)*on2*Math.exp(-a/d.decay)*Math.min(d.near/Math.max(r,1e-9),1);
        if(al<Wt.shown)continue;alive=true;
        var w=d.width*(Wt.thin+(1-Wt.thin)*d.near/(d.near+r));
        q=Math.round(Math.min(al,1)*inkA*96);if(!q)continue;
        key=q*512+Math.max(1,Math.round(1.18*w*8));
        var pth=rings[key]||(rings[key]=new Path2D());pth.moveTo(d.x+r,d.y);pth.arc(d.x,d.y,r,0,2*Math.PI)}
      if(alive)keep.push(d)}
    drops=keep;
    ctx.setTransform(1,0,0,1,0,0);ctx.globalCompositeOperation='source-over';ctx.globalAlpha=1;ctx.clearRect(0,0,cv.width,cv.height);
    ctx.setTransform(K,0,0,K,0,0);ctx.globalCompositeOperation=L.add?'lighter':'source-over';
    ctx.strokeStyle=ctx.fillStyle=L.ink;
    for(key in rings){ctx.globalAlpha=Math.floor(key/512)/96;ctx.lineWidth=(key%512)/8;ctx.stroke(rings[key])}
    for(key in dots){ctx.globalAlpha=key/96;ctx.fill(dots[key])}
    ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';
  }
  function frame(ts){if(!on||!seen){raf=0;return}raf=requestAnimationFrame(frame);
    if(prev&&ts-prev<1000/30-4)return;var dt=prev?Math.min((ts-prev)/1000,.1):1/30;prev=ts;step(dt);draw()}
  function go(){if(on&&seen&&!reduced&&!raf){prev=0;raf=requestAnimationFrame(frame)}}
  function resize(){var k=pixels(cv);if(Math.abs(k-K)<.02*K)return;K=k;cv.width=Math.round(SW*K);cv.height=Math.round(SH*K);if(born&&!raf)draw()}
  var sc={
    show:function(){resize();birth();draw();on=true;go()},
    still:function(){resize();birth();for(var i=0;i<180;i++)step(1/30);draw()},  // 6 s in: the rest's rain
    see:function(v){seen=v;go()},
    key:function(ch){if(!born)return;keys.push(now);sinceKey=0;
      if(ch===' '||ch==='\n'){if(inWord&&sinceWord>=Wt.wordGap){wordDrop(lastKey);sinceWord=0}inWord=false}
      else if(ch!=='\b'){inWord=true;lastKey=keyAt(ch)}},
    resize:resize,
    recolour:function(){if(born&&!raf)draw()}
  };
  scenes.push(sc);return sc;
}

var Code=makeCode(dim.querySelector('canvas'),2800),TileCode=makeCode(tileCanvas('code'),2400),Water=makeWater(tileCanvas('water'));
scale();addEventListener('resize',scale);
function recolour(){scenes.forEach(function(s){s.recolour()})}
if(darkQ.addEventListener)darkQ.addEventListener('change',recolour);else if(darkQ.addListener)darkQ.addListener(recolour);

/* ---------- the sounds: the Keychron pack's clicks (CC0; the first pack, a fresh install's), played as lib/LemnaClicks
   plays them: never the same sample twice in a row, the rate within ±3 % (the pack has no pitched kind), volume 0.6;
   and the Lab bed (CC BY), looped, at the app's level (-43 LUFS under the clicks' 0.6), faded in over 1.5 s as the box
   opens and out over 0.6 s as it goes, on a quarter sine (equal power). Each off until the reader turns it on.
   Web Audio where the files can be fetched, audio elements where they cannot (a page opened from disk). ---------- */
var Audio2=(function(){
  var ac=null,AC=window.AudioContext||window.webkitAudioContext;
  return {
    ctx:function(){if(!ac&&AC&&window.fetch){try{ac=new AC()}catch(e){ac=null}}if(ac&&ac.state==='suspended'&&!document.hidden)ac.resume();return ac},
    load:function(url){var a=this.ctx();if(!a)return Promise.reject();
      return fetch(url).then(function(r){if(!r.ok)throw 0;return r.arrayBuffer()})
        .then(function(b){return new Promise(function(ok,no){a.decodeAudioData(b,ok,no)})})},
    hidden:function(h){if(!ac)return;if(h)ac.suspend();else ac.resume()}
  };
})();
document.addEventListener('visibilitychange',function(){Audio2.hidden(document.hidden)});
var Sound=(function(){
  var btn=$('snd');
  var FILES={letter:[1,2,3,4,5,6],space:[1,2],paragraph:[1,2],backspace:[1,2],send:[1]},PITCHED={};
  var on=false,gain=null,buf={},els={},lastPick={},loaded=false;
  function name(kind,i){return kind+'-'+i}
  function src(n){return 'assets/snd/'+n+'.wav'}
  function load(){
    if(loaded)return;loaded=true;
    var names=[];Object.keys(FILES).forEach(function(k){FILES[k].forEach(function(i){names.push(name(k,i))})});
    names.forEach(function(n){var a=new Audio(src(n));a.preload='auto';els[n]=a});
    var ac=Audio2.ctx();if(!ac)return;
    gain=ac.createGain();gain.gain.value=.6;gain.connect(ac.destination);
    names.forEach(function(n){Audio2.load(src(n)).then(function(d){buf[n]=d},function(){})});
  }
  function label(){btn.textContent=on?'sound: on':'sound: off';btn.setAttribute('aria-pressed',String(on))}
  if(btn){btn.addEventListener('click',function(){on=!on;if(on){load();Audio2.ctx()}label()});label()}
  return {play:function(kind){
    if(!on)return;var list=FILES[kind],n=list.length,p=0;
    if(n>1){p=rnd()*(lastPick[kind]==null?n:n-1)|0;if(lastPick[kind]!=null&&p>=lastPick[kind])p++}
    lastPick[kind]=p;var nm=name(kind,list[p]),rate=PITCHED[kind]?1:1+(2*rnd()-1)*.03,ac=Audio2.ctx();
    if(ac&&buf[nm]&&gain){var s=ac.createBufferSource();s.buffer=buf[nm];s.playbackRate.value=rate;s.connect(gain);s.start();return}
    var a=els[nm]&&els[nm].cloneNode();if(!a)return;
    a.volume=.6;a.preservesPitch=false;a.webkitPreservesPitch=false;a.playbackRate=rate;
    var pr=a.play();if(pr&&pr.catch)pr.catch(function(){});
  }};
})();
var Bed=(function(){
  var btn=$('bed'),GAIN=Math.pow(10,(-43+26)/20);  // Bed.level -43 LUFS for a loop at -26 (bed.json), under a bedVolume of 0.6
  var on=false,isUp=false,g=null,srcNode=null,el=null,loading=false,lvl={from:0,to:0,t0:0,dur:0};
  function levelNow(t){var u=lvl.dur>0?Math.min(Math.max((t-lvl.t0)/lvl.dur,0),1):1;return lvl.from+(lvl.to-lvl.from)*u}
  function fade(to,sec){
    var want=on&&to>0?1:0;
    if(g){var ac=Audio2.ctx(),t=ac.currentTime,from=levelNow(t),dur=Math.abs(want-from)*sec;
      lvl={from:from,to:want,t0:t,dur:dur};g.gain.cancelScheduledValues(t);
      if(dur<.02){g.gain.setValueAtTime(GAIN*Math.sin(Math.PI/2*want),t);return}
      var n=32,curve=new Float32Array(n);for(var i=0;i<n;i++)curve[i]=GAIN*Math.sin(Math.PI/2*(from+(want-from)*i/(n-1)));
      g.gain.setValueCurveAtTime(curve,t,dur);return}
    if(el){if(want){el.volume=GAIN;var p=el.play();if(p&&p.catch)p.catch(function(){})}else el.pause()}
  }
  function load(){
    if(g||el||loading)return;loading=true;
    Audio2.load('assets/snd/lab.m4a').then(function(d){
      var ac=Audio2.ctx();g=ac.createGain();g.gain.value=0;g.connect(ac.destination);
      srcNode=ac.createBufferSource();srcNode.buffer=d;srcNode.loop=true;srcNode.connect(g);srcNode.start();
      if(isUp)fade(1,1.5);
    },function(){el=new Audio('assets/snd/lab.m4a');el.loop=true;if(isUp)fade(1,1.5)});
  }
  function label(){btn.textContent=on?'lab bed: on':'lab bed: off';btn.setAttribute('aria-pressed',String(on))}
  if(btn){btn.addEventListener('click',function(){on=!on;if(on){load();Audio2.ctx();if(isUp)fade(1,1.5)}else fade(0,.6);label()});label()}
  return {up:function(v){if(v===isUp)return;isUp=v;fade(v?1:0,v?1.5:.6)}};
})();

/* ---------- the line: the band and its glide (Line.swift, Glide.swift). Two offsets: the edit's moves only the text
   before the caret (an insertion pushes it left by the inserted text's own width, measured alone, as Line.width does;
   a deletion glides it back), the caret move's moves both parts; each restarts from what remains of it plus the new
   step, a remainder in the same direction capped at one step, and eases to 0 over 140 ms. The newest glyph fades in
   over 80 ms, a paragraph end's ` ¶ ` over 200 ms: its two spaces in Literata, its pilcrow in Menlo, muted. Reduced
   motion jumps. ---------- */
var Line=(function(){
  var bEl=box.querySelector('.ll-b>span'),aEl=box.querySelector('.ll-a>span');
  var text=[],caret=0,edit={from:0,start:0},move={from:0,start:0},raf=0,widths={},m=document.createElement('canvas').getContext('2d');
  function width(ch){
    if(widths[ch]!=null)return widths[ch];
    var w;m.font='400 30px '+SERIF;
    if(ch==='\n'){w=2*m.measureText(' ').width;m.font='400 30px '+MONO;w+=m.measureText('¶').width}else w=m.measureText(ch).width;
    return widths[ch]=w;
  }
  function off(g,t){return g.from*(1-ease((t-g.start)/T.glide))}
  function add(g,dw,t){if(reduced){g.from=0;return}
    var r=off(g,t),c=Math.abs(dw);if(r*dw>0)r=dw>0?Math.min(r,c):Math.max(r,-c);g.from=r+dw;g.start=t}
  function esc(ch){return ch==='<'?'&lt;':ch==='>'?'&gt;':ch==='&'?'&amp;':ch}
  function glyph(ch,fresh){
    if(ch==='\n')return '<span class="p'+(fresh?' new':'')+'"> <b>¶</b> </span>';
    return fresh?'<span class="new">'+esc(ch)+'</span>':esc(ch);
  }
  function render(fresh){
    var h='',i;
    for(i=Math.max(0,caret-120);i<caret;i++)h+=glyph(text[i],fresh&&i===caret-1);
    bEl.innerHTML=h;var a='';for(i=caret;i<Math.min(text.length,caret+120);i++)a+=glyph(text[i],false);aEl.innerHTML=a;
  }
  function paint(t){var mv=off(move,t),e=off(edit,t);
    bEl.style.transform='translateX('+(e+mv).toFixed(2)+'px)';aEl.style.transform='translateX('+mv.toFixed(2)+'px)';
    return t<edit.start+T.glide||t<move.start+T.glide}
  function loop(t){raf=paint(t)?requestAnimationFrame(loop):0}
  function moved(){if(paint(performance.now())&&!raf)raf=requestAnimationFrame(loop)}  // drawn on the key event
  if(document.fonts&&document.fonts.addEventListener)document.fonts.addEventListener('loadingdone',function(){widths={}});
  return {
    text:function(){return text.join('')},
    set:function(s){text=Array.from(s);caret=text.length;edit.from=move.from=0;render(false);moved()},
    insert:function(ch){text.splice(caret,0,ch);caret++;add(edit,width(ch),performance.now());render(true);moved()},
    back:function(){if(!caret)return;var ch=text[caret-1];text.splice(caret-1,1);caret--;add(edit,-width(ch),performance.now());render(false);moved()},
    left:function(){if(!caret)return;caret--;add(move,-width(text[caret]),performance.now());render(false);moved()},
    right:function(){if(caret>=text.length)return;add(move,width(text[caret]),performance.now());caret++;render(false);moved()}
  };
})();

/* ---------- the box: open, close, hand-off (Still: P1 a fade both ways, the hand-off the box's fade with MO1's ring)
   ---------- */
var up=false,gen=0,ringRaf=0;
function show(){
  cancel(box);cancel(dim);endRing();up=true;box.classList.add('up');dim.classList.add('up');
  if(reduced)Code.still();else Code.show();
  Bed.up(true);
  if(!reduced){  // 300 ms, a fade alone (Theme.still's open), the dim with it
    anim(box,[{opacity:0},{opacity:1}],{duration:T.open,easing:Q});
    anim(dim,[{opacity:0},{opacity:1}],{duration:T.open,easing:Q});
  }
}
function hideNow(){cancel(box);cancel(dim);endRing();up=false;box.classList.remove('up');dim.classList.remove('up');Code.close();Bed.up(false)}
function closeFade(){  // Esc, a click outside: a 200 ms fade, the dim with it
  if(!up)return;if(reduced)return hideNow();
  up=false;var g=++gen;Bed.up(false);
  anim(box,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'});
  anim(dim,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'});
  setTimeout(function(){if(g===gen)hideNow()},T.close);
}
/* R1, the fixed pass applied to what goes out, in each paragraph: runs of spaces become one, no trailing space, a
   capital at the start and after a sentence's end, a lone i becomes I */
function tidy(s){
  return s.split('\n').map(function(p){
    return p.replace(/ {2,}/g,' ').trim().replace(/(^|[.!?] )([a-z])/g,function(m,a,b){return a+b.toUpperCase()})
      .replace(/(^| )i(?=[ ,.;:!?]|$)/g,'$1I');
  }).filter(Boolean).join('\n');
}
function paste(s){
  if(!s)return;var cur=pasted.textContent;
  pasted.textContent=(cur?cur+'\n':'')+s;
  if(pasted.textContent.length>300)pasted.textContent='…'+pasted.textContent.slice(-300);
}
/* MO1's ring (Handoff.ring, ringOutline, ringAlpha): two crests 9 px apart leave the box's outline at 60 px/s from
   ⌘⏎'s key-down, each with a trough 3 px inside it at 0.4 of its alpha, each line three strokes laid over each other
   (3.2 px at 0.2, 1.8 at 0.35, 0.9 at 0.45), the box's rectangle grown by how far out it is, its corners with it; the
   ring's alpha up over 0.18 s on the curve to 0.18 by day, 0.08 by night, down as (1 − t / 1.2 s)^1.5 */
var RING=[[0,1],[.05,.4],[.15,1],[.2,.4]],STROKES=[[3.2,.2],[1.8,.35],[.9,.45]];
function ring(){
  endRing();var t0=performance.now(),peak=palette().ringPeak,ls=[];
  RING.forEach(function(l){STROKES.forEach(function(s){var e=document.createElement('i');e.style.borderWidth=s[0]+'px';ringEl.appendChild(e);
    ls.push({e:e,start:l[0],share:l[1]*s[1],w:s[0]})})});
  function f(now){var t=(now-t0)/1000;if(t>=T.ringLife){endRing();return}
    var A=peak*ease(t/T.ringOnset)*Math.pow(1-t/T.ringLife,1.5);
    ls.forEach(function(o){var d=T.ringSpeed*(t-o.start),st=o.e.style;if(d<0){st.opacity=0;return}
      var g=d+o.w/2;st.left=(B.x-g).toFixed(2)+'px';st.top=(B.y-g).toFixed(2)+'px';st.width=(B.w+2*g).toFixed(2)+'px';
      st.height=(B.h+2*g).toFixed(2)+'px';st.borderRadius=(16+g).toFixed(2)+'px';st.opacity=(A*o.share).toFixed(4)});
    ringRaf=requestAnimationFrame(f)}
  ringRaf=requestAnimationFrame(f);
}
function endRing(){if(ringRaf)cancelAnimationFrame(ringRaf);ringRaf=0;ringEl.innerHTML=''}
/* ⌘⏎ under Still: the send sound at the key-down, MO1's ring from it and the wash lifting evenly over the ring's 1.2 s,
   Code fading with it; at Return's key-up the box fades in place over 200 ms, text and all; the paste lands at about
   130 ms and waits for none of it. */
function handOff(){
  var s=tidy(Line.text());if(!s||!up)return false;
  Sound.play('send');Bed.up(false);
  var g=++gen;up=false;
  if(reduced){hideNow();paste(s);Line.set('');return true}
  cancel(box);cancel(dim);ring();
  anim(dim,[{opacity:1},{opacity:0}],{duration:T.ringLife*1000,easing:'linear',fill:'forwards'});
  setTimeout(function(){if(g===gen)anim(box,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'})},T.keyUp);
  setTimeout(function(){paste(s)},T.paste);
  setTimeout(function(){if(g!==gen)return;hideNow();Line.set('')},T.ringLife*1000);
  return true;
}

/* ---------- key hints ---------- */
function hintShow(html){hint.innerHTML=html;if(reduced){hint.style.opacity=1;return}
  cancel(hint);anim(hint,[{opacity:0},{opacity:1}],{duration:T.glide,easing:Q,fill:'forwards'})}
function hintHide(){cancel(hint);if(reduced){hint.style.opacity=0;return}
  anim(hint,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'})}

/* ---------- keys, from the loop or the reader: the line, the click, the ambience ---------- */
function key(ch){
  if(ch==='\b'){Line.back();Sound.play('backspace');Code.pulse();return}
  Line.insert(ch);
  if(ch==='\n'){Sound.play('paragraph');Code.pulse()}
  else if(ch===' '){Sound.play('space');Code.pulse()}
  else{Sound.play('letter');Code.key(ch)}
}

/* ---------- the loop: about 50 s, three paragraphs, so the line is seen carrying a longer piece ---------- */
var SEQ='The morning was grey and I kept circling the same paragraph, so I closed everything and started again from what I actually knew.\nThe argument is simpler than the draft makes it look. Three claims, one example each, and the figure can go.\nWhat worries me is the second claim, which rests on teh\b\bhe older data. Say so plainly, and move on.';
var timers=[],mode='auto',idleT=0;
function later(ms,f){var id=setTimeout(function(){var i=timers.indexOf(id);if(i>=0)timers.splice(i,1);f()},ms);timers.push(id)}
function cancelTimers(){timers.forEach(clearTimeout);timers=[]}
function gap(prev,ch){  // a human pace: 90–200 ms a key, longer after a space or a full stop, a pause before fixing a typo
  if(ch==='\b')return prev==='\b'?130:420;
  var g=90+rnd()*110;if(prev===' ')g+=rnd()*150;if(prev==='.'||prev===',')g+=260;if(prev==='\n')g+=320;return g;
}
function loop(){
  mode='auto';pasted.textContent='';cancel(pasted);
  var t=600;later(t,function(){hintShow('<kbd>⌃⌥Space</kbd>')});
  t+=600;later(t,show);
  later(t+300,hintHide);
  t+=T.open+900;  // Code builds in for a moment before the first key
  var prev='';Array.from(SEQ).forEach(function(ch){t+=gap(prev,ch);prev=ch;later(t,function(){key(ch)})});
  t+=900;later(t,function(){hintShow('<kbd>⌘⏎</kbd>')});
  t+=600;later(t,handOff);
  later(t+500,hintHide);
  t+=T.ringLife*1000+2000;
  later(t,function(){anim(pasted,[{opacity:1},{opacity:0}],{duration:T.close,easing:Q,fill:'forwards'})});
  later(t+T.close,loop);
}
function still(){  // reduced motion: one frame of the box over the dimmed app and Code's rest, the key hints as labels
  mode='still';pasted.textContent='';up=true;box.classList.add('up');dim.classList.add('up');Code.still();
  Line.set(SEQ.replace('teh\b\bhe','the'));
  hintShow('<kbd>⌃⌥Space</kbd><span>opens the box</span><kbd>⌘⏎</kbd><span>sends the text into the app</span>');
}
function idle(){clearTimeout(idleT);idleT=setTimeout(resume,10000)}
function resume(){  // 10 s without the reader: the loop again, unless a sentence of theirs is still in the box
  if(document.activeElement===inp&&Line.text()){idle();return}
  inp.blur();hideNow();Line.set('');reduced?still():loop();
}
function takeOver(){  // the reader's turn: the loop stops, the box is theirs and empty
  if(mode!=='user'){
    cancelTimers();gen++;hintHide();
    if(up&&mode==='auto'){cancel(box);cancel(dim);box.classList.add('up');dim.classList.add('up')}  // open already: it stays
    else{hideNow();show()}
    mode='user';Line.set('');
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
  if(e.key==='Backspace'){e.preventDefault();if(up)key('\b')}
  else if(e.key==='ArrowLeft'){e.preventDefault();Line.left()}
  else if(e.key==='ArrowRight'){e.preventDefault();Line.right()}
  else if(e.key==='Escape'){e.preventDefault();closeFade();inp.blur()}
});
function typed(){var v=inp.value;inp.value='';if(!up)return;Array.from(v).forEach(function(ch){if(ch>=' ')key(ch)})}
inp.addEventListener('input',function(e){if(!e.isComposing)typed()});
inp.addEventListener('compositionend',typed);

/* start the loop when the demo is first in view and Literata is in (the glide measures with it) */
var started=false;
function begin(){
  if(started)return;started=true;
  function go(){reduced?still():loop()}
  if(document.fonts&&document.fonts.load)Promise.race([document.fonts.load('400 30px Literata'),new Promise(function(ok){setTimeout(ok,1500)})]).then(go,go);
  else go();
}
if('IntersectionObserver' in window)new IntersectionObserver(function(es){var v=es[0].isIntersecting;Code.see(v);if(v)begin()}).observe(fit);
else begin();

/* ---------- the burst: every 7 s ten keys at about 6 a second go to both tiles, half the interval apart (Code, Still
   water), so they do not fire at once. They continue the box's sentence, a typo and its fix included. ---------- */
(function(){
  var CONT=' first, tehn\b\b\bhen the agenda and the notes.',at=0,started=false;
  function chunk(){var keys=[],gaps=[];for(var i=0;i<10;i++){keys.push(CONT[at]);at=(at+1)%CONT.length;gaps.push(.14+rnd()*.06)}return {keys:keys,gaps:gaps}}
  var tiles=[
    {feed:function(ch){if(ch===' '||ch==='\b')TileCode.pulse();else TileCode.key(ch)},see:function(v){TileCode.see(v)},offset:0},
    {feed:function(ch){Water.key(ch)},see:function(v){Water.see(v)},offset:3500}];
  var els=Array.prototype.slice.call(document.querySelectorAll('.tile'));  // in the page's order: Code, Still water
  var seen=[false,false];
  function burst(){if(document.hidden)return;var c=chunk();
    tiles.forEach(function(tile,i){if(!seen[i])return;var t=tile.offset;
      c.keys.forEach(function(ch,k){t+=c.gaps[k]*1000;setTimeout(function(){tile.feed(ch)},t)})})}
  function begin(){if(started)return;started=true;
    if(reduced){TileCode.still();Water.still();return}
    TileCode.show();Water.show();setTimeout(burst,1500);setInterval(burst,7000)}
  els.forEach(function(el,i){
    function view(v){seen[i]=v;tiles[i].see(v);if(v)begin()}
    if('IntersectionObserver' in window)new IntersectionObserver(function(es){view(es[0].isIntersecting)}).observe(el);else view(true);
  });
})();
})();
