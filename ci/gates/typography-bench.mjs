// Run in the existing browser image with BENCH_URL and BENCH_OUTPUT as needed.
import { chromium } from 'playwright';
import fs from 'node:fs/promises';
const origin=process.env.BENCH_URL||'http://web:8000';
const output=process.env.BENCH_OUTPUT||'/work/.tmp/typography-bench';
await fs.mkdir(output,{recursive:true});
const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
const page=await browser.newPage({viewport:{width:1100,height:900},deviceScaleFactor:1});
async function specimen(query){await page.goto(`${origin}/typography-bench/specimen?${query}`);await page.waitForFunction(()=>window.benchResult);return page.evaluate(()=>window.benchResult);}
const baseline=await specimen('font=mono&size=3xs&mode=stack');
if(baseline.findings.some(f=>f.kind==='unexpected-layout-gap'))throw Error('Control stack has an unexplained margin');
const margin=await specimen('font=mono&size=3xs&mode=stack&fault=margin');
if(!margin.findings.some(f=>f.kind==='unexpected-layout-gap'))throw Error('Missed injected 12px margin');
const font=await specimen('font=mono&size=3xs&mode=stack&fault=font');
if(!font.findings.some(f=>f.kind==='font-unverified'))throw Error('Missed wrong font');
await specimen('font=mono&size=3xs&mode=stack');
const before=await page.evaluate(()=>window.benchResult.nodes.map(n=>n.box));
await page.evaluate(()=>window.benchOutline(true));
const after=await page.evaluate(async()=>(await window.benchMeasure()).nodes.map(n=>n.box));
if(JSON.stringify(before)!==JSON.stringify(after))throw Error('Inspector altered layout');
const cdp=await page.context().newCDPSession(page);await cdp.send('DOM.enable');await cdp.send('CSS.enable');
const {root}=await cdp.send('DOM.getDocument');const {nodeId}=await cdp.send('DOM.querySelector',{nodeId:root.nodeId,selector:'#text .optical-adjustment'});
const actualFonts=await cdp.send('CSS.getPlatformFontsForNode',{nodeId});
await fs.writeFile(`${output}/fault-checks.json`,JSON.stringify({baseline,margin,font,actualFonts},null,2));
await page.goto(`${origin}/typography-bench`);await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Ready'));
const frame=page.frames().find(f=>f.url().includes('/specimen'));
const embedded=await frame.evaluate(()=>window.benchResult.nodes.map(n=>n.box));
const directPage=await browser.newPage({viewport:{width:await frame.evaluate(()=>innerWidth),height:900}});await directPage.goto(frame.url());await directPage.waitForFunction(()=>window.benchResult);
const direct=await directPage.evaluate(()=>window.benchResult.nodes.map(n=>n.box));
if(JSON.stringify(embedded)!==JSON.stringify(direct))throw Error('Bench frame changed specimen geometry');
await directPage.close();
// Mobile changes must repaint every specimen without a render button or scrolling.
await page.setViewportSize({width:390,height:844});
await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Ready'));
await page.selectOption('#font','cheee');
await page.selectOption('#font','flexa');
await page.selectOption('#locale','ja');
await page.selectOption('#locale','en');
await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Ready') && [...document.querySelectorAll('#sink iframe, #specimen-frame')].every(f=>f.contentWindow.benchResult?.configuration.font==='flexa' && f.contentWindow.benchResult?.configuration.locale==='en'));
const mobile=await page.evaluate(()=>({overflow:document.documentElement.scrollWidth>innerWidth,selectedBottom:document.querySelector('#specimen-frame').getBoundingClientRect().bottom,frames:document.querySelectorAll('#sink iframe').length}));
if(mobile.overflow || mobile.selectedBottom>844 || mobile.frames!==8)throw Error(`Broken mobile interaction: ${JSON.stringify(mobile)}`);
await page.screenshot({path:`${output}/mobile.png`});
await page.setViewportSize({width:320,height:740});
await page.selectOption('#theme','light');
await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Ready') && document.querySelector('#specimen-frame').contentWindow.benchResult?.configuration.theme==='light');
if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))throw Error('320px page overflows');
await page.locator('section details > summary').click();
await page.selectOption('#size','1xs');
await page.selectOption('#sample','descenders');
await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Ready') && document.querySelector('#specimen-frame').contentWindow.benchResult?.configuration.size==='1xs');
const changed=await page.locator('#specimen-frame').evaluate(f=>f.contentWindow.benchResult.nodes.find(n=>n.name==='text'));
if(parseFloat(changed.style.fontSize)<16 || !changed.text.includes('agjpqy'))throw Error('Size/text control did not repaint');
await page.locator('section details > summary').click();
await page.screenshot({path:`${output}/mobile-320-light.png`});
await page.selectOption('#theme','dark');
await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Ready'));
// Pixel bounds are measured separately from line boxes, with all overlays off.
const rasterPage=await browser.newPage({viewport:{width:390,height:844}});
const raster=[];
for(const face of ['mono','flexa','cheee','cardinal','noto']) for(const size of ['3xs','2xs','1xs']) {
  await rasterPage.goto(`${origin}/typography-bench/specimen?font=${face}&size=${size}&mode=single&sample=caps&locale=en`);
  await rasterPage.waitForFunction(()=>window.benchResult);
  const report=await rasterPage.evaluate(()=>window.benchResult);
  if(report.findings.some(f=>f.kind==='trim-height-mismatch' || f.kind==='invalid-leading'))throw Error(`Invalid trim for ${face}/${size}`);
  const box=report.nodes.find(n=>n.name==='text').box;
  const clip={x:Math.floor(box.x),y:Math.floor(box.y),width:Math.ceil(box.width),height:Math.ceil(box.bottom)-Math.floor(box.y)};
  const png=await rasterPage.screenshot({clip});
  const pixels=await rasterPage.evaluate(async(data)=>{
    const image=new Image();image.src=`data:image/png;base64,${data}`;await image.decode();
    const canvas=document.createElement('canvas');canvas.width=image.width;canvas.height=image.height;
    const ctx=canvas.getContext('2d');ctx.drawImage(image,0,0);const p=ctx.getImageData(0,0,canvas.width,canvas.height).data;
    const bg=p.slice((canvas.width-1)*4,(canvas.width-1)*4+3);let top=Infinity,bottom=-1;
    for(let y=0;y<canvas.height;y++)for(let x=0;x<canvas.width;x++){const i=(y*canvas.width+x)*4;if(Math.max(...bg.map((c,j)=>Math.abs(c-p[i+j])))>24){top=Math.min(top,y);bottom=Math.max(bottom,y);}}
    return bottom<0?null:{topInsetPx:top,bottomInsetPx:canvas.height-1-bottom,inkHeightPx:bottom-top+1,threshold:24};
  },png.toString('base64'));
  if(!pixels)throw Error(`No raster ink found for ${face}/${size}`);
  raster.push({face,size,fontSize:report.nodes.find(n=>n.name==='text').style.fontSize,componentHeight:box.height,pixels,opticalDiagnostic:report.opticalDiagnostic});
}
await fs.writeFile(`${output}/raster.json`,JSON.stringify({engine:'Chromium',dpr:1,sample:'HAMBURG TOKYO 0123456789',locale:'en',note:'Thresholded screenshot ink inside component; no optical approval or font identity inferred.',records:raster},null,2));
await rasterPage.close();
// Check multiline rhythm at the live fluid size, including the former 4xl fold.
for(const locale of ['en','ja']) for(const face of ['flexa','cardinal','cheee']) for(const size of ['md','2xl','4xl']) {
  const report=await specimen(`font=${face}&size=${size}&locale=${locale}&sample=paragraph&mode=single`);
  const d=report.opticalDiagnostic;
  if(!d || Math.abs(d.heightError)>1 || d.leading<=0)throw Error(`Invalid multiline trim: ${face}/${locale}/${size}`);
  if(locale==='ja' && Math.abs(d.interlineGap-11)>.01)throw Error('CJK must retain the half-paragraph gap');
}
await specimen('font=flexa&size=md&mode=single');
const large=await page.evaluate(()=>{
  const el=document.querySelector('#text');
  el.style.fontSize='var(--fs-6xl)';
  el.style.lineHeight='var(--lh-en-6xl)';
  const s=getComputedStyle(el);
  return {size:parseFloat(s.fontSize),leading:parseFloat(s.lineHeight)};
});
if(large.leading!==Math.round((.7*large.size+12.6)/7)*7)throw Error('Generated 6xl leading regressed');
const broken=await page.evaluate(async()=>{
  document.querySelector('#text').style.paddingBottom='12px';
  return (await window.benchMeasure()).findings;
});
if(!broken.some(f=>f.kind==='trim-height-mismatch'))throw Error('Missed injected trim mismatch');
await page.goto(`${origin}/typography-bench`);
await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Ready'));
const scope=process.env.BENCH_SCOPE||'small';
await page.locator('#diagnostics > summary').click();
await page.selectOption('#scope',scope);
await page.click('#run');await page.waitForFunction(()=>document.querySelector('#status').textContent.startsWith('Run complete'),{},{timeout:180000});
const [download]=await Promise.all([page.waitForEvent('download'),page.click('#export')]);await download.saveAs(`${output}/matrix.json`);
const matrix=JSON.parse(await fs.readFile(`${output}/matrix.json`,'utf8'));
const expected=matrix.manifest.options.fonts.length*(scope==='small'?3:matrix.manifest.sizes.length)*matrix.manifest.weights.length*matrix.manifest.locales.length*matrix.manifest.specimens.length;
if(matrix.results.some(r=>r.findings.some(f=>['trim-height-mismatch','invalid-leading','unexpected-layout-gap','measurement-failed'].includes(f.kind))))throw Error('Matrix contains structural failures');
if(matrix.results.length!==expected)throw Error(`Incomplete matrix: ${matrix.results.length}/${expected}`);
await page.screenshot({path:`${output}/bench.png`});
console.log(JSON.stringify({cases:matrix.results.length,findingKinds:matrix.results.flatMap(r=>r.findings).reduce((a,f)=>(a[f.kind]=(a[f.kind]||0)+1,a),{}),actualFonts,checks:'margin fault, wrong font, non-invasive outlines, frame parity passed'}));
await browser.close();
