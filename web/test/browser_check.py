"""Browser verification (Playwright). Run: python3 test/browser_check.py  (serves web/ with clean URLs on :3222)"""
import http.server, threading, os, json, sys
from playwright.sync_api import sync_playwright
W = os.path.join(os.path.dirname(__file__), '..')
class H(http.server.SimpleHTTPRequestHandler):
    def __init__(s,*a,**k): super().__init__(*a,directory=W,**k)
    def translate_path(s,p):
        r=super().translate_path(p.split('?')[0])
        return r+'.html' if not os.path.exists(r) and os.path.exists(r+'.html') else r
    def log_message(s,*a): pass
srv=http.server.ThreadingHTTPServer(('127.0.0.1',3222),H); threading.Thread(target=srv.serve_forever,daemon=True).start()
B='http://127.0.0.1:3222'; pages=['','product','features','aquarium','ambient-worlds','creator-studio','productivity','pricing','download','faq','privacy','licensing','support']
SHOT=os.environ.get('SHOTS'); fails=[]
def chk(c,m):
    print(('PASS ' if c else 'FAIL ')+m); 
    if not c: fails.append(m)
def mk(code):
    return lambda r,_=None: r.fulfill(status=code,body='{}')
REL={'tag_name':'v9.9.9','name':'Animatto 9.9.9','published_at':'2026-11-03T00:00:00Z','body':'Notes\nAnimatto.dmg abababababababababababababababababababababababababababababababab',
 'assets':[{'name':'Animatto.dmg','size':5242880,'browser_download_url':'https://github.com/sharmao07/Animatto/releases/download/v9.9.9/Animatto.dmg'},{'name':'evil.dmg','size':1,'browser_download_url':'https://evil.example/x.dmg'}]}
with sync_playwright() as p:
    b=p.chromium.launch()
    for name,vp in [('desktop',{'width':1280,'height':800}),('mobile',{'width':390,'height':780})]:
        ctx=b.new_context(viewport=vp); 
        for path in pages:
            pg=ctx.new_page(); errs=[]
            pg.on('console',lambda m,e=errs: e.append(m.text) if m.type=='error' else None)
            pg.on('pageerror',lambda x,e=errs: e.append(str(x)))
            pg.on('requestfailed',lambda r,e=errs: e.append('REQFAIL '+r.url+' '+str(r.failure)) if 'github.com' not in r.url and 'ERR_ABORTED' not in str(r.failure) else None)
            pg.route('https://api.github.com/**',lambda r: r.fulfill(status=200,content_type='application/json',body=json.dumps(REL)))
            pg.goto(f'{B}/{path}'); pg.wait_for_timeout(700)
            chk(not errs,f'{name} /{path} no console errors {errs[:2]}')
            chk(pg.evaluate('document.documentElement.scrollWidth<=innerWidth+1'),f'{name} /{path} no horizontal overflow')
            if SHOT: pg.screenshot(path=f'{SHOT}/{name}-{path or "home"}.png',full_page=False)
            pg.close()
        ctx.close()
    ctx=b.new_context(viewport={'width':1280,'height':800}); pg=ctx.new_page()
    pg.route('https://api.github.com/**',lambda r: r.fulfill(status=200,content_type='application/json',body=json.dumps(REL)))
    pg.goto(B+'/aquarium'); pg.wait_for_timeout(500)
    pg.click('#aq-themes button:nth-child(3)'); pg.click('#aq-sizes button:nth-child(4)'); pg.wait_for_timeout(600)
    pg.click('canvas',position={'x':100,'y':80}); gt=pg.inner_text('[data-say]'); pg.click('[data-feed]'); fd=pg.inner_text('[data-say]')
    chk(gt.startswith('Glass tap') and fd.startswith('Food pellets'),'aquarium: theme/size/glass tap/feed respond'); chk(pg.evaluate("getComputedStyle(document.querySelector('#aq-stage')).aspectRatio").startswith('3.2'),'aquarium: Panoramic size applied')
    pg.goto(B+'/ambient-worlds'); pg.wait_for_timeout(500); d0=pg.inner_text('[data-desc]'); pg.click('[data-presets] button:nth-child(3)'); chk(pg.inner_text('[data-desc]')!=d0,'ambient: preset switch changes description')
    pg.goto(B+'/productivity'); pg.wait_for_timeout(500); pg.click('[data-go]'); pg.wait_for_timeout(1300); t1=pg.inner_text('[data-time]'); pg.click('[data-go]'); s=pg.inner_text('[data-status]'); pg.click('[data-go]'); pg.click('[data-reset]')
    chk(t1!='25:00' and s=='Paused.' and pg.inner_text('[data-time]')=='25:00','timer: start, pause, resume, reset')
    q0=pg.inner_text('#personality [data-quote]'); pg.click('#personality [data-chips] button:nth-child(4)'); chk(pg.inner_text('#personality [data-quote]')!=q0,'personality: selection changes preview')
    pg.goto(B+'/creator-studio'); pg.wait_for_timeout(500); pg.click('[data-states] button:nth-child(3)'); pg.select_option('#st-bg','#56677d'); pg.fill('#st-size','220'); pg.click('[data-pers] button:nth-child(2)')
    chk('rgb(86, 103, 125)' in pg.evaluate("document.querySelector('[data-stage]').style.background"),'studio: backdrop applies')
    pg.goto(B+'/download'); pg.wait_for_timeout(700); txt=pg.inner_text('.rel'); chk('9.9.9' in txt and 'Animatto.dmg' in txt and '5.0 MB' in txt and 'evil' not in txt,'download: mocked release shown, non-GitHub asset filtered'); chk('abababab' in txt,'download: checksum from release notes shown')
    for status,exp in [(404,'No published release'),(403,'rate limit')]:
        pg2=ctx.new_page(); pg2.route('https://api.github.com/**',mk(status)); pg2.goto(B+'/download'); pg2.wait_for_timeout(600)
        chk(exp in pg2.inner_text('[data-state]') and pg2.is_visible('[data-fallback]'),f'download: {status} handled with fallback link'); pg2.close()
    pg3=ctx.new_page(); pg3.route('https://api.github.com/**',lambda r: r.abort()); pg3.goto(B+'/download'); pg3.wait_for_timeout(600); chk('Couldn' in pg3.inner_text('[data-state]'),'download: network failure handled')
    pg.goto(B+'/pricing'); chk(pg.is_disabled('main button.btn'),'pricing: purchase button disabled')
    m=b.new_context(viewport={'width':390,'height':780}).new_page(); m.goto(B+'/product'); m.click('#mb'); chk(m.is_visible('#nv a[href="/pricing"]'),'mobile menu opens')
    rm=b.new_context(viewport={'width':1280,'height':800},reduced_motion='reduce').new_page(); e=[]; rm.on('pageerror',lambda x:e.append(str(x))); rm.goto(B+'/aquarium'); rm.wait_for_timeout(600); chk(not e,'reduced motion: aquarium loads without errors')
    b.close()
print('FAILURES:',len(fails)); sys.exit(1 if fails else 0)
