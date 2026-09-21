from PIL import Image, ImageDraw
from pathlib import Path
import json
root=Path('GetBuket/Assets.xcassets')
root.mkdir(parents=True,exist_ok=True)
(root/'Contents.json').write_text(json.dumps({'info':{'author':'xcode','version':1}}))
def asset(name,im):
 p=root/(name+'.imageset'); p.mkdir(exist_ok=True)
 im.save(p/'image.png')
 (p/'Contents.json').write_text(json.dumps({'images':[{'filename':'image.png','idiom':'universal'}],'info':{'author':'xcode','version':1}}))
for source in Path('assets/cutouts').glob('*.png'):
 im=Image.open(source).convert('RGBA')
 im.thumbnail((1050,1250),Image.Resampling.LANCZOS)
 asset('bouquet-'+source.stem,im)
 # Real flower details, sampled from the top of the same photograph.
 for j,(cx,cy) in enumerate([(0.35,0.18),(0.62,0.25),(0.48,0.12),(0.68,0.15)]):
  size=int(im.width*0.20);x=int(cx*im.width);y=int(cy*im.height)
  part=im.crop((x-size//2,y-size//2,x+size//2,y+size//2))
  mask=Image.new('L',part.size); d=ImageDraw.Draw(mask);d.ellipse((3,3,size-3,size-3),fill=255)
  from PIL import ImageFilter,ImageChops
  mask=mask.filter(ImageFilter.GaussianBlur(3));part.putalpha(ImageChops.multiply(part.getchannel('A'),mask))
  asset('petal-'+source.stem+'-'+str(j),part)
asset('brand-logo',Image.open('assets/logo.png').convert('RGBA'))
# A simple legible brand app icon.
im=Image.new('RGB',(1024,1024),'#F5F7FA');d=ImageDraw.Draw(im)
for x,y,angle in [(390,360,0),(630,360,0),(510,240,0),(510,480,0)]:
 d.ellipse((x-155,y-155,x+155,y+155),fill='#BC00FF')
d.ellipse((415,265,605,455),fill='#FFFFFF')
d.polygon([(460,600),(565,600),(660,850),(365,850)],fill='#007852')
p=root/'AppIcon.appiconset';p.mkdir(exist_ok=True);im.save(p/'AppIcon.png')
(p/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'xcode','version':1}}))
