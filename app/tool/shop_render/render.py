import asyncio, base64, sys, subprocess, time
from playwright.async_api import async_playwright
items = sys.argv[1:] or ['pen','notebook','mug','bottle','cap','backpack','headphones','tablet','laptop']
srv = subprocess.Popen([sys.executable, '-m', 'http.server', '8765', '--bind', '127.0.0.1'], cwd='/tmp/r3d',
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1)
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(args=['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'])
        pg = await b.new_page(viewport={'width': 1024, 'height': 1024})
        logs = []
        pg.on('console', lambda m: logs.append(m.text))
        pg.on('pageerror', lambda e: logs.append('ERR ' + str(e)))
        await pg.goto('http://127.0.0.1:8765/scene.html')
        await pg.wait_for_function('window.renderItem !== undefined', timeout=60000)
        for it in items:
            url = await pg.evaluate(f'window.renderItem("{it}")')
            open(f'/tmp/r3dout/{it}.png', 'wb').write(base64.b64decode(url.split(',')[1]))
            print('ok', it)
        for l in logs[:20]: print('LOG', l)
        await b.close()
try:
    asyncio.run(main())
finally:
    srv.terminate()
